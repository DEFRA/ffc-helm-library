#!/usr/bin/env bash

set -euo pipefail

: "${CHART_DIRECTORY:?CHART_DIRECTORY is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chart_file="$CHART_DIRECTORY/Chart.yaml"

if [ ! -f "$chart_file" ]; then
  echo "Chart file not found: $chart_file" >&2
  exit 1
fi

version="$(python3 "$script_directory/chart-version.py" "$chart_file")"
if [[ ! "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "Chart version must be a three-part numeric SemVer: $version" >&2
  exit 1
fi

printf 'version=%s\n' "$version" >> "$GITHUB_OUTPUT"
