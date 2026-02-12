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
  description = "The full list of policies created by the Secrets Engine blocks"
  # type        = list(map(any))
}

variable "principal_key" {
  description = "The key to by used in Principals (e.g: `<key>.users.jdoe`)"
  default     = "identity"
}

variable "exclusive" {
  description = "If true, policies are added exclusively to the entity or group (removing any other policies). If false, policies are appended."
  default     = false
}
