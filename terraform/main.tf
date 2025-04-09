# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

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

  authorizations = local.authorization["ldap"]
}

module "ca" {
  source = "./modules/secret-engines/pki"

  path        = "pki/org-ca"
  description = "The central CA of the Org"

  ca_cn           = "Org CA"
  ca_organization = "Org"
  ca_expiration   = "2031-05-10T12:00:00Z"

  templated_common_names = {
    email = "{{identity.entity.aliases.${local.auth_methods["ldap"]["accessor"]}.name}}@my-org.example.com"
  }

  accesses = local.accesses
}

module "adhoc" {
  source = "./modules/adhoc-policies"

  role_directory = "../roles/vault"

  # Maps used for templating policy documents
  auth_methods   = local.auth_methods
  secret_engines = local.secret_engines

  accesses = local.accesses
}


module "kubernetes" {
  source = "./modules/secret-engines/kubernetes"

  role_directory = "../roles/kubernetes"

  path            = "staging/kubernetes"
  description     = "Vault testing for K8s Cluster"
  kubernetes_host = "https://127.0.0.1:6443"

  service_account_jwt = var.kubernetes_token
  kubernetes_ca_cert  = var.kubernetes_ca

  accesses = local.accesses
}
