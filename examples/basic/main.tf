provider "castai" {
  api_token = var.castai_api_token
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

data "castai_eks_clusterid" "castai_cluster_id" {
  account_id   = data.aws_caller_identity.current.account_id
  region       = var.cluster_region
  cluster_name = var.cluster_name
}

data "castai_eks_user_arn" "castai_user_arn" {
  cluster_id = data.castai_eks_clusterid.castai_cluster_id.id
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
