{{- define "vault-yaml-ssh.render" -}}
{{- $root := . -}}
{{- $s := index .Values "_vaultYaml" -}}
{{- $accesses := fromYaml (include "vault-yaml.accesses" .) -}}
{{- range $path, $engine := $accesses }}
{{- if and (kindIs "map" $engine) (eq (default "" $engine.type) "ssh") }}
{{- $mounts := default dict $s.secrets.ssh.mounts -}}
{{- if not (hasKey $mounts $path) }}{{ fail (printf "missing _vaultYaml.secrets.ssh.mounts[%q] for access path %s" $path $path) }}{{ end -}}
{{- $mountSettings := index $mounts $path -}}
{{- range $roleName, $role := default dict $engine.roles }}
{{- if eq (include "vault-yaml.hasAccess" (dict "role" $role)) "true" }}
{{- $context := dict "root" $root "mountSettings" $mountSettings "path" $path "roleName" $roleName "role" $role -}}
{{ include "vault-yaml-ssh.role" $context }}
{{ include "vault-yaml-ssh.policy" $context }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
