variable "castai_api_token" {
  type = string
}

variable "castai_api_url" {
  type    = string
  default = "https://api.cast.ai"
}

variable "cluster_region" {
  type    = string
  default = "eu-central-1"
}

variable "cluster_name" {
  type    = string
  default = "tf-basic"
}

variable "init_script" {
  type    = string
  default = <<EOF
#!/bin/bash
echo "hello"
EOF
}
