# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

provider "vault" {
  address = "https://vault.example.test"
}

mock_provider "null" {}

run "expand_requestor_and_approver_access" {
  command = plan

  providers = {
    vault = vault
    null  = null
  }

  override_module {
    target = module.policy_gate

    outputs = {
      policy_names = {
        requestor = "team-admin-requestor"
        approver  = "team-admin-approver"
        protected = ["team-admin"]
      }
    }
  }

  variables {
    name_prefix = "example"
    vault_addr  = "https://vault.example.test"
    policies = {
      team-admin = {
        name = "team-admin"
      }
    }
    roles_conditional = [
      {
        key               = "team-admin"
        path              = "secret/data/team"
        role_name         = "admin"
        resource_name     = "team"
        access_requestors = ["group.engineers", "group.on-call"]
        access_approvers  = ["group.security"]
        access_conditional = {
          required_approvals    = 2
          require_justification = true
          description           = "Temporary team administration"
        }
      },
    ]
  }

  assert {
    condition     = length(output.access_list) == 3
    error_message = "Each requestor and approver access should produce one compatible policy mapping."
  }

  assert {
    condition     = toset([for item in output.access_list : item.access]) == toset(["group.engineers", "group.on-call", "group.security"])
    error_message = "All requestor and approver principals should be preserved."
  }

  assert {
    condition     = length([for item in output.access_list : item if item.key == "team-admin-requestor"]) == 2 && length([for item in output.access_list : item if item.key == "team-admin-approver"]) == 1
    error_message = "Requestors and approvers should reference their respective mocked gate policies."
  }

  assert {
    condition     = alltrue([for item in output.access_list : item.access_requestors == null && item.access_approvers == null && item.access_conditional == null])
    error_message = "Expanded access records should clear conditional-access-only fields."
  }

  assert {
    condition     = alltrue([for item in output.access_list : item.path == "secret/data/team" && item.role_name == "admin" && item.resource_name == "team"])
    error_message = "Expanded mappings should retain the source role metadata."
  }
}
