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
  }
}

resource "castai_node_template" "this" {
  for_each = {for k, v in var.node_templates : k => v}

  cluster_id = castai_eks_cluster.my_castai_cluster.id

  name             = try(each.value.name, each.key)
  configuration_id = try(each.value.configuration_id, null)
  should_taint     = try(each.value.should_taint, true)

  custom_label {
    key   = each.value.custom_label.key
    value = each.value.custom_label.value
  }


  constraints {
    compute_optimized  = try(each.value.compute_optimized, false)
    storage_optimized  = try(each.value.storage_optimized, false)
    spot               = try(each.value.constraints.spot, false)
    use_spot_fallbacks = try(each.value.constraints.spot, false)
    min_cpu            = try(each.value.constraints.min_cpu, null)
    max_cpu            = try(each.value.constraints.max_cpu, null)
    min_memory         = try(each.value.constraints.min_memory, null)
    max_memory         = try(each.value.constraints.max_memory, null)

    instance_families {
      include = try(each.value.constraints.instance_families.include, [])
      exclude = try(each.value.constraints.instance_families.exclude, [])
    }
    gpu {
      manufacturers = try(each.value.constraints.gpu.manufacturers, [])
      include_names = try(each.value.constraints.gpu.include_names, [])
      exclude_names = try(each.value.constraints.gpu.exclude_names, [])
      min_count     = try(each.value.constraints.gpu.min_count, null)
      max_count     = try(each.value.constraints.gpu.max_count, null)
    }
  }
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

  values = var.agent_values

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

  values = var.cluster_controller_values

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

resource "helm_release" "castai_evictor" {
  name             = "castai-evictor"
  repository       = "https://castai.github.io/helm-charts"
  chart            = "castai-evictor"
  namespace        = "castai-agent"
  create_namespace = true
  cleanup_on_fail  = true
  wait             = true

  values = var.evictor_values

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

  values = var.spot_handler_values

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

  values = var.kvisor_values

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
