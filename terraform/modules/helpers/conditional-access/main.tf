# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

module "policy_gate" {
  for_each = local.roles_conditional_map

  # source = "github.com/gateplane-io/terraform-gateplane-policy-gate?ref=main"
  source  = "gateplane-io/policy-gate/gateplane"
  version = "1.1.1"

  endpoint_prefix = ""

  name        = each.key
  description = each.value["access_conditional"]["description"]

  protected_policies = [var.policies[each.key].name]

  plugin_options = {
    "required_approvals"    = each.value["access_conditional"]["required_approvals"],
    "require_justification" = each.value["access_conditional"]["require_justification"],
  }

  vault_addr_local = var.vault_addr
}

locals {
  compatible_policies_list = flatten([
    for value in var.roles_conditional :
    [
      [for access in value["access_requestors"] :
        merge(value, {
          "key"                = module.policy_gate[value["key"]].policy_names["requestor"],
          "access"             = access
          "access_requestors"  = null,
          "access_approvers"   = null,
          "access_conditional" = null,
        })
      ],
      [for access in value["access_approvers"] :
        merge(value, {
          "key"                = module.policy_gate[value["key"]].policy_names["approver"],
          "access"             = access
          "access_requestors"  = null,
          "access_approvers"   = null,
          "access_conditional" = null,
        })
      ],
    ]
    if module.policy_gate[value["key"]].policy_names["protected"][0] == value["key"]
  ])
}
