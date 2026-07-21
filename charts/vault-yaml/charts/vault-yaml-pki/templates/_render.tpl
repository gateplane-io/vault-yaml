{{- define "vault-yaml-pki.render" -}}
{{- $root := . -}}
{{- $s := index .Values "_vaultYaml" -}}
{{- $accesses := fromYaml (include "vault-yaml.accesses" .) -}}
{{- range $path, $engine := $accesses }}
{{- if and (kindIs "map" $engine) (eq (default "" $engine.type) "pki") }}
{{- $mounts := default dict $s.secrets.pki.mounts -}}
{{- if not (hasKey $mounts $path) }}{{ fail (printf "missing _vaultYaml.secrets.pki.mounts[%q] for access path %s" $path $path) }}{{ end -}}
{{- $mountSettings := index $mounts $path -}}
{{- range $roleName, $role := default dict $engine.roles }}
{{- if eq (include "vault-yaml.hasAccess" (dict "role" $role)) "true" }}
{{- $context := dict "root" $root "mountSettings" $mountSettings "path" $path "roleName" $roleName "role" $role -}}
{{ include "vault-yaml-pki.role" $context }}
{{ include "vault-yaml-pki.policy" $context }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
