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

run "ssh_roles_policies_and_custom_options" {
  command = plan

  variables {
    mount = {
      path     = "ssh/production"
      accessor = "ssh_mock"
    }
    name_prefix              = "ops"
    allowed_users            = "{{identity.entity.name}}"
    default_user             = "ubuntu"
    enable_conditional_roles = false
    accesses = {
      "ssh/production" = {
        type = "ssh"
        roles = {
          developer = {
            access = {
              static      = ["ldap.groups.Developers"]
              conditional = {}
            }
          }
          tunnel = {
            ttl        = 300
            ttl_max    = 1800
            extensions = ["permit-port-forwarding", "permit-agent-forwarding"]
            access = {
              static      = ["ldap.groups.Operators"]
              conditional = {}
            }
          }
        }
      }
    }
  }

  assert {
    condition     = vault_ssh_secret_backend_role.this["developer"].backend == "ssh/production" && vault_ssh_secret_backend_role.this["developer"].key_type == "ca"
    error_message = "The parsed role must map to the selected SSH CA mount."
  }

  assert {
    condition     = tonumber(vault_ssh_secret_backend_role.this["developer"].ttl) == 60 && tonumber(vault_ssh_secret_backend_role.this["developer"].max_ttl) == 600 && vault_ssh_secret_backend_role.this["developer"].allowed_extensions == "permit-pty"
    error_message = "SSH parser defaults must reach the backend role."
  }

  assert {
    condition = (
      tonumber(vault_ssh_secret_backend_role.this["tunnel"].ttl) == 300 &&
      tonumber(vault_ssh_secret_backend_role.this["tunnel"].max_ttl) == 1800 &&
      vault_ssh_secret_backend_role.this["tunnel"].default_extensions["permit-port-forwarding"] == "" &&
      vault_ssh_secret_backend_role.this["tunnel"].default_extensions["permit-agent-forwarding"] == ""
    )
    error_message = "Custom TTLs and extensions must be preserved."
  }

  assert {
    condition     = vault_ssh_secret_backend_role.this["tunnel"].allowed_users == "{{identity.entity.name}}" && vault_ssh_secret_backend_role.this["tunnel"].allowed_users_template && vault_ssh_secret_backend_role.this["tunnel"].default_user == "ubuntu" && vault_ssh_secret_backend_role.this["tunnel"].default_user_template
    error_message = "Templated user constraints must be configured on every SSH role."
  }

  assert {
    condition     = data.vault_policy_document.this["ops-ssh-tunnel-production"].rule[0].path == "ssh/production/sign/tunnel" && tolist(data.vault_policy_document.this["ops-ssh-tunnel-production"].rule[0].capabilities) == tolist(["update"])
    error_message = "The SSH policy must grant signing on the mapped role."
  }

  assert {
    condition     = output.entry == { path = "ssh/production", accessor = "ssh_mock" } && length(output.access_list) == 2
    error_message = "Outputs must retain mount metadata and parsed static accesses."
  }
}
