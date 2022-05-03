resource "castai_eks_cluster" "my_castai_cluster" {
  account_id                 = var.aws_account_id
  region                     = var.aws_cluster_region
  name                       = var.aws_cluster_name
  subnets                    = var.subnets
  security_groups            = var.security_groups
  dns_cluster_ip             = var.dns_cluster_ip
  ssh_public_key             = var.ssh_public_key
  tags                       = var.tags
  access_key_id              = var.aws_access_key_id
  secret_access_key          = var.aws_secret_access_key
  instance_profile_arn       = var.aws_instance_profile_arn
  delete_nodes_on_disconnect = var.delete_nodes_on_disconnect
  assume_role_arn            = var.aws_assume_role_arn

  depends_on = [helm_release.castai_cluster_controller]
}

data "castai_eks_clusterid" "castai_cluster_id" {
  account_id                 = var.aws_account_id
  region                     = var.aws_cluster_region
  cluster_name               = var.aws_cluster_name
}

resource "castai_cluster_token" "cluster_token" {
  cluster_id = data.castai_eks_clusterid.castai_cluster_id.id
}

resource "helm_release" "castai_agent" {
  name            = "castai-agent"
  repository      = "https://castai.github.io/helm-charts"
  chart           = "castai-agent"
  namespace       = "castai-agent"
  create_namespace = true
  cleanup_on_fail = true

  set {
    name  = "provider"
    value = "eks"
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

  set_sensitive {
    name  = "apiKey"
    value = castai_cluster_token.cluster_token.cluster_token
  }
}

resource "helm_release" "castai_cluster_controller" {
  name            = "cluster-controller"
  repository      = "https://castai.github.io/helm-charts"
  chart           = "castai-cluster-controller"
  namespace       = "castai-agent"
  create_namespace = true
  cleanup_on_fail = true

  set {
    name  = "castai.clusterID"
    value = data.castai_eks_clusterid.castai_cluster_id.id
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

  depends_on = [helm_release.castai_agent]
}

resource "helm_release" "castai_evictor" {
  name            = "castai-evictor"
  repository      = "https://castai.github.io/helm-charts"
  chart           = "castai-evictor"
  namespace       = "castai-agent"
  create_namespace = true
  cleanup_on_fail = true

  set {
    name  = "replicaCount"
    value = "0"
  }

  depends_on = [helm_release.castai_agent]
}

resource "castai_autoscaler" "castai_autoscaler_policies" {
  autoscaler_policies_json = var.autoscaler_policies_json
  cluster_id               = castai_eks_cluster.my_castai_cluster.id

  depends_on = [helm_release.castai_agent]
}
