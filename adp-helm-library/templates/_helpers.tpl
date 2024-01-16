{{/*
A default message string to be used when checking for a required value
*/}}
{{- define "adp-helm-library.default-check-required-msg" -}}
{{- "No value found for '%s' in adp-helm-library template" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "adp-helm-library.labels" -}}
{{- $requiredMsg := include "adp-helm-library.default-check-required-msg" . -}}
app: {{ required (printf $requiredMsg "namespace") .Values.namespace | quote }}
app.kubernetes.io/name: {{ required (printf $requiredMsg "name") .Values.name | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.labels.version | default "1.0.0" | quote }}
app.kubernetes.io/component: {{ .Values.labels.component | default "service" | quote }}
app.kubernetes.io/part-of: {{ required (printf $requiredMsg "namespace") .Values.namespace | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{/*
CPU and Memory requests and limits Tiers
*/}}
{{- define "adp-helm-library.mem-cpu-tiers" -}}
{{- $requiredMsg := include "adp-helm-library.default-check-required-msg" . -}}
{{- $memCpuTier := $.Values.container.memCpuTier | default "M" }}

{{- $requestsMemory := "" }}
{{- $requestsCpu := "" }}
{{- $limitsMemory := "" }}
{{- $limitsCpu := "" }}

{{- if eq $memCpuTier "S" }}
{{- $requestsMemory = "50Mi" }}
{{- $requestsCpu = "50m" }}
{{- $limitsMemory = "50Mi" }}
{{- $limitsCpu = "50m" }}

{{- else if eq $memCpuTier "M" }}
{{- $requestsMemory = "100Mi" }}
{{- $requestsCpu = "100m" }}
{{- $limitsMemory = "100Mi" }}
{{- $limitsCpu = "100m" }}

{{- else if eq $memCpuTier "L" }}
{{- $requestsMemory = "150Mi" }}
{{- $requestsCpu = "150m" }}
{{- $limitsMemory = "150Mi" }}
{{- $limitsCpu = "150m" }}

{{- else if eq $memCpuTier "XL" }}
{{- $requestsMemory = "200Mi" }}
{{- $requestsCpu = "200m" }}
{{- $limitsMemory = "200Mi" }}
{{- $limitsCpu = "200m" }}

{{- else if eq $memCpuTier "XXL" }}
{{- $requestsMemory = "300Mi" }}
{{- $requestsCpu = "300m" }}
{{- $limitsMemory = "600Mi" }}
{{- $limitsCpu = "600m" }}

{{- else if eq $memCpuTier "CUSTOM" }}
{{- $requestsMemory = required (printf $requiredMsg "container.requestMemory") .Values.container.requestMemory | quote }}
{{- $requestsCpu = required (printf $requiredMsg "container.requestCpu") .Values.container.requestCpu | quote }}
{{- $limitsMemory = required (printf $requiredMsg "container.limitMemory") .Values.container.limitMemory | quote }}
{{- $limitsCpu = required (printf $requiredMsg "container.limitCpu") .Values.container.limitCpu | quote }}

{{- else }}
{{- fail (printf "Value for memCpuTier is not as expected. '%s' memCpuTier is not in the allowed memCpuTiers (S,M,X,XL,XXL,CUSTOM)." $memCpuTier) }}
{{- end }}
  requests:
    memory: {{ $requestsMemory }}
    cpu: {{ $requestsCpu }}
  limits:
    memory: {{ $limitsMemory }}
    cpu: {{ $limitsCpu }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "adp-helm-library.selector-labels" -}}
{{- $requiredMsg := include "adp-helm-library.default-check-required-msg" . -}}
app.kubernetes.io/name: {{ required (printf $requiredMsg "name") .Values.name | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Settings for an http GET probe to be used for readiness or liveness
*/}}
{{- define "adp-helm-library.http-get-probe" -}}
{{- $settings := (index . 1) -}}
{{- $requiredMsg := include "adp-helm-library.default-check-required-msg" . -}}
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
{{- define "adp-helm-library.exec-probe" -}}
{{- $settings := (index . 1) -}}
{{- $requiredMsg := include "adp-helm-library.default-check-required-msg" . -}}
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
