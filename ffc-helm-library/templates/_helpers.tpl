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
{{- define "ffc-helm-library.selectorLabels" -}}
app.kubernetes.io/name: {{ quote .Values.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Apply required check for a value and output message if value is not defined
*/}}
{{- define "ffc-helm-library.checkRequired.tpl" -}}
{{- $key := (index . 1) -}}
{{- $value := (index . 2) -}}
{{- required (printf "No value found for '%s' in ffc-helm-library template" $key) $value -}}
{{- end -}}

{{/*
Settings for an http Get probe to be used for readiness or liveness
*/}}
{{- define "ffc-helm-library.httpGetProbe" -}}
{{- $settings := (index . 1) -}}
httpGet:
  path: {{ $settings.path | quote }}
  port: {{ $settings.port }}
initialDelaySeconds: {{ $settings.initialDelaySeconds }}
periodSeconds: {{ $settings.periodSeconds }}
failureThreshold: {{ $settings.failureThreshold }}
{{- end -}}

{{/*
Settings for a Node exec probe to be used for readiness or liveness
*/}}
{{- define "ffc-helm-library.execProbe" -}}
{{- $settings := (index . 1) -}}
exec:
  command:
  - sh
  - -c
  - {{ $settings.script }}
initialDelaySeconds: {{ $settings.initialDelaySeconds }}
periodSeconds: {{ $settings.periodSeconds }}
failureThreshold: {{ $settings.failureThreshold }}
{{- end -}}