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
  source      = "./modules/auth-methods/ldap"
  description = "Org LDAP Auth Method"

  path     = "ldap"
  ldap_url = "ldaps://ldap.example.com"

  ldap_userdn   = "dc=org,dc=com"
  ldap_userattr = "uid"

  # Use the query and search their 'memberOf' field values
  ldap_groupdn     = "dc=org,dc=com"
  ldap_groupfilter = "(&(objectClass=person)(uid={{.Username}}))"
  ldap_groupattr   = "memberOf"

  ldap_discoverdn           = true
  ldap_username_as_alias    = true
  ldap_case_sensitive_names = false
  ldap_deny_null_bind       = true

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

  accesses = local.accesses

  path        = "pki/org-ca"
  description = "The central CA of the Org"

  ca_cn           = "Org CA"
  ca_organization = "Org"
  ca_expiration   = "2031-05-10T12:00:00Z"

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

  role_directory = "../roles/kubernetes"
  accesses       = local.accesses

  path        = "staging/cluster01"
  description = "Vault testing for K8s Cluster"

  kubernetes_host     = "https://127.0.0.1:6443"
  service_account_jwt = var.kubernetes_token
  kubernetes_ca_cert  = var.kubernetes_ca
}


module "ssh" {
  source = "./modules/secret-engines/ssh"

  accesses = local.accesses

  path        = "staging/vms"
  description = "Access Staging VM through SSH"

  allowed_users = "{{identity.entity.aliases.${local.auth_methods["ldap"]["accessor"]}.name}}"
  default_user  = "{{identity.entity.aliases.${local.auth_methods["ldap"]["accessor"]}.name}}"
}
