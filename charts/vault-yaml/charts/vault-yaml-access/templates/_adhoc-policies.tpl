{{- define "vault-yaml-access.adhocPolicies" -}}
{{- $root := .root -}}
{{- $accesses := .accesses -}}
{{- $state := .state -}}
{{- $adhoc := default dict (index $accesses "adhoc") -}}
{{- if eq (default "" $adhoc.type) "vault" }}
{{- range $roleName, $role := default dict $adhoc.roles }}
{{- $access := default dict $role.access -}}
{{- if not (default false $role.for_each) }}
{{- $policyName := printf "vault-%s-adhoc" $roleName -}}
---
{{ include "vault-yaml.policyResource" (dict "root" $root "name" $policyName "path" "adhoc" "role" $roleName "policy" (include "vault-yaml.adhocPolicy" (dict "root" $root "role" $roleName "accessName" ""))) }}{{ println }}
{{- end }}
{{- range $principal := default (list) $access.static }}
{{- $accessName := "" -}}
{{- $policyName := printf "vault-%s-adhoc" $roleName -}}
{{- if default false $role.for_each }}
{{- $accessName = include "vault-yaml.principalAccessName" (dict "principal" $principal) -}}
{{- $policyName = printf "%s-%s" $policyName $accessName -}}
---
{{ include "vault-yaml.policyResource" (dict "root" $root "name" $policyName "path" "adhoc" "role" $roleName "policy" (include "vault-yaml.adhocPolicy" (dict "root" $root "role" $roleName "accessName" $accessName))) }}{{ println }}
{{- end }}
{{- $existing := default (list) (index $state.bindings $principal) -}}
{{- $_ := set $state.bindings $principal (uniq (append $existing (lower $policyName))) -}}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
