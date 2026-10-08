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
  # Normalize public arrays into stable maps before using for_each. Real Vault
  # backends use their paths; mountless configurations use explicit aliases.
  pki_mounts        = { for config in var.mounts.pki : config.mount.path => config }
  kubernetes_mounts = { for config in var.mounts.kubernetes : config.mount.path => config }
  ssh_mounts        = { for config in var.mounts.ssh : config.mount.path => config }
  vault_mounts      = { for config in var.mounts.vault : config.alias => config }

  ldap_auth_methods       = { for config in var.auth_methods.ldap : config.mount.path => config }
  identity_auth_methods   = { for config in var.auth_methods.identity : config.alias => config }
  cert_auth_methods       = { for config in var.auth_methods.cert : config.mount.path => config }
  kubernetes_auth_methods = { for config in var.auth_methods.kubernetes : config.mount.path => config }
  userpass_auth_methods   = { for config in var.auth_methods.userpass : config.mount.path => config }

  secret_engines = merge(
    { for path, config in local.pki_mounts : path => {
      path     = config.mount.path
      accessor = config.mount.accessor
    } },
    { for path, config in local.kubernetes_mounts : path => {
      path     = config.mount.path
      accessor = config.mount.accessor
    } },
    { for path, config in local.ssh_mounts : path => {
      path     = config.mount.path
      accessor = config.mount.accessor
    } },
    { for config in var.mounts.external : config.alias => {
      path     = config.mount.path
      accessor = config.mount.accessor
    } },
  )

  auth_methods = merge(
    { for config in var.auth_methods.ldap : config.alias => {
      path     = config.mount.path
      accessor = config.mount.accessor
    } },
    { for config in var.auth_methods.cert : config.alias => {
      path     = config.mount.path
      accessor = config.mount.accessor
    } },
    { for config in var.auth_methods.kubernetes : config.alias => {
      path     = config.mount.path
      accessor = config.mount.accessor
    } },
    { for config in var.auth_methods.userpass : config.alias => {
      path     = config.mount.path
      accessor = config.mount.accessor
    } },
  )
}

module "pki" {
  source   = "./modules/secrets-engines/pki"
  for_each = local.pki_mounts

  mount                    = each.value.mount
  accesses                 = var.accesses
  issuer_id                = each.value.issuer_id
  templated_common_names   = try(each.value.templated_common_names, {})
  name_prefix              = try(each.value.name_prefix, "")
  enable_conditional_roles = try(each.value.enable_conditional_roles, true)
}

module "kubernetes_secrets" {
  source   = "./modules/secrets-engines/kubernetes"
  for_each = local.kubernetes_mounts

  mount                    = each.value.mount
  accesses                 = var.accesses
  role_directory           = each.value.role_directory
  name_prefix              = try(each.value.name_prefix, "")
  enable_conditional_roles = try(each.value.enable_conditional_roles, true)
  name_template = try(
    each.value.name_template,
    "{{.DisplayName | replace \"_\" \"-\"  | replace \" \" \"\"}}-{{.RoleName | replace \"_\" \"-\"}}-{{unix_time}}s"
  )
  kubernetes_labels = try(each.value.kubernetes_labels, { managed_by = "vault" })
}

module "ssh" {
  source   = "./modules/secrets-engines/ssh"
  for_each = local.ssh_mounts

  mount                    = each.value.mount
  accesses                 = var.accesses
  allowed_users            = each.value.allowed_users
  default_user             = each.value.default_user
  name_prefix              = try(each.value.name_prefix, "")
  enable_conditional_roles = try(each.value.enable_conditional_roles, true)
}

module "vault" {
  source   = "./modules/secrets-engines/vault"
  for_each = local.vault_mounts

  accesses                 = var.accesses
  role_directory           = each.value.role_directory
  auth_methods             = local.auth_methods
  secret_engines           = local.secret_engines
  name_prefix              = try(each.value.name_prefix, "")
  enable_conditional_roles = try(each.value.enable_conditional_roles, true)
}

locals {
  policies_list = flatten(concat(
    [for instance in values(module.pki) : instance.access_list],
    [for instance in values(module.kubernetes_secrets) : instance.access_list],
    [for instance in values(module.ssh) : instance.access_list],
    [for instance in values(module.vault) : instance.access_list],
  ))
}

module "ldap" {
  source   = "./modules/auth-methods/ldap"
  for_each = local.ldap_auth_methods

  mount         = each.value.mount
  policies_list = local.policies_list
  principal_key = each.value.alias
}

module "identity" {
  source   = "./modules/auth-methods/identity"
  for_each = local.identity_auth_methods

  policies_list = local.policies_list
  principal_key = each.value.alias
  exclusive     = try(each.value.exclusive, false)
}

module "cert" {
  source   = "./modules/auth-methods/cert"
  for_each = local.cert_auth_methods

  mount               = each.value.mount
  policies_list       = local.policies_list
  principal_key       = each.value.alias
  trusted_certificate = each.value.trusted_certificate
  exclusive           = try(each.value.exclusive, false)
}

module "kubernetes_auth" {
  source   = "./modules/auth-methods/kubernetes"
  for_each = local.kubernetes_auth_methods

  mount         = each.value.mount
  policies_list = local.policies_list
  principal_key = each.value.alias
}

module "userpass" {
  source   = "./modules/auth-methods/userpass"
  for_each = local.userpass_auth_methods

  mount         = each.value.mount
  policies_list = local.policies_list
  principal_key = each.value.alias
  exclusive     = try(each.value.exclusive, false)
}

locals {
  authorizations = merge(concat(
    [for instance in values(module.ldap) : instance.authorizations],
    [for instance in values(module.identity) : instance.authorizations],
    [for instance in values(module.cert) : instance.authorizations],
    [for instance in values(module.kubernetes_auth) : instance.authorizations],
    [for instance in values(module.userpass) : instance.authorizations],
  )...)
}
