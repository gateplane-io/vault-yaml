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
  description = "The configuration object for the certificate auth method, containing its mount path and accessor."
  type = object({
    path     = string
    accessor = string
  })
}

variable "policies_list" {
  description = "The policies created by the secrets-engine modules, reduced to the fields required for principal authorization."
  type = list(object({
    key    = string
    access = string
  }))
}

variable "principal_key" {
  description = "The key to be used in principals (e.g. `<key>.app.example.com`)."
  type        = string
  default     = "cert"
}

variable "exclusive" {
  description = "If true, policies are added exclusively to the entity or group (removing any other policies). If false, policies are appended."
  type        = bool
  default     = false
}

variable "trusted_certificate" {
  description = "The Certificate that can verify incoming certificates"
  type        = string
}
