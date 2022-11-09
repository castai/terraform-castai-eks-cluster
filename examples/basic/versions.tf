terraform {
  required_providers {
    castai = {
      source  = "castai/castai"
      version = ">= 1.3.0"
    }
    aws    = {
      source  = "hashicorp/aws"
      version = ">= 2.49"
    }
  }
  required_version = ">= 0.13"
}
