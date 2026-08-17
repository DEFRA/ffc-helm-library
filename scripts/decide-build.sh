#!/usr/bin/env bash

set -euo pipefail

: "${EVENT_NAME:?EVENT_NAME is required}"
: "${REF_NAME:?REF_NAME is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

should_build=true

if [ "$EVENT_NAME" = pull_request ]; then
  : "${PR_NUMBER:?PR_NUMBER is required for pull requests}"
  : "${GH_TOKEN:?GH_TOKEN is required for pull requests}"

  changed_files="$(gh api --paginate \
    "repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER/files?per_page=100" \
    --jq '.[].filename')"

  if ! grep -Eq \
    '^(ffc-helm-library/|tests/|scripts/|\.github/workflows/publish\.yml$)' \
    <<< "$changed_files"; then
    should_build=false
    echo '::notice title=Chart build skipped::The pull request changes no chart or pipeline files.'
  fi
elif [ "$EVENT_NAME" = push ] && [ "$REF_NAME" != master ]; then
  : "${REPOSITORY_OWNER:?REPOSITORY_OWNER is required for branch pushes}"
  : "${GH_TOKEN:?GH_TOKEN is required for branch pushes}"

  open_pr_count="$(gh api --method GET "repos/$GITHUB_REPOSITORY/pulls" \
    -f state=open \
    -f base=master \
    -f "head=$REPOSITORY_OWNER:$REF_NAME" \
    -f per_page=1 \
    --jq 'length')"

  if [ "$open_pr_count" -gt 0 ]; then
    should_build=false
    echo "::notice title=Alpha build skipped::$REF_NAME has an open pull request targeting master; its pull_request workflow publishes beta."
  fi
fi

printf 'should_build=%s\n' "$should_build" >> "$GITHUB_OUTPUT"
