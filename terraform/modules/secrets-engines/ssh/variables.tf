# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

variable "mount" {
  description = "The mount configuration object for the SSH secrets engine [`vault_mount`](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount)."
  type = object({
    path     = string
    accessor = string
  })
}

# ===



variable "accesses" {
  description = "Map of access configurations for SSH secrets engine, defining heterogeneous role bodies and their properties."
  type        = any
}

variable "name_prefix" {
  description = "Prefix to prepend to resource names created by this module."
  type        = string
  default     = ""
}

variable "allowed_users" {
  description = "Template or pattern for allowed users in SSH certificates (e.g., '{{identity.entity.name}}')."
  type        = string
}

variable "default_user" {
  description = "The default user for SSH certificates when not specified."
  type        = string
}

variable "enable_conditional_roles" {
  description = "Enable or disable conditional access roles that require approval workflows."
  type        = bool
  default     = true
}
