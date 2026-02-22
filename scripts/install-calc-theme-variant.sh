#!/usr/bin/env bash
set -euo pipefail

# Creates a dedicated GTK theme variant for LibreOffice Calc, keeping
# system-wide selection colors unchanged.

BASE_THEME="${BASE_THEME:-CleanFrame-Light}"
VARIANT_THEME="${VARIANT_THEME:-CleanFrame-Light-Calc}"
CALC_SELECTION_BG="${CALC_SELECTION_BG:-#00b8ff}"
CALC_SELECTION_FG="${CALC_SELECTION_FG:-#000000}"
DEST_DIR="${DEST_DIR:-}"

detect_default_dest() {
  if [[ -n "${XDG_DATA_HOME:-}" ]]; then
    echo "${XDG_DATA_HOME}/themes"
  elif [[ -d "${HOME}/.themes" ]]; then
    echo "${HOME}/.themes"
  else
    echo "${HOME}/.local/share/themes"
  fi
}

usage() {
  cat <<EOF
Uso:
  $0 [--dest DIR] [--base NOME] [--variant NOME] [--bg HEX] [--fg HEX]

Exemplos:
  $0
  $0 --base CleanFrame-Light --variant CleanFrame-Light-Calc --bg '#00b8ff'
EOF
}

while [[ $# -gt 0 ]]; do
  case "${1}" in
    --dest)
      DEST_DIR="${2:-}"
      shift 2
      ;;
    --base)
      BASE_THEME="${2:-}"
      shift 2
      ;;
    --variant)
      VARIANT_THEME="${2:-}"
      shift 2
      ;;
    --bg)
      CALC_SELECTION_BG="${2:-}"
      shift 2
      ;;
    --fg)
      CALC_SELECTION_FG="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Opcao invalida: ${1}" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${DEST_DIR}" ]]; then
  DEST_DIR="$(detect_default_dest)"
fi

mkdir -p "${DEST_DIR}"

BASE_DIR="${DEST_DIR}/${BASE_THEME}"
VARIANT_DIR="${DEST_DIR}/${VARIANT_THEME}"

if [[ ! -d "${BASE_DIR}" ]]; then
  echo "Tema base nao encontrado: ${BASE_DIR}" >&2
  echo "Instale primeiro com ./install.sh" >&2
  exit 1
fi

echo "Criando variante '${VARIANT_THEME}' em '${DEST_DIR}'..."
rm -rf "${VARIANT_DIR}" "${VARIANT_DIR}-hdpi" "${VARIANT_DIR}-xhdpi"
cp -a "${BASE_DIR}" "${VARIANT_DIR}"

if [[ -d "${DEST_DIR}/${BASE_THEME}-hdpi" ]]; then
  cp -a "${DEST_DIR}/${BASE_THEME}-hdpi" "${DEST_DIR}/${VARIANT_THEME}-hdpi"
fi
if [[ -d "${DEST_DIR}/${BASE_THEME}-xhdpi" ]]; then
  cp -a "${DEST_DIR}/${BASE_THEME}-xhdpi" "${DEST_DIR}/${VARIANT_THEME}-xhdpi"
fi

if [[ -f "${VARIANT_DIR}/index.theme" ]]; then
  sed -i \
    -e "s/^Name=.*/Name=${VARIANT_THEME}/" \
    -e "s/^GtkTheme=.*/GtkTheme=${VARIANT_THEME}/" \
    -e "s/^MetacityTheme=.*/MetacityTheme=${VARIANT_THEME}/" \
    "${VARIANT_DIR}/index.theme"
fi

patch_gtk_css() {
  local css_file="$1"
  [[ -f "${css_file}" ]] || return 0

  sed -E -i \
    -e "s/@define-color[[:space:]]+theme_selected_bg_color[[:space:]]+[^;]+;/@define-color theme_selected_bg_color ${CALC_SELECTION_BG};/g" \
    -e "s/@define-color[[:space:]]+theme_unfocused_selected_bg_color[[:space:]]+[^;]+;/@define-color theme_unfocused_selected_bg_color ${CALC_SELECTION_BG};/g" \
    -e "s/@define-color[[:space:]]+theme_selected_fg_color[[:space:]]+[^;]+;/@define-color theme_selected_fg_color ${CALC_SELECTION_FG};/g" \
    -e "s/@define-color[[:space:]]+theme_unfocused_selected_fg_color[[:space:]]+[^;]+;/@define-color theme_unfocused_selected_fg_color ${CALC_SELECTION_FG};/g" \
    "${css_file}"
}

patch_gtk_css "${VARIANT_DIR}/gtk-3.0/gtk.css"
patch_gtk_css "${VARIANT_DIR}/gtk-4.0/gtk.css"

if [[ -f "${VARIANT_DIR}/gtk-2.0/gtkrc" ]]; then
  sed -E -i \
    -e "s/selected_bg_color:[^\"\\\\]+/selected_bg_color:${CALC_SELECTION_BG}/g" \
    -e "s/selected_fg_color:[^\"\\\\]+/selected_fg_color:${CALC_SELECTION_FG}/g" \
    "${VARIANT_DIR}/gtk-2.0/gtkrc"
fi

echo "OK: variante pronta."
echo "Tema base   : ${BASE_THEME}"
echo "Tema calc   : ${VARIANT_THEME}"
echo "Selecao bg  : ${CALC_SELECTION_BG}"
echo "Selecao fg  : ${CALC_SELECTION_FG}"
