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

variable "api_url" {
  type        = string
  description = "URL of alternative CAST AI API to be used during development or testing"
  default     = "https://api.cast.ai"
}

variable "castai_api_token" {
  type = string
  description = "Optional CAST AI API token created in console.cast.ai API Access keys section. Used only when `wait_for_cluster_ready` is set to true"
  sensitive = true
  default = ""
}

variable "grpc_url" {
  type        = string
  description = "gRPC endpoint used by pod-pinner"
  default     = "grpc.cast.ai:443"
}

variable "autoscaler_policies_json" {
  type        = string
  description = "Optional json object to override CAST AI cluster autoscaler policies"
  default     = null
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
  type        = map(any)
  description = "Optional additional Kubernetes labels for CAST AI pods"
  default     = {}
}

variable "node_configurations" {
  type        = any
  description = "Map of EKS node configurations to create"
  default     = {}
}

variable "default_node_configuration" {
  type        = string
  description = "ID of the default node configuration"
}

variable "node_templates" {
  type        = any
  description = "Map of node templates to create"
  default     = {}
}

variable "install_security_agent" {
  type        = bool
  default     = false
  description = "Optional flag for installation of security agent (https://docs.cast.ai/product-overview/console/security-insights/)"
}

variable "agent_values" {
  description = "List of YAML formatted string with agent values"
  type        = list(string)
  default     = []
}

variable "spot_handler_values" {
  description = "List of YAML formatted string with spot-handler values"
  type        = list(string)
  default     = []
}

variable "cluster_controller_values" {
  description = "List of YAML formatted string with cluster-controller values"
  type        = list(string)
  default     = []
}

variable "evictor_values" {
  description = "List of YAML formatted string with evictor values"
  type        = list(string)
  default     = []
}

variable "kvisor_values" {
  description = "List of YAML formatted string with kvisor values"
  type        = list(string)
  default     = []
}

variable "agent_version" {
  description = "Version of castai-agent helm chart. Default latest"
  type        = string
  default     = null
}

variable "spot_handler_version" {
  description = "Version of castai-spot-handler helm chart. Default latest"
  type        = string
  default     = null
}

variable "cluster_controller_version" {
  description = "Version of castai-cluster-controller helm chart. Default latest"
  type        = string
  default     = null
}

variable "evictor_version" {
  description = "Version of castai-evictor chart. Default latest"
  type        = string
  default     = null
}

variable "kvisor_version" {
  description = "Version of kvisor chart. Default latest"
  type        = string
  default     = "0.16.74"
}

variable "wait_for_cluster_ready" {
  type        = bool
  description = "Wait for cluster to be ready before finishing the module execution, this option requires `castai_api_token` to be set"
  default     = false
}
