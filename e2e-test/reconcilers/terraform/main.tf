# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

variable "prerequisite_state_path" {
  type = string
}

variable "enable_ldap" {
  description = "Whether the target supports the LDAP auth method."
  type        = bool
  default     = true
}

data "terraform_remote_state" "prerequisites" {
  backend = "local"
  config = {
    path = var.prerequisite_state_path
  }
}

locals {
  accesses     = yamldecode(file("${path.module}/../../access.yaml"))
  mounts       = data.terraform_remote_state.prerequisites.outputs.mounts
  auth_methods = data.terraform_remote_state.prerequisites.outputs.auth_methods
  pki_root     = data.terraform_remote_state.prerequisites.outputs.pki_root

  identity_name_template = "{{identity.entity.name}}"
  ldap_name_template     = var.enable_ldap ? "{{identity.entity.aliases.${local.auth_methods.ldap.accessor}.name}}" : local.identity_name_template
}

module "vault_yaml" {
  source = "../../../terraform"

  accesses = local.accesses

  mounts = {
    pki = [{
      mount                    = local.mounts.pki
      issuer_id                = local.pki_root.issuer_id
      enable_conditional_roles = false
      templated_common_names = {
        email = "${local.ldap_name_template}@example.test"
      }
    }]

    kubernetes = [{
      mount                    = local.mounts.kubernetes
      role_directory           = "${path.module}/../../fixtures/roles/kubernetes"
      enable_conditional_roles = false
    }]

    ssh = [{
      mount                    = local.mounts.ssh
      allowed_users            = local.ldap_name_template
      default_user             = local.ldap_name_template
      enable_conditional_roles = false
    }]

    vault = [{
      role_directory           = "${path.module}/../../fixtures/roles/vault"
      enable_conditional_roles = false
    }]

    external = [{
      alias = "kv"
      mount = local.mounts.kv
    }]
  }

  auth_methods = merge(
    {
      identity = [{
        alias = "identity"
      }]

      cert = [{
        alias               = "cert"
        mount               = local.auth_methods.cert
        trusted_certificate = local.pki_root.certificate
      }]

      kubernetes = [{
        alias = "kubernetes"
        mount = local.auth_methods.kubernetes
      }]
    },
    var.enable_ldap ? {
      ldap = [{
        alias = "ldap"
        mount = local.auth_methods.ldap
      }]
    } : {},
  )
}
