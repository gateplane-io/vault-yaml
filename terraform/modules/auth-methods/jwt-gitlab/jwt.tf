
resource "vault_jwt_auth_backend" "gitlab" {
  description = var.description
  path        = var.path

  # discovery url documented here:
  # https://docs.gitlab.com/integration/openid_connect_provider/#settings-discovery
  jwks_url = "${var.gitlab_url}/oauth/discovery/keys"

  # 'iss' claim documented here:
  # https://docs.gitlab.com/ci/secrets/id_token_authentication/#token-payload
  bound_issuer = var.gitlab_url

  default_role = var.role_name

  tune {
    default_lease_ttl = "5m"
    max_lease_ttl     = "5m"
  }

}

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
