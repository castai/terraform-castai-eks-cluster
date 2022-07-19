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

  aws_access_key_id             = var.aws_access_key_id
  aws_secret_access_key         = var.aws_secret_access_key
  aws_instance_profile_arn      = var.instance_profile_arn
  autoscaler_policies_json      = var.autoscaler_policies_json
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.49 |
| <a name="requirement_castai"></a> [castai](#requirement\_castai) | >= 0.21.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_castai"></a> [castai](#provider\_castai) | 0.18.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.5.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [castai_autoscaler.castai_autoscaler_policies](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/autoscaler) | resource |
| [castai_eks_cluster.my_castai_cluster](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/eks_cluster) | resource |
| [helm_release.castai_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_cluster_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_evictor](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_spot_handler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_aws_access_key_id"></a> [agent\_aws\_access\_key\_id](#input\_agent\_aws\_access\_key\_id) | AWS access key for CAST AI agent to fetch instance details. | `string` | `""` | no |
| <a name="input_agent_aws_iam_service_account_role_arn"></a> [agent\_aws\_iam\_service\_account\_role\_arn](#input\_agent\_aws\_iam\_service\_account\_role\_arn) | Arn of the role to be used by CAST AI agent to fetch instance details. Only readonly AmazonEC2ReadOnlyAccess is needed. | `string` | `""` | no |
| <a name="input_agent_aws_secret_access_key"></a> [agent\_aws\_secret\_access\_key](#input\_agent\_aws\_secret\_access\_key) | AWS access key secret for CAST AI agent to fetch instance details. | `string` | `""` | no |
| <a name="input_api_url"></a> [api\_url](#input\_api\_url) | URL of alternative CAST AI API to be used during development or testing | `string` | `"https://api.cast.ai"` | no |
| <a name="input_autoscaler_policies_json"></a> [autoscaler\_policies\_json](#input\_autoscaler\_policies\_json) | Optional json object to override CAST AI cluster autoscaler policies | `string` | `""` | no |
| <a name="input_aws_access_key_id"></a> [aws\_access\_key\_id](#input\_aws\_access\_key\_id) | AWS access key ID to be used for CAST AI access. | `string` | `null` | no |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | ID of AWS account the cluster is located in. | `string` | n/a | yes |
| <a name="input_aws_assume_role_arn"></a> [aws\_assume\_role\_arn](#input\_aws\_assume\_role\_arn) | Arn of the role to be used by CAST AI for IAM access | `string` | `null` | no |
| <a name="input_aws_cluster_name"></a> [aws\_cluster\_name](#input\_aws\_cluster\_name) | Name of the cluster to be connected to CAST AI. | `string` | n/a | yes |
| <a name="input_aws_cluster_region"></a> [aws\_cluster\_region](#input\_aws\_cluster\_region) | Region of the cluster to be connected to CAST AI. | `string` | n/a | yes |
| <a name="input_aws_instance_profile_arn"></a> [aws\_instance\_profile\_arn](#input\_aws\_instance\_profile\_arn) | ARN of the AWS instance profile that will be used by CAST AI cluster-controller. | `string` | n/a | yes |
| <a name="input_aws_secret_access_key"></a> [aws\_secret\_access\_key](#input\_aws\_secret\_access\_key) | AWS secret access key to be used for CAST AI access. | `string` | `null` | no |
| <a name="input_castai_components_labels"></a> [castai\_components\_labels](#input\_castai\_components\_labels) | Optional additional Kubernetes labels for CAST AI pods | `map` | `{}` | no |
| <a name="input_delete_nodes_on_disconnect"></a> [delete\_nodes\_on\_disconnect](#input\_delete\_nodes\_on\_disconnect) | Optionally delete Cast AI created nodes when the cluster is destroyed | `bool` | `false` | no |
| <a name="input_dns_cluster_ip"></a> [dns\_cluster\_ip](#input\_dns\_cluster\_ip) | Overrides the IP address to use for DNS queries within the cluster. Defaults to 10.100.0.10 or 172.20.0.10 based on the IP address of the primary interface. | `string` | `null` | no |
| <a name="input_override_security_groups"></a> [override\_security\_groups](#input\_override\_security\_groups) | Optional custom security groups for the cluster. If not set security groups from the EKS cluster configuration are used. | `list(string)` | `null` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | Optional SSH public key for VM instances. Accepted values are base64 encoded SSH public key or AWS key pair ID | `string` | `null` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Optional custom subnets for the cluster. If not set subnets from the EKS cluster configuration are used. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Optional tags for new cluster nodes. This parameter applies only to new nodes - tags for old nodes are not reconciled. | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | CAST.AI cluster id, which can be used for accessing cluster data using API |
| <a name="output_security_groups"></a> [security\_groups](#output\_security\_groups) | CAST.AI security groups of EKS cluster |
<!-- END_TF_DOCS -->