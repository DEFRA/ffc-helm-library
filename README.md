# FCP Platform Helm Library Chart

A Helm library chart that captures general configuration for the FCP Kubernetes platform. It can be used by any FCP microservice Helm chart to import K8s object templates configured to run on the FCP platform.

## Including the library chart

In your microservice Helm chart:

- Update `Chart.yaml` to `apiVersion: v2`.
- Add the library chart under `dependencies` and choose the version you want (example below). Version number can include `~` or `^` to pick up latest PATCH and MINOR versions respectively.
- Issue the following commands to add the repo that contains the library chart, update the repo, then update dependencies in your Helm chart:

```bash
helm repo add ffc https://raw.githubusercontent.com/defra/ffc-helm-repository/master/
helm repo update
helm dependency update <helm_chart_location>
```

An example FCP microservice `Chart.yaml`:

```yaml
apiVersion: v2
description: A Helm chart to deploy a microservice to the FCP Kubernetes platform
name: ffc-microservice
version: 1.0.0
dependencies:
  - name: ffc-helm-library
    version: 4.1.0
    repository: https://raw.githubusercontent.com/defra/ffc-helm-repository/master/
```

## Using the K8s object templates

First, follow [the instructions](#including-the-library-chart) for including the FCP Helm library chart.

The FCP Helm library chart has been configured using the conventions described in the [Helm library chart documentation](https://helm.sh/docs/topics/library_charts/). The K8s object templates provide settings shared by all objects of that type, which can be augmented with extra settings from the parent (FCP microservice) chart. The library object templates will merge the library and parent templates. In the case where settings are defined in both the library and parent chart, the parent chart settings will take precedence, so library chart settings can be overridden. The library object templates will expect values to be set in the parent `.values.yaml`. Any required values (defined for each template below) that are not provided will result in an error message when processing the template (`helm install`, `helm upgrade`, `helm template`).

The general strategy for using one of the library templates in the parent microservice Helm chart is to create a template for the K8s object formateted as so:

```yaml
{{- include "ffc-helm-library.secret" (list . "ffc-microservice.secret") -}}
{{- define "ffc-microservice.secret" -}}
# Microservice specific configuration in here
{{- end -}}
```

This example would be for `template/secret.yaml` in the `ffc-microservice` Helm chart. The initial `include` statement can be wrapped in an `if` statement if you only wish to create the K8s object based on a condition. E.g., only create the secret is a `pr` value has been set in `values.yaml`:

```yaml
{{- if .Values.pr }}
{{- include "ffc-helm-library.secret" (list . "ffc-microservice.secret") -}}
{{- end }}
{{- define "ffc-microservice.secret" -}}
# Microservice specific configuration in here
{{- end -}}
```

### Azure Identity template

- Template file: `_azure-identity.yaml`
- Template name: `ffc-helm-library.azure-identity`

A K8s `AzureIdentity` object. Must be used in conjunction with the `AzureIdentityBinding` described below. The name of the template is set automatically based on the name of the Helm chart (as defined by `name:` in the `values.yaml`) to `<name>-identity`.

A basic usage of this object template would involve the creation of `templates/azure-identity.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```yaml
{{- include "ffc-helm-library.azure-identity" (list . "ffc-microservice.azure-identity") -}}
{{- define "ffc-microservice.azure-identity" -}}
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml`:

```yaml
azureIdentity:
  resourceID:
  clientID:
```

### Azure Identity Binding template

- Template file: `_azure-identity-binding.yaml`
- Template name: `ffc-helm-library.azure-identity-binding`

A K8s `AzureIdentityBinding` object. Must be used in conjunction with the `AzureIdentity` described above. The name of the template is set automatically based on the name of the Helm chart (as defined by `name:` in the `values.yaml`) to `<name>-identity-binding`.

A basic usage of this object template would involve the creation of `templates/azure-identity-binding.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```yaml
{{- include "ffc-helm-library.azure-identity-binding" (list . "ffc-microservice.azure-identity-binding") -}}
{{- define "ffc-microservice.azure-identity-binding" -}}
{{- end -}}
```

### Cluster IP service template

- Template file: `_cluster-ip-service.yaml`
- Template name: `ffc-helm-library.cluster-ip-service`

A K8s `Service` object of type `ClusterIP`.

A basic usage of this object template would involve the creation of `templates/cluster-ip-service.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```yaml
{{- include "ffc-helm-library.cluster-ip-service" (list . "ffc-microservice.service") -}}
{{- define "ffc-microservice.service" -}}
# Microservice specific configuration in here
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml`:

```yaml
container:
  port: <integer>
```

### Container template

- Template file: `_container.yaml`
- Template name: `ffc-helm-library.container`

A template for the container definition to be used within a K8s `Deployment` object.

A basic usage of this object template would involve the creation of `templates/_container.yaml` in the parent Helm chart (e.g. `ffc-microservice`). Note the `_` in the name. This template is part of the `Deployment` object definition and will be used in conjunction the `_deployment.yaml` template ([see below](#deployment-template)). As a minimum `templates/_container.yaml` would define environment variables and may also include liveness/readiness probes when applicable e.g.:

```yaml
{{- define "ffc-microservice.container" -}}
env: <list>
livenessProbe: <map>
readinessProbe: <map>
{{- end -}}
```

The liveness and readiness probes could take advantage of the helper templates for [http GET probe](#http-get-probe) and [exec probe](#exec-probe) defined within the library chart and described below.

#### Required values

The following values need to be set in the parent chart's `values.yaml`:

```yaml
image: <string>
container:
  resourceTier: <string> # Allowed values: S, M, L, XL
```

#### Optional values

The following values can optionally be set in the parent chart's `values.yaml` to enable a command with arguments to run within the container or change the security context:

```yaml
container:
  imagePullPolicy: <string>
  command: <list of strings>
  args: <list of strings>
  readOnlyRootFilesystem: <boolean>
  allowPrivilegeEscalation: <boolean>
  requestMemory: <string> # if not using resourceTier
  requestCPU: <string> # if not using resourceTier
  limitMemory: <string> # if not using resourceTier
  limitCPU: <string> # if not using resourceTier
```

### Container ConfigMap template

- Template file: `_containter-config-map.yaml`
- Template name: `ffc-helm-library.containter-config-map`

A K8s `ConfigMap` object object to host non-sensitive container configuration data.

A basic usage of this object template would involve the creation of `templates/containter-config-map.yaml` in the parent Helm chart (e.g. `ffc-microservice`), which should include the `data` map containing the configuration data:

```yaml
{{- include "ffc-helm-library.containter-config-map" (list . "ffc-microservice.containter-config-map") -}}
{{- define "ffc-microservice.containter-config-map" -}}
data:
  <key1>: <value1>
  ...
{{- end -}}
```

### Container Secret template

- Template file: `_containter-secret.yaml`
- Template name: `ffc-helm-library.containter-secret`

A K8s `Secret` object to host sensitive data such as a password or token in a container.

A basic usage of this object template would involve the creation of `templates/containter-secret.yaml` in the parent Helm chart (e.g. `ffc-microservice`), which should include the `data` map containing the sensitive data :

```yaml
{{- include "ffc-helm-library.containter-secret" (list . "ffc-microservice.containter-secret") -}}
{{- define "ffc-microservice.containter-secret" -}}
data:
  <key1>: <value1>
  ...
{{- end -}}
```

### Deployment template

- Template file: `_deployment.yaml`
- Template name: `ffc-helm-library.deployment`

A K8s `Deployment` object.

A basic usage of this object template would involve the creation of `templates/deployment.yaml` in the parent Helm chart (e.g. `ffc-microservice`) that includes the template defined in `_container.yaml` template:

```yaml
{{- include "ffc-helm-library.deployment" (list . "ffc-microservice.deployment") -}}
{{- define "ffc-microservice.deployment" -}}
{{- end -}}
```

#### Optional values

The following value can optionally be set in the parent chart's `values.yaml` to enable the configuration of imagePullSecrets in the K8s object or change the running user:

```yaml
deployment:
  automountServiceAccountToken: <boolean> # defaults to false
  imagePullSecret: <string>
  runAsUser: <integer>
  runAsNonRoot: <boolean>
  priorityClassName: <string>
  restartPolicy: <string>
  replicas: <integer>
  minReadySeconds: <integer>
```

The following value can optionally be set in the parent chart's `values.yaml` to link the deployment to a service account K8s object:

```yaml
serviceAccount:
  name: <string>
  roleArn: <string>
```

### Service account template

- Template file: `_service-account.yaml`
- Template name: `ffc-helm-library.service-account`

A K8s `ServiceAccount` object.

A basic usage of this object template would involve the creation of `templates/service-account.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

A service account is needed when the service needs to use Workload Identity to connect to the resources in Azure
After adding the service account, `workloadIdentity: true` needs to be added to the `value.yaml` file. By activating Workload Identity, the Pod Identity will be disabled.

```yaml
{{- include "ffc-helm-library.service-account" (list . "ffc-microservice.service-account") -}}
{{- define "ffc-microservice.service-account" -}}
# Microservice specific configuration in here
{{- end -}}
```

### EKS service account template

- Template file: `_eks-service-account.yaml`
- Template name: `ffc-helm-library.eks-service-account`

A K8s `ServiceAccount` object configured for use on AWS's managed K8s service EKS.

A basic usage of this object template would involve the creation of `templates/eks-service-account.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```yaml
{{- include "ffc-helm-library.eks-service-account" (list . "ffc-microservice.eks-service-account") -}}
{{- define "ffc-microservice.eks-service-account" -}}
# Microservice specific configuration in here
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml`:

```yaml
serviceAccount:
  name: <string>
  roleArn: <string>
```

### Ingress template

- Template file: `_ingress.yaml`
- Template name: `ffc-helm-library.ingress`

A K8s `Ingress` object that can be configured for Nginx or AWS ALB (Amazon Load Balancer).

A basic Nginx `Ingress` object would involve the creation of `templates/ingress.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```yaml
{{- include "ffc-helm-library.ingress" (list . "ffc-microservice.ingress") -}}
{{- define "ffc-microservice.ingress" -}}
metadata:
  annotations:
    <map_of_nginx-ingress-annotations>
{{- end -}}
```

A basic ALB `Ingress` object would involve the creation of `templates/ingress-alb.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```yaml
{{- include "ffc-helm-library.ingress" (list . "ffc-microservice.ingress-alb") -}}
{{- define "ffc-microservice.ingress-alb" -}}
metadata:
  annotations:
    <map_of_alb-ingress-annotation>
{{- end -}}
```

#### Optional values

The following values can optionally be set in the parent chart's `values.yaml` to set the value of `host`:

```yaml
pr: <string>
ingress:
  endpoint: <string>
  server: <string>
```

### Azure Ingress template

- Template file: `_azure-ingress.yaml`
- Template name: `ffc-helm-library.azure-ingress`

A K8s `Ingress` object that can be configured for Nginx for use in Azure.

A basic Nginx `Ingress` object would involve the creation of `templates/ingress.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```yaml
{{- include "ffc-helm-library.azure-ingress" (list . "ffc-microservice.ingress") -}}
{{- define "ffc-microservice.ingress" -}}
metadata:
  annotations:
    <map_of_nginx-ingress-annotations>
{{- end -}}
```

#### Optional values

The following values can optionally be set in the parent chart's `values.yaml` to set the value of `host`:

```yaml
pr: <string>
ingress:
  endpoint: <string>
  server: <string>
  type: <string>
  path: <string>
```

The `type` value is used to create a [mergeable ingress type](https://github.com/nginxinc/kubernetes-ingress/tree/master/examples/mergeable-ingress-types)
and should have the value `master` or `minion`.

### Azure Ingress template (master)

- Template file: `_azure-ingress-master.yaml`
- Template name: `ffc-helm-library.azure-ingress-master`

A K8s `Ingress` object that can be configured for Nginx for use in Azure with a `master` [mergeable ingress type](https://github.com/nginxinc/kubernetes-ingress/tree/master/examples/mergeable-ingress-types).

Although the `Azure Ingress template` can also be used to create `master` mergeable ingress types. This template exists to support scenarios where a Helm chart needs to contain both a `master` and a `minion` resource without conflicts in value properties.

A basic Nginx `Ingress` object would involve the creation of `templates/ingress.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```yaml
{{- include "ffc-helm-library.azure-ingress-master" (list . "ffc-microservice.ingress") -}}
{{- define "ffc-microservice.ingress" -}}
metadata:
  annotations:
    <map_of_nginx-ingress-annotations>
{{- end -}}
```

#### Optional values

The following values can optionally be set in the parent chart's `values.yaml` to set the value of `host`:

```yaml
pr: <string>
ingress:
  endpoint: <string>
  server: <string>
```

### Postgres service template

- Template file: `_postgres-service.yaml`
- Template name: `ffc-helm-library.postgres-service`

A K8s `Service` object of type `ExternalName` configured to refer to a Postgres database hosted on a server outside of the K8s cluster such as AWS RDS.

A basic usage of this object template would involve the creation of `templates/postgres-service.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```yaml
{{- include "ffc-helm-library.postgres-service" (list . "ffc-microservice.postgres-service") -}}
{{- define "ffc-microservice.postgres-service" -}}
# Microservice specific configuration in here
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml`:

```
postgresService:
  postgresHost: <string>
  postgresExternalName: <string>
  postgresPort: <integer>
```

### RBAC role binding template

- Template file: `_role-binding.yaml`
- Template name: `ffc-helm-library.role-binding`

A K8s `RoleBinding` object used to bind a role to a user as part of RBAC configuration in the K8s cluster.

A basic usage of this object template would involve the creation of `templates/role-binding.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```yaml
{{- include "ffc-helm-library.role-binding" (list . "ffc-microservice.role-binding") -}}
{{- define "ffc-microservice.role-binding" -}}
# Microservice specific configuration in here
{{- end -}}
```

### Secret template

- Template file: `_secret.yaml`
- Template name: `ffc-helm-library.secret`

A K8s `Secret` object to host sensitive data such as a password or token.

A basic usage of this object template would involve the creation of `templates/secret.yaml` in the parent Helm chart (e.g. `ffc-microservice`), which should include the `data` map containing the sensitive data :

```yaml
{{- include "ffc-helm-library.secret" (list . "ffc-microservice.secret") -}}
{{- define "ffc-microservice.secret" -}}
stringData:
  <key1>: <value1>
  ...
{{- end -}}
```

### Secret Provider Class template

- Template file: `_secret-provider-class.yaml`
- Template name: `ffc-helm-library.secret-provider-class`

A K8s `SecretProviderClass` object for the Secrets Store CSI Driver. This template enables integration with external secret management systems like Azure Key Vault to mount secrets as volumes in pods, using [workload identity](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-identity-access?tabs=azure-portal&pivots=access-with-a-microsoft-entra-workload-identity) for authentication.

When `secretProviderClass` is configured, secrets from Azure Key Vault are automatically mounted as files at `/mnt/secrets-store` in all containers (Deployment, StatefulSet, and CronJob). Applications can read these secrets directly from the filesystem.

A basic usage of this object template would involve the creation of `templates/secret-provider-class.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```yaml
{{- if .Values.secretProviderClass }}
{{- include "ffc-helm-library.secret-provider-class.tpl" . }}
{{- end }}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml` for Azure Key Vault integration:

```yaml
secretProviderClass:
  azure:
    clientID: <string> # Client ID for workload identity
    keyvaultName: <string> # Name of the Azure Key Vault
    tenantId: <string> # Azure tenant ID
    objects:
      - objectName: <string> # Name of the secret in Key Vault
        objectType: secret # Type: secret, key, or cert (default: "secret")
        objectVersion: <string> # Specific version (optional, default: latest)
```

#### Optional values

The following values can optionally be set in the parent chart's `values.yaml`:

```yaml
secretProviderClass:
  azure:
    usePodIdentity: "false" # Default: "false" (for workload identity)

  # Optional: Create Kubernetes secrets from mounted secrets
  secretObjects:
    - secretName: <string> # Name of the K8s secret to create
      type: <string> # Default: "Opaque"
      data:
        - objectName: <string> # Name from Key Vault
          key: <string> # Key name in the K8s secret
```

#### Example configuration

```yaml
secretProviderClass:
  azure:
    usePodIdentity: "false" # Default: "false" (can be omitted)
    clientID: "your-client-id" # Setting this to use workload identity
    keyvaultName: "your-keyvault-name" # Set to the name of your key vault
    tenantId: "87654321-4321-4321-4321-210987654321" # Your Azure tenant ID
    objects:
      - objectName: "database-password" # Set to the name of your secret
        objectType: "secret" # object types: secret, key, or cert
      - objectName: "api-key"
        objectType: "secret"
        objectVersion: "latest" # [OPTIONAL] object versions, default to latest if empty

  # Optional: Create Kubernetes secrets from mounted secrets
  secretObjects:
    - secretName: "app-secrets"
      type: "Opaque"
      data:
        - objectName: "database-password"
          key: "DB_PASSWORD"
        - objectName: "api-key"
          key: "API_KEY"
```

### Service template

- Template file: `_service.yaml`
- Template name: `ffc-helm-library.service`

A generic K8s `Service` object requiring a service type to be set.

A basic usage of this object template would involve the creation of `templates/secret.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```yaml
{{- include "ffc-helm-library.service" (list . "ffc-microservice.service") -}}
{{- define "ffc-microservice.service" -}}
# Microservice specific configuration in here
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml`:

```yaml
service:
  type: <string>
```

### Horizontal Pod Autoscaler template

- Template file: `_horizontal-pod-autoscaler.yaml`
- Template name: `helm-library.horizontal-pod-autoscaler`

A k8s `HorizontalPodAutoscaler`.

A basic usage of this object template would involve the creation of `templates/horizontal-pod-autoscaler.yaml` in the parent Helm chart (e.g. `microservice`).

```yaml
{{- include "ffc-helm-library.horizontal-pod-autoscaler" (list . "microservice.horizontal-pod-autoscaler") -}}
{{- define "microservice.horizontal-pod-autoscaler" -}}
spec:
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: AverageValue
        averageValue: 100Mi
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml`:

```yaml
deployment:
  minReplicas: <integer>
  maxReplicas: <integer>
```

### Vertical Pod Autoscaler template

- Template file: `_vertical-pod-autoscaler.yaml`
- Template name: `helm-library.vertical-pod-autoscaler`

A k8s `VerticalPodAutoscaler`.

A basic usage of this object template would involve the creation of `templates/vertical-pod-autoscaler.yaml` in the parent Helm chart (e.g. `microservice`).

```yaml
{{- include "ffc-helm-library.vertical-pod-autoscaler" (list . "microservice.vertical-pod-autoscaler") -}}
{{- define "microservice.vertical-pod-autoscaler" -}}
{{- end -}}
```

#### Required values

The following values need to be set in the parent chart's `values.yaml`:

```yaml
deployment:
  updateMode: <string>
```

### Storage Class template

- Template file: `_storage-class.yaml`
- Template name: `helm-library.storage-class`

A k8s `StorageClass`.

A basic usage of this object template would involve the creation of `templates/storage-class.yaml` in the parent Helm chart (e.g. `microservice`).

```yaml
{{- include "ffc-helm-library.storage-class" (list . "microservice.storage-class") -}}
{{- define "microservice.storage-class" -}}
{{- end -}}
```

### Persistent Volume template

- Template file: `_persistent-volume.yaml`
- Template name: `helm-library.persistent-volume`

A k8s `PersistentVolume`.

A basic usage of this object template would involve the creation of `templates/persistent-volume.yaml` in the parent Helm chart (e.g. `microservice`).

```yaml
{{- include "ffc-helm-library.persistent-volume" (list . "microservice.persistent-volume") -}}
{{- define "microservice.persistent-volume" -}}
{{- end -}}
```

### Persistent Volume Claim template

- Template file: `_persistent-volume-claim.yaml`
- Template name: `helm-library.persistent-volume-claim`

A k8s `PersistentVolumeClaim`.

A basic usage of this object template would involve the creation of `templates/persistent-volume-claim.yaml` in the parent Helm chart (e.g. `microservice`).

```yaml
{{- include "ffc-helm-library.persistent-volume-claim" (list . "microservice.persistent-volume-claim") -}}
{{- define "microservice.persistent-volume-claim" -}}
{{- end -}}
```

## Helper templates

In addition to the K8s object templates described above, a number of helper templates are defined in `_helpers.tpl` that are both used within the library chart and available to use within a consuming parent chart.

### Default check required message

- Template name: `ffc-helm-library.default-check-required-msg`
- Usage: `{{- include "ffc-helm-library.default-check-required-msg" . }}`

A template defining the default message to print when checking for a required value within the library. This is not designed to be used outside of the library.

### Labels

- Template name: `ffc-helm-library.labels`
- Usage: `{{- include "ffc-helm-library.labels" . }}`

Common labels to apply to `metadata` of all K8s objects on the FCP K8s platform. This template relies on the globally required values [listed above](#all-template-required-values).

### Selector labels

- Template name: `ffc-helm-library.selector-labels`
- Usage: `{{- include "ffc-helm-library.selector-labels" . }}`

Common selector labels that can be applied where necessary to K8s objects on the FCP K8s platform. This template relies on the globally required values [listed above](#all-template-required-values).

### Http GET probe

- Template name: `ffc-helm-library.http-get-probe`
- Usage: `{{- include "ffc-helm-library.http-get-probe" (list . <map_of_probe_values>) }}`

Template for configuration of an http GET probe, which can be used for `readinessProbe` and/or `livenessProbe` in a container definition within a `Deployment` (see [container template](#container-template)).

#### Required values

The following values need to be passed to the probe in the `<map_of_probe_values>`:

```yaml
path: <string>
port: <integer>
initialDelaySeconds: <integer>
periodSeconds: <integer>
failureThreshold: <integer>
```

#### Optional values

```yaml
timeoutSeconds: <integer>
```

### Exec probe

- Template name: `ffc-helm-library.exec-probe`
- Usage: `{{- include "ffc-helm-library.exec-probe" (list . <map_of_probe_values>) }}`

Template for configuration of an "exec" probe that runs a local script, which can be used for `readinessProbe` and/or `livenessProbe` in a container definition within a `Deployment` (see [container template](#container-template)).

#### Required values

The following values need to be passed to the probe in the `<map_of_probe_values>`:

```yaml
script: <string>
initialDelaySeconds: <integer>
periodSeconds: <integer>
timeoutSeconds: <integer>
failureThreshold: <integer>
```

#### Optional values

```yaml
timeoutSeconds: <integer>
```

### Cron Job template

- Template file: `_cron-job.yaml`
- Template name: `ffc-helm-library.cron-job`

A k8s `CronJob`.

A basic usage of this object template would involve the creation of `templates/cron-job.yaml` in the parent Helm chart (e.g. `microservice`) that includes the template defined in `_container.yaml` template:

```yaml
{{- include "ffc-helm-library.cron-job" (list . "microservice.cron-job") -}}
{{- define "microservice.cron-job" -}}
{{- end -}}

```

### StatefulSet template

- Template file: `_statefulset.yaml`
- Template name: `ffc-helm-library.statefulset`

A K8s `StatefulSet` object.

A basic usage of this object template would involve the creation of `templates/statefulset.yaml` in the parent Helm chart (e.g. `microservice`) that includes the template defined in `_container.yaml` template:

```yaml
{{- include "ffc-helm-library.statefulset" (list . "microservice.deployment") -}}
{{- define "microservice.deployment" -}}
{{- end -}}
```

## Licence

THIS INFORMATION IS LICENSED UNDER THE CONDITIONS OF THE OPEN GOVERNMENT LICENCE found at:

http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3

The following attribution statement MUST be cited in your products and applications when using this information.

> Contains public sector information licensed under the Open Government license v3

### About the licence

The Open Government Licence (OGL) was developed by the Controller of Her Majesty's Stationery Office (HMSO) to enable information providers in the public sector to license the use and re-use of their information under a common open licence.

It is designed to encourage use and re-use of information freely and flexibly, with only a few conditions.
