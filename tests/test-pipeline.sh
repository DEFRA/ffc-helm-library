#!/usr/bin/env bash

set -euo pipefail

test_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$test_directory/test-versioning.sh"
bash "$test_directory/test-pipeline-scripts.sh"
