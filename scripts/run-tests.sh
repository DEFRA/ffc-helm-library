#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
results_directory="${TEST_RESULTS_DIRECTORY:-$repository_root/test-results}"

mkdir -p "$results_directory"
cd "$repository_root"

python3 -m pytest \
  --verbose \
  --junitxml "$results_directory/pytest.xml"
