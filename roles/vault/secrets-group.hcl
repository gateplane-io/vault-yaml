# Group Secrets
# Rendered for each access entry
path "${secret_engines["kv"]["path"]}/data/vaults/teams/${split(".", access)[2]}/*" {
  capabilities = ["create", "update", "patch", "read", "delete"]
}

path "${secret_engines["kv"]["path"]}/metadata/vaults/teams/${split(".", access)[2]}/*" {
  capabilities = ["list"]
}
