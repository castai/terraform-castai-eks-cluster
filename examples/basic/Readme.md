# Example usage of CAST AI EKS module

This example contains a sample setup of:
* Creating a new EKS cluster;
* Connecting it to CAST AI and configuring it for autoscaling.

# Setup

1. Copy/rename file "terraform.tfvars.sample" to "terraform.tfvars" and provide your credentials and cluster setup details.

1. Configure AWS access per [AWS Provider instructions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration); e.g. using environment variables: 
   ```shell
   export AWS_ACCESS_KEY_ID=ABCD
   export AWS_SECRET_ACCESS_KEY=pc+abcdef1234567890
   ```
1. Review `module "cast-eks-cluster"` configuration in `main.tf`, adust settings per your needs (e.g. autoscaling settings);
1. Prepare and review terraform plan
   ```shell
   terraform init 
   terraform plan
   ```
1. Create infrastructure. When `apply` completes, you should have a fully working cluster that is connected to CAST AI
   ```shell
   terraform apply
   ```
1. Inspect the created cluster in [CAST AI console](https://console.cast.ai);
1. (Optional) delete created infrastructure.
   ```shell
   terraform destroy
   ```
