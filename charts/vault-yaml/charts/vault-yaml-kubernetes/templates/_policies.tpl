{{- define "vault-yaml-kubernetes.policy" -}}
{{- $root := .root -}}
{{- $path := .path -}}
{{- $roleName := .roleName -}}
{{- $role := .role -}}
{{- $policyName := include "vault-yaml.policyName" (dict "type" "kubernetes" "role" $roleName "path" $path) }}
{{- $namespaces := default (list) $role.namespaces }}
---
{{ include "vault-yaml.policyResource" (dict "root" $root "name" $policyName "path" $path "role" $roleName "policy" (printf "path \"%s/creds/%s\" {\n  capabilities = [\"read\", \"update\"]\n  allowed_parameters = {\n    \"kubernetes_namespace\" = %s\n  }\n}" $path $roleName (toJson $namespaces))) }}
{{- end -}}
