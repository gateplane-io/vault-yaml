# Personal secrets
path "${secret_engines["kv"]["path"]}/data/vaults/personal/{{identity.entity.aliases.${auth_methods["ldap"]["accessor"]}.metadata.name}}/*" {
  capabilities = ["create", "update", "patch", "read", "delete"]
}

path "${secret_engines["kv"]["path"]}/metadata/vaults/personal/{{identity.entity.aliases.${auth_methods["ldap"]["accessor"]}.metadata.name}}/*" {
  capabilities = ["list"]
}
