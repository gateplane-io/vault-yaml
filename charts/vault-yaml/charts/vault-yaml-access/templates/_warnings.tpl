{{- define "vault-yaml-access.addUnsupportedWarning" -}}
{{- $_ := set .state "warnings" (append .state.warnings (printf "principal %s was not rendered (unsupported type or auth integration disabled)" .principal)) -}}
{{- end -}}

{{- define "vault-yaml-access.warnings" -}}
{{- if gt (len .state.warnings) 0 }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "vault-yaml.name" (dict "raw" "vault-yaml-render-warnings") }}
  labels:
{{ include "vault-yaml.labels" (dict "root" .root "type" "warnings" "path" "warnings") | indent 4 }}
data:
  warnings: |
{{ range .state.warnings }}    - {{ . }}
{{ end }}
{{- end }}
{{- end -}}
