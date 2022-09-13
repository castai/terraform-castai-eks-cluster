output "cluster_id" {
  value       = castai_eks_cluster.this.id
  description = "CAST AI cluster id, which can be used for accessing cluster data using API"
  sensitive   = true
}

output "security_groups" {
  value       = castai_eks_cluster.this.security_groups
  description = "CAST AI security groups of EKS cluster"
}

output "castai_node_configurations" {
  description = "Map of node configurations ids by name"
  value       = {
    for k, v in castai_node_configuration.this : v.name => v.id
  }
}