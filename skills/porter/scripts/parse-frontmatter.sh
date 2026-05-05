#!/bin/bash
# Usage: parse-frontmatter.sh <file>
# Output: YAML content between --- delimiters
FILE="$1"
awk '/^---$/{if(n++)exit;next}n' "$FILE"
