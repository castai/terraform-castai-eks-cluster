locals {
  # Common conditional non-sensitive values that we pass to helm_releases.
  # Set up as lists so they can be concatenated.
  set_apiurl = var.api_url != "" ? [{
    name  = "castai.apiURL"
    value = var.api_url
  }] : []
  set_cluster_id = [{
    name  = "castai.clusterID"
    value = castai_eks_cluster.my_castai_cluster.id
  }]
  set_organization_id = var.organization_id != "" ? [{
    name  = "castai.organizationID"
    value = var.organization_id
  }] : []
  set_agent_aws_iam_service_account_role_arn = var.agent_aws_iam_service_account_role_arn != "" ? [{
    name  = "serviceAccount.annotations.eks\\.\\amazonaws\\.\\com/role-arn"
    value = var.agent_aws_iam_service_account_role_arn
  }] : []
  set_grpc_url = var.grpc_url != "" ? [{
    name  = "castai.grpcURL"
    value = var.grpc_url
  }] : []
  set_kvisor_grpc_addr = var.kvisor_grpc_addr != "" ? [{
    name  = "castai.grpcAddr"
    value = var.kvisor_grpc_addr
  }] : []
  set_pod_labels = [for k, v in var.castai_components_labels : {
    name  = "podLabels.${k}"
    value = v
  }]
  set_components_sets = [for k, v in var.castai_components_sets : {
    name  = k
    value = v
  }]


  # Common conditional SENSITIVE values that we pass to helm_releases.
  # Set up as lists so they can be concatenated.
  set_sensitive_apikey = [{
    name  = "castai.apiKey"
    value = castai_eks_cluster.my_castai_cluster.cluster_token
  }]
  set_sensitive_aws_access_key = var.agent_aws_access_key_id != "" ? [{
    name  = "additionalSecretEnv.AWS_ACCESS_KEY_ID"
    value = var.agent_aws_access_key_id
  }] : []
  set_sensitive_aws_secret_access_key = var.agent_aws_secret_access_key != "" ? [{
    name  = "additionalSecretEnv.AWS_SECRET_ACCESS_KEY"
    value = var.agent_aws_secret_access_key
  }] : []
}