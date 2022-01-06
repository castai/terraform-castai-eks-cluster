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
  source = "../../"

  aws_account_id     = var.aws_account_id
  aws_cluster_region = var.cluster_region
  aws_cluster_name   = var.cluster_id

  aws_access_key_id             = var.aws_access_key_id
  aws_secret_access_key         = var.aws_secret_access_key
  aws_instance_profile_arn      = var.instance_profile_arn
}
```
