{{- define "vault-yaml-access.inventory" -}}
{{- $accesses := .accesses -}}
{{- $state := .state -}}
{{- range $path, $engine := $accesses }}
{{- if and (kindIs "map" $engine) (has $engine.type (list "pki" "kubernetes" "ssh")) }}
{{- range $roleName, $role := default dict $engine.roles }}
{{- $access := default dict $role.access -}}
{{- if hasKey $access "conditional" }}
{{- $_ := set $state "warnings" (append $state.warnings (printf "%s/%s uses conditional access; GatePlane endpoint reconciliation is not enabled in this release" $path $roleName)) -}}
{{- end }}
{{- $policyName := include "vault-yaml.policyName" (dict "type" $engine.type "role" $roleName "path" $path) -}}
{{- range $principal := default (list) $access.static }}
{{- $existing := default (list) (index $state.bindings $principal) -}}
{{- $_ := set $state.bindings $principal (uniq (append $existing (lower $policyName))) -}}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
