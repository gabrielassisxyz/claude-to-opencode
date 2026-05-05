#!/bin/bash
# Homunculus v2 Start Hook (yaml-hooks adapted)
# Detects new session start and increments counter

set -e

PROJECT_DIR="${OPENCODE_PROJECT_DIR:-.}"
STATE="$PROJECT_DIR/.opencode/homunculus/identity.json"
PENDING_DIR="$PROJECT_DIR/.opencode/homunculus/instincts/pending"

# Ensure directories exist
mkdir -p "$(dirname "$STATE")"
mkdir -p "$PENDING_DIR"

# Update session count if new session (lastSession > 5 min ago)
if [ -f "$STATE" ] && command -v jq >/dev/null 2>&1; then
  LAST_SESSION=$(jq -r ".journey.lastSession // empty" "$STATE")
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Check if lastSession is more than 5 minutes ago
  IS_NEW_SESSION=1
  if [ -n "$LAST_SESSION" ]; then
    LAST_EPOCH=$(date -d "$LAST_SESSION" +%s 2>/dev/null || echo "0")
    NOW_EPOCH=$(date -d "$TIMESTAMP" +%s)
    DIFF=$((NOW_EPOCH - LAST_EPOCH))
    if [ "$DIFF" -lt 300 ]; then
      IS_NEW_SESSION=0
    fi
  fi

  if [ "$IS_NEW_SESSION" -eq 1 ]; then
    COUNT=$(jq -r ".journey.sessionCount // 0" "$STATE")
    TMP=$(mktemp)
    jq --arg c "$((COUNT+1))" --arg t "$TIMESTAMP" \
      '.journey.sessionCount = ($c|tonumber) | .journey.lastSession = $t' \
      "$STATE" > "$TMP" && mv "$TMP" "$STATE"
  fi
fi

exit 0
