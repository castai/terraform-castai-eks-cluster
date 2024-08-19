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
  type        = string
  description = "Optional CAST AI API token created in console.cast.ai API Access keys section. Used only when `wait_for_cluster_ready` is set to true"
  sensitive   = true
  default     = ""
}

variable "grpc_url" {
  type        = string
  description = "gRPC endpoint used by pod-pinner"
  default     = "grpc.cast.ai:443"
}

variable "api_grpc_addr" {
  type        = string
  description = "CAST AI GRPC API address"
  default     = "api-grpc.cast.ai:443"
}

variable "kvisor_controller_extra_args" {
  type        = map(string)
  description = "Extra arguments for the kvisor controller. Optionally enable kvisor to lint Kubernetes YAML manifests, scan workload images and check if workloads pass CIS Kubernetes Benchmarks as well as NSA, WASP and PCI recommendations."
  default = {
    "kube-linter-enabled"        = "true"
    "image-scan-enabled"         = "true"
    "kube-bench-enabled"         = "true"
  }
}

variable "autoscaler_policies_json" {
  type        = string
  description = "Optional json object to override CAST AI cluster autoscaler policies. Deprecated, use `autoscaler_settings` instead."
  default     = null
}

variable "autoscaler_settings" {
  type        = any
  description = "Optional Autoscaler policy definitions to override current autoscaler settings"
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
  default = ""
}

variable "default_node_configuration_name" {
  type        = string
  description = "Name of the default node configuration"
  default = ""
}

variable "node_templates" {
  type        = any
  description = "Map of node templates to create"
  default     = {}
}

variable "workload_scaling_policies" {
  type        = any
  description = "Map of workload scaling policies to create"
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

variable "evictor_ext_values" {
  description = "List of YAML formatted string with evictor-ext values"
  type        = list(string)
  default     = []
}

variable "pod_pinner_values" {
  description = "List of YAML formatted string values for agent helm chart"
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

variable "evictor_ext_version" {
  description = "Version of castai-evictor-ext chart. Default latest"
  type        = string
  default     = null
}

variable "pod_pinner_version" {
  description = "Version of pod-pinner helm chart. Default latest"
  type        = string
  default     = null
}

variable "spot_handler_version" {
  description = "Version of castai-spot-handler helm chart. Default latest"
  type        = string
  default     = null
}

variable "kvisor_version" {
  description = "Version of kvisor chart. Default latest"
  type        = string
  default     = null
}

variable "kvisor_wait" {
  description = "Wait for kvisor chart to finish release"
  type        = bool
  default     = true
}

variable "wait_for_cluster_ready" {
  type        = bool
  description = "Wait for cluster to be ready before finishing the module execution, this option requires `castai_api_token` to be set"
  default     = false
}

variable "install_workload_autoscaler" {
  type        = bool
  default     = false
  description = "Optional flag for installation of workload autoscaler (https://docs.cast.ai/docs/workload-autoscaling-configuration)"
}

variable "workload_autoscaler_version" {
  description = "Version of castai-workload-autoscaler helm chart. Default latest"
  type        = string
  default     = null
}

variable "workload_autoscaler_values" {
  description = "List of YAML formatted string with cluster-workload-autoscaler values"
  type        = list(string)
  default     = []
}

variable "install_egressd" {
  type        = bool
  default     = false
  description = "Optional flag for installation of Egressd (Network cost monitoring) (https://docs.cast.ai/docs/network-cost)"
}

variable "egressd_version" {
  description = "Version of castai-egressd helm chart. Default latest"
  type        = string
  default     = null
}

variable "egressd_values" {
  description = "List of YAML formatted string with egressd values"
  type        = list(string)
  default     = []
}

variable "self_managed" {
  type        = bool
  default     = false
  description = "Whether CAST AI components' upgrades are managed by a customer; by default upgrades are managed CAST AI central system."
}
