# FFC Platform Helm Library Chart

A Helm library chart that captures general configuration for the FFC Kubernetes platform (MORE HERE)

## Using the library chart

Steps:
  * Update `Chart.yaml` to `apiVersion: v2`
  * Add library chart under `dependencies`. Choose the version you want. Version number can include `~` or `^` to pick up latest PATCH and MINOR versions respectively
  * Need to do `helm dependency update` (check if need to do add helm repo -- see Helm chart documentation)

An example `Chart.yaml`:

```
apiVersion: v2
description: A Helm chart to deploy a microservices to FFC Kubernetes platform
name: ffc-microservice
version: 1.0.0
dependencies:
- name: ffc-helm-library
  version: ^1.0.0
  repository: https://raw.githubusercontent.com/defra/ffc-helm-repository/master/
```

## Using the k8s object templates

(Follow instructions for using the library chart)

(Intro text here, generally how you use the templates. Basically include the library template and pass it the template defined in the parent helm chart)

(TODO: include an example of an IF statement)

```
{{- include "ffc-helm-library.secret" (list . "ffc-microservice.secret") -}}
{{- define "ffc-microservice.secret" -}}
# Microservice specific configuration in here
{{- end -}}
```

### All template required values

All the object templates include labels (TODO: list them and any other globals)

```
namespace: <value>
```

### AWS service account template

Template file: `_aws-service-account.yaml`

A basic usage of this object template would involve the creation of `templates/aws-service-account.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```
{{- include "ffc-helm-library.aws-service-account" (list . "ffc-microservice.aws-service-account") -}}
{{- define "ffc-microservice.aws-service-account" -}}
{{- end -}}
```

#### Required values

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
serviceAccount: <value>
  name: <value>
  roleArn: <value>
```

### Cluster IP service template

Template file: `_cluster-ip-service.yaml`

A basic usage of this object template would involve the creation of `templates/cluster-ip-service.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```
{{- include "ffc-helm-library.cluster-ip-service" (list . "ffc-microservice.cluster-ip-service") -}}
{{- define "ffc-microservice.cluster-ip-service" -}}
{{- end -}}
```

#### Required values

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
TODO
```

### Container template

Template file: `_container.yaml`

A basic usage of this object template would involve the creation of `templates/_container.yaml` in the parent Helm chart (e.g. `ffc-microservice`). Note the `_` in the name. This template is part of the `deployment` object definition and will be used within the `deployment.yaml` ([see below](#deployment-template)). As a minimum, `templates/_container.yaml` would contain:

```
TODO
```

#### Required values

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
TODO
```

### Deployment template

Template file: `_deployment.yaml`

A basic usage of this object template would involve the creation of `templates/deployment.yaml` in the parent Helm chart (e.g. `ffc-microservice`) containing:

```
TODO
```

#### Required values

Including this template requires the following values to be set in the parent chart's `values.yaml` in addition to the globally required values [listed above](#all-template-required-values):

```
TODO
```
