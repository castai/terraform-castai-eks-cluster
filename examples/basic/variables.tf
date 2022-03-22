variable "castai_api_token" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

variable "aws_cluster_region" {
  type = string
}

variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "aws_cluster_name" {
  type = string
}

variable "aws_instance_profile_arn" {
  type = string
}

variable "delete_nodes_on_disconnect" {
  type = bool
}

variable "ssh_public_key" {
  type = string
}
