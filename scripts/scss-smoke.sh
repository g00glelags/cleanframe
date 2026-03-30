#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d /tmp/cleanframe-scss-smoke.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT
source "${ROOT_DIR}/scripts/lib/metadata.sh"

if ! command -v sassc >/dev/null 2>&1; then
  echo "ERROR: sassc not found in PATH." >&2
  exit 1
fi

SASSC_OPT='-M -t expanded'
SASS_OPT='--no-source-map --style=expanded --silence-deprecation=import,global-builtin,color-functions,slash-div,if-function,strict-unary'
MODE="${1:-default}"

detect_sass_compiler() {
  if command -v sass >/dev/null 2>&1; then
    echo "sass"
    return
  fi

  if command -v npx >/dev/null 2>&1 && npx sass --version >/dev/null 2>&1; then
    echo "npx-sass"
    return
  fi

  if command -v sassc >/dev/null 2>&1; then
    echo "sassc"
    return
  fi

  echo ""
}

SASS_COMPILER="$(detect_sass_compiler)"

if [[ -z "$SASS_COMPILER" ]]; then
  echo "ERROR: no Sass compiler found (sass, npx sass, sassc)." >&2
  exit 1
fi

compile() {
  local input="$1"
  local out_name="$2"
  local output="$TMP_DIR/$out_name"

  echo "[smoke] compiling $input"
  case "$SASS_COMPILER" in
    sass)
      sass $SASS_OPT "$ROOT_DIR/$input:$output"
      ;;
    npx-sass)
      npx sass $SASS_OPT "$ROOT_DIR/$input:$output"
      ;;
    sassc)
      sassc $SASSC_OPT "$ROOT_DIR/$input" "$output"
      ;;
  esac
}

compile "src/gtk/3.0/gtk.scss" "gtk-3.0.css"
compile "src/gtk/4.0/gtk.scss" "gtk-4.0.css"
compile "src/cinnamon/cinnamon.scss" "cinnamon.css"

if [[ "$MODE" == "--all" ]]; then
  for shell_scss in "$ROOT_DIR"/src/gnome-shell/shell-*/gnome-shell.scss; do
    version_dir="$(basename "$(dirname "$shell_scss")")"
    compile "src/gnome-shell/$version_dir/gnome-shell.scss" "$version_dir.css"
  done
else
  if command -v gnome-shell >/dev/null 2>&1; then
    shell_major="$(gnome-shell --version | awk '{print $3}' | cut -d. -f1)"
  else
    shell_major="$(latest_supported_gnome_shell_major)"
  fi

  shell_major="$(resolve_gnome_shell_major "$shell_major")"
  shell_dir="shell-$(gnome_shell_dir_from_major "$shell_major")"

  compile "src/gnome-shell/${shell_dir}/gnome-shell.scss" "${shell_dir}.css"
fi

echo "[smoke] OK: all SCSS entrypoints compiled successfully"
