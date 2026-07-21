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
  description = "The configuration object for the Kubernetes auth method, containing the mount path and accessor ([`vault_kubernetes_auth_backend_config`](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_config))."
}

variable "policies_list" {
  description = "The full list of policies created by the Secrets Engine blocks"
  # type        = list(map(any))
}

variable "principal_key" {
  description = "The key used as the Principal prefix (e.g. `<key>.default.external-secrets`)."
  default     = "kubernetes"
}
