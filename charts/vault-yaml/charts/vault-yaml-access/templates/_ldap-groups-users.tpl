{{- define "vault-yaml-access.ldapGroup" -}}
{{- $parts := .parts -}}
{{- $s := .settings -}}
{{- if and (ge (len $parts) 3) (eq (index $parts 0) "ldap") (eq (index $parts 1) "groups") $s.auth.ldap.enabled }}
{{- $_ := set . "handled" true -}}
{{- $name := join "." (slice $parts 2) }}
---
apiVersion: ldap.vault.upbound.io/v1alpha1
kind: AuthBackendGroup
metadata:
  name: {{ include "vault-yaml.name" (dict "raw" (printf "ldap-group-%s" $name)) }}
  labels:
{{ include "vault-yaml.labels" (dict "root" .root "type" "ldap-group" "path" "ldap") | indent 4 }}
  annotations:
{{ include "vault-yaml.annotations" (dict "path" $s.auth.ldap.backend "role" $name) | indent 4 }}
spec:
  forProvider:
    backend: {{ $s.auth.ldap.backend | quote }}
    groupname: {{ $name | quote }}
    policies:
{{ toYaml (sortAlpha .policies) | indent 6 }}
{{ include "vault-yaml.lifecycle" (dict "root" .root) | indent 2 }}
{{- end }}
{{- end -}}

{{- define "vault-yaml-access.ldapUser" -}}
{{- $parts := .parts -}}
{{- $s := .settings -}}
{{- if and (not .handled) (ge (len $parts) 3) (eq (index $parts 0) "ldap") (eq (index $parts 1) "users") $s.auth.ldap.enabled }}
{{- $_ := set . "handled" true -}}
{{- $name := join "." (slice $parts 2) }}
---
apiVersion: ldap.vault.upbound.io/v1alpha1
kind: AuthBackendUser
metadata:
  name: {{ include "vault-yaml.name" (dict "raw" (printf "ldap-user-%s" $name)) }}
  labels:
{{ include "vault-yaml.labels" (dict "root" .root "type" "ldap-user" "path" "ldap") | indent 4 }}
  annotations:
{{ include "vault-yaml.annotations" (dict "path" $s.auth.ldap.backend "role" $name) | indent 4 }}
spec:
  forProvider:
    backend: {{ $s.auth.ldap.backend | quote }}
    username: {{ $name | quote }}
    policies:
{{ toYaml (sortAlpha .policies) | indent 6 }}
{{ include "vault-yaml.lifecycle" (dict "root" .root) | indent 2 }}
{{- end }}
{{- end -}}
