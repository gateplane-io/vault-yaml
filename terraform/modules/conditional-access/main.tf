

module "policy_gate" {
  for_each = local.conditional_roles

  # source = "github.com/gateplane-io/terraform-gateplane-policy-gate?ref=main"
  source  = "gateplane-io/policy-gate/gateplane"
  version = "1.1.0"

  endpoint_prefix = ""

  name = each.key

  protected_policies = [var.policies[each.key].name]

  plugin_options = {
    "required_approvals"    = each.value["access_conditional"]["required_approvals"],
    "require_justification" = each.value["access_conditional"]["require_justification"],
  }

  vault_addr_local = var.vault_addr
}

locals {
  compatible_policies_list = flatten([
    for value in local.conditional_roles :
    [
      [for access in value["access_requestors"] :
        merge(value, {
          "key"               = module.policy_gate[value["key"]].policy_names["requestor"],
          "access"            = access
          "access_requestors" = null,
          "access_approvers"  = null,
        })
      ],
      [for access in value["access_approvers"] :
        merge(value, {
          "key"               = module.policy_gate[value["key"]].policy_names["approver"],
          "access"            = access
          "access_requestors" = null,
          "access_approvers"  = null,
        })
      ],
    ]
    if module.policy_gate[value["key"]].policy_names["protected"][0] == value["key"]
  ])
}
