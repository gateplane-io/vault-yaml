{{- define "vault-yaml-pki.policy" -}}
{{- $root := .root -}}
{{- $path := .path -}}
{{- $roleName := .roleName -}}
{{- $policyName := include "vault-yaml.policyName" (dict "type" "pki" "role" $roleName "path" $path) }}
---
{{ include "vault-yaml.policyResource" (dict "root" $root "name" $policyName "path" $path "role" $roleName "policy" (printf "path \"%s/issue/%s\" {\n  capabilities = [\"read\", \"update\"]\n}\npath \"%s/sign/%s\" {\n  capabilities = [\"read\", \"update\"]\n}\npath \"%s/roles\" {\n  capabilities = [\"read\", \"list\"]\n}\npath \"%s/roles/%s\" {\n  capabilities = [\"read\", \"list\"]\n}\npath \"%s\" {\n  capabilities = [\"read\", \"list\"]\n}" $path $roleName $path $roleName $path $path $roleName $path)) }}
{{- end -}}
