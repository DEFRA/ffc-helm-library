#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
consumer_chart="$repository_root/tests/consumer"
rendered_manifest="$(mktemp)"
render_error="$(mktemp)"
helm_repository_cache="$(mktemp -d)"

cleanup() {
  rm -rf "$consumer_chart/charts"
  rm -rf "$helm_repository_cache"
  rm -f "$consumer_chart/Chart.lock" "$rendered_manifest" "$render_error"
}
trap cleanup EXIT

assert_contains() {
  local expected="$1"
  if ! grep -Fq -- "$expected" "$rendered_manifest"; then
    echo "Expected rendered chart to contain: $expected" >&2
    exit 1
  fi
}

chart_version="$(python3 "$repository_root/scripts/chart-version.py" "$repository_root/ffc-helm-library/Chart.yaml")"
if [[ ! "$chart_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Unexpected chart version: $chart_version" >&2
  exit 1
fi

helm lint "$repository_root/ffc-helm-library"
HELM_REPOSITORY_CONFIG=/dev/null \
  HELM_REPOSITORY_CACHE="$helm_repository_cache" \
  helm dependency update --skip-refresh "$consumer_chart"
helm lint "$consumer_chart"
helm template helm-library-test "$consumer_chart" \
  --namespace helm-library-test > "$rendered_manifest"

assert_contains 'kind: Deployment'
assert_contains 'kind: Service'
assert_contains 'kind: ConfigMap'
assert_contains 'kind: Secret'
assert_contains 'kind: HorizontalPodAutoscaler'
assert_contains 'kind: Ingress'
assert_contains 'kind: ServiceAccount'
assert_contains 'kind: SecretProviderClass'
assert_contains 'namespace: helm-library-test'
assert_contains 'image: example/helm-library-consumer:1.0.0'
assert_contains 'replicas: 2'
assert_contains 'automountServiceAccountToken: false'
assert_contains 'serviceAccountName: helm-library-consumer'
assert_contains 'readOnlyRootFilesystem: true'
assert_contains 'allowPrivilegeEscalation: false'
assert_contains 'NET_BIND_SERVICE'
assert_contains 'memory: 100Mi'
assert_contains 'targetPort: 8080'
assert_contains 'LOG_LEVEL: info'
assert_contains 'TEST_TOKEN: dGVzdA=='
assert_contains 'minReplicas: 2'
assert_contains 'maxReplicas: 4'
assert_contains 'helm-library-consumer.example.test'
assert_contains 'azure.workload.identity/client-id: 00000000-0000-0000-0000-000000000001'
assert_contains 'secretProviderClass: helm-library-consumer'

if helm template helm-library-test "$consumer_chart" \
  --namespace helm-library-test --set image= > /dev/null 2> "$render_error"; then
  echo 'Expected rendering without an image to fail.' >&2
  exit 1
fi

if ! grep -Fq "No value found for 'image'" "$render_error"; then
  echo 'Missing-image failure did not contain the expected validation message.' >&2
  cat "$render_error" >&2
  exit 1
fi

echo 'Helm library consumer tests passed.'
