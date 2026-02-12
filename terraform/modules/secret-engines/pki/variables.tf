# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

variable "mount" {}

variable "issuer_id" {}

variable "templated_common_names" {
  type = map(string)
}

# ==========

variable "accesses" {}

variable "name_prefix" {
  default = ""
}

variable "enable_conditional_roles" {
  default = true
}
