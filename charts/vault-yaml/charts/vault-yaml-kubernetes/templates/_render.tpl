{{- define "vault-yaml-kubernetes.render" -}}
{{- $root := . -}}
{{- $s := index .Values "_vaultYaml" -}}
{{- $accesses := fromYaml (include "vault-yaml.accesses" .) -}}
{{- range $path, $engine := $accesses }}
{{- if and (kindIs "map" $engine) (eq (default "" $engine.type) "kubernetes") }}
{{- $mounts := default dict $s.secrets.kubernetes.mounts -}}
{{- $roleDefinitions := default dict $s.secrets.kubernetes.roleDefinitions -}}
{{- if not (hasKey $mounts $path) }}{{ fail (printf "missing _vaultYaml.secrets.kubernetes.mounts[%q] for access path %s" $path $path) }}{{ end -}}
{{- $mountSettings := index $mounts $path -}}
{{- range $roleName, $role := default dict $engine.roles }}
{{- if eq (include "vault-yaml.hasAccess" (dict "role" $role)) "true" }}
{{- $context := dict "root" $root "mountSettings" $mountSettings "roleDefinitions" $roleDefinitions "path" $path "roleName" $roleName "role" $role -}}
{{ include "vault-yaml-kubernetes.role" $context }}
{{ include "vault-yaml-kubernetes.policy" $context }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
