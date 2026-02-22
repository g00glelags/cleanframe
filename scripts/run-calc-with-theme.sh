#!/usr/bin/env bash
set -euo pipefail

# Launch LibreOffice Calc with a dedicated GTK theme variant.

GTK_THEME_VARIANT="${GTK_THEME_VARIANT:-CleanFrame-Light-Calc}"
CALC_VCL="${CALC_VCL:-gtk3}"

if ! command -v libreoffice >/dev/null 2>&1 && ! command -v soffice >/dev/null 2>&1; then
  echo "LibreOffice nao encontrado no PATH." >&2
  exit 1
fi

LO_BIN="libreoffice"
if ! command -v libreoffice >/dev/null 2>&1; then
  LO_BIN="soffice"
fi

exec env \
  GTK_THEME="${GTK_THEME_VARIANT}" \
  SAL_USE_VCLPLUGIN="${CALC_VCL}" \
  "${LO_BIN}" --calc "$@"
