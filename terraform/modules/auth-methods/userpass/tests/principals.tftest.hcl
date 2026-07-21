# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

mock_provider "vault" {}

run "userpass_principals" {
  command = plan

  variables {
    mount = {
      path     = "userpass"
      accessor = "auth_userpass_mock"
    }
    policies_list = [
      {
        key    = "ALICE-READ"
        access = "userpass.alice"
      },
      {
        key    = "ALICE-WRITE"
        access = "userpass.alice"
      },
      {
        key    = "BOB-READ"
        access = "userpass.bob"
      },
      {
        key    = "IGNORED"
        access = "ldap.users.alice"
      }
    ]
  }

  assert {
    condition     = length(output.authorizations["userpass"]["users"]) == 2
    error_message = "Userpass principals must be parsed and unrelated auth-method principals ignored."
  }

  assert {
    condition     = vault_generic_endpoint.userpass_user["alice"].path == "auth/userpass/users/alice/policies"
    error_message = "The userpass principal must create the expected policy endpoint."
  }

  assert {
    condition     = jsondecode(vault_generic_endpoint.userpass_user["alice"].data_json).token_policies == ["alice-read", "alice-write"]
    error_message = "All matching policies must be normalized in the userpass payload."
  }

  assert {
    condition     = vault_generic_endpoint.userpass_user["bob"].disable_read && vault_generic_endpoint.userpass_user["bob"].disable_delete && vault_generic_endpoint.userpass_user["bob"].ignore_absent_fields
    error_message = "Userpass policy endpoints must retain their write-only lifecycle settings."
  }
}

run "custom_principal_key" {
  command = plan

  variables {
    mount = {
      path     = "userpass/contractors"
      accessor = "auth_userpass_contractors_mock"
    }
    principal_key = "contractor"
    policies_list = [
      {
        key    = "CONTRACTOR-READ"
        access = "contractor.carol"
      },
      {
        key    = "IGNORED-DEFAULT"
        access = "userpass.ignored"
      }
    ]
  }

  assert {
    condition     = length(output.authorizations["contractor"]["users"]) == 1 && output.authorizations["contractor"]["users"]["carol"].policies == ["CONTRACTOR-READ"]
    error_message = "A custom userpass principal key must select only matching users."
  }

  assert {
    condition     = vault_generic_endpoint.userpass_user["carol"].path == "auth/userpass/contractors/users/carol/policies"
    error_message = "Custom userpass principals must use the requested mount path."
  }
}
