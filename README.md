<a href="https://cast.ai">
    <img src="https://cast.ai/wp-content/themes/cast/img/cast-logo-dark-blue.svg" align="right" height="100" />
</a>

Terraform module for connecting an AWS EKS cluster to CAST AI
==================


Website: https://www.cast.ai

Requirements
------------

- [Terraform](https://www.terraform.io/downloads.html) 0.13+

Using the module
------------

A module to connect an EKS cluster to CAST AI.

Requires `castai/castai` and `hashicorp/aws` providers to be configured.

```hcl
module "castai-eks-cluster" {
  source = "castai/eks-cluster/castai"

  aws_account_id     = var.aws_account_id
  aws_cluster_region = var.cluster_region
  aws_cluster_name   = var.cluster_id

  aws_assume_role_arn      = module.castai-eks-role-iam.role_arn
  autoscaler_policies_json = var.autoscaler_policies_json

  // Default node configuration will be used for all CAST provisioned nodes unless specific configuration is requested.
  default_node_configuration = module.cast-eks-cluster.castai_node_configurations["default"]

  node_configurations = {
    default = {
      subnets                   = module.vpc.private_subnets
      dns_cluster_ip            = "10.100.0.10"
      instance_profile_role_arn = var.instance_profile_arn
      ssh_public_key            = var.ssh_public_key
      security_groups           = [
        module.eks.node_security_group_id,
      ]
      tags = {
        "team" : "core"
      }
      init_script    = base64encode(var.init_script)
      docker_config  = jsonencode({
        "insecure-registries"      = ["registry.com:5000"],
        "max-concurrent-downloads" = 10
      })
      kubelet_config = jsonencode({
        "registryBurst" : 20,
        "registryPullQPS" : 10
      })
      container_runtime = "dockerd"
    }
  }
}
```

Migrating from 2.x.x to 3.x.x
------------
Existing configuration:
```hcl
module "castai-eks-cluster" {
  // ...
  
  subnets                   = module.vpc.private_subnets
  dns_cluster_ip            = "10.100.0.10"
  instance_profile_role_arn = var.instance_profile_arn
  ssh_public_key            = var.ssh_public_key
  override_security_groups  = [
    module.eks.node_security_group_id,
  ]
  tags = {
    "team" : "core"
  }
}
```
New configuration: 
```hcl
module "castai-eks-cluster" {
  // ...
  
  // Default node configuration will be used for all CAST provisioned nodes unless specific configuration is requested.
  default_node_configuration = module.cast-eks-cluster.castai_node_configurations["default"]

  node_configurations = {
    default = {
      subnets                   = module.vpc.private_subnets
      dns_cluster_ip            = "10.100.0.10"
      instance_profile_role_arn = var.instance_profile_arn
      ssh_public_key            = var.ssh_public_key
      security_groups           = [
        module.eks.node_security_group_id,
      ]
      tags = {
        "team" : "core"
      }
    }
  }
}

```

### Generate docs

```shell
terraform-docs markdown table . --output-file README.md
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.49 |
| <a name="requirement_castai"></a> [castai](#requirement\_castai) | >= 1.3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_castai"></a> [castai](#provider\_castai) | >= 1.3.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [castai_autoscaler.castai_autoscaler_policies](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/autoscaler) | resource |
| [castai_cluster_token.cluster_token](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/cluster_token) | resource |
| [castai_eks_cluster.my_castai_cluster](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/eks_cluster) | resource |
| [castai_node_configuration.this](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/node_configuration) | resource |
| [castai_node_configuration_default.this](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/node_configuration_default) | resource |
| [helm_release.castai_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_cluster_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_evictor](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_sec_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_spot_handler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_aws_access_key_id"></a> [agent\_aws\_access\_key\_id](#input\_agent\_aws\_access\_key\_id) | AWS access key for CAST AI agent to fetch instance details. | `string` | `""` | no |
| <a name="input_agent_aws_iam_service_account_role_arn"></a> [agent\_aws\_iam\_service\_account\_role\_arn](#input\_agent\_aws\_iam\_service\_account\_role\_arn) | Arn of the role to be used by CAST AI agent to fetch instance details. Only readonly AmazonEC2ReadOnlyAccess is needed. | `string` | `""` | no |
| <a name="input_agent_aws_secret_access_key"></a> [agent\_aws\_secret\_access\_key](#input\_agent\_aws\_secret\_access\_key) | AWS access key secret for CAST AI agent to fetch instance details. | `string` | `""` | no |
| <a name="input_api_url"></a> [api\_url](#input\_api\_url) | URL of alternative CAST AI API to be used during development or testing | `string` | `"https://api.cast.ai"` | no |
| <a name="input_autoscaler_policies_json"></a> [autoscaler\_policies\_json](#input\_autoscaler\_policies\_json) | Optional json object to override CAST AI cluster autoscaler policies | `string` | `""` | no |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | ID of AWS account the cluster is located in. | `string` | n/a | yes |
| <a name="input_aws_assume_role_arn"></a> [aws\_assume\_role\_arn](#input\_aws\_assume\_role\_arn) | Arn of the role to be used by CAST AI for IAM access | `string` | `null` | no |
| <a name="input_aws_cluster_name"></a> [aws\_cluster\_name](#input\_aws\_cluster\_name) | Name of the cluster to be connected to CAST AI. | `string` | n/a | yes |
| <a name="input_aws_cluster_region"></a> [aws\_cluster\_region](#input\_aws\_cluster\_region) | Region of the cluster to be connected to CAST AI. | `string` | n/a | yes |
| <a name="input_castai_components_labels"></a> [castai\_components\_labels](#input\_castai\_components\_labels) | Optional additional Kubernetes labels for CAST AI pods | `map` | `{}` | no |
| <a name="input_default_node_configuration"></a> [default\_node\_configuration](#input\_default\_node\_configuration) | ID of the default node configuration | `string` | n/a | yes |
| <a name="input_delete_nodes_on_disconnect"></a> [delete\_nodes\_on\_disconnect](#input\_delete\_nodes\_on\_disconnect) | Optionally delete Cast AI created nodes when the cluster is destroyed | `bool` | `false` | no |
| <a name="input_install_security_agent"></a> [install\_security\_agent](#input\_install\_security\_agent) | Optional flag for installation of security agent (https://docs.cast.ai/product-overview/console/security-insights/) | `bool` | `false` | no |
| <a name="input_node_configurations"></a> [node\_configurations](#input\_node\_configurations) | Map of EKS node configurations to create | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_castai_node_configurations"></a> [castai\_node\_configurations](#output\_castai\_node\_configurations) | Map of node configurations ids by name |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | CAST AI cluster id, which can be used for accessing cluster data using API |
<!-- END_TF_DOCS -->