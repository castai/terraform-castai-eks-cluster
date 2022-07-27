resource "castai_eks_cluster" "my_castai_cluster" {
  account_id                 = var.aws_account_id
  region                     = var.aws_cluster_region
  name                       = var.aws_cluster_name
  subnets                    = var.subnets
  override_security_groups   = var.override_security_groups
  dns_cluster_ip             = var.dns_cluster_ip
  ssh_public_key             = var.ssh_public_key
  tags                       = var.tags
  access_key_id              = var.aws_access_key_id
  secret_access_key          = var.aws_secret_access_key
  instance_profile_arn       = var.aws_instance_profile_arn
  delete_nodes_on_disconnect = var.delete_nodes_on_disconnect
  assume_role_arn            = var.aws_assume_role_arn
}

resource "castai_cluster_token" "cluster_token" {
  cluster_id = castai_eks_cluster.my_castai_cluster.id
}

resource "helm_release" "castai_agent" {
  name            = "castai-agent"
  repository      = "https://castai.github.io/helm-charts"
  chart           = "castai-agent"
  namespace       = "castai-agent"
  create_namespace = true
  cleanup_on_fail = true
  wait = true

  set {
    name  = "provider"
    value = "eks"
  }

  set {
    name = "additionalEnv.STATIC_CLUSTER_ID"
    value =  castai_eks_cluster.my_castai_cluster.id
  }

  set {
    name = "createNamespace"
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
    value = castai_cluster_token.cluster_token.cluster_token
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
  name            = "cluster-controller"
  repository      = "https://castai.github.io/helm-charts"
  chart           = "castai-cluster-controller"
  namespace       = "castai-agent"
  create_namespace = true
  cleanup_on_fail = true
  wait = true

  set {
    name  = "castai.clusterID"
    value =  castai_eks_cluster.my_castai_cluster.id
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
    value = castai_cluster_token.cluster_token.cluster_token
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
  name            = "castai-evictor"
  repository      = "https://castai.github.io/helm-charts"
  chart           = "castai-evictor"
  namespace       = "castai-agent"
  create_namespace = true
  cleanup_on_fail = true
  wait = true

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
    value =  castai_eks_cluster.my_castai_cluster.id
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
