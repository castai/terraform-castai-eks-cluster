<a href="https://cast.ai">
    <img src="https://cast.ai/wp-content/themes/cast/img/cast-logo-dark-blue.svg" align="right" height="100" />
</a>

Terraform module for connecting an AWS EKS cluster to CAST AI
==================

Website: <https://www.cast.ai>

Requirements
------------

- [Terraform](https://www.terraform.io/downloads.html) 0.13+

Using the module
------------

A module to connect an EKS cluster to CAST AI.

Requires `castai/castai` and `hashicorp/aws` providers to be configured.

```hcl
module "castai-eks-cluster" {
  source = "castai/eks-cluster/castai"

  aws_account_id     = var.aws_account_id
  aws_cluster_region = var.cluster_region
  aws_cluster_name   = var.cluster_id

  aws_assume_role_arn      = module.castai-eks-role-iam.role_arn

  // Default node configuration will be used for all CAST provisioned nodes unless specific configuration is requested.
  default_node_configuration = module.cast-eks-cluster.castai_node_configurations["default"]

  node_configurations = {
    default = {
      subnets                   = module.vpc.private_subnets
      dns_cluster_ip            = "10.100.0.10"
      instance_profile_role_arn = var.instance_profile_arn
      ssh_public_key            = var.ssh_public_key
      security_groups           = [
        module.eks.node_security_group_id,
      ]
      tags = {
        "team" : "core"
      }
      init_script   = base64encode(var.init_script)
      docker_config = jsonencode({
        "insecure-registries"      = ["registry.com:5000"],
        "max-concurrent-downloads" = 10
      })
      kubelet_config = jsonencode({
        "registryBurst" : 20,
        "registryPullQPS" : 10
      })
      container_runtime = "dockerd"
    }
  }

  node_templates = {
    spot_tmpl = {
      configuration_id = module.cast-eks-cluster.castai_node_configurations["default"]

      should_taint = true

      custom_labels = {
        custom-label-key-1 = "custom-label-value-1"
        custom-label-key-2 = "custom-label-value-2"
      }

      custom_taints = [
        {
          key   = "custom-taint-key-1"
          value = "custom-taint-value-1"
        },
        {
          key   = "custom-taint-key-2"
          value = "custom-taint-value-2"
        }
      ]

      constraints = {
        fallback_restore_rate_seconds = 1800
        spot                          = true
        use_spot_fallbacks            = true
        min_cpu                       = 4
        max_cpu                       = 100
        instance_families             = {
          exclude = ["m5"]
        }
        compute_optimized_state = "disabled"
        storage_optimized_state = "disabled"
        is_gpu_only              = false
        architectures            = ["amd64"]

        gpu = {
          fractional_gpus = "enabled"
        }
      }
      gpu = {
        default_shared_clients_per_gpu = 9
        enable_time_sharing            = true

        sharing_configuration = [
          {
            gpu_name = "A100"
            shared_clients_per_gpu = 11
          },
          {
            gpu_name = "L4"
            shared_clients_per_gpu = 5
          },
          {
            gpu_name = "T4"
            shared_clients_per_gpu = 3
          }
        ]
      }
    }
  }

  autoscaler_settings = {
    enabled                                 = true
    node_templates_partial_matching_enabled = false

    unschedulable_pods = {
      enabled = true

      headroom = {
        enabled           = true
        cpu_percentage    = 10
        memory_percentage = 10
      }

      headroom_spot = {
        enabled           = true
        cpu_percentage    = 10
        memory_percentage = 10
      }
    }

    node_downscaler = {
      enabled = true

      empty_nodes = {
        enabled = true
      }

      evictor = {
        aggressive_mode           = false
        cycle_interval            = "5s10s"
        dry_run                   = false
        enabled                   = true
        node_grace_period_minutes = 10
        scoped_mode               = false
      }
    }

    cluster_limits = {
      enabled = true

      cpu = {
        max_cores = 20
        min_cores = 1
      }
    }
  }

  workload_scaling_policies = {
    default = {
      apply_type        = "IMMEDIATE"
      management_option = "MANAGED"

      cpu = {
        function                 = "QUANTILE"
        args                     = ["0.9"]
        overhead                 = 0.15
        look_back_period_seconds = 172800
        min                      = 0.1
        max                      = 2.0
      }

      memory = {
        function                 = "MAX"
        overhead                 = 0.35
        look_back_period_seconds = 172800

        limit = {
          type = "NOLIMIT"
        }
      }

      assignment_rules = {
        rules = [
          {
            namespace = {
              names = ["default", "kube-system"]
            }
          },
          {
            workload = {
              gvk: ["Deployment", "StatefulSet"]
              labels_expressions = [
                {
                  key      = "region"
                  operator = "NotIn"
                  values   = ["eu-west-1", "eu-west-2"]
                },
                {
                  key      = "helm.sh/chart"
                  operator = "Exists"
                }
              ]
            }
          }
        ]
      }

      startup = {
        period_seconds = 300
      }

      predictive_scaling = {
        cpu = {
          enabled = true
        }
      }
    }
  }
}
```

Migrating from 2.x.x to 3.x.x
------------

Existing configuration:

```hcl
module "castai-eks-cluster" {
  // ...
  
  subnets                   = module.vpc.private_subnets
  dns_cluster_ip            = "10.100.0.10"
  instance_profile_role_arn = var.instance_profile_arn
  ssh_public_key            = var.ssh_public_key
  override_security_groups  = [
    module.eks.node_security_group_id,
  ]
  tags = {
    "team" : "core"
  }
}
```

New configuration:

```hcl
module "castai-eks-cluster" {
  // ...
  
  // Default node configuration will be used for all CAST provisioned nodes unless specific configuration is requested.
  default_node_configuration = module.cast-eks-cluster.castai_node_configurations["default"]

  node_configurations = {
    default = {
      subnets                   = module.vpc.private_subnets
      dns_cluster_ip            = "10.100.0.10"
      instance_profile_role_arn = var.instance_profile_arn
      ssh_public_key            = var.ssh_public_key
      security_groups           = [
        module.eks.node_security_group_id,
      ]
      tags = {
        "team" : "core"
      }
    }
  }
}

```

Migrating from 5.x.x to 6.x.x
------------

Existing configuration:

```hcl
module "castai-eks-cluster" {
  // ...

  node_templates = {
    // ...
  }
  autoscaler_policies_json = <<-EOT
    {
        "enabled": true,
        "unschedulablePods": {
            "enabled": true
        },
        "spotInstances": {
            "enabled": true,
            "clouds": ["aws"],
            "spotBackups": {
                "enabled": true
            },
            "spotDiversityEnabled": false,
            "spotDiversityPriceIncreaseLimitPercent": 20,
            "spotInterruptionPredictions": {
              "enabled": true,
              "type": "AWSRebalanceRecommendations"
            }
        },
        "nodeDownscaler": {
            "enabled": true,
            "emptyNodes": {
                "enabled": true
            },
            "evictor": {
                "aggressiveMode": true,
                "cycleInterval": "5m10s",
                "dryRun": false,
                "enabled": true,
                "nodeGracePeriodMinutes": 10,
                "scopedMode": false
            }
        }
    }
  EOT
}
```

New configuration:

```hcl
module "castai-eks-cluster" {
  // ...

  node_templates = {
    default_by_castai = {
      name = "default-by-castai"
      configuration_id = module.castai-eks-cluster.castai_node_configurations["default"]
      is_default   = true
      should_taint = false

      constraints = {
        on_demand          = true
        spot               = true
        use_spot_fallbacks = true

        enable_spot_diversity                       = false
        spot_diversity_price_increase_limit_percent = 20

        spot_interruption_predictions_enabled = true
        spot_interruption_predictions_type = "aws-rebalance-recommendations"
      }
    }
  }
  autoscaler_policies_json = <<-EOT
    {
        "enabled": true,
        "unschedulablePods": {
            "enabled": true
        },
        "nodeDownscaler": {
            "enabled": true,
            "emptyNodes": {
                "enabled": true
            },
            "evictor": {
                "aggressiveMode": true,
                "cycleInterval": "5m10s",
                "dryRun": false,
                "enabled": true,
                "nodeGracePeriodMinutes": 10,
                "scopedMode": false
            }
        }
    }
  EOT
}

```

Migrating from 6.x.x to 7.x.x
---------------------------

Version 7.x.x changes:
- Removed `custom_label` attribute in `castai_node_template` resource. Use `custom_labels` instead.

Old configuration:

```terraform
module "castai-eks-cluster" {
  // ...

  node_templates = {
    spot_tmpl = {
      custom_label = {
        key = "custom-label-key-1"
        value = "custom-label-value-1"
      }
    }
  }
}
```

New configuration:

```terraform
module "castai-eks-cluster" {
  // ...

  node_templates = {
    spot_tmpl = {
      custom_labels = {
        custom-label-key-1 = "custom-label-value-1"
      }
    }
  }
}
```

Migrating from 7.x.x to 8.x.x
---------------------------

Version 8.x.x changed:
- Removed `compute_optimized` and `storage_optimized` attributes in `castai_node_template` resource, `constraints` object. Use `compute_optimized_state` and `storage_optimized_state` instead.

Old configuration:

```terraform
module "castai-eks-cluster" {
  node_templates = {
    spot_tmpl = {
      constraints = {
        compute_optimized = false
        storage_optimized = true
      }
    }
  }
}
```

New configuration:

```terraform
module "castai-eks-cluster" {
  node_templates = {
    spot_tmpl = {
      constraints = {
        compute_optimized_state = "disabled"
        storage_optimized_state = "enabled"
      }
    }
  }
}
```

Migrating from 9.x.x to 9.3.x
---------------------------

Version 9.3.x changed:
- Deprecated `autoscaler_policies_json` attribute. Use `autoscaler_settings` instead.

Old configuration:

```hcl
module "castai-eks-cluster" {
  autoscaler_policies_json = <<-EOT
    {
        "enabled": true,
        "unschedulablePods": {
            "enabled": true
        },
        "nodeDownscaler": {
            "enabled": true,
            "emptyNodes": {
                "enabled": true
            },
            "evictor": {
                "aggressiveMode": false,
                "cycleInterval": "5m10s",
                "dryRun": false,
                "enabled": true,
                "nodeGracePeriodMinutes": 10,
                "scopedMode": false
            }
        },
        "nodeTemplatesPartialMatchingEnabled": false,
        "clusterLimits": {
            "cpu": {
                "maxCores": 20,
                "minCores": 1
            },
            "enabled": true
        }
    }
  EOT
}
```

New configuration:

```hcl
module "castai-eks-cluster" {
  autoscaler_settings = {
    enabled                                 = true
    node_templates_partial_matching_enabled = false

    unschedulable_pods = {
      enabled = true
    }

    node_downscaler = {
      enabled = true

      empty_nodes = {
        enabled = true
      }

      evictor = {
        aggressive_mode           = false
        cycle_interval            = "5m10s"
        dry_run                   = false
        enabled                   = true
        node_grace_period_minutes = 10
        scoped_mode               = false
      }
    }

    cluster_limits = {
      enabled = true

      cpu = {
        max_cores = 20
        min_cores = 1
      }
    }
  }
}
```

# Examples

Usage examples are located in [terraform provider repo](https://github.com/castai/terraform-provider-castai/tree/master/examples/eks)

### Generate docs

```shell
terraform-docs markdown table . --output-file README.md
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.49 |
| <a name="requirement_castai"></a> [castai](#requirement\_castai) | >= 8.1 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_castai"></a> [castai](#provider\_castai) | 8.1.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [castai_autoscaler.castai_autoscaler_policies](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/autoscaler) | resource |
| [castai_eks_cluster.my_castai_cluster](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/eks_cluster) | resource |
| [castai_node_configuration.this](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/node_configuration) | resource |
| [castai_node_configuration_default.this](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/node_configuration_default) | resource |
| [castai_node_template.this](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/node_template) | resource |
| [castai_workload_scaling_policy.this](https://registry.terraform.io/providers/castai/castai/latest/docs/resources/workload_scaling_policy) | resource |
| [helm_release.castai_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_ai_optimizer_proxy](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_ai_optimizer_proxy_self_managed](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_cluster_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_cluster_controller_self_managed](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_egressd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_egressd_self_managed](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_evictor](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_evictor_ext](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_evictor_self_managed](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_kvisor](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_kvisor_self_managed](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_live](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_live_self_managed](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_pod_mutator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_pod_mutator_self_managed](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_pod_pinner](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_pod_pinner_self_managed](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_spot_handler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_workload_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.castai_workload_autoscaler_self_managed](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.wait_for_cluster](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_aws_access_key_id"></a> [agent\_aws\_access\_key\_id](#input\_agent\_aws\_access\_key\_id) | AWS access key for CAST AI agent to fetch instance details. | `string` | `""` | no |
| <a name="input_agent_aws_iam_service_account_role_arn"></a> [agent\_aws\_iam\_service\_account\_role\_arn](#input\_agent\_aws\_iam\_service\_account\_role\_arn) | Arn of the role to be used by CAST AI agent to fetch instance details. Only readonly AmazonEC2ReadOnlyAccess is needed. | `string` | `""` | no |
| <a name="input_agent_aws_secret_access_key"></a> [agent\_aws\_secret\_access\_key](#input\_agent\_aws\_secret\_access\_key) | AWS access key secret for CAST AI agent to fetch instance details. | `string` | `""` | no |
| <a name="input_agent_values"></a> [agent\_values](#input\_agent\_values) | List of YAML formatted string with agent values | `list(string)` | `[]` | no |
| <a name="input_agent_version"></a> [agent\_version](#input\_agent\_version) | Version of castai-agent helm chart. Default latest | `string` | `null` | no |
| <a name="input_ai_optimizer_values"></a> [ai\_optimizer\_values](#input\_ai\_optimizer\_values) | List of YAML formatted string with ai-optimizer values | `list(string)` | `[]` | no |
| <a name="input_ai_optimizer_version"></a> [ai\_optimizer\_version](#input\_ai\_optimizer\_version) | Version of castai-ai-optimizer helm chart. Default latest | `string` | `null` | no |
| <a name="input_api_url"></a> [api\_url](#input\_api\_url) | URL of alternative CAST AI API to be used during development or testing | `string` | `"https://api.cast.ai"` | no |
| <a name="input_autoscaler_policies_json"></a> [autoscaler\_policies\_json](#input\_autoscaler\_policies\_json) | Optional json object to override CAST AI cluster autoscaler policies. Deprecated, use `autoscaler_settings` instead. | `string` | `null` | no |
| <a name="input_autoscaler_settings"></a> [autoscaler\_settings](#input\_autoscaler\_settings) | Optional Autoscaler policy definitions to override current autoscaler settings | `any` | `null` | no |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | ID of AWS account the cluster is located in. | `string` | n/a | yes |
| <a name="input_aws_assume_role_arn"></a> [aws\_assume\_role\_arn](#input\_aws\_assume\_role\_arn) | Arn of the role to be used by CAST AI for IAM access | `string` | `null` | no |
| <a name="input_aws_cluster_name"></a> [aws\_cluster\_name](#input\_aws\_cluster\_name) | Name of the cluster to be connected to CAST AI. | `string` | n/a | yes |
| <a name="input_aws_cluster_region"></a> [aws\_cluster\_region](#input\_aws\_cluster\_region) | Region of the cluster to be connected to CAST AI. | `string` | n/a | yes |
| <a name="input_castai_api_token"></a> [castai\_api\_token](#input\_castai\_api\_token) | Optional CAST AI API token created in console.cast.ai API Access keys section. Used only when `wait_for_cluster_ready` is set to true | `string` | `""` | no |
| <a name="input_castai_components_labels"></a> [castai\_components\_labels](#input\_castai\_components\_labels) | Optional additional Kubernetes labels for CAST AI pods | `map(any)` | `{}` | no |
| <a name="input_cluster_controller_values"></a> [cluster\_controller\_values](#input\_cluster\_controller\_values) | List of YAML formatted string with cluster-controller values | `list(string)` | `[]` | no |
| <a name="input_cluster_controller_version"></a> [cluster\_controller\_version](#input\_cluster\_controller\_version) | Version of castai-cluster-controller helm chart. Default latest | `string` | `null` | no |
| <a name="input_default_node_configuration"></a> [default\_node\_configuration](#input\_default\_node\_configuration) | ID of the default node configuration | `string` | `""` | no |
| <a name="input_default_node_configuration_name"></a> [default\_node\_configuration\_name](#input\_default\_node\_configuration\_name) | Name of the default node configuration | `string` | `""` | no |
| <a name="input_delete_nodes_on_disconnect"></a> [delete\_nodes\_on\_disconnect](#input\_delete\_nodes\_on\_disconnect) | Optionally delete Cast AI created nodes when the cluster is destroyed | `bool` | `false` | no |
| <a name="input_egressd_values"></a> [egressd\_values](#input\_egressd\_values) | List of YAML formatted string with egressd values | `list(string)` | `[]` | no |
| <a name="input_egressd_version"></a> [egressd\_version](#input\_egressd\_version) | Version of castai-egressd helm chart. Default latest | `string` | `null` | no |
| <a name="input_evictor_ext_values"></a> [evictor\_ext\_values](#input\_evictor\_ext\_values) | List of YAML formatted string with evictor-ext values | `list(string)` | `[]` | no |
| <a name="input_evictor_ext_version"></a> [evictor\_ext\_version](#input\_evictor\_ext\_version) | Version of castai-evictor-ext chart. Default latest | `string` | `null` | no |
| <a name="input_evictor_values"></a> [evictor\_values](#input\_evictor\_values) | List of YAML formatted string with evictor values | `list(string)` | `[]` | no |
| <a name="input_evictor_version"></a> [evictor\_version](#input\_evictor\_version) | Version of castai-evictor chart. Default latest | `string` | `null` | no |
| <a name="input_grpc_url"></a> [grpc\_url](#input\_grpc\_url) | gRPC endpoint used by pod-pinner | `string` | `"grpc.cast.ai:443"` | no |
| <a name="input_install_ai_optimizer"></a> [install\_ai\_optimizer](#input\_install\_ai\_optimizer) | Optional flag for installation of AI Optimizer (https://docs.cast.ai/docs/getting-started-ai) | `bool` | `false` | no |
| <a name="input_install_egressd"></a> [install\_egressd](#input\_install\_egressd) | Optional flag for installation of Egressd (Network cost monitoring) (https://docs.cast.ai/docs/network-cost) | `bool` | `false` | no |
| <a name="input_install_live"></a> [install\_live](#input\_install\_live) | Optional flag for installation of CAST AI Live (https://docs.cast.ai/docs/clm-getting-started). Default is true | `bool` | `true` | no |
| <a name="input_install_live_cni"></a> [install\_live\_cni](#input\_install\_live\_cni) | Optional flag for installing CAST AI aws-vpc-cni fork for CAST AI Live. Default is true | `bool` | `true` | no |
| <a name="input_install_pod_mutator"></a> [install\_pod\_mutator](#input\_install\_pod\_mutator) | Optional flag for installation of pod mutator | `bool` | `false` | no |
| <a name="input_install_security_agent"></a> [install\_security\_agent](#input\_install\_security\_agent) | Optional flag for installation of security agent (Kvisor - https://docs.cast.ai/docs/kvisor) | `bool` | `false` | no |
| <a name="input_install_workload_autoscaler"></a> [install\_workload\_autoscaler](#input\_install\_workload\_autoscaler) | Optional flag for installation of workload autoscaler (https://docs.cast.ai/docs/workload-autoscaling-configuration) | `bool` | `false` | no |
| <a name="input_kvisor_controller_extra_args"></a> [kvisor\_controller\_extra\_args](#input\_kvisor\_controller\_extra\_args) | ⚠️ DEPRECATED: use kvisor\_values instead (see example: https://github.com/castai/terraform-provider-castai/tree/master/examples/eks/eks_cluster_with_security/castai.tf ). Extra arguments for the kvisor controller. Optionally enable kvisor to lint Kubernetes YAML manifests, scan workload images and check if workloads pass CIS Kubernetes Benchmarks as well as NSA, WASP and PCI recommendations. | `map(string)` | <pre>{<br/>  "image-scan-enabled": "true",<br/>  "kube-bench-enabled": "true",<br/>  "kube-linter-enabled": "true"<br/>}</pre> | no |
| <a name="input_kvisor_grpc_addr"></a> [kvisor\_grpc\_addr](#input\_kvisor\_grpc\_addr) | CAST AI Kvisor optimized GRPC API address | `string` | `"kvisor.prod-master.cast.ai:443"` | no |
| <a name="input_kvisor_values"></a> [kvisor\_values](#input\_kvisor\_values) | List of YAML formatted string with kvisor values, see example: https://github.com/castai/terraform-provider-castai/tree/master/examples/eks/eks_cluster_with_security/castai.tf | `list(string)` | `[]` | no |
| <a name="input_kvisor_version"></a> [kvisor\_version](#input\_kvisor\_version) | Version of kvisor chart. Default latest | `string` | `null` | no |
| <a name="input_kvisor_wait"></a> [kvisor\_wait](#input\_kvisor\_wait) | Wait for kvisor chart to finish release | `bool` | `true` | no |
| <a name="input_live_values"></a> [live\_values](#input\_live\_values) | List of YAML formatted string with castai-live values | `list(string)` | `[]` | no |
| <a name="input_live_version"></a> [live\_version](#input\_live\_version) | Version of castai-live helm chart. Default latest | `string` | `null` | no |
| <a name="input_node_configurations"></a> [node\_configurations](#input\_node\_configurations) | Map of EKS node configurations to create | `any` | `{}` | no |
| <a name="input_node_templates"></a> [node\_templates](#input\_node\_templates) | Map of node templates to create | `any` | `{}` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | DEPRECATED (required only for pod mutator v0.0.25 and older): CAST AI Organization ID | `string` | `""` | no |
| <a name="input_pod_mutator_version"></a> [pod\_mutator\_version](#input\_pod\_mutator\_version) | Version of castai-pod-mutator helm chart. Default latest | `string` | `null` | no |
| <a name="input_pod_pinner_values"></a> [pod\_pinner\_values](#input\_pod\_pinner\_values) | List of YAML formatted string values for agent helm chart | `list(string)` | `[]` | no |
| <a name="input_pod_pinner_version"></a> [pod\_pinner\_version](#input\_pod\_pinner\_version) | Version of pod-pinner helm chart. Default latest | `string` | `null` | no |
| <a name="input_self_managed"></a> [self\_managed](#input\_self\_managed) | Whether CAST AI components' upgrades are managed by a customer; by default upgrades are managed CAST AI central system. WARNING: changing this after the module was created is not supported. | `bool` | `false` | no |
| <a name="input_spot_handler_values"></a> [spot\_handler\_values](#input\_spot\_handler\_values) | List of YAML formatted string with spot-handler values | `list(string)` | `[]` | no |
| <a name="input_spot_handler_version"></a> [spot\_handler\_version](#input\_spot\_handler\_version) | Version of castai-spot-handler helm chart. Default latest | `string` | `null` | no |
| <a name="input_wait_for_cluster_ready"></a> [wait\_for\_cluster\_ready](#input\_wait\_for\_cluster\_ready) | Wait for cluster to be ready before finishing the module execution, this option requires `castai_api_token` to be set | `bool` | `false` | no |
| <a name="input_workload_autoscaler_values"></a> [workload\_autoscaler\_values](#input\_workload\_autoscaler\_values) | List of YAML formatted string with cluster-workload-autoscaler values | `list(string)` | `[]` | no |
| <a name="input_workload_autoscaler_version"></a> [workload\_autoscaler\_version](#input\_workload\_autoscaler\_version) | Version of castai-workload-autoscaler helm chart. Default latest | `string` | `null` | no |
| <a name="input_workload_scaling_policies"></a> [workload\_scaling\_policies](#input\_workload\_scaling\_policies) | Map of workload scaling policies to create | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_castai_node_configurations"></a> [castai\_node\_configurations](#output\_castai\_node\_configurations) | Map of node configurations ids by name |
| <a name="output_castai_node_templates"></a> [castai\_node\_templates](#output\_castai\_node\_templates) | Map of node template by name |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | CAST AI cluster id, which can be used for accessing cluster data using API |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | CAST.AI organization id of the cluster |
<!-- END_TF_DOCS -->
