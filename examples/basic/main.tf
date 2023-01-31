provider "castai" {
  api_token = var.castai_api_token
  api_url   = var.castai_api_url
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

provider "aws" {
  region = var.cluster_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

data "aws_caller_identity" "current" {}

resource "castai_eks_clusterid" "cluster_id" {
  account_id   = data.aws_caller_identity.current.account_id
  region       = var.cluster_region
  cluster_name = var.cluster_name
}

data "castai_eks_user_arn" "castai_user_arn" {
  cluster_id = castai_eks_clusterid.cluster_id.id
}

module "castai-eks-role-iam" {
  source = "castai/eks-role-iam/castai"

  aws_account_id     = data.aws_caller_identity.current.account_id
  aws_cluster_region = var.cluster_region
  aws_cluster_name   = var.cluster_name
  aws_cluster_vpc_id = module.vpc.vpc_id

  castai_user_arn = data.castai_eks_user_arn.castai_user_arn.arn

  create_iam_resources_per_cluster = true
}

module "cast-eks-cluster" {
  source = "../../"

  aws_account_id      = data.aws_caller_identity.current.account_id
  aws_cluster_region  = var.cluster_region
  aws_cluster_name    = var.cluster_name
  aws_assume_role_arn = module.castai-eks-role-iam.role_arn

  // Set default node configuration which will be used for all CAST provisioned nodes unless specific node configuration is selected.
  default_node_configuration = module.cast-eks-cluster.castai_node_configurations["default"]

  node_configurations = {
    default = {
      disk_cpu_ratio = 25
      subnets        = module.vpc.private_subnets
      tags           = {
        "node-config" : "default"
      }
      security_groups = [
        module.eks.cluster_security_group_id,
        module.eks.node_security_group_id,
        aws_security_group.additional.id,
      ]
      docker_config = jsonencode({
        "insecure-registries"      = ["registry.com:5000"],
        "max-concurrent-downloads" = 10
      })
      kubelet_config = jsonencode({
        "registryBurst" : 20,
        "registryPullQPS" : 10
      })
      container_runtime    = "dockerd"
      init_script          = base64encode(var.init_script)
      instance_profile_arn = module.castai-eks-role-iam.instance_profile_arn
    }

    gpu = {
      subnets = module.vpc.private_subnets
      tags    = {
        "node-config" : "gpu"
      }
      security_groups = [
        aws_security_group.additional.id,
      ]
      instance_profile_arn = module.castai-eks-role-iam.instance_profile_arn
      // Use latest eks gpu image by cluster version.
      image                = "amazon-eks-gpu-node-${module.eks.cluster_version}-*"
    }
  }

  node_templates = {
    spot_tmpl = {
      configuration_id = module.cast-eks-cluster.castai_node_configurations["default"]

      should_taint = true
      custom_label = {
        key = "custom-key"
        value = "label-value"
      }

      constraints = {
        fallback_restore_rate_seconds = 1800
        spot = true
        use_spot_fallbacks = true
        min_cpu = 4
        max_cpu = 100
        instance_families = {
          exclude = ["m5"]
        }
        compute_optimized = false
        storage_optimized = false
      }
    }
  }

  autoscaler_policies_json   = <<-EOT
    {
        "enabled": true,
        "unschedulablePods": {
            "enabled": true
        },
        "spotInstances": {
            "enabled": true,
            "clouds": ["aws"],
            "spotBackups": {
                "enabled": true
            }
        },
        "nodeDownscaler": {
            "emptyNodes": {
                "enabled": true
            }
        }
    }
  EOT
  delete_nodes_on_disconnect = true

  depends_on = [module.castai-eks-role-iam]
}
