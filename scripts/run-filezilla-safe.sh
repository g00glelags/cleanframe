#!/usr/bin/env bash
set -euo pipefail

# Safer launcher for FileZilla when GTK theming causes DnD/inline-rename glitches.
#
# Defaults prefer compatibility:
# - fallback theme (Adwaita)
# - X11 backend
# - disable ARGB visuals (avoids black rendering artifacts in some wxGTK builds)
# - disable CSD for simpler decoration path
#
# You can override env vars when calling:
#   FILEZILLA_GTK_THEME=CleanFrame-Light ./scripts/run-filezilla-safe.sh

FILEZILLA_BIN="${FILEZILLA_BIN:-filezilla}"
FILEZILLA_GTK_THEME="${FILEZILLA_GTK_THEME:-Adwaita:light}"
FILEZILLA_GDK_BACKEND="${FILEZILLA_GDK_BACKEND:-x11}"
FILEZILLA_GSK_RENDERER="${FILEZILLA_GSK_RENDERER:-cairo}"
FILEZILLA_XLIB_SKIP_ARGB_VISUALS="${FILEZILLA_XLIB_SKIP_ARGB_VISUALS:-1}"
FILEZILLA_GTK_CSD="${FILEZILLA_GTK_CSD:-0}"

if ! command -v "${FILEZILLA_BIN}" >/dev/null 2>&1; then
  echo "FileZilla nao encontrado no PATH (${FILEZILLA_BIN})." >&2
  exit 1
fi

exec env \
  GTK_THEME="${FILEZILLA_GTK_THEME}" \
  GDK_BACKEND="${FILEZILLA_GDK_BACKEND}" \
  GSK_RENDERER="${FILEZILLA_GSK_RENDERER}" \
  XLIB_SKIP_ARGB_VISUALS="${FILEZILLA_XLIB_SKIP_ARGB_VISUALS}" \
  GTK_CSD="${FILEZILLA_GTK_CSD}" \
  "${FILEZILLA_BIN}" "$@"
