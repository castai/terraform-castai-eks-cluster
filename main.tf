resource "castai_eks_cluster" "my_castai_cluster" {
  account_id = var.aws_account_id
  region     = var.aws_cluster_region
  name       = var.aws_cluster_name

  delete_nodes_on_disconnect = var.delete_nodes_on_disconnect
  assume_role_arn            = var.aws_assume_role_arn
}

resource "castai_node_configuration" "this" {
  for_each = {for k, v in var.node_configurations : k => v}

  cluster_id = castai_eks_cluster.my_castai_cluster.id

  name              = try(each.value.name, each.key)
  disk_cpu_ratio    = try(each.value.disk_cpu_ratio, 0)
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
    security_groups      = try(each.value.security_groups, null)
    dns_cluster_ip       = try(each.value.dns_cluster_ip, null)
    instance_profile_arn = try(each.value.instance_profile_arn, null)
    key_pair_id          = try(each.value.key_pair_id, null)
    volume_type          = try(each.value.volume_type, null)
    volume_iops          = try(each.value.volume_iops, null)
    volume_throughput    = try(each.value.volume_throughput, null)
    imds_v1              = try(each.value.imds_v1, null)
    imds_hop_limit       = try(each.value.imds_hop_limit, null)
    volume_kms_key_arn   = try(each.value.volume_kms_key_arn, null)
  }
}

resource "castai_node_template" "this" {
  for_each = {for k, v in var.node_templates : k => v}

  cluster_id = castai_eks_cluster.my_castai_cluster.id

  name             = try(each.value.name, each.key)
  is_default       = try(each.value.is_default, false)
  is_enabled       = try(each.value.is_enabled, null)
  configuration_id = try(each.value.configuration_id, null)
  should_taint     = try(each.value.should_taint, true)

  dynamic "custom_label" {
    for_each = flatten([lookup(each.value, "custom_label", [])])

    content {
      key   = try(custom_label.value.key, null)
      value = try(custom_label.value.value, null)
    }
  }

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
    for_each = flatten([lookup(each.value, "constraints", [])])
    content {
      compute_optimized                           = try(constraints.value.compute_optimized, false)
      storage_optimized                           = try(constraints.value.storage_optimized, false)
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

      dynamic "instance_families" {
        for_each = flatten([lookup(constraints.value, "instance_families", [])])

        content {
          include = try(instance_families.value.include, [])
          exclude = try(instance_families.value.exclude, [])
        }
      }

      dynamic "gpu" {
        for_each = flatten([lookup(constraints.value, "gpu", [])])
        content {
          manufacturers = try(gpu.value.manufacturers, [])
          include_names = try(gpu.value.include_names, [])
          exclude_names = try(gpu.value.exclude_names, [])
          min_count     = try(gpu.value.min_count, null)
          max_count     = try(gpu.value.max_count, null)
        }
      }
    }
  }
  depends_on = [ castai_autoscaler.castai_autoscaler_policies ]
}

resource "castai_node_configuration_default" "this" {
  cluster_id       = castai_eks_cluster.my_castai_cluster.id
  configuration_id = var.default_node_configuration
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

resource "castai_autoscaler" "castai_autoscaler_policies" {
  autoscaler_policies_json = var.autoscaler_policies_json
  cluster_id               = castai_eks_cluster.my_castai_cluster.id

  depends_on = [helm_release.castai_agent, helm_release.castai_evictor]
}

resource "helm_release" "castai_kvisor" {
  count = var.install_security_agent == true ? 1 : 0

  name             = "castai-kvisor"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-kvisor"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true

  values  = var.kvisor_values
  version = var.kvisor_version

  set {
    name  = "castai.apiURL"
    value = var.api_url
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
    name  = "structuredConfig.provider"
    value = "eks"
  }
}
