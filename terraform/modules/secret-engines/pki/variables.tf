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
  description = "The mount configuration object for the PKI secrets engine ([`vault_mount`](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount))."
}

variable "issuer_id" {
  description = "The ID of the issuer to use for generating certificates."
}

variable "templated_common_names" {
  description = "Map of templates strings resolve CNs for certificate generation (e.g. `{email = '{{identity.entity.name}}@example.com'}`)."
  type        = map(string)
}

# ==========

variable "accesses" {
  description = "Map of access configurations for PKI secrets engine, defining roles and their certificate properties."
}

variable "name_prefix" {
  description = "Prefix to prepend to resource names created by this module."
  default     = ""
}

variable "enable_conditional_roles" {
  description = "Enable or disable conditional access roles that require approval workflows."
  default     = true
}
