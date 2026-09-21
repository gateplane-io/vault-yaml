#!/bin/sh
# Copyright (C) 2025 Ioannis Torakis <john.torakis@gmail.com>
# SPDX-License-Identifier: Elastic-2.0

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
terraform_bin=${TERRAFORM_BIN:-terraform}

modules="
terraform/modules/auth-methods/cert
terraform/modules/auth-methods/identity
terraform/modules/auth-methods/kubernetes
terraform/modules/auth-methods/ldap
terraform/modules/auth-methods/userpass
terraform/modules/helpers/conditional-access
terraform/modules/helpers/principal-parser
terraform/modules/helpers/role-parser
terraform/modules/secrets-engines/kubernetes
terraform/modules/secrets-engines/pki
terraform/modules/secrets-engines/ssh
terraform/modules/secrets-engines/vault
"

current_module_path=""

cleanup() {
  if [ -n "$current_module_path" ]; then
    rm -rf "$current_module_path/.terraform"
    rm -f "$current_module_path/.terraform.lock.hcl"
  fi
}

trap cleanup EXIT INT TERM

"$terraform_bin" -chdir="$repo_root" fmt -check -recursive terraform

for module in $modules; do
  current_module_path="$repo_root/$module"
  printf '\n==> Testing %s\n' "$module"
  "$terraform_bin" -chdir="$current_module_path" init -backend=false -input=false
  "$terraform_bin" -chdir="$current_module_path" test
  cleanup
  current_module_path=""
done
