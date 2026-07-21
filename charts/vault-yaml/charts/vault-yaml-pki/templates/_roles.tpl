{{- define "vault-yaml-pki.role" -}}
{{- $root := .root -}}
{{- $mountSettings := .mountSettings -}}
{{- $path := .path -}}
{{- $roleName := .roleName -}}
{{- $role := .role -}}
{{- $clientFlag := true }}{{ if hasKey $role "client_flag" }}{{ $clientFlag = $role.client_flag }}{{ end }}
{{- $serverFlag := false }}{{ if hasKey $role "server_flag" }}{{ $serverFlag = $role.server_flag }}{{ end }}
{{- $domains := default (list) $role.allowed_domains }}
{{- range $templateName := default (list) $role.templated_common_name }}
{{- $domains = append $domains (required (printf "unknown templated_common_name %s for PKI mount %s" $templateName $path) (index $mountSettings.templatedCommonNames $templateName)) }}
{{- end }}
---
apiVersion: pki.vault.upbound.io/v1alpha1
kind: SecretBackendRole
metadata:
  name: {{ include "vault-yaml.name" (dict "raw" (printf "pki-role-%s-%s" $path $roleName)) }}
  labels:
{{ include "vault-yaml.labels" (dict "root" $root "type" "pki-role" "path" $path) | indent 4 }}
  annotations:
{{ include "vault-yaml.annotations" (dict "path" $path "role" $roleName) | indent 4 }}
spec:
  forProvider:
    backend: {{ $path | quote }}
    name: {{ $roleName | quote }}
    issuerRef: {{ default "default" $mountSettings.issuerRef | quote }}
    noStore: false
    clientFlag: {{ $clientFlag }}
    serverFlag: {{ $serverFlag }}
    organization:
{{ toYaml (default (list) $role.organization) | indent 6 }}
    country:
{{ toYaml (default (list) $role.country) | indent 6 }}
    locality:
{{ toYaml (default (list) $role.locality) | indent 6 }}
    ttl: {{ printf "%.0f" (default 600 $role.ttl) | quote }}
    maxTtl: {{ printf "%.0f" (default 600 $role.ttl) | quote }}
    keyUsage:
{{ toYaml (default (list "DigitalSignature" "KeyAgreement" "KeyEncipherment") $role.key_usage) | indent 6 }}
    extKeyUsage:
{{ toYaml (default (list) $role.ext_key_usage) | indent 6 }}
    allowBareDomains: {{ default false $role.allow_bare_domains }}
    allowGlobDomains: {{ default false $role.allow_glob_domains }}
    allowedDomains:
{{ toYaml $domains | indent 6 }}
    allowedDomainsTemplate: {{ gt (len (default (list) $role.templated_common_name)) 0 }}
{{ include "vault-yaml.lifecycle" (dict "root" $root) | indent 2 }}
{{ end -}}
