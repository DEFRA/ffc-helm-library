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
app: {{ quote .Values.namespace }}
app.kubernetes.io/name: {{ quote .Values.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ quote .Values.labels.version | default "1.0.0" }}
app.kubernetes.io/component: {{ quote .Values.labels.component | default "service" }}
app.kubernetes.io/part-of: {{ quote .Values.namespace }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
environment: {{ quote .Values.environment }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "ffc-helm-library.selector-labels" -}}
app.kubernetes.io/name: {{ quote .Values.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
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
{{- end -}}

{{/*
Settings for a Node exec probe to be used for readiness or liveness
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
{{- end -}}
