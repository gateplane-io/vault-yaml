{{- define "vault-yaml-ssh.policy" -}}
{{- $root := .root -}}
{{- $path := .path -}}
{{- $roleName := .roleName -}}
{{- $policyName := include "vault-yaml.policyName" (dict "type" "ssh" "role" $roleName "path" $path) }}
---
{{ include "vault-yaml.policyResource" (dict "root" $root "name" $policyName "path" $path "role" $roleName "policy" (printf "path \"%s/sign/%s\" {\n  capabilities = [\"update\"]\n}\npath \"%s/roles/*\" {\n  capabilities = [\"list\", \"read\"]\n}" $path $roleName $path)) }}
{{- end -}}
