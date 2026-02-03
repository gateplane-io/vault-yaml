
variable "description" {}

variable "path" {}

# ===

variable "db_addr" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}


variable "db_default_database" {
  default = "postgres"
}

variable "name_template" {
  default = "{{.DisplayName | replace \"_\" \"-\"  | replace \" \" \"\"}}-{{.RoleName | replace \"_\" \"-\"}}-{{unix_time}}s"
}

# ======

variable "role_definitions" {
  default = {}
}

variable "accesses" {

}

# variable "repository_url" {}

variable "name_prefix" {
  default = ""
}
