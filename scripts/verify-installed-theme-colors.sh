#!/usr/bin/env bash
set -euo pipefail

GTK3_CSS="${HOME}/.themes/CleanFrame-Light/gtk-3.0/gtk.css"
CINNAMON_CSS="${HOME}/.themes/CleanFrame-Light/cinnamon/cinnamon.css"

usage() {
  cat <<'EOF'
Uso:
  scripts/verify-installed-theme-colors.sh [--gtk3-css PATH] [--cinnamon-css PATH]

Valida no tema instalado:
  - botoes accent/suggested com fundo #35A854 e texto preto
  - foco/borda de entradas com #00B8FF
  - indicador ativo do windowlist do Cinnamon com #2DFF3D
  - relatorio de blocos interativos com fundo #00B8FF + texto branco (suspeitos)
EOF
}

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --gtk3-css)
      GTK3_CSS="${2:-}"
      shift 2
      ;;
    --cinnamon-css)
      CINNAMON_CSS="${2:-}"
      shift 2
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

[[ -f "$GTK3_CSS" ]] || { echo "[FAIL] gtk.css nao encontrado: $GTK3_CSS" >&2; exit 1; }
[[ -f "$CINNAMON_CSS" ]] || { echo "[FAIL] cinnamon.css nao encontrado: $CINNAMON_CSS" >&2; exit 1; }

extract_blocks() {
  local css="$1"
  awk '
    BEGIN { sel=""; cap=0 }
    {
      if (!cap) {
        sel = sel $0 ORS
        if (index($0, "{") > 0) {
          cap = 1
          print "<<<SELECTOR>>>"
          printf "%s", sel
          print "<<<BODY>>>"
          sel = ""
        }
        next
      }
      print
      if (index($0, "}") > 0) {
        print "<<<END>>>"
        cap = 0
      }
    }
  ' "$css"
}

assert_regex() {
  local label="$1"
  local regex="$2"
  local file="$3"
  if rg -n -U "$regex" "$file" >/dev/null; then
    echo "[PASS] $label"
    return 0
  fi
  echo "[FAIL] $label" >&2
  return 1
}

report_suspicious_blue_white_blocks() {
  local css="$1"
  local tmp
  tmp="$(mktemp /tmp/cleanframe-css-blocks.XXXXXX)"
  extract_blocks "$css" > "$tmp"

  awk '
    BEGIN { RS="<<<END>>>\n"; found=0 }
    {
      if ($0 !~ /<<<SELECTOR>>>/ || $0 !~ /<<<BODY>>>/) next
      split($0, parts, /<<<BODY>>>\n/)
      selector = parts[1]
      sub(/^<<<SELECTOR>>>\n/, "", selector)
      body = parts[2]

      low_sel = tolower(selector)
      low_body = tolower(body)

      interactive = (low_sel ~ /button|switch|check|radio/)
      blue_bg = (low_body ~ /background-color:[^;]*#00b8ff/)
      white_fg = (low_body ~ /color:[^;]*(#ffffff|white)/)

      if (interactive && blue_bg && white_fg) {
        found=1
        print "[WARN] Bloco interativo com fundo #00B8FF + texto branco:"
        gsub(/[[:space:]]+$/, "", selector)
        print selector
        print body
      }
    }
    END { if (!found) print "[PASS] Nenhum bloco interativo suspeito (#00B8FF + texto branco)." }
  ' "$tmp"

  rm -f "$tmp"
}

status=0

echo "[INFO] gtk.css: $GTK3_CSS"
echo "[INFO] cinnamon.css: $CINNAMON_CSS"

assert_regex "Botao suggested-action verde com texto branco (GTK3)" \
  'button\.suggested-action\s*\{[^}]*background-color:\s*#35A854;[^}]*color:\s*(#FFF|#FFFFFF);' \
  "$GTK3_CSS" || status=1

assert_regex "Botao checked verde com texto branco (GTK3)" \
  'button:checked\s*\{[^}]*background-color:\s*#35A854;[^}]*color:\s*(#FFF|#FFFFFF);' \
  "$GTK3_CSS" || status=1

assert_regex "Stackswitcher checked verde com texto branco (GTK3)" \
  'stackswitcher:not\(\.vertical\)\s*>\s*button:not\(\.suggested-action\):not\(\.destructive-action\):checked\s*\{[^}]*background-color:\s*#35A854;[^}]*color:\s*(#FFF|#FFFFFF);' \
  "$GTK3_CSS" || status=1

assert_regex "Foco/borda de entrada em #00B8FF (GTK3)" \
  '(box-shadow:\s*inset 0 0 0 2px #00B8FF;|outline:\s*2px solid #00B8FF;|border:\s*1px solid #00B8FF;)' \
  "$GTK3_CSS" || status=1

assert_regex "Cinnamon windowlist ativo em #2DFF3D" \
  '(window-list-item-box:focus[^}]*\{[^}]*#2DFF3D|border-color:\s*#2DFF3D;)' \
  "$CINNAMON_CSS" || status=1

report_suspicious_blue_white_blocks "$GTK3_CSS"

if [[ $status -ne 0 ]]; then
  echo "[FAIL] Verificacao de cores do tema instalado falhou." >&2
  exit 1
fi

echo "[OK] Verificacao de cores do tema instalado concluida."
