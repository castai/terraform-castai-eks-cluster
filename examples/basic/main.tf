provider "castai" {
  api_token = var.castai_api_token
}

provider "aws" {
  region     = var.aws_cluster_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

module "cast-eks-cluster" {
  source = "../../"

  aws_account_id     = var.aws_account_id
  aws_cluster_vpc_id = var.aws_vpc_id
  aws_cluster_region = var.aws_cluster_region
  aws_cluster_name   = var.aws_cluster_name

  aws_access_key_id         = var.aws_access_key_id
  aws_secret_access_key     = var.aws_secret_access_key
  instance_profile_role_arn = var.instance_profile_arn
  autoscaler_policies_json  = <<-EOT
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
  delete_nodes_on_disconnect = var.delete_nodes_on_disconnect
}
