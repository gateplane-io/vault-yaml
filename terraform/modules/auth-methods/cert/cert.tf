# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0
#
# Licensed under the Elastic License 2.0.
# You may obtain a copy of the license at:
# https://www.elastic.co/licensing/elastic-license
#
# Use, modification, and redistribution permitted under the terms of the license,
# except for providing this software as a commercial service or product.

resource "vault_cert_auth_backend_role" "cert" {
  for_each = local.authorizations["common_names"]

  name          = replace(each.key, "@", "-")
  certificate   = var.trusted_certificate
  backend       = var.mount.path
  allowed_names = [each.key]

  # More opinionated checks can be exposed here
  # like CRL, allowed SANS,etc

  token_policies = [for p in each.value["policies"] : lower(p)]

  # This allows usage of the created token ONLY by the IPs
  # that the CN resolves to (IPv4 and IPv6)
  token_bound_cidrs = (
    try(each.value["ip_bind"], false) ?
    flatten([
      [for ipv4 in data.dns_a_record_set.ipv4[each.key].addrs : "${ipv4}/32"],
      [for ipv6 in data.dns_aaaa_record_set.ipv6[each.key].addrs : "${ipv6}/128"],
    ])
    : null #["0.0.0.0/0", "::/0"]
  )

}

data "dns_a_record_set" "ipv4" {
  for_each = {
    for cn, values in local.authorizations["common_names"] :
    cn => values if try(values["ip_bind"], false)
  }

  host = each.key
}

data "dns_aaaa_record_set" "ipv6" {
  for_each = {
    for cn, values in local.authorizations["common_names"] :
    cn => values if try(values["ip_bind"], false)
  }

  host = each.key
}
