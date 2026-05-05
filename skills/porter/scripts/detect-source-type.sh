#!/bin/bash
# Usage: detect-source-type.sh <file>
# Output: skill | agent | command | unknown
FILE="$1"
if [[ "$(basename "$FILE")" == "SKILL.md" ]]; then
  echo "skill"
elif echo "$FILE" | grep -qE '/(agents?)/'; then
  echo "agent"
elif echo "$FILE" | grep -qE '/(commands?)/'; then
  echo "command"
elif grep -q "^tools:" "$FILE" 2>/dev/null; then
  echo "agent"
elif grep -q "^description:" "$FILE" 2>/dev/null; then
  echo "command"
else
  echo "unknown"
fi
