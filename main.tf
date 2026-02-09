resource "castai_eks_cluster" "my_castai_cluster" {
  account_id = var.aws_account_id
  region     = var.aws_cluster_region
  name       = var.aws_cluster_name

  delete_nodes_on_disconnect = var.delete_nodes_on_disconnect
  assume_role_arn            = var.aws_assume_role_arn
}

resource "castai_node_configuration" "this" {
  for_each = { for k, v in var.node_configurations : k => v }

  cluster_id = castai_eks_cluster.my_castai_cluster.id

  name              = try(each.value.name, each.key)
  disk_cpu_ratio    = try(each.value.disk_cpu_ratio, 0)
  drain_timeout_sec = try(each.value.drain_timeout_sec, 0)
  min_disk_size     = try(each.value.min_disk_size, 100)
  subnets           = try(each.value.subnets, null)
  ssh_public_key    = try(each.value.ssh_public_key, null)
  image             = try(each.value.image, null)
  tags              = try(each.value.tags, {})
  container_runtime = try(each.value.container_runtime, null)
  init_script       = try(each.value.init_script, null)
  docker_config     = try(each.value.docker_config, null)
  kubelet_config    = try(each.value.kubelet_config, null)

  eks {
    security_groups           = try(each.value.security_groups, null)
    dns_cluster_ip            = try(each.value.dns_cluster_ip, null)
    instance_profile_arn      = try(each.value.instance_profile_arn, null)
    key_pair_id               = try(each.value.key_pair_id, null)
    volume_type               = try(each.value.volume_type, null)
    volume_iops               = try(each.value.volume_iops, null)
    volume_throughput         = try(each.value.volume_throughput, null)
    imds_v1                   = try(each.value.imds_v1, null)
    imds_hop_limit            = try(each.value.imds_hop_limit, null)
    volume_kms_key_arn        = try(each.value.volume_kms_key_arn, null)
    max_pods_per_node_formula = try(each.value.max_pods_per_node_formula, null)
    ips_per_prefix            = try(each.value.ips_per_prefix, null)
    eks_image_family          = try(each.value.eks_image_family, null)
    node_group_arn            = try(each.value.node_group_arn, null)
    threads_per_cpu           = try(each.value.threads_per_cpu, null)

    dynamic "target_group" {
      for_each = try(each.value.target_group, {})
      content {
        arn  = target_group.value.arn
        port = target_group.value.port
      }
    }
  }
}

resource "castai_node_template" "this" {
  for_each = { for k, v in var.node_templates : k => v }

  cluster_id = castai_eks_cluster.my_castai_cluster.id

  name             = try(each.value.name, each.key)
  is_default       = try(each.value.is_default, false)
  is_enabled       = try(each.value.is_enabled, true)
  configuration_id = try(each.value.configuration_name, null) != null ? castai_node_configuration.this[each.value.configuration_name].id : try(each.value.configuration_id, null)
  should_taint     = try(each.value.should_taint, true)
  clm_enabled      = try(each.value.clm_enabled, false)

  custom_labels = try(each.value.custom_labels, {})

  dynamic "custom_taints" {
    for_each = flatten([lookup(each.value, "custom_taints", [])])

    content {
      key    = try(custom_taints.value.key, null)
      value  = try(custom_taints.value.value, null)
      effect = try(custom_taints.value.effect, null)
    }
  }

  edge_location_ids = try(each.value.edge_location_ids, null)

  dynamic "constraints" {
    for_each = [for constraints in flatten([lookup(each.value, "constraints", [])]) : constraints if constraints != null]

    content {
      compute_optimized                             = try(constraints.value.compute_optimized, null)
      storage_optimized                             = try(constraints.value.storage_optimized, null)
      compute_optimized_state                       = try(constraints.value.compute_optimized_state, "")
      storage_optimized_state                       = try(constraints.value.storage_optimized_state, "")
      is_gpu_only                                   = try(constraints.value.is_gpu_only, false)
      spot                                          = try(constraints.value.spot, false)
      on_demand                                     = try(constraints.value.on_demand, null)
      use_spot_fallbacks                            = try(constraints.value.use_spot_fallbacks, false)
      fallback_restore_rate_seconds                 = try(constraints.value.fallback_restore_rate_seconds, null)
      enable_spot_diversity                         = try(constraints.value.enable_spot_diversity, false)
      spot_diversity_price_increase_limit_percent   = try(constraints.value.spot_diversity_price_increase_limit_percent, null)
      spot_reliability_enabled                      = try(constraints.value.spot_reliability_enabled, false)
      spot_reliability_price_increase_limit_percent = try(constraints.value.spot_reliability_price_increase_limit_percent, null)
      spot_interruption_predictions_enabled         = try(constraints.value.spot_interruption_predictions_enabled, false)
      spot_interruption_predictions_type            = try(constraints.value.spot_interruption_predictions_type, null)
      min_cpu                                       = try(constraints.value.min_cpu, null)
      max_cpu                                       = try(constraints.value.max_cpu, null)
      min_memory                                    = try(constraints.value.min_memory, null)
      max_memory                                    = try(constraints.value.max_memory, null)
      architectures                                 = try(constraints.value.architectures, ["amd64"])
      architecture_priority                         = try(constraints.value.architecture_priority, [])
      azs                                           = try(constraints.value.azs, null)
      bare_metal                                    = try(constraints.value.bare_metal, false)
      burstable_instances                           = try(constraints.value.burstable_instances, null)
      customer_specific                             = try(constraints.value.customer_specific, null)
      cpu_manufacturers                             = try(constraints.value.cpu_manufacturers, null)

      dynamic "instance_families" {
        for_each = [for instance_families in flatten([lookup(constraints.value, "instance_families", [])]) : instance_families if instance_families != null]

        content {
          include = try(instance_families.value.include, [])
          exclude = try(instance_families.value.exclude, [])
        }
      }

      dynamic "gpu" {
        for_each = [for gpu in flatten([lookup(constraints.value, "gpu", [])]) : gpu if gpu != null]

        content {
          manufacturers   = try(gpu.value.manufacturers, [])
          include_names   = try(gpu.value.include_names, [])
          exclude_names   = try(gpu.value.exclude_names, [])
          min_count       = try(gpu.value.min_count, null)
          max_count       = try(gpu.value.max_count, null)
          fractional_gpus = try(gpu.value.fractional_gpus, null)
        }
      }

      dynamic "custom_priority" {
        for_each = [for custom_priority in flatten([lookup(constraints.value, "custom_priority", [])]) : custom_priority if custom_priority != null]

        content {
          instance_families = try(custom_priority.value.instance_families, [])
          spot              = try(custom_priority.value.spot, false)
          on_demand         = try(custom_priority.value.on_demand, false)
        }
      }

      dynamic "resource_limits" {
        for_each = [for resource_limits in flatten([lookup(constraints.value, "resource_limits", [])]) : resource_limits if resource_limits != null]

        content {
          cpu_limit_enabled   = try(resource_limits.value.cpu_limit_enabled, false)
          cpu_limit_max_cores = try(resource_limits.value.cpu_limit_max_cores, 0)
        }
      }
    }
  }

  dynamic "gpu" {
    for_each = [for gpu in flatten([lookup(each.value, "gpu", [])]) : gpu if gpu != null]

    content {
      enable_time_sharing            = try(gpu.value.enable_time_sharing, null)
      default_shared_clients_per_gpu = try(gpu.value.default_shared_clients_per_gpu, null)

      dynamic "sharing_configuration" {
        for_each = [for sharing_configuration in flatten([lookup(gpu.value, "sharing_configuration", [])]) : sharing_configuration if sharing_configuration != null]

        content {
          gpu_name               = try(sharing_configuration.value.gpu_name, null)
          shared_clients_per_gpu = try(sharing_configuration.value.shared_clients_per_gpu, null)
        }
      }
    }
  }
  depends_on = [castai_autoscaler.castai_autoscaler_policies]
}

resource "castai_node_configuration_default" "this" {
  cluster_id       = castai_eks_cluster.my_castai_cluster.id
  configuration_id = var.default_node_configuration_name != "" ? castai_node_configuration.this[var.default_node_configuration_name].id : var.default_node_configuration
}

resource "castai_workload_scaling_policy" "this" {
  for_each = { for k, v in var.workload_scaling_policies : k => v }

  name       = try(each.value.name, each.key)
  cluster_id = castai_eks_cluster.my_castai_cluster.id

  apply_type        = try(each.value.apply_type, "DEFERRED")
  management_option = try(each.value.management_option, "READ_ONLY")

  cpu {
    function                 = try(each.value.cpu.function, "QUANTILE")
    overhead                 = try(each.value.cpu.overhead, 0)
    apply_threshold          = try(each.value.cpu.apply_threshold, 0.1)
    args                     = try(each.value.cpu.args, ["0.8"])
    look_back_period_seconds = try(each.value.cpu.look_back_period_seconds, null)
    min                      = try(each.value.cpu.min, null)
    max                      = try(each.value.cpu.max, null)
    management_option        = try(each.value.cpu.management_option, null)

    dynamic "apply_threshold_strategy" {
      for_each = try([each.value.cpu.apply_threshold_strategy], [])
      content {
        type        = try(apply_threshold_strategy.value.type, null)
        percentage  = try(apply_threshold_strategy.value.percentage, null)
        numerator   = try(apply_threshold_strategy.value.numerator, null)
        denominator = try(apply_threshold_strategy.value.denominator, null)
        exponent    = try(apply_threshold_strategy.value.exponent, null)
      }
    }

    dynamic "limit" {
      for_each = try([each.value.cpu.limit], [])
      content {
        type       = try(limit.value.type, null)
        multiplier = try(limit.value.multiplier, null)
      }
    }
  }

  memory {
    function                 = try(each.value.memory.function, "MAX")
    overhead                 = try(each.value.memory.overhead, 0.1)
    apply_threshold          = try(each.value.memory.apply_threshold, 0.1)
    args                     = try(each.value.memory.args, null)
    look_back_period_seconds = try(each.value.memory.look_back_period_seconds, null)
    min                      = try(each.value.memory.min, null)
    max                      = try(each.value.memory.max, null)
    management_option        = try(each.value.memory.management_option, null)

    dynamic "apply_threshold_strategy" {
      for_each = try([each.value.memory.apply_threshold_strategy], [])
      content {
        type        = try(apply_threshold_strategy.value.type, null)
        percentage  = try(apply_threshold_strategy.value.percentage, null)
        numerator   = try(apply_threshold_strategy.value.numerator, null)
        denominator = try(apply_threshold_strategy.value.denominator, null)
        exponent    = try(apply_threshold_strategy.value.exponent, null)
      }
    }

    dynamic "limit" {
      for_each = try([each.value.memory.limit], [])
      content {
        type       = try(limit.value.type, null)
        multiplier = try(limit.value.multiplier, null)
      }
    }
  }

  dynamic "assignment_rules" {
    for_each = try([each.value.assignment_rules], [])
    content {
      dynamic "rules" {
        for_each = try(assignment_rules.value.rules, [])
        content {
          dynamic "namespace" {
            for_each = try([rules.value.namespace], [])
            content {
              names = try(namespace.value.names, null)
            }
          }

          dynamic "workload" {
            for_each = try([rules.value.workload], [])
            content {
              gvk = try(workload.value.gvk, null)

              dynamic "labels_expressions" {
                for_each = try(workload.value.labels_expressions, [])
                content {
                  key      = try(labels_expressions.value.key, null)
                  operator = try(labels_expressions.value.operator, null)
                  values   = try(labels_expressions.value.values, null)
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "confidence" {
    for_each = try([each.value.confidence], [])
    content {
      threshold = try(confidence.value.threshold, null)
    }
  }

  dynamic "startup" {
    for_each = try([each.value.startup], [])
    content {
      period_seconds = try(startup.value.period_seconds, null)
    }
  }

  dynamic "downscaling" {
    for_each = try([each.value.downscaling], [])
    content {
      apply_type = try(downscaling.value.apply_type, null)
    }
  }

  dynamic "memory_event" {
    for_each = try([each.value.memory_event], [])
    content {
      apply_type = try(memory_event.value.apply_type, null)
    }
  }

  dynamic "anti_affinity" {
    for_each = try([each.value.anti_affinity], [])
    content {
      consider_anti_affinity = try(anti_affinity.value.consider_anti_affinity, null)
    }
  }

  dynamic "predictive_scaling" {
    for_each = try([each.value.predictive_scaling], [])
    content {
      dynamic "cpu" {
        for_each = try([predictive_scaling.value.cpu], [])
        content {
          enabled = try(cpu.value.enabled, null)
        }
      }
    }
  }

  dynamic "rollout_behavior" {
    for_each = try([each.value.rollout_behavior], [])
    content {
      type              = try(rollout_behavior.value.type, null)
      prefer_one_by_one = try(rollout_behavior.value.prefer_one_by_one, null)
    }
  }

  depends_on = [helm_release.castai_workload_autoscaler]
}

resource "helm_release" "castai_agent" {
  name             = "castai-agent"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-agent"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.agent_version
  values  = var.agent_values

  set = concat(
    [
      {
        name  = "replicaCount"
        value = "2"
        }, {
        name  = "provider"
        value = "eks"
        }, {
        name  = "additionalEnv.STATIC_CLUSTER_ID"
        value = castai_eks_cluster.my_castai_cluster.id
        }, {
        name  = "createNamespace"
        value = "false"
      }
    ],
    // castai-agent chart requires "apiURL" on the top level, NOT under "castai.apiURL"
    var.api_url != "" ? [{
      name  = "apiURL"
      value = var.api_url
    }] : [],
    local.set_agent_aws_iam_service_account_role_arn,
    local.set_pod_labels,
    local.set_components_sets,
  )

  set_sensitive = concat(
    [
      // castai-agent chart requires "apiKey" on the top level, NOT under "castai.apiKey"
      {
        name  = "apiKey"
        value = castai_eks_cluster.my_castai_cluster.cluster_token
      }
    ],
    local.set_sensitive_aws_access_key,
    local.set_sensitive_aws_secret_access_key,
    local.set_sensitive_apikey,
  )
}

resource "helm_release" "castai_cluster_controller" {
  count = var.self_managed ? 0 : 1

  name             = "cluster-controller"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-cluster-controller"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.cluster_controller_version
  values  = var.cluster_controller_values

  set = concat(
    local.set_cluster_id,
    local.set_apiurl,
    local.set_pod_labels,
    local.set_components_sets,
  )

  set_sensitive = local.set_sensitive_apikey

  depends_on = [helm_release.castai_agent]

  lifecycle {
    ignore_changes = [version]
  }
}

resource "helm_release" "castai_cluster_controller_self_managed" {
  count = var.self_managed ? 1 : 0

  name             = "cluster-controller"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-cluster-controller"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.cluster_controller_version
  values  = var.cluster_controller_values

  set = concat(
    local.set_cluster_id,
    local.set_apiurl,
    local.set_pod_labels,
    local.set_components_sets,
  )

  set_sensitive = local.set_sensitive_apikey

  depends_on = [helm_release.castai_agent]
}

# Helm Release for CAST AI Pod Mutator
resource "helm_release" "castai_pod_mutator" {
  count = var.install_pod_mutator && !var.self_managed ? 1 : 0

  name             = "castai-pod-mutator"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-pod-mutator"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.pod_mutator_version
  values  = var.pod_mutator_values

  set = concat(
    local.set_cluster_id,
    local.set_organization_id,
    local.set_apiurl,
    local.set_pod_labels,
    local.set_components_sets,
  )

  set_sensitive = local.set_sensitive_apikey

  depends_on = [helm_release.castai_agent, helm_release.castai_cluster_controller]

  lifecycle {
    ignore_changes = [version]
  }
}
#---------------------------------------------------#
# CAST.AI Workload Autoscaler configuration         #
#---------------------------------------------------#
resource "helm_release" "castai_workload_autoscaler" {
  count = var.install_workload_autoscaler && !var.self_managed ? 1 : 0

  name             = "castai-workload-autoscaler"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-workload-autoscaler"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.workload_autoscaler_version
  values  = var.workload_autoscaler_values

  set = concat(
    [
      {
        name  = "castai.apiKeySecretRef"
        value = "castai-cluster-controller"
      },
      {
        name  = "castai.configMapRef"
        value = "castai-cluster-controller"
      },
    ],
    local.set_components_sets,
  )

  depends_on = [helm_release.castai_agent, helm_release.castai_cluster_controller]

  lifecycle {
    ignore_changes = [version]
  }
}

resource "helm_release" "castai_workload_autoscaler_self_managed" {
  count = var.install_workload_autoscaler && var.self_managed ? 1 : 0

  name             = "castai-workload-autoscaler"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-workload-autoscaler"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.workload_autoscaler_version
  values  = var.workload_autoscaler_values

  set = concat(
    [
      {
        name  = "castai.apiKeySecretRef"
        value = "castai-cluster-controller"
      },
      {
        name  = "castai.configMapRef"
        value = "castai-cluster-controller"
      },
    ],
    local.set_components_sets,
  )

  depends_on = [helm_release.castai_agent, helm_release.castai_cluster_controller]
}

#----------------------------------------------------#
# CAST.AI Workload Autoscaler Exporter configuration #
#----------------------------------------------------#
resource "helm_release" "castai_workload_autoscaler_exporter" {
  count = var.install_workload_autoscaler_exporter && !var.self_managed ? 1 : 0

  name             = "castai-workload-autoscaler-exporter"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-workload-autoscaler-exporter"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.workload_autoscaler_exporter_version
  values  = var.workload_autoscaler_exporter_values

  set = concat(
    [
      {
        name  = "castai.apiKeySecretRef"
        value = "castai-cluster-controller"
      },
      {
        name  = "castai.configMapRef"
        value = "castai-cluster-controller"
      },
    ],
    local.set_components_sets,
  )

  depends_on = [helm_release.castai_agent, helm_release.castai_cluster_controller]

  lifecycle {
    ignore_changes = [version]
  }
}

resource "helm_release" "castai_workload_autoscaler_exporter_self_managed" {
  count = var.install_workload_autoscaler_exporter && var.self_managed ? 1 : 0

  name             = "castai-workload-autoscaler-exporter"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-workload-autoscaler-exporter"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.workload_autoscaler_exporter_version
  values  = var.workload_autoscaler_exporter_values

  set = concat(
    [
      {
        name  = "castai.apiKeySecretRef"
        value = "castai-cluster-controller"
      },
      {
        name  = "castai.configMapRef"
        value = "castai-cluster-controller"
      },
    ],
    local.set_components_sets,
  )

  depends_on = [helm_release.castai_agent, helm_release.castai_cluster_controller]
}

#---------------------------------------------------#
# CAST.AI Network Cost Monitoring configuration     #
#---------------------------------------------------#
resource "helm_release" "castai_egressd" {
  count = var.install_egressd && !var.self_managed ? 1 : 0

  name             = "castai-egressd"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "egressd"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.egressd_version
  values  = var.egressd_values

  set = concat(
    local.set_cluster_id,
    local.set_apiurl,
    local.set_components_sets,
  )

  set_sensitive = local.set_sensitive_apikey

  depends_on = [helm_release.castai_agent]

  lifecycle {
    ignore_changes = [version]
  }
}

resource "helm_release" "castai_egressd_self_managed" {
  count = var.install_egressd && var.self_managed ? 1 : 0

  name             = "castai-egressd"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "egressd"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.egressd_version
  values  = var.egressd_values

  set = concat(
    local.set_cluster_id,
    local.set_apiurl,
    local.set_components_sets,
  )

  set_sensitive = local.set_sensitive_apikey

  depends_on = [helm_release.castai_agent]
}

resource "null_resource" "wait_for_cluster" {
  count      = var.wait_for_cluster_ready ? 1 : 0
  depends_on = [helm_release.castai_cluster_controller, helm_release.castai_agent]

  provisioner "local-exec" {
    environment = {
      API_KEY = var.castai_api_token
    }
    command = <<-EOT
        RETRY_COUNT=20
        POOLING_INTERVAL=30

        for i in $(seq 1 $RETRY_COUNT); do
            sleep $POOLING_INTERVAL
            curl -s ${var.api_url}/v1/kubernetes/external-clusters/${castai_eks_cluster.my_castai_cluster.id} -H "x-api-key: $API_KEY" | grep '"status"\s*:\s*"ready"' && exit 0
        done

        echo "Cluster is not ready after 10 minutes"
        exit 1
    EOT

    interpreter = ["bash", "-c"]
  }
}

resource "helm_release" "castai_evictor" {
  count = var.self_managed ? 0 : 1

  name             = "castai-evictor"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-evictor"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.evictor_version
  values  = var.evictor_values

  set = concat(
    [
      {
        name  = "replicaCount"
        value = "0"
      },
      {
        name  = "castai-evictor-ext.enabled"
        value = "false"
      },
    ],
    local.set_pod_labels,
    local.set_components_sets,
  )

  depends_on = [helm_release.castai_agent]

  lifecycle {
    ignore_changes = [set, version]
  }
}

resource "helm_release" "castai_evictor_self_managed" {
  count = var.self_managed ? 1 : 0

  name             = "castai-evictor"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-evictor"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.evictor_version
  values  = var.evictor_values

  set = concat(
    [
      {
        name  = "castai-evictor-ext.enabled"
        value = "false"
      },
      {
        name  = "managedByCASTAI"
        value = "false"
      },
    ],
    try(var.autoscaler_settings.node_downscaler.evictor.enabled, null) == false ? [
      {
        name  = "replicaCount"
        value = "0"
      }
    ] : [],
    local.set_pod_labels,
    local.set_components_sets,
  )

  depends_on = [helm_release.castai_agent]
}

resource "helm_release" "castai_evictor_ext" {
  name             = "castai-evictor-ext"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-evictor-ext"
  namespace        = "castai-agent"
  create_namespace = false
  cleanup_on_fail  = true
  wait             = true

  version = var.evictor_ext_version
  values  = var.evictor_ext_values

  set = concat(
    local.set_components_sets,
  )

  depends_on = [helm_release.castai_evictor, helm_release.castai_evictor_self_managed]
}

resource "helm_release" "castai_pod_pinner" {
  count = var.self_managed ? 0 : 1

  name             = "castai-pod-pinner"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-pod-pinner"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.pod_pinner_version
  values  = var.pod_pinner_values

  set = concat(
    [
      {
        name  = "replicaCount"
        value = "0"
      }
    ],
    local.set_cluster_id,
    local.set_apiurl,
    local.set_grpc_url,
    local.set_pod_labels,
    local.set_components_sets,
  )

  set_sensitive = local.set_sensitive_apikey

  depends_on = [helm_release.castai_agent]

  lifecycle {
    ignore_changes = [version]
  }
}

resource "helm_release" "castai_pod_pinner_self_managed" {
  count = var.self_managed ? 1 : 0

  name             = "castai-pod-pinner"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-pod-pinner"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.pod_pinner_version
  values  = var.pod_pinner_values

  set = concat(
    [
      {
        name  = "managedByCASTAI"
        value = "false"
      }
    ],
    local.set_cluster_id,
    local.set_apiurl,
    local.set_grpc_url,
    local.set_pod_labels,
    local.set_components_sets,
    try(var.autoscaler_settings.unschedulable_pods.pod_pinner.enabled, null) == false ? [
      {
        name  = "replicaCount"
        value = "0"
      }
    ] : [],
  )

  set_sensitive = local.set_sensitive_apikey

  depends_on = [helm_release.castai_agent]
}

resource "helm_release" "castai_spot_handler" {
  name             = "castai-spot-handler"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-spot-handler"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.spot_handler_version
  values  = var.spot_handler_values

  set = concat(
    [
      {
        name  = "castai.provider"
        value = "aws"
      },
      {
        name  = "createNamespace"
        value = "false"
      }
    ],
    local.set_apiurl,
    local.set_cluster_id,
    local.set_pod_labels,
    local.set_components_sets,
  )

  depends_on = [helm_release.castai_agent]
}

resource "helm_release" "castai_kvisor" {
  count = var.install_security_agent && !var.self_managed ? 1 : 0

  name             = "castai-kvisor"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-kvisor"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true

  values  = var.kvisor_values
  version = var.kvisor_version
  wait    = var.kvisor_wait

  lifecycle {
    ignore_changes = [version]
  }

  set = concat(
    [
      {
        name  = "controller.extraArgs.kube-bench-cloud-provider"
        value = "eks"
      },
    ],
    local.set_cluster_id,
    local.set_kvisor_grpc_addr,
    local.set_components_sets,
    [for k, v in var.kvisor_controller_extra_args : {
      name  = "controller.extraArgs.${k}"
      value = v
    }],
  )

  set_sensitive = local.set_sensitive_apikey
}

resource "helm_release" "castai_kvisor_self_managed" {
  count = var.install_security_agent && var.self_managed ? 1 : 0

  name             = "castai-kvisor"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-kvisor"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true

  values  = var.kvisor_values
  version = var.kvisor_version
  wait    = var.kvisor_wait

  set = concat(
    [
      {
        name  = "controller.extraArgs.kube-bench-cloud-provider"
        value = "eks"
      },
    ],
    local.set_cluster_id,
    local.set_kvisor_grpc_addr,
    local.set_components_sets,
    [for k, v in var.kvisor_controller_extra_args : {
      name  = "controller.extraArgs.${k}"
      value = v
    }],
  )

  set_sensitive = local.set_sensitive_apikey
}

resource "helm_release" "castai_pod_mutator_self_managed" {
  count = var.install_pod_mutator && var.self_managed ? 1 : 0

  name             = "castai-pod-mutator"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-pod-mutator"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.pod_mutator_version
  values  = var.pod_mutator_values

  set = concat(
    local.set_cluster_id,
    local.set_organization_id,
    local.set_apiurl,
    local.set_pod_labels,
    local.set_components_sets,
  )

  set_sensitive = local.set_sensitive_apikey

  depends_on = [helm_release.castai_agent, helm_release.castai_cluster_controller]
}

resource "helm_release" "castai_live" {
  count = var.install_live && !var.self_managed ? 1 : 0

  name             = "castai-live"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-live"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  lifecycle {
    ignore_changes = [version]
  }

  version = var.live_version
  values  = var.live_values

  set = concat(
    var.install_live_cni ? [{ name = "castai-aws-vpc-cni.enabled", value = "true" }] : [],
    local.set_cluster_id,
    local.set_apiurl,
    local.set_components_sets,
  )

  set_sensitive = concat(
    local.set_sensitive_apikey,
  )

  depends_on = [helm_release.castai_agent]
}

resource "helm_release" "castai_live_self_managed" {
  count = var.install_live && var.self_managed ? 1 : 0

  name             = "castai-live"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-live"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.live_version
  values  = var.live_values

  set = concat(
    var.install_live_cni ? [{ name = "castai-aws-vpc-cni.enabled", value = "true" }] : [],
    local.set_cluster_id,
    local.set_apiurl,
    local.set_components_sets,
  )

  set_sensitive = concat(
    local.set_sensitive_apikey,
  )

  depends_on = [helm_release.castai_agent]
}

resource "castai_autoscaler" "castai_autoscaler_policies" {
  cluster_id = castai_eks_cluster.my_castai_cluster.id

  dynamic "autoscaler_settings" {
    for_each = var.autoscaler_settings != null ? [var.autoscaler_settings] : []

    content {
      enabled                                 = try(autoscaler_settings.value.enabled, null)
      is_scoped_mode                          = try(autoscaler_settings.value.is_scoped_mode, null)
      node_templates_partial_matching_enabled = try(autoscaler_settings.value.node_templates_partial_matching_enabled, null)

      dynamic "unschedulable_pods" {
        for_each = try([autoscaler_settings.value.unschedulable_pods], [])

        content {
          enabled = try(unschedulable_pods.value.enabled, null)

          dynamic "pod_pinner" {
            for_each = try([unschedulable_pods.value.pod_pinner], [])

            content {
              enabled = try(pod_pinner.value.enabled, null)
            }
          }
        }
      }

      dynamic "cluster_limits" {
        for_each = try([autoscaler_settings.value.cluster_limits], [])

        content {
          enabled = try(cluster_limits.value.enabled, null)


          dynamic "cpu" {
            for_each = try([cluster_limits.value.cpu], [])

            content {
              min_cores = try(cpu.value.min_cores, null)
              max_cores = try(cpu.value.max_cores, null)
            }
          }
        }
      }

      dynamic "node_downscaler" {
        for_each = try([autoscaler_settings.value.node_downscaler], [])

        content {
          enabled = try(node_downscaler.value.enabled, null)

          dynamic "empty_nodes" {
            for_each = try([node_downscaler.value.empty_nodes], [])

            content {
              enabled       = try(empty_nodes.value.enabled, null)
              delay_seconds = try(empty_nodes.value.delay_seconds, null)
            }
          }

          dynamic "evictor" {
            for_each = try([node_downscaler.value.evictor], [])

            content {
              enabled                                = try(evictor.value.enabled, null)
              dry_run                                = try(evictor.value.dry_run, null)
              aggressive_mode                        = try(evictor.value.aggressive_mode, null)
              scoped_mode                            = try(evictor.value.scoped_mode, null)
              cycle_interval                         = try(evictor.value.cycle_interval, null)
              node_grace_period_minutes              = try(evictor.value.node_grace_period_minutes, null)
              pod_eviction_failure_back_off_interval = try(evictor.value.pod_eviction_failure_back_off_interval, null)
              ignore_pod_disruption_budgets          = try(evictor.value.ignore_pod_disruption_budgets, null)
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.castai_agent, helm_release.castai_evictor, helm_release.castai_evictor_ext, helm_release.castai_pod_pinner]
}

resource "helm_release" "castai_ai_optimizer_proxy" {
  count = var.install_ai_optimizer && !var.self_managed ? 1 : 0

  name             = "castai-ai-optimizer-proxy"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-ai-optimizer-proxy"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.ai_optimizer_version
  values  = var.ai_optimizer_values

  set = concat(
    local.set_cluster_id,
    local.set_apiurl,
    local.set_pod_labels,
    local.set_components_sets,
  )

  set_sensitive = local.set_sensitive_apikey

  depends_on = [helm_release.castai_agent, helm_release.castai_cluster_controller]

  lifecycle {
    ignore_changes = [version]
  }
}

resource "helm_release" "castai_ai_optimizer_proxy_self_managed" {
  count = var.install_ai_optimizer && var.self_managed ? 1 : 0

  name             = "castai-ai-optimizer-proxy"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-ai-optimizer-proxy"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  version = var.ai_optimizer_version
  values  = var.ai_optimizer_values

  set = concat(
    local.set_cluster_id,
    local.set_apiurl,
    local.set_pod_labels,
    local.set_components_sets,
  )

  set_sensitive = local.set_sensitive_apikey

  depends_on = [helm_release.castai_agent, helm_release.castai_cluster_controller]
}

data "aws_eks_cluster" "this" {
  count = var.install_omni && !var.self_managed ? 1 : 0

  name = var.aws_cluster_name
}

data "aws_vpc" "eks_vpc" {
  count = var.install_omni && !var.self_managed ? 1 : 0

  id     = data.aws_eks_cluster.this[0].vpc_config[0].vpc_id
  region = var.aws_cluster_region
}

module "castai_omni_cluster" {
  count   = var.install_omni && !var.self_managed ? 1 : 0
  source  = "castai/omni-cluster/castai"
  version = "~> 2.0"

  k8s_provider    = "eks"
  api_url         = var.api_url
  api_token       = var.castai_api_token
  organization_id = castai_eks_cluster.my_castai_cluster.organization_id
  cluster_id      = castai_eks_cluster.my_castai_cluster.id
  cluster_name    = var.aws_cluster_name

  api_server_address = data.aws_eks_cluster.this[0].endpoint
  pod_cidr           = data.aws_vpc.eks_vpc[0].cidr_block
  service_cidr       = data.aws_eks_cluster.this[0].kubernetes_network_config[0].service_ipv4_cidr

  depends_on = [helm_release.castai_agent, helm_release.castai_cluster_controller]
}
