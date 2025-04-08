# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

variable "description" {}

variable "path" {}

variable "ca_cn" {
  type = string
}

variable "ca_organization" {
  type = string
}

variable "ca_expiration" {
  type = string
}

variable "templated_common_names" {
  type = map(string)
}

# ==========

variable "accesses" {}

variable "name_prefix" {
  default = ""
}
