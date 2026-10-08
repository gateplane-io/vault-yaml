# Complete example

This example consumes `vault-yaml` through one root-module call:

```hcl
module "vault_yaml" {
  source = "../.."

  accesses     = local.accesses
  mounts       = { /* arrays of existing engines keyed by type */ }
  auth_methods = { /* arrays keyed by type; every item has an alias */ }
}
```

- `*.byov.tf` files demonstrate resources that pre-exist vault-yaml and remain owned by the caller.
- `gateplane.tf` demonstrates the optional GatePlane installation and services setup.

Configure the Vault provider and example-specific variables before planning.
