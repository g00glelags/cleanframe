#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TOTAL_ERR=0
STRICT_MODE="false"

DEFAULT_TARGETS=(
  "src/_sass/cinnamon"
  "src/_sass/gnome-shell/widgets"
)
STRICT_TARGETS=(
  "src/_sass"
)

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --strict)
      STRICT_MODE="true"
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Uso:
  bash scripts/audit-color-leaks.sh [--strict]

Modos:
  default  Audita areas centrais (cinnamon + gnome-shell/widgets) para vazamentos de cor.
  --strict Expande a cobertura para src/_sass com allowlist de excecoes conhecidas.
EOF
      exit 0
      ;;
    *)
      echo "Opcao invalida: $1" >&2
      exit 1
      ;;
  esac
done

TARGETS=("${DEFAULT_TARGETS[@]}")
if [[ "$STRICT_MODE" == "true" ]]; then
  TARGETS=("${STRICT_TARGETS[@]}")
fi

ok() {
  echo "[PASS] $*"
}

warn() {
  echo "[FAIL] $*"
  TOTAL_ERR=$((TOTAL_ERR + 1))
}

filter_strict_allowlist() {
  if [[ "$STRICT_MODE" != "true" ]]; then
    cat
    return
  fi

  # Known/intentional hardcoded palettes and app-specific visual overrides.
  rg -v \
    -e '^src/_sass/_color-palette-default\.scss:' \
    -e '^src/_sass/_colors\.scss:' \
    -e '^src/_sass/gtk/_colors-libadwaita\.scss:' \
    -e '^src/_sass/gtk/_colors-public\.scss:' \
    -e '^src/_sass/gtk/apps/_libadwaita\.scss:' \
    -e '^src/_sass/gtk/apps/_gnome-4\.0\.scss:' \
    -e '^src/_sass/gtk/apps/_xfce\.scss:' \
    -e '^src/_sass/gtk/apps/_nemo\.scss:' \
    -e '^src/_sass/gnome-shell/_extensions-46-0\.scss:' \
    -e '^src/_sass/gnome-shell/_common-3-28\.scss:'
}

scan_hex_leaks() {
  local hits
  hits="$(
    rg -n --glob '*.scss' '^\s*[-a-zA-Z]+\s*:[^/]*#[0-9A-Fa-f]{3,8}\b' "${TARGETS[@]}" \
      | filter_strict_allowlist || true
  )"

  if [[ -n "$hits" ]]; then
    warn "Hex literals found outside palette/allowed app overrides:"
    echo "$hits"
  else
    ok "No unexpected hex literals found in audited SCSS."
  fi
}

scan_named_debug_colors() {
  local hits
  hits="$(
    rg -n --glob '*.scss' '^\s*[-a-zA-Z]+\s*:.*\b(red|green|blue|yellow|orange|pink|purple)\b' "${TARGETS[@]}" \
      | filter_strict_allowlist || true
  )"

  if [[ -n "$hits" ]]; then
    warn "Potential named debug/accent color leaks found:"
    echo "$hits"
  else
    ok "No named debug/accent color leaks found in audited SCSS."
  fi
}

echo "[INFO] Mode: ${STRICT_MODE}"
echo "[INFO] Targets: ${TARGETS[*]}"

scan_hex_leaks
scan_named_debug_colors

if [[ "$TOTAL_ERR" -gt 0 ]]; then
  exit 1
fi
