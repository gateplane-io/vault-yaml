# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_mount" "this" {
  type = "ssh"
  path = var.path
}

resource "vault_ssh_secret_backend_ca" "this" {
  backend              = vault_mount.this.path
  generate_signing_key = true

  lifecycle {
    ignore_changes = [generate_signing_key]
  }
}

resource "vault_ssh_secret_backend_role" "this" {
  for_each = {
    for k, v in local.ssh_policies :
    v["role_name"] => v if v["path"] == var.path
  }

  name                    = each.key
  backend                 = vault_ssh_secret_backend_ca.this.backend
  key_type                = "ca"
  allow_user_certificates = true

  # Only be able to sign a certificate with your username as principal!
  allowed_users          = var.allowed_users
  allowed_users_template = true

  default_user          = var.default_user
  default_user_template = true

  allowed_extensions = join(",", each.value["extensions"])
  # join(",",[
  #     "permit-pty",
  #     "permit-port-forwarding",
  #     "permit-agent-forwarding",
  #     "permit-user-rc",
  #     "permit-X11-forwarding"
  #   ])
  default_extensions = { for e in each.value["extensions"] : e => "" }

  ttl     = each.value["ttl"]
  max_ttl = each.value["ttl_max"]
}
