# Example usage of CAST AI EKS module

This example contains a sample setup of:
* Creating a new EKS cluster;
* Connecting it to CAST AI and configuring it for autoscaling.

## Running the example

1. Copy/rename file "terraform.tfvars.sample" to "terraform.tfvars" and provide your credentials and cluster setup details.

1. Configure AWS access per [AWS Provider instructions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration); e.g. using environment variables: 
   ```shell
   export AWS_ACCESS_KEY_ID=ABCD
   export AWS_SECRET_ACCESS_KEY=pc+abcdef1234567890
   ```
1. Review `module "cast-eks-cluster"` configuration in `main.tf`, adust settings per your needs (e.g. autoscaling settings);
1. Prepare and review Terraform plan
   ```shell
   terraform init 
   terraform plan
   ```
1. Create infrastructure. When `apply` completes, you should have a fully working cluster that is connected to CAST AI
   ```shell
   terraform apply
   ```
1. Inspect the created cluster in [CAST AI console](https://console.cast.ai);
1. Configure `kubectl` access to your cluster locally:
   ```shell
   aws sts get-caller-identity
   aws eks update-kubeconfig --region your-cluster-region --name your-cluster-name
   # inspect status of CAST AI components
   kubectl get po -n castai-agent
   ```
1. (Optional) delete created infrastructure.
   ```shell
   terraform destroy
   ```
