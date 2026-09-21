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
group_open=false

begin_group() {
  title=$1

  if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    printf '::group::%s\n' "$title"
  else
    printf '\n------------------------------------------------------------------------\n'
    printf '%s\n' "$title"
    printf '%s\n' '------------------------------------------------------------------------'
  fi

  group_open=true
}

end_group() {
  if [ "$group_open" = false ]; then
    return
  fi

  if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    printf '::endgroup::\n'
  fi

  group_open=false
}

cleanup() {
  if [ -n "$current_module_path" ]; then
    rm -rf "$current_module_path/.terraform"
    rm -f "$current_module_path/.terraform.lock.hcl"
  fi

  end_group
}

trap cleanup EXIT INT TERM

set -- $modules
module_count=$#
module_index=0

begin_group "Terraform formatting"
"$terraform_bin" -chdir="$repo_root" fmt -check -recursive terraform
printf '\nResult: PASS\n'
end_group

for module in $modules; do
  module_index=$((module_index + 1))
  current_module_path="$repo_root/$module"

  begin_group "[$module_index/$module_count] $module"

  printf '\n-- Initialize -----------------------------------------------------------\n\n'
  "$terraform_bin" -chdir="$current_module_path" init -backend=false -input=false

  printf '\n-- Test -----------------------------------------------------------------\n\n'
  "$terraform_bin" -chdir="$current_module_path" test

  printf '\nResult: PASS\n'
  cleanup
  current_module_path=""
done

printf '\n========================================================================\n'
printf 'All %s Terraform modules passed.\n' "$module_count"
printf '%s\n' '========================================================================'
