#!/usr/bin/env bash

set -euo pipefail

: "${EVENT_NAME:?EVENT_NAME is required}"
: "${REF_NAME:?REF_NAME is required}"
: "${REQUESTED_CHANNEL:=auto}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

channel="$REQUESTED_CHANNEL"
if [ "$channel" = auto ]; then
  if [ "$EVENT_NAME" = merge_group ]; then
    channel=validation
  elif [ "$EVENT_NAME" = pull_request ] || [ "$EVENT_NAME" = pull_request_target ]; then
    channel=beta
  elif [ "$REF_NAME" = master ]; then
    channel=release
  else
    channel=alpha
  fi
fi

case "$channel" in
  alpha|beta|release|validation) ;;
  *)
    echo "Unsupported package channel: $channel" >&2
    exit 1
    ;;
esac

if [ "$channel" = release ] && [ "$REF_NAME" != master ]; then
  echo 'The release channel is allowed only on master.' >&2
  exit 1
fi

printf 'channel=%s\n' "$channel" >> "$GITHUB_OUTPUT"
