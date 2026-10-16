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

run "dispatches_multiple_mounts_and_aggregates_outputs" {
  command = plan

  variables {
    name_prefix = "platform"

    accesses = {
      "pki/company" = {
        type = "pki"
        roles = {
          service = {
            access = {
              static      = ["identity.entity_id.entity-123"]
              conditional = {}
            }
          }
        }
      }
      "pki/partners" = {
        type = "pki"
        roles = {
          client = {
            access = {
              static      = ["identity.entity_id.entity-456"]
              conditional = {}
            }
          }
        }
      }
    }

    mounts = {
      pki = [
        {
          mount                    = { path = "pki/company", accessor = "pki_company_mock" }
          issuer_id                = "issuer-company"
          templated_common_names   = {}
          name_prefix              = "team"
          enable_conditional_roles = false
        },
        {
          mount                    = { path = "pki/partners", accessor = "pki_partners_mock" }
          issuer_id                = "issuer-partners"
          templated_common_names   = {}
          enable_conditional_roles = false
        },
      ]
      external = [{
        alias = "kv"
        mount = { path = "kvv2", accessor = "kv_mock" }
      }]
    }

    auth_methods = {}
  }

  assert {
    condition     = length(output.policies_list) == 2
    error_message = "The root module must aggregate policy metadata from every mount of the same type."
  }

  assert {
    condition = toset([for policy in output.policies_list : policy.key]) == toset([
      "platform-team-pki-service-company",
      "platform-pki-client-partners",
    ])
    error_message = "The root name_prefix must apply to every policy and combine with per-mount prefixes."
  }

  assert {
    condition     = toset(keys(module.pki)) == toset(["pki/company", "pki/partners"])
    error_message = "Mount arrays must be normalized into module instances keyed by mount path."
  }

  assert {
    condition = output.secret_engines == {
      "pki/company"  = { path = "pki/company", accessor = "pki_company_mock" }
      "pki/partners" = { path = "pki/partners", accessor = "pki_partners_mock" }
      kv             = { path = "kvv2", accessor = "kv_mock" }
    }
    error_message = "All managed and external mounts must be exposed to ad-hoc policy templates."
  }
}

run "dispatches_multiple_auth_methods_with_explicit_aliases" {
  command = plan

  variables {
    accesses = {}
    mounts = {
      vault = [{
        role_directory = "unused"
      }]
    }
    auth_methods = {
      identity = [
        { alias = "primary_identity" },
        { alias = "partner_identity" },
      ]
    }
  }

  assert {
    condition = (
      contains(keys(output.authorizations), "primary_identity") &&
      contains(keys(output.authorizations), "partner_identity")
    )
    error_message = "Every auth-method instance must use its explicit alias as the principal prefix."
  }

  assert {
    condition     = toset(keys(module.identity)) == toset(["primary_identity", "partner_identity"])
    error_message = "Mountless auth arrays must be normalized into module instances keyed by alias."
  }

  assert {
    condition     = toset(keys(module.vault)) == toset(["adhoc"])
    error_message = "The mountless Vault policy configuration must use the fixed adhoc module key without requiring an alias."
  }
}

run "rejects_malformed_access_entry" {
  command = plan

  variables {
    accesses = {
      adhoc = {
        type       = "pki"
        roles      = {}
        unexpected = true
      }
    }
    mounts       = {}
    auth_methods = {}
  }

  expect_failures = [var.accesses]
}

run "rejects_malformed_static_access" {
  command = plan

  variables {
    accesses = {
      pki = {
        type = "pki"
        roles = {
          invalid = {
            access = {
              static      = "ldap.groups.Administrators"
              conditional = {}
            }
          }
        }
      }
    }
    mounts       = {}
    auth_methods = {}
  }

  expect_failures = [var.accesses]
}

run "rejects_malformed_conditional_access" {
  command = plan

  variables {
    accesses = {
      pki = {
        type = "pki"
        roles = {
          invalid = {
            access = {
              static = []
              conditional = {
                requestors         = ["ldap.groups.Developers"]
                approvers          = ["ldap.groups.Administrators"]
                required_approvals = 0
              }
            }
          }
        }
      }
    }
    mounts       = {}
    auth_methods = {}
  }

  expect_failures = [var.accesses]
}

run "rejects_multiple_adhoc_configurations" {
  command = plan

  variables {
    accesses = {}
    mounts = {
      vault = [
        { role_directory = "first" },
        { role_directory = "second" },
      ]
    }
    auth_methods = {}
  }

  expect_failures = [var.mounts]
}
