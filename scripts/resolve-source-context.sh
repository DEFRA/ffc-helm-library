#!/usr/bin/env bash

set -euo pipefail

: "${EVENT_NAME:?EVENT_NAME is required}"
: "${REF_NAME:?REF_NAME is required}"
: "${GITHUB_SHA:?GITHUB_SHA is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

requested_pr_number="${REQUESTED_PR_NUMBER:-}"

if [ -n "$requested_pr_number" ]; then
  : "${GH_TOKEN:?GH_TOKEN is required to resolve a pull request}"
  : "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
  context="$(gh api "repos/$GITHUB_REPOSITORY/pulls/$requested_pr_number" \
    --jq '[.head.sha, .head.ref, .base.sha, .base.ref, .number] | @tsv')"
  IFS=$'\t' read -r source_sha source_ref base_sha base_ref pr_number <<< "$context"
elif [ "$EVENT_NAME" = pull_request ] || [ "$EVENT_NAME" = pull_request_target ]; then
  : "${PR_HEAD_SHA:?PR_HEAD_SHA is required for pull requests}"
  : "${PR_HEAD_REF:?PR_HEAD_REF is required for pull requests}"
  : "${PR_BASE_SHA:?PR_BASE_SHA is required for pull requests}"
  : "${PR_BASE_REF:?PR_BASE_REF is required for pull requests}"
  : "${PR_NUMBER:?PR_NUMBER is required for pull requests}"
  source_sha="$PR_HEAD_SHA"
  source_ref="$PR_HEAD_REF"
  base_sha="$PR_BASE_SHA"
  base_ref="$PR_BASE_REF"
  pr_number="$PR_NUMBER"
else
  source_sha="$GITHUB_SHA"
  source_ref="$REF_NAME"
  base_sha="$GITHUB_SHA"
  base_ref=master
  pr_number=''
fi

if [ -n "$pr_number" ]; then
  trusted_ref="$base_sha"
elif [ "$source_ref" = master ]; then
  trusted_ref="$source_sha"
else
  trusted_ref=master
fi

{
  printf 'source_sha=%s\n' "$source_sha"
  printf 'source_ref=%s\n' "$source_ref"
  printf 'base_ref=%s\n' "$base_ref"
  printf 'pr_number=%s\n' "$pr_number"
  printf 'trusted_ref=%s\n' "$trusted_ref"
} >> "$GITHUB_OUTPUT"
