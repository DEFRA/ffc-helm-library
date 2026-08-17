#!/usr/bin/env bash

set -euo pipefail

: "${CHART_DIRECTORY:?CHART_DIRECTORY is required}"
: "${CHART_VERSION:?CHART_VERSION is required}"
: "${CHANNEL:?CHANNEL is required}"
: "${BUILD_NUMBER:?BUILD_NUMBER is required}"
: "${RUNNER_TEMP:?RUNNER_TEMP is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

if [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "BUILD_NUMBER must be numeric: $BUILD_NUMBER" >&2
  exit 1
fi

case "$CHANNEL" in
  alpha)
    package_version="${CHART_VERSION}-alpha.${BUILD_NUMBER}"
    ;;
  beta)
    package_version="${CHART_VERSION}-beta.${BUILD_NUMBER}"
    ;;
  release)
    package_version="$CHART_VERSION"
    ;;
  *)
    echo "Cannot package unsupported channel: $CHANNEL" >&2
    exit 1
    ;;
esac

chart_name="$(basename "$CHART_DIRECTORY")"
package_directory="$RUNNER_TEMP/chart-package"
mkdir -p "$package_directory"

if [ "$package_version" = "$CHART_VERSION" ]; then
  helm package "$CHART_DIRECTORY" --destination "$package_directory"
else
  helm package "$CHART_DIRECTORY" \
    --version "$package_version" \
    --destination "$package_directory"
fi

{
  printf 'file=%s/%s-%s.tgz\n' \
    "$package_directory" "$chart_name" "$package_version"
  printf 'name=%s\n' "$chart_name"
  printf 'version=%s\n' "$package_version"
} >> "$GITHUB_OUTPUT"
