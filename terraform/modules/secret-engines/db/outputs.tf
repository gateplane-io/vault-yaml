output "policies" {
  value = vault_policy.pgsql
}

output "access_list" {
  value = flatten([local.pgsql_policies_list, module.gateplane.policies_list])
}

output "entry" {
  value = {
    "path"     = vault_database_secrets_mount.this.path,
    "accessor" = vault_database_secrets_mount.this.accessor,
  }
}
