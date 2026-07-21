# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

variable "policies_list" {
  description = "Collection of policy mappings containing `key` and `access` attributes."
  type        = any
}

variable "principal_key" {
  description = "Principal prefix to select and remove, such as `ldap` or `kubernetes`."
  type        = string
}
