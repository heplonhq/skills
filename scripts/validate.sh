#!/usr/bin/env bash
# Checks each skills/<name>/SKILL.md: frontmatter is present, `name` is the
# directory name, `description` is 1-1024 characters.
# Usage: scripts/validate.sh [repo-root]
# ponytail: reads single-line `key: value` frontmatter only. Use a YAML parser
# if a skill needs a multi-line description.
set -euo pipefail
cd "${1:-$(dirname "$0")/..}"

fail=0
err() { echo "::error file=$1::$2"; fail=1; }
field() {
  awk -v k="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    index($0, k ":") == 1 { sub("^" k ":[ \t]*", ""); gsub(/^["\047]|["\047]$/, ""); print; exit }
  ' "$1"
}

count=0
for dir in skills/*/; do
  [ -d "$dir" ] || continue
  count=$((count + 1))
  name=$(basename "$dir")
  file="${dir}SKILL.md"
  [ -f "$file" ] || { err "$dir" "SKILL.md is missing"; continue; }
  echo "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' && [ ${#name} -le 64 ] ||
    err "$file" "directory name must be lowercase letters, digits and single hyphens, 64 characters maximum"
  [ "$(field "$file" name)" = "$name" ] ||
    err "$file" "frontmatter 'name' must be '$name' (the directory name)"
  desc=$(field "$file" description)
  [ -n "$desc" ] && [ ${#desc} -le 1024 ] ||
    err "$file" "frontmatter 'description' must be on one line and have 1 to 1024 characters"
done

echo "Checked $count skill(s)."
exit $fail
