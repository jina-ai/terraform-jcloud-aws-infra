locals {
  alertmanager_yaml_body = yamlencode({
    "alertmanager" : {
      "config" : try(yamldecode(var.grafana_settings.alertmanager_config), {})
    }
  })

  grafana_yaml_body = !var.enable_grafana ? yamlencode({ "enabled" : false }) : yamlencode({
    "grafana" : {
      "grafana.ini" : {
        "server" : {
          "domain" : try(var.grafana_settings.server_domain, "localhost:3000")
        }
      },
      "database" : try(grafana_settings.database, {}),
      "adminPassword" : var.grafana_settings.admin_password,
    }
  })

  # [TODO] to enable path rewrite: https://stackoverflow.com/questions/66423946/how-can-i-use-kong-s-capturing-group-in-ingress-k8s-object-for-rewirting-logic
  grafana_ingress_yaml_body = var.grafana_settings.ingress_yaml_body != "" ? yamlencode(
    {
      "grafana" : {
        "ingress" : try(yamldecode(var.grafana_settings.ingress_yaml_body), {})
      }
    }
    ) : yamlencode({
      "grafana" : {
        "ingress" : {
          "enabled" : true,
          "ingressClassName" : var.grafana_settings.ingress_class,
          "path" : "/",
          "hosts" : [try(var.grafana_settings.server_domain, "*")],
          "tls" : [
            {
              "secretName" : var.grafana_settings.ingress_tls_secret_name,
              "hosts" : [try(var.grafana_settings.server_domain, "*")]
            }
          ]
        }
      }
  })

  grafana_additional_data_sources_yaml_body = yamlencode({
    "grafana" : {
      "additionalDataSources" : var.grafana_settings.additional_data_sources != [] ? yamldecode(var.grafana_settings.additional_data_sources) : []
    }
  })

  default_additional_scrape_configs = <<-YAML
  - job_name: gpu-metrics
    scrape_interval: 1s
    metrics_path: /metrics
    scheme: http
    kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
            - nvidia-device-plugin
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_node_name]
        action: replace
        target_label: kubernetes_node
  - job_name: "jina-endpoints"
    kubernetes_sd_configs:
      - role: endpoints
    relabel_configs:
      - source_labels: ["__meta_kubernetes_namespace"]
        regex: "jnamespace-.*"
        action: keep
      - source_labels: ["__meta_kubernetes_endpoint_port_name"]
        regex: "monitoring"
        action: keep
      - source_labels: ["__meta_kubernetes_namespace"]
        target_label: "jina_namespace"
        regex: "jnamespace-(.*)"
      - source_labels: ["__meta_kubernetes_endpoints_label_app"]
        target_label: "jina_instance_name"
      - source_labels: ["__meta_kubernetes_pod_name"]
        target_label: "jina_pod_name"
  YAML

  otlp_scrape_config = <<-YAML
  - job_name: opentelemetry-collector
    scrape_interval: 10s   
    static_configs:
    - targets: ["${var.prometheus_otlp_collector_scrape_endpoint}"]
  YAML

  prometheus_additional_scrape_config_yaml_body = yamlencode({
    "prometheus" : {
      "prometheusSpec" : {
        "additionalScrapeConfigs" : concat(yamldecode(local.default_additional_scrape_configs),
        !var.enable_otlp_collector ? [] : yamldecode(local.otlp_scrape_config))
      }
    }
  })

  prometheus_yaml_body = yamlencode({
    "prometheus" : {
      "thanosService" : {
        "enabled" : var.enable_thanos
      },
      "prometheusSpec" : {
        "externalLabels" : {
          "cluster" : var.cluster_name,
          "cluster_id" : var.cluster_name,
        },
        "thanos" : var.enable_thanos ? {
          "objectStorageConfig" : {
            "name" : var.thanos_object_storage_config_name,
            "key" : var.thanos_object_storage_config_key
          }
        } : {},
      },
    },
  })

  remote_write_url_yaml_body = yamlencode({
    "prometheus": {
      "prometheusSpec": {
        "remoteWrite": [
          {
            "url": var.remote_write_url,
            "metadataConfig": {
              "send": false
            }
          }
        ]
      }
    }
  })
}


resource "helm_release" "prometheus_stack" {
  namespace        = var.namespace
  create_namespace = true

  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "45.19.0"

  values = flatten([
    file("${path.module}/default-prom-values.yaml"),
    local.alertmanager_yaml_body,
    var.enable_grafana == true ? [local.grafana_yaml_body] : [],
    var.enable_grafana == true ? [local.grafana_ingress_yaml_body] : [],
    var.enable_grafana == true ? [local.grafana_additional_data_sources_yaml_body] : [],
    local.prometheus_yaml_body,
    local.prometheus_additional_scrape_config_yaml_body,
    var.remote_write_url != "" ? [local.remote_write_url_yaml_body] : [],
    var.prometheus_stack_overwrite_values_yaml_body,
  ])

  lifecycle {
    precondition {
      condition     = (var.enable_grafana && var.grafana_server_domain != "") || (!var.enable_grafana && var.grafana_server_domain == "")
      error_message = "If grafana is enabled, please also provide server domain address"
    }
    precondition {
      condition     = (var.enable_grafana && var.grafana_database.type != "") || (!var.enable_grafana && var.grafana_database.type == "")
      error_message = "If grafana is enabled, please also provide grafana_database. If grafana is disabled, this is an unused field please remove"
    }
    precondition {
      condition     = (var.enable_grafana && var.grafana_admin_password != "") || (!var.enable_grafana && var.grafana_admin_password == "")
      error_message = "If grafana is enabled, please also provide grafana_admin_password. If grafana is disabled, this is an unused field please remove"
    }
  }
}

resource "kubernetes_config_map" "grafana_flow_dashboard_cm" {
  count = var.enable_grafana ? 1 : 0

  metadata {
    name      = "flow-dashboard"
    namespace = var.namespace
    labels = {
      "grafana_dashboard" : 1
    }
  }
  data = {
    "flow-monitor.json" = file("${path.module}/grafana-dashboards/flow-monitor.json")
    # "admin-flow-monitor.json" = file("${path.module}/grafana-dashboards/admin-flow-monitor.json")
    "flow-monitor-2.json" = file("${path.module}/grafana-dashboards/flow-monitor-2.json")
  }
}