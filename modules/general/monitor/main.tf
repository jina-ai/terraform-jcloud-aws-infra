locals {
  monitor_namespace = "monitor"
}

module "monitor_store" {
  count          = var.enable_monitor_store ? 1 : 0
  source         = "./modules/monitor-store"
  cluster_name   = var.cluster_name
  create_buckets = var.create_buckets
  traces_bucket  = var.traces_bucket
  metrics_bucket = var.metrics_bucket
  log_bucket     = var.log_bucket
  tags           = var.tags
}


resource "kubernetes_namespace" "monitor" {
  metadata {
     name = "monitor"
  }
}

module "prometheus_stack" {
  source                                      = "./modules/prometheus"
  count                                       = (var.enable_metrics || var.enable_prometheus) ? 1 : 0
  namespace                                   = local.monitor_namespace
  alertmanager_config_yaml_body               = var.alertmanager_config_yaml_body
  cluster_name                                = var.cluster_name
  enable_grafana                              = var.enable_grafana
  enable_thanos                               = var.enable_thanos
  grafana_additional_data_sources_yaml_body   = var.grafana_additional_data_sources_yaml_body
  grafana_server_domain                       = var.grafana_server_domain
  grafana_database                            = var.grafana_database
  grafana_admin_password                      = var.grafana_admin_password
  grafana_ingress_tls_secret_name             = var.grafana_ingress_tls_secret_name
  grafana_ingress_class_name                  = var.grafana_ingress_class_name
  grafana_ingress_yaml_body                   = var.grafana_ingress_yaml_body
  thanos_object_storage_config_name           = var.thanos_object_storage_config_name
  thanos_object_storage_config_key            = var.thanos_object_storage_config_key
  prometheus_stack_overwrite_values_yaml_body = var.prometheus_stack_overwrite_values_yaml_body
  enable_loki                                 = var.enable_loki
  enable_tempo                                = var.enable_tempo
  prometheus_otlp_collector_scrape_endpoint   = var.prometheus_otlp_collector_scrape_endpoint
  enable_otlp_collector                       = var.enable_otlp_collector
  enable_logging                              = var.enable_logging
  enable_metrics                              = var.enable_metrics
  enable_tracing                              = var.enable_tracing

  // jcloud-monitor-store is needed
  depends_on = [module.thanos, kubernetes_namespace.monitor]
}

module "promtail" {
  source                              = "./modules/promtail"
  count                               = var.enable_logging || var.enable_promtail ? 1 : 0
  namespace                           = local.monitor_namespace
  clients_urls                        = var.promtail_clients_urls
  promtail_overwrite_values_yaml_body = var.promtail_overwrite_values_yaml_body

  depends_on = [kubernetes_namespace.monitor]
}

module "loki" {
  source                          = "./modules/loki"
  count                           = var.enable_loki ? 1 : 0
  namespace                       = local.monitor_namespace
  loki_overwrite_values_yaml_body = var.loki_overwrite_values_yaml_body
  log_bucket_name                 = var.enable_monitor_store ? module.monitor_store[0].log_bucket_name : var.log_bucket
  log_bucket_region               = var.enable_monitor_store ? module.monitor_store[0].log_bucket_region : var.log_bucket_region
  monitor_iam_access_key_id       = var.enable_monitor_store ? module.monitor_store[0].iam_access_key_id : var.monitor_iam_access_key_id
  monitor_iam_access_key_secret   = var.enable_monitor_store ? module.monitor_store[0].iam_access_key_secret : var.monitor_iam_access_key_secret
  depends_on                      = [module.monitor_store, kubernetes_namespace.monitor]
}

module "tempo" {
  source                           = "./modules/tempo"
  count                            = (var.enable_tracing || var.enable_tempo) ? 1 : 0
  namespace                        = local.monitor_namespace
  tempo_overwrite_values_yaml_body = var.tempo_overwrite_values_yaml_body
  traces_bucket_name               = var.enable_monitor_store ? module.monitor_store[0].traces_bucket_name : var.traces_bucket
  traces_bucket_region             = var.enable_monitor_store ? module.monitor_store[0].traces_bucket_region : var.traces_bucket_region
  monitor_iam_access_key_id        = var.enable_monitor_store ? module.monitor_store[0].iam_access_key_id : var.monitor_iam_access_key_id
  monitor_iam_access_key_secret    = var.enable_monitor_store ? module.monitor_store[0].iam_access_key_secret : var.monitor_iam_access_key_secret
  depends_on                       = [module.monitor_store, kubernetes_namespace.monitor]
}

module "otlp_collector" {
  source                                    = "./modules/otlp-collector"
  count                                     = (var.enable_tracing || var.enable_otlp_collector) ? 1 : 0
  namespace                                 = local.monitor_namespace
  otlp_endpoint                             = var.otlp_endpoint
  otlp_collector_overwrite_values_yaml_body = var.otlp_collector_overwrite_values_yaml_body

  depends_on = [kubernetes_namespace.monitor, module.prometheus_stack]
}

module "thanos" {
  source                            = "./modules/thanos"
  count                             = var.enable_thanos ? 1 : 0
  namespace                         = local.monitor_namespace
  thanos_object_storage_config_name = var.thanos_object_storage_config_name
  thanos_object_storage_config_key  = var.thanos_object_storage_config_key
  thanos_overwrite_values_yaml_body = var.thanos_overwrite_values_yaml_body
  metrics_bucket_name               = var.enable_monitor_store ? module.monitor_store[0].metrics_bucket_name : var.metrics_bucket
  metrics_bucket_region             = var.enable_monitor_store ? module.monitor_store[0].metrics_bucket_region : var.metrics_bucket_region
  monitor_iam_access_key_id         = var.enable_monitor_store ? module.monitor_store[0].iam_access_key_id : var.monitor_iam_access_key_id
  monitor_iam_access_key_secret     = var.enable_monitor_store ? module.monitor_store[0].iam_access_key_secret : var.monitor_iam_access_key_secret
  depends_on                        = [module.monitor_store, kubernetes_namespace.monitor]
}

module "dcgm_exporter" {
  source    = "./modules/dcgm-exporter"
  count     = (var.enable_metrics || var.enable_dcgm_exporter) ? 1 : 0
  namespace = local.monitor_namespace

  depends_on = [kubernetes_namespace.monitor, module.prometheus_stack]
}