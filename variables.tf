variable "aws_account_id" {
  type        = string
  description = "ID of AWS account the cluster is located in."
}

variable "aws_cluster_region" {
  type        = string
  description = "Region of the cluster to be connected to CAST AI."
}

variable "aws_cluster_name" {
  type = string
  description = "Name of the cluster to be connected to CAST AI."
}

variable "aws_access_key_id" {
  type = string
  description = "AWS access key ID to be used for CAST AI access."
}

variable "aws_secret_access_key" {
  type = string
  description = "AWS secret access key to be used for CAST AI access."
}

variable "aws_instance_profile_arn" {
  type = string
  description = "ARN of the AWS instance profile that will be used by CAST AI cluster-controller."
}

variable "api_url" {
  type = string
  description = "URL of alternative CAST AI API to be used during development or testing"
  default = "https://api.cast.ai/"
}

variable "subnets" {
  type = list(string)
  description = "Optional custom subnets for the cluster. If not set subnets from the EKS cluster configuration are used."
  default = []
}

variable "security_groups" {
  type = list(string)
  description = "Optional custom security groups for the cluster. If not set security groups from the EKS cluster configuration are used."
  default = []
}

variable "tags" {
  type = map
  description = "Optional tags for new cluster nodes. This parameter applies only to new nodes - tags for old nodes are not reconciled."
  default = {}
}
