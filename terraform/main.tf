# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

# Authentication Methods

module "ldap" {
  source = "./modules/auth-methods/ldap"

  mount = vault_ldap_auth_backend.this

  policies_list = local.policies_list
  principal_key = "ldap" # handles Principals starting with 'ldap'
}

# Handle Principals directly existing in Vault/OpenBao (Entities/Groups)
module "identity" {
  source = "./modules/auth-methods/identity"

  policies_list = local.policies_list
  principal_key = "identity" # handles Principals starting with 'identity'
}


# Secrets Engines
module "ca" {
  source = "./modules/secret-engines/pki"

  mount = vault_mount.pki

  accesses  = local.accesses
  issuer_id = vault_pki_secret_backend_root_cert.this.issuer_id

  templated_common_names = {
    email = "{{identity.entity.aliases.${local.auth_methods["ldap"]["accessor"]}.name}}@my-org.example.com"
  }
}


module "adhoc" {
  source = "./modules/adhoc-policies"

  role_directory = "../roles/vault"
  accesses       = local.accesses

  # Maps used for templating policy documents
  auth_methods   = local.auth_methods
  secret_engines = local.secret_engines
}


module "kubernetes" {
  source = "./modules/secret-engines/kubernetes"

  mount = vault_kubernetes_secret_backend.kubernetes

  role_directory = "../roles/kubernetes"
  accesses       = local.accesses
}


module "ssh" {
  source = "./modules/secret-engines/ssh"

  accesses = local.accesses

  mount = vault_mount.ssh

  allowed_users = "{{identity.entity.aliases.${local.auth_methods["ldap"]["accessor"]}.name}}"
  default_user  = "{{identity.entity.aliases.${local.auth_methods["ldap"]["accessor"]}.name}}"
}
