# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

variable "name_prefix" {
  description = "Prefix to prepend to resource names created by this module."
  default     = ""
}

variable "roles_conditional" {
  description = "List of conditional role configurations that require approval workflows."
}

variable "policies" {
  description = "Map of Vault policies that will be protected by conditional access gates."
}

variable "vault_addr" {
  description = "The URL used by the Vault/OpenBao plugin to access the API."
  default     = "http://127.0.0.1:8200"
  type        = string
}
