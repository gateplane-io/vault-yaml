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

# The Vault provider has a dedicated data source for auth methods.
data "vault_auth_backend" "userpass" {
  path = var.userpass_auth_path
}

# There is no dedicated single-mount data source for secrets engines. The
# generic data source can read the mount metadata from Vault's sys API.
data "vault_generic_secret" "kubernetes_mount" {
  path = "sys/mounts/${var.kubernetes_mount_path}"
}

locals {
  accesses = yamldecode(file("${path.module}/access.yaml"))

  kubernetes_mount = {
    path     = var.kubernetes_mount_path
    accessor = nonsensitive(data.vault_generic_secret.kubernetes_mount.data["accessor"])
  }

  # A complete provider resource or data source is not required. Any object
  # containing the path and accessor expected by vault-yaml can be supplied.
  cert_auth_mount = {
    path     = var.cert_auth_path
    accessor = var.cert_auth_accessor
  }
}

module "vault_yaml" {
  source = "../.."

  accesses = local.accesses

  mounts = {
    kubernetes = [{
      mount                    = local.kubernetes_mount
      role_directory           = "${path.module}/roles/kubernetes"
      enable_conditional_roles = false
    }]
  }

  auth_methods = {
    userpass = [{
      alias = "userpass"
      mount = data.vault_auth_backend.userpass
    }]

    cert = [{
      alias               = "cert"
      mount               = local.cert_auth_mount
      trusted_certificate = file(var.cert_trusted_certificate_file)
    }]
  }
}
