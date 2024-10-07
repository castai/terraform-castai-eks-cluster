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

  custom_labels = try(each.value.custom_labels, {})

  dynamic "custom_taints" {
    for_each = flatten([lookup(each.value, "custom_taints", [])])

    content {
      key    = try(custom_taints.value.key, null)
      value  = try(custom_taints.value.value, null)
      effect = try(custom_taints.value.effect, null)
    }
  }

  dynamic "constraints" {
    for_each = [for constraints in flatten([lookup(each.value, "constraints", [])]) : constraints if constraints != null]

    content {
      compute_optimized                           = try(constraints.value.compute_optimized, null)
      storage_optimized                           = try(constraints.value.storage_optimized, null)
      compute_optimized_state                     = try(constraints.value.compute_optimized_state, "")
      storage_optimized_state                     = try(constraints.value.storage_optimized_state, "")
      is_gpu_only                                 = try(constraints.value.is_gpu_only, false)
      spot                                        = try(constraints.value.spot, false)
      on_demand                                   = try(constraints.value.on_demand, null)
      use_spot_fallbacks                          = try(constraints.value.use_spot_fallbacks, false)
      fallback_restore_rate_seconds               = try(constraints.value.fallback_restore_rate_seconds, null)
      enable_spot_diversity                       = try(constraints.value.enable_spot_diversity, false)
      spot_diversity_price_increase_limit_percent = try(constraints.value.spot_diversity_price_increase_limit_percent, null)
      spot_interruption_predictions_enabled       = try(constraints.value.spot_interruption_predictions_enabled, false)
      spot_interruption_predictions_type          = try(constraints.value.spot_interruption_predictions_type, null)
      min_cpu                                     = try(constraints.value.min_cpu, null)
      max_cpu                                     = try(constraints.value.max_cpu, null)
      min_memory                                  = try(constraints.value.min_memory, null)
      max_memory                                  = try(constraints.value.max_memory, null)
      architectures                               = try(constraints.value.architectures, ["amd64"])
      architecture_priority                       = try(constraints.value.architecture_priority, [])
      azs                                         = try(constraints.value.azs, null)
      burstable_instances                         = try(constraints.value.burstable_instances, null)
      customer_specific                           = try(constraints.value.customer_specific, null)
      cpu_manufacturers                           = try(constraints.value.cpu_manufacturers, null)

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
          manufacturers = try(gpu.value.manufacturers, [])
          include_names = try(gpu.value.include_names, [])
          exclude_names = try(gpu.value.exclude_names, [])
          min_count     = try(gpu.value.min_count, null)
          max_count     = try(gpu.value.max_count, null)
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

  name              = try(each.value.name, each.key)
  cluster_id        = castai_eks_cluster.my_castai_cluster.id

  apply_type        = try(each.value.apply_type, "DEFERRED")
  management_option = try(each.value.management_option, "READ_ONLY")
  cpu {
    function        = try(each.value.cpu.function, "QUANTILE")
    overhead        = try(each.value.cpu.overhead, 0)
    apply_threshold = try(each.value.cpu.apply_threshold, 0.1)
    args            = try(each.value.cpu.args, ["0.8"])
  }
  memory {
    function        = try(each.value.memory.function, "MAX")
    overhead        = try(each.value.memory.overhead, 0.1)
    apply_threshold = try(each.value.memory.apply_threshold, 0.1)
  }
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

  set {
    name  = "replicaCount"
    value = "2"
  }

  set {
    name  = "provider"
    value = "eks"
  }

  set {
    name  = "additionalEnv.STATIC_CLUSTER_ID"
    value = castai_eks_cluster.my_castai_cluster.id
  }

  set {
    name  = "createNamespace"
    value = "false"
  }

  dynamic "set" {
    for_each = var.api_url != "" ? [var.api_url] : []
    content {
      name  = "apiURL"
      value = var.api_url
    }
  }

  dynamic "set" {
    for_each = var.agent_aws_iam_service_account_role_arn != "" ? [var.agent_aws_iam_service_account_role_arn] : []
    content {
      name  = "serviceAccount.annotations.eks\\.\\amazonaws\\.\\com/role-arn"
      value = var.agent_aws_iam_service_account_role_arn
    }
  }

  dynamic "set_sensitive" {
    for_each = var.agent_aws_access_key_id != "" ? [var.agent_aws_access_key_id] : []
    content {
      name  = "additionalSecretEnv.AWS_ACCESS_KEY_ID"
      value = var.agent_aws_access_key_id
    }
  }

  dynamic "set_sensitive" {
    for_each = var.agent_aws_secret_access_key != "" ? [var.agent_aws_secret_access_key] : []
    content {
      name  = "additionalSecretEnv.AWS_SECRET_ACCESS_KEY"
      value = var.agent_aws_secret_access_key
    }
  }

  set_sensitive {
    name  = "apiKey"
    value = castai_eks_cluster.my_castai_cluster.cluster_token
  }

  dynamic "set" {
    for_each = var.castai_components_labels
    content {
      name  = "podLabels.${set.key}"
      value = set.value
    }
  }
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

  set {
    name  = "castai.clusterID"
    value = castai_eks_cluster.my_castai_cluster.id
  }

  dynamic "set" {
    for_each = var.api_url != "" ? [var.api_url] : []
    content {
      name  = "castai.apiURL"
      value = var.api_url
    }
  }

  set_sensitive {
    name  = "castai.apiKey"
    value = castai_eks_cluster.my_castai_cluster.cluster_token
  }

  dynamic "set" {
    for_each = var.castai_components_labels
    content {
      name  = "podLabels.${set.key}"
      value = set.value
    }
  }

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

  set {
    name  = "castai.clusterID"
    value = castai_eks_cluster.my_castai_cluster.id
  }

  dynamic "set" {
    for_each = var.api_url != "" ? [var.api_url] : []
    content {
      name  = "castai.apiURL"
      value = var.api_url
    }
  }

  set_sensitive {
    name  = "castai.apiKey"
    value = castai_eks_cluster.my_castai_cluster.cluster_token
  }

  dynamic "set" {
    for_each = var.castai_components_labels
    content {
      name  = "podLabels.${set.key}"
      value = set.value
    }
  }

  depends_on = [helm_release.castai_agent, helm_release.castai_cluster_controller]
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

  set {
    name  = "castai.apiKeySecretRef"
    value = "castai-cluster-controller"
  }

  set {
    name  = "castai.configMapRef"
    value = "castai-cluster-controller"
  }

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

  set {
    name  = "castai.apiKeySecretRef"
    value = "castai-cluster-controller"
  }

  set {
    name  = "castai.configMapRef"
    value = "castai-cluster-controller"
  }

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

  set {
    name  = "castai.apiURL"
    value = var.api_url
  }

  set {
    name  = "castai.apiKey"
    value = castai_eks_cluster.my_castai_cluster.cluster_token
  }

  set {
    name  = "castai.clusterID"
    value = castai_eks_cluster.my_castai_cluster.id
  }

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

  set {
    name  = "castai.apiURL"
    value = var.api_url
  }

  set {
    name  = "castai.apiKey"
    value = castai_eks_cluster.my_castai_cluster.cluster_token
  }

  set {
    name  = "castai.clusterID"
    value = castai_eks_cluster.my_castai_cluster.id
  }

  depends_on = [helm_release.castai_agent, helm_release.castai_egressd]
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

  set {
    name  = "replicaCount"
    value = "0"
  }

  set {
    name  = "castai-evictor-ext.enabled"
    value = "false"
  }

  depends_on = [helm_release.castai_agent]

  lifecycle {
    ignore_changes = [set, version]
  }

  dynamic "set" {
    for_each = var.castai_components_labels
    content {
      name  = "podLabels.${set.key}"
      value = set.value
    }
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

  set {
    name  = "castai-evictor-ext.enabled"
    value = "false"
  }

  depends_on = [helm_release.castai_agent, helm_release.castai_evictor]

  dynamic "set" {
    for_each = var.castai_components_labels
    content {
      name  = "podLabels.${set.key}"
      value = set.value
    }
  }
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

  depends_on = [helm_release.castai_agent]
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

  set {
    name  = "castai.clusterID"
    value = castai_eks_cluster.my_castai_cluster.id
  }

  dynamic "set" {
    for_each = var.api_url != "" ? [var.api_url] : []
    content {
      name  = "castai.apiURL"
      value = var.api_url
    }
  }

  set_sensitive {
    name  = "castai.apiKey"
    value = castai_eks_cluster.my_castai_cluster.cluster_token
  }

  dynamic "set" {
    for_each = var.grpc_url != "" ? [var.grpc_url] : []
    content {
      name  = "castai.grpcURL"
      value = var.grpc_url
    }
  }

  dynamic "set" {
    for_each = var.castai_components_labels
    content {
      name  = "podLabels.${set.key}"
      value = set.value
    }
  }

  set {
    name  = "replicaCount"
    value = "0"
  }

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

  set {
    name  = "castai.clusterID"
    value = castai_eks_cluster.my_castai_cluster.id
  }

  dynamic "set" {
    for_each = var.api_url != "" ? [var.api_url] : []
    content {
      name  = "castai.apiURL"
      value = var.api_url
    }
  }

  set_sensitive {
    name  = "castai.apiKey"
    value = castai_eks_cluster.my_castai_cluster.cluster_token
  }

  dynamic "set" {
    for_each = var.grpc_url != "" ? [var.grpc_url] : []
    content {
      name  = "castai.grpcURL"
      value = var.grpc_url
    }
  }

  dynamic "set" {
    for_each = var.castai_components_labels
    content {
      name  = "podLabels.${set.key}"
      value = set.value
    }
  }

  depends_on = [helm_release.castai_agent, helm_release.castai_pod_pinner]
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

  set {
    name  = "castai.provider"
    value = "aws"
  }

  set {
    name  = "createNamespace"
    value = "false"
  }

  dynamic "set" {
    for_each = var.api_url != "" ? [var.api_url] : []
    content {
      name  = "castai.apiURL"
      value = var.api_url
    }
  }

  set {
    name  = "castai.clusterID"
    value = castai_eks_cluster.my_castai_cluster.id
  }

  dynamic "set" {
    for_each = var.castai_components_labels
    content {
      name  = "podLabels.${set.key}"
      value = set.value
    }
  }

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
  wait = var.kvisor_wait

  lifecycle {
    ignore_changes = [version]
  }

  set {
    name  = "castai.clusterID"
    value = castai_eks_cluster.my_castai_cluster.id
  }

  set_sensitive {
    name  = "castai.apiKey"
    value = castai_eks_cluster.my_castai_cluster.cluster_token
  }

  set {
    name  = "castai.grpcAddr"
    value = var.api_grpc_addr
  }

  dynamic "set" {
    for_each = var.kvisor_controller_extra_args
    content {
      name  = "controller.extraArgs.${set.key}"
      value = set.value
    }
  }

  set {
    name  = "controller.extraArgs.kube-bench-cloud-provider"
    value = "eks"
  }
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
  wait = var.kvisor_wait

  set {
    name  = "castai.clusterID"
    value = castai_eks_cluster.my_castai_cluster.id
  }

  set_sensitive {
    name  = "castai.apiKey"
    value = castai_eks_cluster.my_castai_cluster.cluster_token
  }

  set {
    name  = "castai.grpcAddr"
    value = var.api_grpc_addr
  }

  dynamic "set" {
    for_each = var.kvisor_controller_extra_args
    content {
      name  = "controller.extraArgs.${set.key}"
      value = set.value
    }
  }

  set {
    name  = "controller.extraArgs.kube-bench-cloud-provider"
    value = "eks"
  }

  depends_on = [helm_release.castai_kvisor]
}

resource "castai_autoscaler" "castai_autoscaler_policies" {
  cluster_id = castai_eks_cluster.my_castai_cluster.id

  autoscaler_policies_json = var.autoscaler_policies_json

  dynamic "autoscaler_settings" {
    for_each = var.autoscaler_settings != null ? [var.autoscaler_settings] : []

    content {
      enabled                                 = try(autoscaler_settings.value.enabled, null)
      is_scoped_mode                          = try(autoscaler_settings.value.is_scoped_mode, null)
      node_templates_partial_matching_enabled = try(autoscaler_settings.value.node_templates_partial_matching_enabled, null)

      dynamic "unschedulable_pods" {
        for_each = try([autoscaler_settings.value.unschedulable_pods], [])

        content {
          enabled                  = try(unschedulable_pods.value.enabled, null)
          custom_instances_enabled = try(unschedulable_pods.value.custom_instances_enabled, null)

          dynamic "headroom" {
            for_each = try([unschedulable_pods.value.headroom], [])

            content {
              enabled           = try(headroom.value.enabled, null)
              cpu_percentage    = try(headroom.value.cpu_percentage, null)
              memory_percentage = try(headroom.value.memory_percentage, null)
            }
          }

          dynamic "headroom_spot" {
            for_each = try([unschedulable_pods.value.headroom_spot], [])

            content {
              enabled           = try(headroom_spot.value.enabled, null)
              cpu_percentage    = try(headroom_spot.value.cpu_percentage, null)
              memory_percentage = try(headroom_spot.value.memory_percentage, null)
            }
          }

          dynamic "node_constraints" {
            for_each = try([unschedulable_pods.value.node_constraints], [])

            content {
              enabled       = try(node_constraints.value.enabled, null)
              min_cpu_cores = try(node_constraints.value.min_cpu_cores, null)
              max_cpu_cores = try(node_constraints.value.max_cpu_cores, null)
              min_ram_mib   = try(node_constraints.value.min_ram_mib, null)
              max_ram_mib   = try(node_constraints.value.max_ram_mib, null)
            }
          }

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

      dynamic "spot_instances" {
        for_each = try([autoscaler_settings.value.spot_instances], [])

        content {
          enabled                             = try(spot_instances.value.enabled, null)
          max_reclaim_rate                    = try(spot_instances.value.max_reclaim_rate, null)
          spot_diversity_enabled              = try(spot_instances.value.spot_diversity_enabled, null)
          spot_diversity_price_increase_limit = try(spot_instances.value.spot_diversity_price_increase_limit, null)

          dynamic "spot_backups" {
            for_each = try([spot_instances.value.spot_backups], [])

            content {
              enabled                          = try(spot_backups.value.enabled, null)
              spot_backup_restore_rate_seconds = try(spot_backups.value.spot_backup_restore_rate_seconds, null)
            }
          }

          dynamic "spot_interruption_predictions" {
            for_each = try([spot_instances.value.spot_interruption_predictions], [])

            content {
              enabled                            = try(spot_interruption_predictions.value.enabled, null)
              spot_interruption_predictions_type = try(spot_interruption_predictions.value.spot_interruption_predictions_type, null)
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
