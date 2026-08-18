#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 -m pip install \
  --disable-pip-version-check \
  --requirement "$repository_root/requirements-dev.txt"
