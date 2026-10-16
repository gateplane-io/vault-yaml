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
  description = "Decoded vault-yaml access document, typically produced with yamldecode(file(...)). This remains dynamic because role bodies differ by secrets-engine type and Terraform has no union types."
  type        = any

  validation {
    condition = try(alltrue([
      for path, config in var.accesses : try(
        trimspace(path) != "" &&
        contains(["pki", "kubernetes", "ssh", "vault"], config.type) &&
        can(keys(config.roles)) &&
        length(setsubtract(toset(keys(config)), toset(["type", "roles"]))) == 0 &&
        (config.type == "vault" ? path == "adhoc" : path != "adhoc"),
        false,
      )
    ]), false)
    error_message = "accesses must be a map of non-empty paths containing only type and roles; type must be pki, kubernetes, ssh, or vault, and only the vault type may use the reserved adhoc path."
  }

  validation {
    condition = try(alltrue(flatten([
      for config in var.accesses : [
        for role_name, role in config.roles : try(
          trimspace(role_name) != "" &&
          can(keys(role.access)) &&
          length(setsubtract(toset(keys(role.access)), toset(["static", "conditional"]))) == 0,
          false,
        )
      ]
    ])), false)
    error_message = "Every role must have a non-empty name and an access object containing only static and conditional fields."
  }

  validation {
    condition = try(alltrue(flatten([
      for config in var.accesses : [
        for role in config.roles : try(alltrue([
          for principal in try(role.access.static, []) : trimspace(principal) != ""
        ]), false)
      ]
    ])), false)
    error_message = "Every access.static value must be a list of non-empty principal strings."
  }

  validation {
    condition = try(alltrue(flatten([
      for config in var.accesses : [
        for role in config.roles : try(
          length(keys(try(role.access.conditional, {}))) == 0 || (
            length(setsubtract(
              toset(keys(role.access.conditional)),
              toset(["requestors", "approvers", "required_approvals", "require_justification", "description"]),
            )) == 0 &&
            alltrue([for principal in role.access.conditional.requestors : trimspace(principal) != ""]) &&
            alltrue([for principal in role.access.conditional.approvers : trimspace(principal) != ""]) &&
            try(role.access.conditional.required_approvals, 1) >= 1 &&
            floor(try(role.access.conditional.required_approvals, 1)) == try(role.access.conditional.required_approvals, 1) &&
            try(role.access.conditional.required_approvals, 1) <= length(distinct(role.access.conditional.approvers)) &&
            contains([true, false], try(role.access.conditional.require_justification, false)) &&
            can(regex("(?s).*", try(role.access.conditional.description, "")))
          ),
          false,
        )
      ]
    ])), false)
    error_message = "Every non-empty access.conditional value must contain requestors and approvers lists of non-empty principal strings; optional required_approvals must be a positive integer no greater than the number of distinct approvers, require_justification must be boolean, and description must be a string."
  }
}

variable "name_prefix" {
  description = "Prefix applied to all generated policy names. Per-mount name_prefix values, when set, are appended to this prefix."
  type        = string
  default     = ""

  validation {
    condition     = var.name_prefix == trimspace(var.name_prefix)
    error_message = "name_prefix must not contain leading or trailing whitespace."
  }
}

variable "mounts" {
  description = "Secrets-engine configurations grouped into arrays by supported type. mounts.vault accepts at most one entry and always configures the adhoc access path."
  type = object({
    pki = optional(list(object({
      mount = object({
        path     = string
        accessor = string
      })
      issuer_id                = string
      templated_common_names   = optional(map(string), {})
      name_prefix              = optional(string, "")
      enable_conditional_roles = optional(bool, true)
    })), [])
    kubernetes = optional(list(object({
      mount = object({
        path     = string
        accessor = string
      })
      role_directory           = string
      name_prefix              = optional(string, "")
      enable_conditional_roles = optional(bool, true)
      name_template            = optional(string, "{{.DisplayName | replace \"_\" \"-\"  | replace \" \" \"\"}}-{{.RoleName | replace \"_\" \"-\"}}-{{unix_time}}s")
      kubernetes_labels        = optional(map(string), { managed_by = "vault" })
    })), [])
    ssh = optional(list(object({
      mount = object({
        path     = string
        accessor = string
      })
      allowed_users            = string
      default_user             = string
      name_prefix              = optional(string, "")
      enable_conditional_roles = optional(bool, true)
    })), [])
    vault = optional(list(object({
      role_directory           = string
      name_prefix              = optional(string, "")
      enable_conditional_roles = optional(bool, true)
    })), [])
    external = optional(list(object({
      alias = string
      mount = object({
        path     = string
        accessor = string
      })
    })), [])
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
      for config in var.mounts.vault : trimspace(config.role_directory) != ""
    ]), false)
    error_message = "The mounts.vault entry requires role_directory."
  }

  validation {
    condition     = length(var.mounts.vault) <= 1
    error_message = "mounts.vault accepts at most one entry because it always configures the adhoc access path."
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
    ldap = optional(list(object({
      alias = string
      mount = object({
        path     = string
        accessor = string
      })
    })), [])
    identity = optional(list(object({
      alias     = string
      exclusive = optional(bool, false)
    })), [])
    cert = optional(list(object({
      alias = string
      mount = object({
        path     = string
        accessor = string
      })
      trusted_certificate = string
      exclusive           = optional(bool, false)
    })), [])
    kubernetes = optional(list(object({
      alias = string
      mount = object({
        path     = string
        accessor = string
      })
    })), [])
    userpass = optional(list(object({
      alias = string
      mount = object({
        path     = string
        accessor = string
      })
      exclusive = optional(bool, false)
    })), [])
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
