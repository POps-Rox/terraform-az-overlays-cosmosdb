mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/existing-rg"
      name     = "existing-rg"
      location = "westus2"
    }
  }

  mock_resource "azurerm_management_lock" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/existing-rg/providers/Microsoft.Authorization/locks/mock-lock"
    }
  }
}

mock_provider "popsrox" {
  mock_data "popsrox_resource_name" {
    defaults = {
      result = "generated-resource-group-name"
    }
  }
}

override_module {
  target = module.mod_azregions
  outputs = {
    location_cli   = "westus2"
    location_short = "wus2"
  }
}

override_module {
  target = module.mod_scaffold_rg
  outputs = {
    resource_group_name     = "created-rg"
    resource_group_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/created-rg"
    resource_group_location = "centralus"
  }
}

variables {
  location                     = "westus2"
  environment                  = "public"
  deploy_environment           = "dev"
  workload_name                = "cosmos"
  org_name                     = "anoa"
  existing_resource_group_name = "existing-rg"
}

run "custom_name_override_precedence" {
  command = plan

  variables {
    custom_resource_group_name = "explicit-rg"
  }

  assert {
    condition     = local.example_custom_name == "explicit-rg"
    error_message = "custom_resource_group_name must override the generated popsrox name."
  }
}

run "empty_custom_name_falls_through_to_generated" {
  command = plan

  variables {
    custom_resource_group_name = ""
  }

  assert {
    condition     = local.example_custom_name == "generated-resource-group-name"
    error_message = "An empty custom_resource_group_name must fall through to the generated popsrox name."
  }
}

run "existing_resource_group_path_and_locks_disabled" {
  command = plan

  variables {
    create_resource_group = false
    enable_resource_locks = false
  }

  assert {
    condition     = length(data.azurerm_resource_group.rg) == 1
    error_message = "create_resource_group=false must look up the existing resource group."
  }

  assert {
    condition     = length(module.mod_scaffold_rg) == 0
    error_message = "create_resource_group=false must not create the resource group module."
  }

  assert {
    condition     = local.resource_group_name == "existing-rg"
    error_message = "Existing resource group lookup must drive local.resource_group_name."
  }

  assert {
    condition     = local.resource_group_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/existing-rg"
    error_message = "Existing resource group lookup must drive local.resource_group_id."
  }

  assert {
    condition     = local.location == "westus2"
    error_message = "Existing resource group lookup must pass through the Azure location."
  }

  assert {
    condition     = length(azurerm_management_lock.resource_group_level_lock) == 0
    error_message = "enable_resource_locks=false must not create a management lock."
  }
}

run "created_resource_group_path_and_locks_enabled" {
  command = plan

  variables {
    create_resource_group = true
    enable_resource_locks = true
    lock_level            = "ReadOnly"
    add_tags = {
      owner = "platform"
    }
  }

  assert {
    condition     = length(data.azurerm_resource_group.rg) == 0
    error_message = "create_resource_group=true must not look up an existing resource group."
  }

  assert {
    condition     = length(module.mod_scaffold_rg) == 1
    error_message = "create_resource_group=true must create one resource group module instance."
  }

  assert {
    condition     = local.resource_group_name == "created-rg"
    error_message = "Created resource group module output must drive local.resource_group_name."
  }

  assert {
    condition     = local.resource_group_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/created-rg"
    error_message = "Created resource group module output must drive local.resource_group_id."
  }

  assert {
    condition     = local.location == "centralus"
    error_message = "Created resource group module output must pass through local.location."
  }

  assert {
    condition     = length(azurerm_management_lock.resource_group_level_lock) == 1
    error_message = "enable_resource_locks=true must create one management lock."
  }

  assert {
    condition     = azurerm_management_lock.resource_group_level_lock[0].name == "created-rg-ReadOnly-lock"
    error_message = "Management lock name must be derived from the selected resource group and lock level."
  }

  assert {
    condition     = local.default_tags.deployedBy == "AzureNoOpsTF [default]" && local.default_tags.env == "public" && local.default_tags.workload == "cosmos"
    error_message = "Default tags must preserve environment and workload passthrough values."
  }

  assert {
    condition     = lookup(local.resource_group_tags, "owner", "") == "platform" && lookup(local.resource_group_tags, "DeployedBy", "") == "AzureNoOpsTF [default]"
    error_message = "Resource group module tags must merge caller tags with the deployment tag."
  }
}
