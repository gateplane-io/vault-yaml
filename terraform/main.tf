# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

/*
  ====================================================
  This file IS PART OF the 'vault-yaml' installation

  Tie all Secrets Engines and Auth Methods in the
  'secrets-engines.tf' and 'auth-methods.tf' files
  to their respective 'vault-yaml' modules (under ./modules)
  ====================================================
*/

locals {
  accesses = yamldecode(
    # Change this filepath to the YAML file
    # containing a 'vault-yaml' schema
    file("${path.module}/../access.example.yaml")
  )
}

/* === Secrets Engines ===  */

module "ca" {
  source = "./modules/secret-engines/pki"

  mount = vault_mount.pki

  accesses  = local.accesses
  issuer_id = vault_pki_secret_backend_root_cert.this.issuer_id

  templated_common_names = {
    email = "{{identity.entity.aliases.${local.auth_methods["ldap"]["accessor"]}.name}}@my-org.example.com"
  }
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

locals {
  # == Definitions to be used when templating Vault Policies ==
  auth_methods = {
    (module.ldap.principal_key) : module.ldap.entry,
    # E.g: "ldap" : {accessor : "ldap_accessor_123", path: "ldap/old_infra"}

    # The module.identity DOES NOT need to be added
    # as Vault/OpenBao Templating can handle these entries internally:
    # https://developer.hashicorp.com/vault/docs/concepts/policies#templated-policies

    # ... <-- extend here for new Auth Method modules
  }

  secrets_engines = {
    # Manually adding KV storage
    "kv" = {
      "accessor" : vault_mount.kvv2.accessor,
      "path" : vault_mount.kvv2.path,
    },
    # Module outputs should be added:
    (module.ca.entry["path"])         = module.ca.entry,
    (module.kubernetes.entry["path"]) = module.kubernetes.entry,
    (module.ssh.entry["path"])        = module.ssh.entry,
    # ... <-- extend here for new Secrets Engine modules
  }
}

module "vault" {
  source = "./modules/secret-engines/vault"

  role_directory = "../roles/vault"
  accesses       = local.accesses

  # Maps used for templating Vault Policy documents under roles/vault
  auth_methods   = local.auth_methods
  secret_engines = local.secrets_engines
}

# Structured output to by used by the Auth Method modules
locals {
  policies_list = flatten([
    module.ca.access_list,
    module.kubernetes.access_list,
    module.ssh.access_list,
    module.vault.access_list,
    # ... <-- extend here for new Secrets Engine modules
  ])
}

/* === Authentication Methods ===  */

# Handle Principals authenticated through LDAP
module "ldap" {
  source = "./modules/auth-methods/ldap"

  mount = vault_ldap_auth_backend.this

  policies_list = local.policies_list
  # handles Principals starting with 'ldap'
  # (e.g: ldap.users.jdoe)
  principal_key = "ldap"
}

# Handle Principals directly existing in Vault/OpenBao (Entities/Groups)
module "identity" {
  source = "./modules/auth-methods/identity"

  policies_list = local.policies_list
  # handles Principals starting with 'identity'
  # (e.g: identity.entity_id.de494a79-6ed1-4bd4-8a94-bb4f0e5bdec0)
  principal_key = "identity"
}

locals {
  # Populates a mapping of principals
  # to attached created Vault Policies
  authorizations = [
    module.identity.authorizations,
    module.ldap.authorizations,
  ]
}
