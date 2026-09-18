# Changelog

## Unreleased

### Changed

- Migrated the module and examples to `hashicorp/azurerm` 5.x constraints.
- Updated the private DNS zone virtual network link template to use
  `private_dns_zone_id`.

### Fixed

- Resource group locks now use the selected resource group ID whether the
  resource group is created by this module or looked up as an existing group.

### Added

- Added `terraform test` functional coverage for naming precedence, empty-name
  fallthrough, resource group selection, lock conditionals, tag merging, and
  location passthrough.

## [2.0.0] - 2026-05-12

### ⚠️ Breaking Changes

- Upgraded `hashicorp/azurerm` provider from `~> 3.116` to `~> 4.20`.
- Minimum Terraform CLI version raised from `>= 1.9` to `>= 1.10`.
- `azurerm_subnet.private_endpoint_network_policies_enabled` (bool) →
  `azurerm_subnet.private_endpoint_network_policies` (string enum:
  `Enabled` / `Disabled` / `NetworkSecurityGroupEnabled` /
  `RouteTableEnabled`) on the private-endpoint template. azurerm 4.x
  replaced the bool with a string enum. The pre-existing value `true`
  maps to `"Enabled"`. Note: this resource lives inside a commented-out
  template block in `resources.template.private.endpoints.tf`; the
  rewrite is preemptive so future un-commenting works on 4.x without
  further edits.

### Behavior Notes

- This overlay does not yet declare an `azurerm_cosmosdb_account`
  resource (only private-endpoint scaffolding and RG/region lookups).
  No data-plane resource changes are included in this PR — the 4.x
  rename matrix for `azurerm_cosmosdb_account` will be applied when
  the resource block is added in a subsequent feature PR.

### Migration Notes for Consumers

- Bump your root `azurerm` provider constraint to `~> 4.20`.
- Ensure Terraform CLI `>= 1.10`.
- Set `ARM_SUBSCRIPTION_ID` env var or `subscription_id` in your
  `provider "azurerm"` block — azurerm 4.x requires it.
- Module public input/output surface is unchanged. No variable renames
  or removals.

### Added

- `azapi ~> 2.0` provider declaration in `versions.tf` (root + every
  example).
- Complete `terraform {}` block in each example `versions.tf` (was a
  provider-only file previously, leaving azurerm un-pinned per example).

### Fixed

- Removed broken `output "echo_text"` (referenced an undeclared
  `module.echo`) from both Commerical and Government example
  `outputs.tf`. Pre-existing template artifact that surfaced once
  validation became enforceable.

### Internal

- Standardized `versions.tf` format across root and all examples.
- Bumped `required_version` to `>= 1.10` everywhere.

### Cross-module dependency

This module sources two sibling overlays from GitHub
(`tf-az-overlays-azregionslookup`, `tf-az-overlays-resourcegroup`)
which are still pinned to `azurerm ~> 3.116`. Production consumers
must wait for those overlays' Phase 1 PRs to merge before this
`2.0.0` can be cleanly initialized. Local validation was performed by
patching the cached `versions.tf` of those submodules during
`terraform init -get=false`.

# v1.0.0 - <date>

Changed
- Bump minimum Terraform version from `>= 1.3` to `>= 1.9`
- Bump azurerm provider from `~> 3.22` to `~> 3.116`

Added
- Add Something you added
