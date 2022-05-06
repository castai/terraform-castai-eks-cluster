output "cluster_id" {
  value =  data.castai_eks_clusterid.castai_cluster_id.id
  description = "CAST.AI cluster id, which can be used for accessing cluster data using API"
  sensitive = true
}

output "security_groups" {
  value = castai_eks_cluster.my_castai_cluster.security_groups
  description = "CAST.AI security groups of EKS cluster"
}
