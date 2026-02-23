#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CSS_FILE=""
KEEP_TMP="false"
TMP_DIR=""

usage() {
  cat <<'EOF'
Uso:
  scripts/verify-drop-target-theme.sh [--css CAMINHO] [--keep-tmp]

Sem --css:
  Gera um tema final em diretório temporário via ./install.sh e valida o gtk-3.0/gtk.css gerado.

Com --css:
  Valida diretamente um arquivo gtk.css já compilado/instalado.

Validações:
  - blocos :drop(active) para Nemo e Thunar existem no CSS final
  - blocos possuem color/background-color/border-color com !important
  - blocos não usam #f57c00 (laranja antigo) no destaque de drop desses apps
EOF
}

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --css)
      CSS_FILE="${2:-}"
      shift 2
      ;;
    --keep-tmp)
      KEEP_TMP="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERRO: opcao desconhecida: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

cleanup() {
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" && "$KEEP_TMP" != "true" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

extract_drop_blocks() {
  local css_path="$1"
  local marker="$2"

  awk -v marker="$marker" '
    BEGIN {
      selector = ""
      capturing = 0
    }
    {
      if (!capturing) {
        selector = selector $0 ORS
        if (index($0, "{") > 0) {
          if (index(selector, marker) > 0 && index(selector, ":drop(active)") > 0) {
            capturing = 1
            print selector
          }
          selector = ""
        }
        next
      }

      print
      if (index($0, "}") > 0) {
        print "<<BLOCK-END>>"
        capturing = 0
      }
    }
  ' "$css_path"
}

validate_app_blocks() {
  local app_name="$1"
  local marker="$2"
  local css_path="$3"
  local tmp_blocks

  tmp_blocks="$(mktemp /tmp/cleanframe-drop-blocks.XXXXXX)"
  extract_drop_blocks "$css_path" "$marker" > "$tmp_blocks"

  if ! grep -q '<<BLOCK-END>>' "$tmp_blocks"; then
    echo "[FAIL] $app_name: nenhum bloco :drop(active) encontrado no CSS final." >&2
    rm -f "$tmp_blocks"
    return 1
  fi

  local blocks
  blocks="$(cat "$tmp_blocks")"
  rm -f "$tmp_blocks"

  local fail=0
  if ! grep -Eq 'color:[^;]*!important' <<<"$blocks"; then
    echo "[FAIL] $app_name: color com !important nao encontrado." >&2
    fail=1
  fi
  if ! grep -Eq 'background-color:[^;]*!important' <<<"$blocks"; then
    echo "[FAIL] $app_name: background-color com !important nao encontrado." >&2
    fail=1
  fi
  if ! grep -Eq 'border-color:[^;]*!important' <<<"$blocks"; then
    echo "[FAIL] $app_name: border-color com !important nao encontrado." >&2
    fail=1
  fi
  if grep -Eiq '#f57c00' <<<"$blocks"; then
    echo "[FAIL] $app_name: bloco de drop ainda contem #f57c00." >&2
    fail=1
  fi

  echo "[INFO] $app_name: blocos encontrados no CSS final:"
  echo "$blocks" | sed '/^<<BLOCK-END>>$/d'

  if [[ $fail -eq 0 ]]; then
    echo "[PASS] $app_name"
    return 0
  fi

  return 1
}

validate_global_treeview_drop() {
  local css_path="$1"
  local block

  block="$(awk '
    BEGIN { capture=0 }
    /^treeview\.view:drop\(active\)[[:space:]]*\{/ { capture=1 }
    capture { print }
    capture && /\}/ { exit }
  ' "$css_path")"

  if [[ -z "$block" ]]; then
    echo "[FAIL] Global treeview.view:drop(active): bloco nao encontrado." >&2
    return 1
  fi

  local fail=0
  if grep -Eiq '#f57c00' <<<"$block"; then
    echo "[FAIL] Global treeview.view:drop(active): ainda contem #f57c00." >&2
    fail=1
  fi
  if ! grep -Eq 'border-color:[^;]*#' <<<"$block"; then
    echo "[FAIL] Global treeview.view:drop(active): border-color nao encontrado." >&2
    fail=1
  fi

  echo "[INFO] Global treeview.view:drop(active):"
  echo "$block"

  [[ $fail -eq 0 ]]
}

if [[ -z "$CSS_FILE" ]]; then
  TMP_DIR="$(mktemp -d /tmp/cleanframe-theme-verify.XXXXXX)"
  DEST_DIR="$TMP_DIR/themes"
  mkdir -p "$DEST_DIR"

  echo "[INFO] Gerando tema final em: $DEST_DIR"
  (cd "$ROOT_DIR" && bash ./install.sh -d "$DEST_DIR" >/tmp/cleanframe-install-verify.log 2>&1) || {
    echo "[FAIL] install.sh falhou. Log:" >&2
    cat /tmp/cleanframe-install-verify.log >&2
    exit 1
  }

  CSS_FILE="$(find "$DEST_DIR" -path '*/gtk-3.0/gtk.css' | head -n 1)"
  if [[ -z "$CSS_FILE" || ! -f "$CSS_FILE" ]]; then
    echo "[FAIL] gtk-3.0/gtk.css nao encontrado no tema final gerado." >&2
    exit 1
  fi
fi

if [[ ! -f "$CSS_FILE" ]]; then
  echo "[FAIL] Arquivo CSS nao encontrado: $CSS_FILE" >&2
  exit 1
fi

echo "[INFO] Validando CSS: $CSS_FILE"

status=0
validate_global_treeview_drop "$CSS_FILE" || status=1
validate_app_blocks "Nemo" ".nemo-window" "$CSS_FILE" || status=1
validate_app_blocks "Thunar" ".thunar" "$CSS_FILE" || status=1

if [[ $status -ne 0 ]]; then
  echo "[FAIL] Validacao de drop target falhou." >&2
  exit 1
fi

echo "[OK] Validacao concluida: override de drop target presente no tema final (GTK3)."
