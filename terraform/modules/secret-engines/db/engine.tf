

locals {
  db_url = "host=${split(":", var.db_addr)[0]} port=${split(":", var.db_addr)[1]} user={{username}} database=${var.db_default_database} password={{password}}"
}

resource "vault_database_secrets_mount" "this" {
  path        = var.path
  description = var.description

  postgresql {
    name = "db"

    connection_url = local.db_url

    username          = var.db_user
    password          = var.db_password
    verify_connection = true
    # disable_escaping = true

    # Role Access Control happens through policies
    allowed_roles = ["*"]

    username_template = "{{.DisplayName | replace \"_\" \"-\" }}-{{.RoleName | replace \"_\" \"-\"}}-{{unix_time}}s"
  }
}

resource "vault_database_secret_backend_role" "role" {
  for_each = {
    for k, v in local.pgsql_policies :
    v["role_name"] => v if v["path"] == vault_database_secrets_mount.this.path
  }

  backend = vault_database_secrets_mount.this.path
  name    = each.value["role_name"]
  db_name = vault_database_secrets_mount.this.postgresql[0].name
  creation_statements = flatten([
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    // Maybe a 'REVOKE CONNECT ON DATABASE * ...' must be set here
    [for db in each.value["databases"] : "GRANT CONNECT ON DATABASE ${db} TO \"{{name}}\";"],
    var.role_definitions[each.value["role_name"]],
  ])

  default_ttl = each.value["ttl"]
  max_ttl     = each.value["ttl_max"]
}


