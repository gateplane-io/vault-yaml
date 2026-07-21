{{- define "vault-yaml-access.render" -}}
{{- $root := . -}}
{{- $s := index .Values "_vaultYaml" -}}
{{- $accesses := fromYaml (include "vault-yaml.accesses" .) -}}
{{- $state := dict "bindings" (dict) "warnings" (list) -}}
{{- include "vault-yaml-access.inventory" (dict "accesses" $accesses "state" $state) -}}
{{- include "vault-yaml-access.adhocPolicies" (dict "root" $root "accesses" $accesses "state" $state) }}
{{- range $principal, $policies := $state.bindings }}
{{- $binding := dict "root" $root "settings" $s "principal" $principal "parts" (splitList "." $principal) "policies" $policies "handled" false -}}
{{- include "vault-yaml-access.ldapGroup" $binding }}
{{- include "vault-yaml-access.ldapUser" $binding }}
{{- include "vault-yaml-access.identityEntityPolicies" $binding }}
{{- include "vault-yaml-access.identityGroupPolicies" $binding }}
{{- include "vault-yaml-access.certRole" $binding }}
{{- include "vault-yaml-access.kubernetesRole" $binding }}
{{- if not $binding.handled }}
{{- include "vault-yaml-access.addUnsupportedWarning" (dict "state" $state "principal" $principal) -}}
{{- end }}
{{- end }}
{{- include "vault-yaml-access.warnings" (dict "root" $root "state" $state) }}
{{- end -}}
