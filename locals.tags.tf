# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#------------------------------------------------------------
# Local Tags configuration - Default (required). 
#------------------------------------------------------------
locals {
  default_tags = var.default_tags_enabled ? {
    deployedBy = format("AzureNoOpsTF [%s]", terraform.workspace)
    env        = var.environment
    workload   = var.workload_name
  } : {}

  resource_group_tags = merge(var.add_tags, {
    DeployedBy = format("AzureNoOpsTF [%s]", terraform.workspace)
  })
}
