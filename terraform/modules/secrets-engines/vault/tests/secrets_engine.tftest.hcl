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

run "templates_parsing_and_per_access_policies" {
  command = plan

  variables {
    role_directory           = "tests/fixtures/roles"
    name_prefix              = "team"
    enable_conditional_roles = false
    secret_engines = {
      kv = {
        path     = "secret"
        accessor = "kv_mock"
      }
    }
    auth_methods = {
      ldap = {
        path     = "ldap"
        accessor = "ldap_mock"
      }
    }
    accesses = {
      adhoc = {
        type = "vault"
        roles = {
          shared = {
            access = {
              static      = ["ldap.groups.Everyone", "ldap.groups.Operators"]
              conditional = {}
            }
          }
          personal = {
            for_each = true
            access = {
              static      = ["ldap.users.alice", "ldap.users.bob"]
              conditional = {}
            }
          }
        }
      }
    }
  }

  assert {
    condition     = length(vault_policy.adhoc) == 1 && vault_policy.adhoc["team-vault-shared-adhoc"].name == "team-vault-shared-adhoc"
    error_message = "Repeated static accesses must map to one shared policy."
  }

  assert {
    condition     = length(vault_policy.adhoc_for_each) == 2 && contains(keys(vault_policy.adhoc_for_each), "team-vault-personal-adhoc-alice") && contains(keys(vault_policy.adhoc_for_each), "team-vault-personal-adhoc-bob")
    error_message = "for_each roles must create one policy per parsed access identity."
  }

  assert {
    condition     = strcontains(vault_policy.adhoc["team-vault-shared-adhoc"].policy, "secret/data/shared") && strcontains(vault_policy.adhoc["team-vault-shared-adhoc"].policy, "team-vault-shared-adhoc")
    error_message = "Shared templates must receive secret-engine data and the generated policy name."
  }

  assert {
    condition     = strcontains(vault_policy.adhoc_for_each["team-vault-personal-adhoc-alice"].policy, "secret/data/alice") && strcontains(vault_policy.adhoc_for_each["team-vault-personal-adhoc-alice"].policy, "ldap/users/alice")
    error_message = "Per-access templates must receive the parsed access and auth-method data."
  }

  assert {
    condition     = length(output.access_list) == 4 && toset([for access in output.access_list : access.key]) == toset(["team-vault-shared-adhoc", "team-vault-personal-adhoc-alice", "team-vault-personal-adhoc-bob"])
    error_message = "Access output must retain all parsed memberships and normalized keys."
  }
}
