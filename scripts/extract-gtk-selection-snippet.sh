#!/usr/bin/env bash
set -euo pipefail

# Extracts app selection colors from GTK CSS exports and prints snippets for
# external apps (VSCode / Electron / Teams) without accidentally using accent/focus.

SCRIPT_NAME="$(basename "$0")"
FORMAT="all"
CSS_FILES=()

usage() {
  cat <<EOF
Uso:
  ${SCRIPT_NAME} [--css FILE]... [--format FORMATO]

Objetivo:
  Extrair a cor de selecao de app do GTK (priorizando aliases do CleanFrame)
  e gerar snippets prontos para VSCode e apps Electron (ex.: Teams).

Opcoes:
  --css FILE        Arquivo CSS para leitura (pode repetir). Se omitido, usa auto-detect.
  --format VALOR    all | values | vscode | electron | env (padrao: all)
  -h, --help        Exibe esta ajuda

Busca (ordem):
  1) ~/.config/gtk-4.0/gtk.css
  2) ~/.config/gtk-3.0/gtk.css
  3) ~/.themes/CleanFrame-Light/gtk-4.0/gtk.css
  4) ~/.themes/CleanFrame-Light/gtk-3.0/gtk.css
EOF
}

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'ERRO: %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --css)
      [[ -n "${2:-}" ]] || die "Informe um caminho para --css"
      CSS_FILES+=("${2}")
      shift 2
      ;;
    --format)
      FORMAT="${2:-}"
      [[ -n "${FORMAT}" ]] || die "Informe um valor para --format"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Opcao invalida: $1"
      ;;
  esac
done

case "${FORMAT}" in
  all|values|vscode|electron|env)
    ;;
  *)
    die "Formato invalido '${FORMAT}'. Use: all, values, vscode, electron, env"
    ;;
esac

if [[ ${#CSS_FILES[@]} -eq 0 ]]; then
  for f in \
    "${HOME}/.config/gtk-4.0/gtk.css" \
    "${HOME}/.config/gtk-3.0/gtk.css" \
    "${HOME}/.themes/CleanFrame-Light/gtk-4.0/gtk.css" \
    "${HOME}/.themes/CleanFrame-Light/gtk-3.0/gtk.css"
  do
    [[ -f "${f}" ]] && CSS_FILES+=("${f}")
  done
fi

[[ ${#CSS_FILES[@]} -gt 0 ]] || die "Nenhum gtk.css encontrado. Use --css FILE."

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

extract_define_color() {
  local css_file="$1"
  local key="$2"
  awk -v key="$key" '
    BEGIN { IGNORECASE=1 }
    {
      if (match($0, "^[[:space:]]*@define-color[[:space:]]+" key "[[:space:]]+([^;]+);[[:space:]]*$", m)) {
        print m[1]
        exit
      }
    }
  ' "$css_file" 2>/dev/null || true
}

extract_css_var() {
  local css_file="$1"
  local key="$2"
  awk -v key="$key" '
    BEGIN { IGNORECASE=1 }
    {
      if (match($0, "^[[:space:]]*" key "[[:space:]]*:[[:space:]]*([^;]+);[[:space:]]*$", m)) {
        print m[1]
        exit
      }
    }
  ' "$css_file" 2>/dev/null || true
}

normalize_color() {
  local value
  value="$(trim "${1:-}")"
  value="${value#\'}"
  value="${value%\'}"
  # Collapse internal spaces for rgb()/rgba() variants.
  value="$(printf '%s' "$value" | tr -d '[:space:]')"
  printf '%s' "$value"
}

hex_to_upper() {
  local value="${1:-}"
  if [[ "$value" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    printf '%s' "${value^^}"
  else
    printf '%s' "$value"
  fi
}

selection_bg=""
selection_fg=""
bg_source=""
fg_source=""

for css_file in "${CSS_FILES[@]}"; do
  if [[ -z "${selection_bg}" ]]; then
    for key in cleanframe_app_selection_bg_color theme_selected_bg_color selected_bg_color text_selected_bg_color; do
      if [[ "$key" == --* ]]; then
        candidate="$(extract_css_var "$css_file" "$key")"
      else
        candidate="$(extract_define_color "$css_file" "$key")"
      fi
      candidate="$(normalize_color "$candidate")"
      if [[ -n "$candidate" ]]; then
        selection_bg="$candidate"
        bg_source="${css_file} :: ${key}"
        break
      fi
    done

    if [[ -z "${selection_bg}" ]]; then
      for key in --cleanframe-app-selection-bg; do
        candidate="$(extract_css_var "$css_file" "$key")"
        candidate="$(normalize_color "$candidate")"
        if [[ -n "$candidate" ]]; then
          selection_bg="$candidate"
          bg_source="${css_file} :: ${key}"
          break
        fi
      done
    fi
  fi

  if [[ -z "${selection_fg}" ]]; then
    for key in cleanframe_app_selection_fg_color theme_selected_fg_color selected_fg_color text_selected_fg_color; do
      candidate="$(extract_define_color "$css_file" "$key")"
      candidate="$(normalize_color "$candidate")"
      if [[ -n "$candidate" ]]; then
        selection_fg="$candidate"
        fg_source="${css_file} :: ${key}"
        break
      fi
    done

    if [[ -z "${selection_fg}" ]]; then
      for key in --cleanframe-app-selection-fg; do
        candidate="$(extract_css_var "$css_file" "$key")"
        candidate="$(normalize_color "$candidate")"
        if [[ -n "$candidate" ]]; then
          selection_fg="$candidate"
          fg_source="${css_file} :: ${key}"
          break
        fi
      done
    fi
  fi
done

[[ -n "${selection_bg}" ]] || die "Nao foi possivel extrair a cor de selecao (background)."
[[ -n "${selection_fg}" ]] || selection_fg="#000000"

selection_bg="$(hex_to_upper "${selection_bg}")"
selection_fg="$(hex_to_upper "${selection_fg}")"

print_values() {
  cat <<EOF
[INFO] Arquivos analisados:
$(printf ' - %s\n' "${CSS_FILES[@]}")
[OK] Selecao de app extraida do GTK
  background: ${selection_bg}
  foreground: ${selection_fg}
  bg source : ${bg_source}
  fg source : ${fg_source:-fallback}
EOF
}

print_env() {
  cat <<EOF
export CLEANFRAME_APP_SELECTION_BG='${selection_bg}'
export CLEANFRAME_APP_SELECTION_FG='${selection_fg}'
EOF
}

print_vscode() {
  cat <<EOF
{
  "workbench.colorCustomizations": {
    "editor.selectionBackground": "${selection_bg}",
    "editor.inactiveSelectionBackground": "${selection_bg}",
    "list.activeSelectionBackground": "${selection_bg}",
    "list.inactiveSelectionBackground": "${selection_bg}",
    "list.hoverBackground": "${selection_bg}",
    "list.activeSelectionForeground": "${selection_fg}",
    "list.inactiveSelectionForeground": "${selection_fg}",
    "list.hoverForeground": "${selection_fg}",
    "quickInputList.focusBackground": "${selection_bg}",
    "quickInputList.focusForeground": "${selection_fg}"
  }
}
EOF
}

print_electron() {
  cat <<EOF
/* Generic Electron/Chromium snippet (Teams, wrappers, custom CSS loaders) */
:root {
  --cleanframe-app-selection-bg: ${selection_bg};
  --cleanframe-app-selection-fg: ${selection_fg};
}

::selection {
  background: var(--cleanframe-app-selection-bg) !important;
  color: var(--cleanframe-app-selection-fg) !important;
}

input::selection,
textarea::selection,
[contenteditable="true"]::selection {
  background: var(--cleanframe-app-selection-bg) !important;
  color: var(--cleanframe-app-selection-fg) !important;
}
EOF
}

case "${FORMAT}" in
  values)
    print_values
    ;;
  env)
    print_env
    ;;
  vscode)
    print_values
    echo
    print_vscode
    ;;
  electron)
    print_values
    echo
    print_electron
    ;;
  all)
    print_values
    echo
    echo "### VSCode (settings.json)"
    print_vscode
    echo
    echo "### Electron / Teams (CSS)"
    print_electron
    echo
    echo "### Shell exports"
    print_env
    ;;
esac

