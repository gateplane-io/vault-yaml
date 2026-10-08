# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

variable "accesses" {
  description = "Decoded vault-yaml access document, typically produced with yamldecode(file(...))."
  type        = any
}

variable "mounts" {
  description = "Secrets-engine configurations grouped into arrays by supported type."
  type = object({
    pki        = optional(any, [])
    kubernetes = optional(any, [])
    ssh        = optional(any, [])
    vault      = optional(any, [])
    external   = optional(any, [])
  })
  default = {}

  validation {
    condition = try(alltrue([
      for config in var.mounts.pki :
      config.mount.path != "" && config.mount.accessor != "" && config.issuer_id != null
    ]), false)
    error_message = "Each mounts.pki entry requires mount (with path and accessor) and issuer_id."
  }

  validation {
    condition = try(alltrue([
      for config in var.mounts.kubernetes :
      config.mount.path != "" && config.mount.accessor != "" && trimspace(config.role_directory) != ""
    ]), false)
    error_message = "Each mounts.kubernetes entry requires mount (with path and accessor) and role_directory."
  }

  validation {
    condition = try(alltrue([
      for config in var.mounts.ssh :
      config.mount.path != "" && config.mount.accessor != "" && config.allowed_users != null && config.default_user != null
    ]), false)
    error_message = "Each mounts.ssh entry requires mount (with path and accessor), allowed_users, and default_user."
  }

  validation {
    condition = try(alltrue([
      for config in var.mounts.vault : trimspace(config.alias) != "" && trimspace(config.role_directory) != ""
    ]), false)
    error_message = "Each mounts.vault entry requires alias and role_directory."
  }

  validation {
    condition = length(var.mounts.vault) == length(distinct([
      for config in var.mounts.vault : config.alias
    ]))
    error_message = "Each mounts.vault alias must be unique."
  }

  validation {
    condition = try(alltrue([
      for config in var.mounts.external :
      trimspace(config.alias) != "" && config.mount.path != "" && config.mount.accessor != ""
    ]), false)
    error_message = "Each mounts.external entry requires alias and mount (with path and accessor)."
  }

  validation {
    condition = length(concat(
      [for config in var.mounts.pki : config.mount.path],
      [for config in var.mounts.kubernetes : config.mount.path],
      [for config in var.mounts.ssh : config.mount.path],
      [for config in var.mounts.external : config.alias],
      )) == length(distinct(concat(
        [for config in var.mounts.pki : config.mount.path],
        [for config in var.mounts.kubernetes : config.mount.path],
        [for config in var.mounts.ssh : config.mount.path],
        [for config in var.mounts.external : config.alias],
    )))
    error_message = "Managed mount paths and external aliases must be unique template lookup keys."
  }
}

variable "auth_methods" {
  description = "Authentication-method configurations grouped into arrays by supported type. Every entry requires an explicit principal alias."
  type = object({
    ldap       = optional(any, [])
    identity   = optional(any, [])
    cert       = optional(any, [])
    kubernetes = optional(any, [])
    userpass   = optional(any, [])
  })
  default = {}

  validation {
    condition = try(alltrue([
      for config in var.auth_methods.ldap :
      trimspace(config.alias) != "" && config.mount.path != "" && config.mount.accessor != ""
    ]), false)
    error_message = "Each auth_methods.ldap entry requires alias and mount (with path and accessor)."
  }

  validation {
    condition = try(alltrue([
      for config in var.auth_methods.identity : trimspace(config.alias) != ""
    ]), false)
    error_message = "Each auth_methods.identity entry requires alias."
  }

  validation {
    condition = try(alltrue([
      for config in var.auth_methods.cert :
      trimspace(config.alias) != "" && config.mount.path != "" && config.mount.accessor != "" && config.trusted_certificate != null
    ]), false)
    error_message = "Each auth_methods.cert entry requires alias, mount (with path and accessor), and trusted_certificate."
  }

  validation {
    condition = try(alltrue([
      for config in var.auth_methods.kubernetes :
      trimspace(config.alias) != "" && config.mount.path != "" && config.mount.accessor != ""
    ]), false)
    error_message = "Each auth_methods.kubernetes entry requires alias and mount (with path and accessor)."
  }

  validation {
    condition = try(alltrue([
      for config in var.auth_methods.userpass :
      trimspace(config.alias) != "" && config.mount.path != "" && config.mount.accessor != ""
    ]), false)
    error_message = "Each auth_methods.userpass entry requires alias and mount (with path and accessor)."
  }

  validation {
    condition = alltrue([
      length(var.auth_methods.ldap) == length(distinct([for config in var.auth_methods.ldap : config.mount.path])),
      length(var.auth_methods.cert) == length(distinct([for config in var.auth_methods.cert : config.mount.path])),
      length(var.auth_methods.kubernetes) == length(distinct([for config in var.auth_methods.kubernetes : config.mount.path])),
      length(var.auth_methods.userpass) == length(distinct([for config in var.auth_methods.userpass : config.mount.path])),
    ])
    error_message = "Mount paths must be unique within each auth method type."
  }

  validation {
    condition = length(concat(
      [for config in var.auth_methods.ldap : config.alias],
      [for config in var.auth_methods.identity : config.alias],
      [for config in var.auth_methods.cert : config.alias],
      [for config in var.auth_methods.kubernetes : config.alias],
      [for config in var.auth_methods.userpass : config.alias],
      )) == length(distinct(concat(
        [for config in var.auth_methods.ldap : config.alias],
        [for config in var.auth_methods.identity : config.alias],
        [for config in var.auth_methods.cert : config.alias],
        [for config in var.auth_methods.kubernetes : config.alias],
        [for config in var.auth_methods.userpass : config.alias],
    )))
    error_message = "Auth method aliases must be unique."
  }
}
