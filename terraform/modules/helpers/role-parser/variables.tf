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
  description = "Decoded YAML structure containing engine paths and heterogeneous engine-specific role bodies."
  type        = any
}

variable "field_defaults" {
  description = "Engine-specific field defaults. This remains dynamic because values can mix strings, numbers, booleans, and collections."
  type        = any
  default     = {}
}

variable "name_prefix" {
  description = "Prefix to add to generated keys"
  type        = string
  default     = ""
}

variable "path" {
  description = "Path of the Access Block to parse (e.g: kubernetes, pki, ssh)"
  type        = string
}
