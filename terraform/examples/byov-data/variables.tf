# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# Copyright (C) 2026 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

variable "kubernetes_mount_path" {
  description = "Path of the existing Kubernetes secrets engine."
  type        = string
  default     = "staging/cluster01"
}

variable "userpass_auth_path" {
  description = "Path of the existing userpass auth method."
  type        = string
  default     = "userpass"
}

variable "cert_auth_path" {
  description = "Path of the existing certificate auth method."
  type        = string
  default     = "cert"
}

variable "cert_auth_accessor" {
  description = "Accessor of the existing certificate auth method, available from `vault auth list -format=json`."
  type        = string
}

variable "cert_trusted_certificate_file" {
  description = "Path to the PEM certificate used to validate clients of the existing certificate auth method."
  type        = string
}
