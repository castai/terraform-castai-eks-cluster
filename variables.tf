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
  default     = null
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret access key to be used for CAST AI access."
  default     = null
}

variable "api_url" {
  type        = string
  description = "URL of alternative CAST AI API to be used during development or testing"
  default     = "https://api.cast.ai"
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
  type        = map
  description = "Optional additional Kubernetes labels for CAST AI pods"
  default     = {}
}

variable "node_configurations" {
  type = map(object({
    disk_cpu_ratio       = optional(number)
    subnets              = list(string)
    ssh_public_key       = optional(string)
    image                = optional(string)
    tags                 = optional(map(string))
    security_groups      = list(string)
    dns_cluster_ip       = optional(string)
    instance_profile_arn = string
    key_pair_id          = optional(string)
  }))
  description = "Map of EKS node configurations to create"
  default     = {}
}

variable "default_node_configuration" {
  type        = string
  description = "ID of the default node configuration"
}
