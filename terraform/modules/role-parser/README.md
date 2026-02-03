# Role Parser Module

This Terraform module parses a decoded YAML structure containing roles and conditional roles, extracting specified fields with default values.

## Features

- Processes both regular `roles` and `roles_conditional` from the YAML structure
- Extracts specified fields from each role with configurable default values
- Generates a unified list of policies combining regular and conditional roles
- Applies a name prefix to generated keys

## Usage

```hcl
module "role_parser" {
  source = "./modules/role-parser"
  
  # Pass the decoded YAML structure
  accesses = var.accesses
  
  # Define fields to extract with defaults
  field_defaults = {
    ttl     = 600
    ttl_max = 3600
  }
  
  # Optional name prefix
  name_prefix = "env-"
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| accesses | Decoded YAML structure containing paths with roles and roles_conditional | any | n/a |
| field_defaults | Map of field keys to their default values for roles | map(any) | {} |
| name_prefix | Prefix to add to generated keys | string | "" |

## Outputs

| Name | Description |
|------|-------------|
| kubernetes_policies_list | List of policies extracted from both regular and conditional roles with specified fields |
| regular_policies_list | List of policies extracted from regular roles with specified fields |
| conditional_policies_list | List of policies extracted from conditional roles with specified fields |

## Example Output Structure

Each policy in the output list contains:
- `path`: The path from the YAML structure
- `role_name`: The name of the role
- `key`: Generated key for the policy
- `resource_name`: Extracted resource name from the path
- `access`: The access configuration
- `type`: Either "regular" or "conditional"
- Any additional fields specified in `field_defaults`

## Notes

- The module automatically handles both regular and conditional roles
- If a field is not present in a role, the default value from `field_defaults` is used
- Conditional roles have a more complex `access` structure with requestors, approvers, etc.