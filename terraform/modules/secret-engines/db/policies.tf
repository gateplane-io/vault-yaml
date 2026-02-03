
data "vault_policy_document" "pgsql" {
  for_each = local.pgsql_policies

  rule {
    description = "PostgreSQL access to role '${each.value["role_name"]}' in '${each.value["resource_name"]}'"

    path         = "${each.value["path"]}/creds/${each.value["role_name"]}"
    capabilities = ["read"]
  }

  rule {
    description = "PostgreSQL list all role names"

    path         = "${each.value["path"]}/roles/*"
    capabilities = ["list", "read"]
  }

}

resource "vault_policy" "pgsql" {
  for_each = data.vault_policy_document.pgsql

  name   = each.key
  policy = each.value.hcl
}
