resource "castai_eks_cluster" "my_castai_cluster" {
  account_id                 = var.aws_account_id
  region                     = var.aws_cluster_region
  name                       = var.aws_cluster_name
  subnets                    = var.subnets
  security_groups            = var.security_groups
  dns_cluster_ip             = var.dns_cluster_ip == "" ? null : var.dns_cluster_ip
  tags                       = var.tags
  access_key_id              = var.aws_access_key_id
  secret_access_key          = var.aws_secret_access_key
  instance_profile_arn       = var.aws_instance_profile_arn
  delete_nodes_on_disconnect = var.delete_nodes_on_disconnect
}

resource "helm_release" "castai_agent" {
  name            = "castai-agent"
  repository      = "https://castai.github.io/helm-charts"
  chart           = "castai-agent"
  cleanup_on_fail = true

  set {
    name  = "provider"
    value = "eks"
  }

  dynamic "set" {
    for_each = var.api_url != "" ? [var.api_url] : []
    content {
      name  = "apiURL"
      value = var.api_url
    }
  }

  set_sensitive {
    name  = "apiKey"
    value = castai_eks_cluster.my_castai_cluster.cluster_token
  }
}

resource "helm_release" "castai_cluster_controller" {
  name            = "castai-cluster-controller"
  repository      = "https://castai.github.io/helm-charts"
  chart           = "castai-cluster-controller"
  cleanup_on_fail = true

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

  depends_on = [helm_release.castai_agent]
}

resource "castai_autoscaler" "castai_autoscaler_policies" {
  autoscaler_policies_json = var.autoscaler_policies_json
  cluster_id               = castai_eks_cluster.my_castai_cluster.id

  depends_on = [helm_release.castai_agent]
}
