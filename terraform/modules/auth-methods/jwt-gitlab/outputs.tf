output "accessor" {
  value = vault_jwt_auth_backend.gitlab.accessor
}

output "path" {
  value = vault_jwt_auth_backend.gitlab.path
}

output "entry" {
  value = {
    "accessor" : vault_jwt_auth_backend.gitlab.accessor,
    "path" : vault_jwt_auth_backend.gitlab.path,
  }
}
