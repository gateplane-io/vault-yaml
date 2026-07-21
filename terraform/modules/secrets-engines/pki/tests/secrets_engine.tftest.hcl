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

run "certificate_roles_policies_and_options" {
  command = plan

  variables {
    mount = {
      path     = "pki/company"
      accessor = "pki_mock"
    }
    issuer_id                = "issuer-123"
    name_prefix              = "corp"
    enable_conditional_roles = false
    templated_common_names = {
      email = "{{identity.entity.name}}@example.com"
    }
    accesses = {
      "pki/company" = {
        type = "pki"
        roles = {
          service = {
            server_flag           = true
            client_flag           = false
            ttl                   = 86400
            organization          = ["Example Corp"]
            country               = ["US"]
            locality              = ["Boston"]
            allowed_domains       = ["example.com"]
            templated_common_name = ["email"]
            allow_glob_domains    = true
            allow_bare_domains    = true
            key_usage             = ["DigitalSignature"]
            ext_key_usage         = ["ServerAuth"]
            access = {
              static      = ["ldap.groups.Operators"]
              conditional = {}
            }
          }
          client = {
            access = {
              static      = ["ldap.groups.Users"]
              conditional = {}
            }
          }
        }
      }
    }
  }

  assert {
    condition     = vault_pki_secret_backend_role.this["corp-pki-service-company"].backend == "pki/company" && vault_pki_secret_backend_role.this["corp-pki-service-company"].issuer_ref == "issuer-123"
    error_message = "The role must map to the selected PKI mount and issuer."
  }

  assert {
    condition     = tolist(vault_pki_secret_backend_role.this["corp-pki-service-company"].allowed_domains) == tolist(["example.com", "{{identity.entity.name}}@example.com"]) && vault_pki_secret_backend_role.this["corp-pki-service-company"].allowed_domains_template
    error_message = "Literal and named templated common names must be combined and template handling enabled."
  }

  assert {
    condition     = tonumber(vault_pki_secret_backend_role.this["corp-pki-service-company"].ttl) == 86400 && tonumber(vault_pki_secret_backend_role.this["corp-pki-service-company"].max_ttl) == 86400 && vault_pki_secret_backend_role.this["corp-pki-service-company"].allow_glob_domains && vault_pki_secret_backend_role.this["corp-pki-service-company"].allow_bare_domains
    error_message = "Custom TTL and domain options must reach the PKI role."
  }

  assert {
    condition     = tonumber(vault_pki_secret_backend_role.this["corp-pki-client-company"].ttl) == 600 && vault_pki_secret_backend_role.this["corp-pki-client-company"].client_flag && !vault_pki_secret_backend_role.this["corp-pki-client-company"].server_flag && !vault_pki_secret_backend_role.this["corp-pki-client-company"].allow_bare_domains
    error_message = "PKI parser defaults must reach roles that omit custom options."
  }

  assert {
    condition     = data.vault_policy_document.this["corp-pki-service-company"].rule[0].path == "pki/company/issue/service" && data.vault_policy_document.this["corp-pki-service-company"].rule[1].path == "pki/company/sign/service"
    error_message = "PKI policies must grant issue and sign access to the mapped role."
  }

  assert {
    condition     = output.entry == { path = "pki/company", accessor = "pki_mock" } && length(output.access_list) == 2
    error_message = "Outputs must retain mount metadata and parsed static accesses."
  }
}
