terraform {
  required_version = ">= 0.13"
  experiments      = [module_variable_optional_attrs]

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.49"
    }
    castai = {
      source  = "castai/castai"
      version = ">= 0.25.0"
    }
  }
}
