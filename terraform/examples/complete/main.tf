# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

locals {
  accesses = yamldecode(file("${path.module}/../../../access.example.yaml"))
}

module "vault_yaml" {
  source = "../.."

  accesses = local.accesses

  mounts = {
    pki = [{
      mount                    = vault_mount.pki
      issuer_id                = vault_pki_secret_backend_root_cert.this.issuer_id
      enable_conditional_roles = true
      templated_common_names = {
        email = "{{identity.entity.aliases.${vault_ldap_auth_backend.this.accessor}.name}}@my-org.example.com"
      }
    }]

    kubernetes = [{
      mount          = vault_kubernetes_secret_backend.kubernetes
      role_directory = "${path.module}/../../../roles/kubernetes"
    }]

    ssh = [{
      mount         = vault_mount.ssh
      allowed_users = "{{identity.entity.aliases.${vault_ldap_auth_backend.this.accessor}.name}}"
      default_user  = "{{identity.entity.aliases.${vault_ldap_auth_backend.this.accessor}.name}}"
    }]

    vault = [{
      role_directory = "${path.module}/../../../roles/vault"
    }]

    external = [{
      alias = "kv"
      mount = vault_mount.kvv2
    }]
  }

  auth_methods = {
    ldap = [{
      alias = "ldap"
      mount = vault_ldap_auth_backend.this
    }]

    identity = [{
      alias = "identity"
    }]

    cert = [{
      alias               = "cert"
      mount               = vault_auth_backend.cert
      trusted_certificate = vault_pki_secret_backend_root_cert.this.certificate
    }]
  }
}
