{{/*
A default message string to be used when checking for a required value
*/}}
{{- define "ffc-helm-library.default-check-required-msg" -}}
{{- "No value found for '%s' in ffc-helm-library template" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "ffc-helm-library.labels" -}}
app: {{ .Release.Namespace | quote }}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/instance: {{ .Chart.Name | quote }}
app.kubernetes.io/version: {{ .Values.labels.version | default "1.0.0" | quote }}
app.kubernetes.io/component: {{ .Values.labels.component | default "service" | quote }}
app.kubernetes.io/part-of: {{ .Release.Namespace | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "ffc-helm-library.selector-labels" -}}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Settings for an http GET probe to be used for readiness or liveness
*/}}
{{- define "ffc-helm-library.http-get-probe" -}}
{{- $settings := (index . 1) -}}
{{- $requiredMsg := include "ffc-helm-library.default-check-required-msg" . -}}
httpGet:
  path: {{ required (printf $requiredMsg "probe.path") $settings.path | quote }}
  port: {{ required (printf $requiredMsg "probe.port") $settings.port }}
initialDelaySeconds: {{ required (printf $requiredMsg  "probe.initialDelaySeconds") $settings.initialDelaySeconds }}
periodSeconds: {{ required (printf $requiredMsg "probe.periodSeconds") $settings.periodSeconds }}
failureThreshold: {{ required (printf $requiredMsg "probe.failureThreshold") $settings.failureThreshold }}
timeoutSeconds: {{ $settings.timeoutSeconds | default 1 }}
{{- end -}}

{{/*
Settings for a script execution probe to be used for readiness or liveness
*/}}
{{- define "ffc-helm-library.exec-probe" -}}
{{- $settings := (index . 1) -}}
{{- $requiredMsg := include "ffc-helm-library.default-check-required-msg" . -}}
exec:
  command:
  - "sh"
  - "-c"
  - {{ required (printf $requiredMsg "probe.script") $settings.script | quote }}
initialDelaySeconds: {{ required (printf $requiredMsg "probe.initialDelaySeconds") $settings.initialDelaySeconds }}
periodSeconds: {{ required (printf $requiredMsg "probe.periodSeconds") $settings.periodSeconds }}
failureThreshold: {{ required (printf $requiredMsg "probe.failureThreshold") $settings.failureThreshold }}
timeoutSeconds: {{ $settings.timeoutSeconds | default 1 }}
{{- end -}}
