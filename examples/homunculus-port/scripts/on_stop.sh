#!/bin/bash
# Homunculus v2 Stop Hook (yaml-hooks adapted)
# Updates lastSession timestamp

set -e

PROJECT_DIR="${OPENCODE_PROJECT_DIR:-.}"
STATE="$PROJECT_DIR/.opencode/homunculus/identity.json"
PENDING_DIR="$PROJECT_DIR/.opencode/homunculus/instincts/pending"

# Ensure directories exist
mkdir -p "$(dirname "$STATE")"
mkdir -p "$PENDING_DIR"

# Update lastSession timestamp
if [ -f "$STATE" ] && command -v jq >/dev/null 2>&1; then
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  TMP=$(mktemp)

  jq --arg t "$TIMESTAMP" \
    '.journey.lastSession = $t' \
    "$STATE" > "$TMP" && mv "$TMP" "$STATE"
fi

exit 0
