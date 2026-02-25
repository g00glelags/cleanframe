#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_CONF="${REPO_DIR}/src/gnome-terminal/cleanframe-current-sharp.profile.conf"
SET_DEFAULT="false"
DRY_RUN="false"

usage() {
  cat <<'EOF'
Usage: install-gnome-terminal-cleanframe.sh [--set-default] [--dry-run]

Creates a new GNOME Terminal profile for color selection only.
Supports palette-only presets (recommended) and broader color presets.
The original GNOME Terminal profile is not overwritten.
EOF
}

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --set-default)
      SET_DEFAULT="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$UID" -eq 0 && -n "${SUDO_USER:-}" ]]; then
  target_uid="$(id -u "$SUDO_USER" 2>/dev/null || true)"
  runtime_dir="/run/user/${target_uid}"
  forwarded_args=()

  [[ "$SET_DEFAULT" == "true" ]] && forwarded_args+=(--set-default)
  [[ "$DRY_RUN" == "true" ]] && forwarded_args+=(--dry-run)

  if [[ -n "$target_uid" && -S "${runtime_dir}/bus" ]]; then
    echo "Re-executando como usuario '${SUDO_USER}' na sessao grafica (DBus)..."
    exec sudo -u "$SUDO_USER" env \
      XDG_RUNTIME_DIR="$runtime_dir" \
      DBUS_SESSION_BUS_ADDRESS="unix:path=${runtime_dir}/bus" \
      bash "$0" "${forwarded_args[@]}"
  fi

  echo "ERROR: Executado com sudo, mas a sessao DBus do usuario nao foi encontrada." >&2
  echo "Rode sem sudo no terminal da sua sessao grafica:" >&2
  if [[ "$SET_DEFAULT" == "true" ]]; then
    echo "  bash scripts/install-gnome-terminal-cleanframe.sh --set-default" >&2
  else
    echo "  bash scripts/install-gnome-terminal-cleanframe.sh" >&2
  fi
  exit 1
fi

if ! command -v gsettings >/dev/null 2>&1; then
  echo "ERROR: gsettings not found." >&2
  exit 1
fi

if ! command -v uuidgen >/dev/null 2>&1; then
  echo "ERROR: uuidgen not found." >&2
  exit 1
fi

if [[ ! -f "$PROFILE_CONF" ]]; then
  echo "ERROR: profile preset not found: $PROFILE_CONF" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$PROFILE_CONF"
APPLY_PALETTE_ONLY="${APPLY_PALETTE_ONLY:-false}"

profiles_schema="org.gnome.Terminal.ProfilesList"
profile_schema_base="org.gnome.Terminal.Legacy.Profile"

gsettings_get() {
  gsettings get "$@"
}

gsettings_set() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "gsettings set $*"
    return 0
  fi
  gsettings set "$@"
}

gsettings_get_quiet() {
  gsettings get "$@" 2>/dev/null || true
}

new_uuid="$(uuidgen | tr '[:upper:]' '[:lower:]')"
profile_path="/org/gnome/terminal/legacy/profiles:/:${new_uuid}/"
profile_schema="${profile_schema_base}:${profile_path}"

current_list="$(gsettings_get "${profiles_schema}" list)"
if [[ "$current_list" == "@as []" ]]; then
  new_list="['${new_uuid}']"
else
  new_list="${current_list%]}"
  if [[ "$new_list" != "[" ]]; then
    new_list="${new_list}, "
  fi
  new_list="${new_list}'${new_uuid}']"
fi

echo "Creating GNOME Terminal profile:"
echo "  UUID: ${new_uuid}"
echo "  Name: ${VISIBLE_NAME}"

gsettings_set "${profiles_schema}" list "${new_list}"
gsettings_set "${profile_schema}" visible-name "'${VISIBLE_NAME}'"

# Apply only color-related keys so this behaves as a color scheme profile.
gsettings_set "${profile_schema}" use-theme-colors "${USE_THEME_COLORS}"

gsettings_set "${profile_schema}" palette "${PALETTE}"

if [[ "${APPLY_PALETTE_ONLY}" != "true" ]]; then
  gsettings_set "${profile_schema}" background-color "${BACKGROUND_COLOR}"
  gsettings_set "${profile_schema}" foreground-color "${FOREGROUND_COLOR}"

  gsettings_set "${profile_schema}" bold-color "${BOLD_COLOR}"
  gsettings_set "${profile_schema}" bold-color-same-as-fg "${BOLD_COLOR_SAME_AS_FG}"
  gsettings_set "${profile_schema}" bold-is-bright "${BOLD_IS_BRIGHT}"

  gsettings_set "${profile_schema}" cursor-colors-set "${CURSOR_COLORS_SET}"
  gsettings_set "${profile_schema}" cursor-background-color "${CURSOR_BACKGROUND_COLOR}"
  gsettings_set "${profile_schema}" cursor-foreground-color "${CURSOR_FOREGROUND_COLOR}"

  gsettings_set "${profile_schema}" highlight-colors-set "${HIGHLIGHT_COLORS_SET}"
  gsettings_set "${profile_schema}" highlight-background-color "${HIGHLIGHT_BACKGROUND_COLOR}"
  gsettings_set "${profile_schema}" highlight-foreground-color "${HIGHLIGHT_FOREGROUND_COLOR}"
fi

if [[ "${SET_DEFAULT}" == "true" ]]; then
  gsettings_set "${profiles_schema}" default "'${new_uuid}'"
  echo "Profile set as default."
fi

if [[ "${DRY_RUN}" != "true" ]]; then
  persisted_list="$(gsettings_get_quiet "${profiles_schema}" list)"
  persisted_name="$(gsettings_get_quiet "${profile_schema}" visible-name)"

  if [[ "${persisted_list}" != *"${new_uuid}"* ]] || [[ "${persisted_name}" != *"${VISIBLE_NAME}"* ]]; then
    echo "ERROR: GNOME Terminal profile was not persisted in gsettings." >&2
    echo "Likely cause: command was executed outside the user's graphical DBus session (common with sudo)." >&2
    echo "Run this command in your normal terminal session (without sudo):" >&2
    if [[ "${SET_DEFAULT}" == "true" ]]; then
      echo "  bash scripts/install-gnome-terminal-cleanframe.sh --set-default" >&2
    else
      echo "  bash scripts/install-gnome-terminal-cleanframe.sh" >&2
    fi
    exit 1
  fi
fi

echo "GNOME Terminal profile installed successfully."
echo "Original profiles were preserved."
