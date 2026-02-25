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
  description = "Map of access configurations for creating ad-hoc policies, defining what paths and capabilities each access level requires."
}

variable "name_prefix" {
  description = "Prefix to prepend to resource names created by this module."
  default     = ""
}

variable "role_directory" {
  description = "The directory path where role definitions are stored and will be parsed."
  type        = string
}

variable "secret_engines" {
  description = "Map of secret engine configurations used for policy generation, keyed by engine type."
  type        = map(map(string))
}

variable "auth_methods" {
  description = "Map of authentication method configurations used for policy generation, keyed by auth method type."
  type        = map(map(string))
}

variable "enable_conditional_roles" {
  description = "Enable or disable conditional access roles that require approval workflows."
  default     = true
}
