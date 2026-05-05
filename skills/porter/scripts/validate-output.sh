#!/bin/bash
# Usage: validate-output.sh <file>
# Exit 0 if valid, non-zero with errors printed to stderr
FILE="$1"
ERRORS=0

# Check frontmatter exists
if ! head -1 "$FILE" | grep -q "^---$"; then
  echo "ERROR: Missing opening frontmatter delimiter" >&2
  ERRORS=$((ERRORS + 1))
fi

# Check name format (SKILL.md only)
if [[ "$(basename "$FILE")" == "SKILL.md" ]]; then
  NAME=$(awk '/^---$/{if(n++)exit;next}n' "$FILE" | grep "^name:" | sed 's/name: *//')
  if [[ -z "$NAME" ]]; then
    echo "ERROR: Missing required field 'name'" >&2
    ERRORS=$((ERRORS + 1))
  elif ! echo "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    echo "ERROR: Name '$NAME' does not match required pattern" >&2
    ERRORS=$((ERRORS + 1))
  fi
fi

# Check description exists
if ! awk '/^---$/{if(n++)exit;next}n' "$FILE" | grep -q "^description:"; then
  echo "ERROR: Missing required field 'description'" >&2
  ERRORS=$((ERRORS + 1))
fi

# Check description length
DESC=$(awk '/^---$/{if(n++)exit;next}n' "$FILE" | grep "^description:" | sed 's/description: *//')
if [[ ${#DESC} -gt 1024 ]]; then
  echo "ERROR: Description exceeds 1024 characters (${#DESC})" >&2
  ERRORS=$((ERRORS + 1))
fi

if [[ $ERRORS -eq 0 ]]; then
  echo "VALID" >&1
fi
exit $ERRORS
