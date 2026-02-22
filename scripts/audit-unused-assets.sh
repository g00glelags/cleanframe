#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TARGETS=("*.scss" "*.svg" "*.css")

# Files here are generated, copied by wildcard, or external integration assets.
EXCLUDE_DIRS=(
  "./node_modules/*"
  "./src/xfwm4/svg/*"
  "./src/firefox/*"
)

is_excluded() {
  local file="$1"
  for pattern in "${EXCLUDE_DIRS[@]}"; do
    if [[ "$file" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}

echo "Unused asset candidates (reference scan):"
echo

while IFS= read -r file; do
  is_excluded "$file" && continue

  rel="${file#./}"
  base="$(basename "$file")"

  # Count references excluding this file path itself.
  refs=$(rg -n --fixed-strings --glob '!*node_modules*' --glob '!*package-lock.json' -- "$rel" . | wc -l || true)
  refs_base=$(rg -n --fixed-strings --glob '!*node_modules*' --glob '!*package-lock.json' -- "$base" . | wc -l || true)

  # One hit is usually the file listing from scan itself; require >1 meaningful hit.
  if [[ "$refs" -eq 0 && "$refs_base" -le 1 ]]; then
    echo "$rel"
  fi
done < <(find . -type f \( -name "${TARGETS[0]}" -o -name "${TARGETS[1]}" -o -name "${TARGETS[2]}" \) | sort)
