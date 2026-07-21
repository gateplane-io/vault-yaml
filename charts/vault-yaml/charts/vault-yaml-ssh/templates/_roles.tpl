{{- define "vault-yaml-ssh.role" -}}
{{- $root := .root -}}
{{- $mountSettings := .mountSettings -}}
{{- $path := .path -}}
{{- $roleName := .roleName -}}
{{- $role := .role -}}
{{- $extensions := default (list "permit-pty") $role.extensions }}
{{- $extensionMap := dict }}{{ range $extensions }}{{ $_ := set $extensionMap . "" }}{{ end }}
---
apiVersion: ssh.vault.upbound.io/v1alpha1
kind: SecretBackendRole
metadata:
  name: {{ include "vault-yaml.name" (dict "raw" (printf "ssh-role-%s-%s" $path $roleName)) }}
  labels:
{{ include "vault-yaml.labels" (dict "root" $root "type" "ssh-role" "path" $path) | indent 4 }}
  annotations:
{{ include "vault-yaml.annotations" (dict "path" $path "role" $roleName) | indent 4 }}
spec:
  forProvider:
    backend: {{ $path | quote }}
    name: {{ $roleName | quote }}
    keyType: ca
    allowUserCertificates: true
    allowedUsers: {{ $mountSettings.allowedUsers | quote }}
    allowedUsersTemplate: true
    defaultUser: {{ $mountSettings.defaultUser | quote }}
    defaultUserTemplate: true
    allowedExtensions: {{ join "," $extensions | quote }}
    defaultExtensions:
{{ toYaml $extensionMap | indent 6 }}
    ttl: {{ printf "%.0f" (default 60 $role.ttl) | quote }}
    maxTtl: {{ printf "%.0f" (default 600 $role.ttl_max) | quote }}
{{ include "vault-yaml.lifecycle" (dict "root" $root) | indent 2 }}
{{ end -}}
