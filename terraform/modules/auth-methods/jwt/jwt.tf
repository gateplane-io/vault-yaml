
resource "vault_jwt_auth_backend" "this" {
  description = var.description
  path        = var.path
  # type        = "oidc"

  oidc_client_id     = "client-id"
  oidc_client_secret = "client-secret"

  oidc_discovery_url = "http://desktop.lan:8181"
  bound_issuer       = "http://desktop.lan:8181"

  default_role = var.default_role

  tune {
    listing_visibility = "unauth"
  }


}

resource "vault_jwt_auth_backend_role" "this" {
  backend   = vault_jwt_auth_backend.this.path
  role_name = var.default_role
  # token_policies          = var.token_policies
  token_no_default_policy = true

  # bound_audiences = var.bound_audiences
  allowed_redirect_uris = [
    "http://127.0.0.1:8200/ui/vault/auth/oidc/oidc/callback"
  ]

  # claims documented here:
  user_claim = "sub"
  # role_type  = "oidc"


  bound_claims = {
    # Only accept from a pipeline running on a not protected ref
    # ref_protected = var.protected
  }
}

/*

resource "vault_jwt_auth_backend_role" "this" {
  backend                 = vault_jwt_auth_backend.gitlab.path
  role_name               = var.role_name
  token_policies          = var.token_policies
  token_no_default_policy = true

  bound_audiences = var.bound_audiences

  # claims documented here:
  # https://docs.gitlab.com/ci/secrets/id_token_authentication/#token-payload
  user_claim = "project_path"
  role_type  = "jwt"

  bound_claims = {
    # Only accept from a pipeline running on a not protected ref
    ref_protected = var.protected
  }
}

data "vault_identity_entity" "this" {
  for_each = var.authorizations

  alias_name           = each.key
  alias_mount_accessor = vault_jwt_auth_backend.gitlab.accessor
}

resource "vault_identity_entity_policies" "this" {
  for_each = data.vault_identity_entity.this

  entity_id = each.value["entity_id"]
  policies  = var.authorizations[each.key]["policies"]

  exclusive = true
}
*/
