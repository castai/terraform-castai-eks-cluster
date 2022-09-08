variable "aws_account_id" {
  type        = string
  description = "ID of AWS account the cluster is located in."
}

variable "aws_cluster_region" {
  type        = string
  description = "Region of the cluster to be connected to CAST AI."
}

variable "aws_cluster_name" {
  type        = string
  description = "Name of the cluster to be connected to CAST AI."
}

variable "aws_access_key_id" {
  type        = string
  description = "AWS access key ID to be used for CAST AI access."
  default = null
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret access key to be used for CAST AI access."
  default = null
}

variable "aws_instance_profile_arn" {
  type        = string
  description = "ARN of the AWS instance profile that will be used by CAST AI cluster-controller."
}

variable "api_url" {
  type        = string
  description = "URL of alternative CAST AI API to be used during development or testing"
  default     = "https://api.cast.ai"
}

variable "subnets" {
  type        = list(string)
  description = "Optional custom subnets for the cluster. If not set subnets from the EKS cluster configuration are used."
  default     = []
}

variable "dns_cluster_ip" {
  type        = string
  description = "Overrides the IP address to use for DNS queries within the cluster. Defaults to 10.100.0.10 or 172.20.0.10 based on the IP address of the primary interface."
  default     = null
}

variable "ssh_public_key" {
  type        = string
  description = "Optional SSH public key for VM instances. Accepted values are base64 encoded SSH public key or AWS key pair ID"
  default     = null
}

variable "override_security_groups" {
  type        = list(string)
  description = "Optional custom security groups for the cluster. If not set security groups from the EKS cluster configuration are used."
  default     = null
}

variable "tags" {
  type        = map(any)
  description = "Optional tags for new cluster nodes. This parameter applies only to new nodes - tags for old nodes are not reconciled."
  default     = {}
}

variable "autoscaler_policies_json" {
  type        = string
  description = "Optional json object to override CAST AI cluster autoscaler policies"
  default     = ""
}

variable "delete_nodes_on_disconnect" {
  type        = bool
  description = "Optionally delete Cast AI created nodes when the cluster is destroyed"
  default     = false
}

variable "aws_assume_role_arn" {
  type        = string
  description = "Arn of the role to be used by CAST AI for IAM access"
  default     = null
}

variable "agent_aws_iam_service_account_role_arn" {
  type        = string
  description = "Arn of the role to be used by CAST AI agent to fetch instance details. Only readonly AmazonEC2ReadOnlyAccess is needed."
  default     = ""
}

variable "agent_aws_access_key_id" {
  type        = string
  description = "AWS access key for CAST AI agent to fetch instance details."
  default     = ""
}

variable "agent_aws_secret_access_key" {
  type        = string
  description = "AWS access key secret for CAST AI agent to fetch instance details."
  default     = ""
}

variable "castai_components_labels" {
  type = map
  description = "Optional additional Kubernetes labels for CAST AI pods"
  default = {}
}

variable "node_configurations" {
  type = map(any)
  description = "Optional configuration for CAST AI provisioned nodes"
  default = {}
}
