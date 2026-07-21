# Group Secrets
# Rendered for each access entry
path "${secret_engines["kv"]["path"]}/data/vaults/teams/${access_name}/*" {
  capabilities = ["create", "update", "patch", "read", "delete"]
}

path "${secret_engines["kv"]["path"]}/metadata/vaults/teams/${access_name}/*" {
  capabilities = ["list"]
}
