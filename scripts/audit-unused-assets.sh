#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TARGETS=("*.scss" "*.svg" "*.css")

# Files here are generated, copied by wildcard, or external integration assets.
EXCLUDE_DIRS=(
  "./.git/*"
  "./node_modules/*"
  "./original/*"
  "./src/xfwm4/svg/*"
  "./src/firefox/*"
)

EXCLUDE_FILES=(
  "./src/gnome-shell/activities/activities-default.svg"
)

is_excluded() {
  local file="$1"

  local exact
  for exact in "${EXCLUDE_FILES[@]}"; do
    if [[ "$file" == "$exact" ]]; then
      return 0
    fi
  done

  for pattern in "${EXCLUDE_DIRS[@]}"; do
    if [[ "$file" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}

reference_candidates() {
  local rel="$1"
  local base="$2"
  local ext="${rel##*.}"
  local rel_stem="${rel%.*}"
  local base_stem="${base%.*}"
  local rel_dir="${rel_stem%/*}"

  printf '%s\n' "$rel"
  printf '%s\n' "$base"
  printf '%s\n' "$rel_stem"
  printf '%s\n' "$base_stem"

  if [[ "$ext" == "scss" ]]; then
    if [[ "$base_stem" == _* ]]; then
      printf '%s\n' "${base_stem#_}"
      printf '%s\n' "${rel_dir}/${base_stem#_}"
    fi

    if [[ "$rel_stem" == *_* ]]; then
      printf '%s\n' "${rel_stem%/_*}/${base_stem#_}"
    fi
  fi
}

count_refs() {
  local total=0
  local candidate

  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] || continue
    total=$((total + $(rg -n --fixed-strings \
      --glob '!*node_modules*' \
      --glob '!*package-lock.json' \
      --glob '!*original*' \
      -- "$candidate" . | wc -l || true)))
  done

  printf '%s\n' "$total"
}

FIND_PRUNE_ARGS=(
  -path './.git' -o
  -path './node_modules' -o
  -path './original' -o
  -path './src/xfwm4/svg' -o
  -path './src/firefox'
)

echo "Unused asset candidates (reference scan):"
echo

while IFS= read -r file; do
  is_excluded "$file" && continue

  rel="${file#./}"
  base="$(basename "$file")"

  refs="$(reference_candidates "$rel" "$base" | sort -u | count_refs)"

  # Zero hits means we could not find any meaningful reference candidate in repo sources.
  if [[ "$refs" -eq 0 ]]; then
    printf '%s\n' "$rel"
  fi
done < <(
  find . \( -type d \( "${FIND_PRUNE_ARGS[@]}" \) -prune \) -o \
    \( -type f \( -name "${TARGETS[0]}" -o -name "${TARGETS[1]}" -o -name "${TARGETS[2]}" \) -print \) \
    | sort
)
