{{- define "vault-yaml.settings" -}}
{{- default dict (index .Values "_vaultYaml") -}}
{{- end -}}

{{- define "vault-yaml.accesses" -}}
{{- $raw := required "accessFile is required; pass it with --set-file accessFile=path/to/access.yaml" .Values.accessFile -}}
{{- $parsed := fromYaml $raw -}}
{{- if $parsed.Error }}{{ fail (printf "accessFile is not valid YAML: %s" $parsed.Error) }}{{ end -}}
{{- toYaml $parsed -}}
{{- end -}}

{{- define "vault-yaml.name" -}}
{{- $raw := required "vault-yaml.name requires raw" .raw -}}
{{- $normalized := regexReplaceAll "[^a-z0-9-]+" (lower $raw) "-" | trimAll "-" -}}
{{- $hash := trunc 8 (sha256sum $raw) -}}
{{- printf "%s-%s" (trunc 54 $normalized | trimSuffix "-") $hash | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "vault-yaml.policyName" -}}
{{- printf "%s-%s-%s" .type .role (last (splitList "/" .path)) -}}
{{- end -}}

{{- define "vault-yaml.hasAccess" -}}
{{- $access := default dict .role.access -}}
{{- if or (gt (len (default list $access.static)) 0) (hasKey $access "conditional") }}true{{ end -}}
{{- end -}}

{{- define "vault-yaml.labels" -}}
app.kubernetes.io/name: vault-yaml
app.kubernetes.io/instance: {{ .root.Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .root.Release.Service | quote }}
vault-yaml.gateplane.io/type: {{ .type | quote }}
{{- if .path }}
vault-yaml.gateplane.io/path-hash: {{ trunc 16 (sha256sum .path) | quote }}
{{- end }}
{{- end -}}

{{- define "vault-yaml.annotations" -}}
vault-yaml.gateplane.io/path: {{ .path | quote }}
{{- if .role }}
vault-yaml.gateplane.io/role: {{ .role | quote }}
{{- end }}
{{- end -}}

{{- define "vault-yaml.lifecycle" -}}
{{- $s := index .root.Values "_vaultYaml" -}}
deletionPolicy: {{ default "Orphan" $s.lifecycle.deletionPolicy }}
managementPolicies:
{{ toYaml (default (list "Create" "Observe" "Update" "LateInitialize") $s.lifecycle.managementPolicies) }}
providerConfigRef:
  name: {{ default "default" $s.provider.configRef }}
{{ println }}
{{- end -}}

{{- define "vault-yaml.policyResource" -}}
{{- $objectName := include "vault-yaml.name" (dict "raw" (printf "policy-%s" .name)) -}}
apiVersion: vault.vault.upbound.io/v1alpha1
kind: Policy
metadata:
  name: {{ $objectName }}
  labels:
{{ include "vault-yaml.labels" (dict "root" .root "type" "policy" "path" .path) | indent 4 }}
  annotations:
{{ include "vault-yaml.annotations" (dict "path" .path "role" .role) | indent 4 }}
spec:
  forProvider:
    name: {{ .name | quote }}
    policy: |
{{ .policy | indent 6 }}
{{ include "vault-yaml.lifecycle" (dict "root" .root) | indent 2 }}
{{- end -}}

{{- define "vault-yaml.roleRules" -}}
{{- $raw := index .mountSettings.roleDefinitions .role -}}
{{- if not $raw }}{{ fail (printf "missing Kubernetes role definition %s for mount %s" .role .path) }}{{ end -}}
{{- $parsed := fromYaml $raw -}}
{{- if $parsed.Error }}{{ fail (printf "invalid Kubernetes role definition %s: %s" .role $parsed.Error) }}{{ end -}}
{{- $_ := required (printf "role definition %s must contain rules" .role) $parsed.rules -}}
{{- toJson $parsed -}}
{{- end -}}

{{- define "vault-yaml.principalAccessName" -}}
{{- $principal := required "vault-yaml.principalAccessName requires principal" .principal -}}
{{- $base := first (splitList "::" $principal) -}}
{{- $parts := splitList "." $base -}}
{{- $raw := "" -}}
{{- if and (ge (len $parts) 3) (eq (index $parts 0) "ldap") (has (index $parts 1) (list "users" "groups")) -}}
{{- $raw = join "-" (slice $parts 2) -}}
{{- else if and (ge (len $parts) 3) (eq (index $parts 0) "identity") (has (index $parts 1) (list "entity_id" "entity_name" "group_id" "group_name")) -}}
{{- $raw = join "-" (slice $parts 2) -}}
{{- else if and (eq (len $parts) 3) (eq (index $parts 0) "kubernetes") -}}
{{- $raw = join "-" (slice $parts 1) -}}
{{- else if and (ge (len $parts) 2) (eq (index $parts 0) "cert") -}}
{{- $raw = join "-" (slice $parts 1) -}}
{{- else if and (ge (len $parts) 2) (eq (index $parts 0) "userpass") -}}
{{- $raw = join "-" (slice $parts 1) -}}
{{- else -}}
{{- fail (printf "cannot derive adhoc for_each accessName from unsupported or malformed principal %s" $principal) -}}
{{- end -}}
{{- $normalized := regexReplaceAll "[^A-Za-z0-9]+" $raw "-" | trimAll "-" -}}
{{- if eq $normalized "" }}{{ fail (printf "principal %s produces an empty adhoc for_each accessName" $principal) }}{{ end -}}
{{- $normalized -}}
{{- end -}}

{{- define "vault-yaml.adhocPolicy" -}}
{{- $s := index .root.Values "_vaultYaml" -}}
{{- $template := index $s.adhoc.policyTemplates .role -}}
{{- if not $template }}{{ fail (printf "missing _vaultYaml.adhoc.policyTemplates.%s" .role) }}{{ end -}}
{{- $parameters := default dict $s.adhoc.parameters -}}
{{- if hasKey $parameters "accessName" }}{{ fail "_vaultYaml.adhoc.parameters.accessName is reserved and supplied by for_each rendering" }}{{ end -}}
{{- $result := $template -}}
{{- range $name, $value := $parameters }}
{{- $result = replace (printf "${%s}" $name) (toString $value) $result -}}
{{- end }}
{{- $result = replace "${accessName}" (default "" .accessName) $result -}}
{{- $result -}}
{{- end -}}
