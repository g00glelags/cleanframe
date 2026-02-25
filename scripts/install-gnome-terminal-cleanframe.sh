#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE_CONF="${REPO_DIR}/src/gnome-terminal/cleanframe-current-sharp.profile.conf"
SET_DEFAULT="false"
DRY_RUN="false"
APPLY_TO_DEFAULT_PROFILE="false"
UPDATED_EXISTING_NAMED_PROFILE="false"

usage() {
  cat <<'EOF'
Usage: install-gnome-terminal-cleanframe.sh [--set-default] [--apply-to-default-profile] [--dry-run]

Creates or updates a GNOME Terminal profile for color selection only.
Supports palette-only presets (recommended) and broader color presets.
Re-running the installer updates the existing CleanFrame profile with the same name.

Options:
  --apply-to-default-profile  Apply colors in-place to the current default GNOME Terminal profile
                              (does not create a new profile).
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
    --apply-to-default-profile)
      APPLY_TO_DEFAULT_PROFILE="true"
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
  [[ "$APPLY_TO_DEFAULT_PROFILE" == "true" ]] && forwarded_args+=(--apply-to-default-profile)

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

if [[ ! -f "$PROFILE_CONF" ]]; then
  echo "ERROR: profile preset not found: $PROFILE_CONF" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$PROFILE_CONF"
APPLY_PALETTE_ONLY="${APPLY_PALETTE_ONLY:-false}"
APPLY_HIGHLIGHT_OVERRIDE="${APPLY_HIGHLIGHT_OVERRIDE:-false}"

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

find_profile_uuid_by_visible_name() {
  local wanted_name="$1"
  local profiles_list uuid_token candidate_uuid candidate_profile_path candidate_schema candidate_name

  profiles_list="$(gsettings_get_quiet "${profiles_schema}" list)"
  if [[ -z "${profiles_list}" || "${profiles_list}" == "@as []" ]]; then
    return 1
  fi

  while IFS= read -r uuid_token; do
    candidate_uuid="${uuid_token//\'}"
    [[ -z "${candidate_uuid}" ]] && continue

    candidate_profile_path="/org/gnome/terminal/legacy/profiles:/:${candidate_uuid}/"
    candidate_schema="${profile_schema_base}:${candidate_profile_path}"
    candidate_name="$(gsettings_get_quiet "${candidate_schema}" visible-name)"

    if [[ "${candidate_name}" == "'${wanted_name}'" ]]; then
      printf '%s\n' "${candidate_uuid}"
      return 0
    fi
  done < <(printf '%s\n' "${profiles_list}" | grep -oE "'[^']+'")

  return 1
}

target_uuid=""
profile_path=""
profile_schema=""
created_new_profile="false"

if [[ "${APPLY_TO_DEFAULT_PROFILE}" == "true" ]]; then
  default_uuid_raw="$(gsettings_get_quiet "${profiles_schema}" default)"
  target_uuid="${default_uuid_raw//\'}"

  if [[ -z "${target_uuid}" ]]; then
    echo "ERROR: Could not resolve GNOME Terminal default profile UUID." >&2
    exit 1
  fi

  profile_path="/org/gnome/terminal/legacy/profiles:/:${target_uuid}/"
  profile_schema="${profile_schema_base}:${profile_path}"

  current_name="$(gsettings_get_quiet "${profile_schema}" visible-name)"
  echo "Applying GNOME Terminal colors to existing default profile:"
  echo "  UUID: ${target_uuid}"
  [[ -n "${current_name}" ]] && echo "  Name: ${current_name}"
else
  existing_uuid="$(find_profile_uuid_by_visible_name "${VISIBLE_NAME}" || true)"
  if [[ -n "${existing_uuid}" ]]; then
    target_uuid="${existing_uuid}"
    profile_path="/org/gnome/terminal/legacy/profiles:/:${target_uuid}/"
    profile_schema="${profile_schema_base}:${profile_path}"
    UPDATED_EXISTING_NAMED_PROFILE="true"

    echo "Updating existing GNOME Terminal profile (same name):"
    echo "  UUID: ${target_uuid}"
    echo "  Name: ${VISIBLE_NAME}"
  else
    if ! command -v uuidgen >/dev/null 2>&1; then
      echo "ERROR: uuidgen not found." >&2
      exit 1
    fi

    target_uuid="$(uuidgen | tr '[:upper:]' '[:lower:]')"
    profile_path="/org/gnome/terminal/legacy/profiles:/:${target_uuid}/"
    profile_schema="${profile_schema_base}:${profile_path}"
    created_new_profile="true"

    current_list="$(gsettings_get "${profiles_schema}" list)"
    if [[ "$current_list" == "@as []" ]]; then
      new_list="['${target_uuid}']"
    else
      new_list="${current_list%]}"
      if [[ "$new_list" != "[" ]]; then
        new_list="${new_list}, "
      fi
      new_list="${new_list}'${target_uuid}']"
    fi

    echo "Creating GNOME Terminal profile:"
    echo "  UUID: ${target_uuid}"
    echo "  Name: ${VISIBLE_NAME}"

    gsettings_set "${profiles_schema}" list "${new_list}"
    gsettings_set "${profile_schema}" visible-name "'${VISIBLE_NAME}'"
  fi

  if [[ "${UPDATED_EXISTING_NAMED_PROFILE}" == "true" ]]; then
    # Keep the expected visible name stable in case the user renamed it partially.
    gsettings_set "${profile_schema}" visible-name "'${VISIBLE_NAME}'"
  fi
fi

# Apply only color-related keys so this behaves as a color scheme profile.
# Also enforce infinite scrollback as a usability default for this profile.
gsettings_set "${profile_schema}" use-theme-colors "${USE_THEME_COLORS}"
gsettings_set "${profile_schema}" scrollback-unlimited "true"
gsettings_set "${profile_schema}" scrollback-lines "100000"

gsettings_set "${profile_schema}" palette "${PALETTE}"

if [[ "${APPLY_HIGHLIGHT_OVERRIDE}" == "true" ]]; then
  gsettings_set "${profile_schema}" highlight-colors-set "${HIGHLIGHT_COLORS_SET}"
  gsettings_set "${profile_schema}" highlight-background-color "${HIGHLIGHT_BACKGROUND_COLOR}"
  gsettings_set "${profile_schema}" highlight-foreground-color "${HIGHLIGHT_FOREGROUND_COLOR}"
fi

if [[ "${APPLY_PALETTE_ONLY}" != "true" ]]; then
  gsettings_set "${profile_schema}" background-color "${BACKGROUND_COLOR}"
  gsettings_set "${profile_schema}" foreground-color "${FOREGROUND_COLOR}"

  gsettings_set "${profile_schema}" bold-color "${BOLD_COLOR}"
  gsettings_set "${profile_schema}" bold-color-same-as-fg "${BOLD_COLOR_SAME_AS_FG}"
  gsettings_set "${profile_schema}" bold-is-bright "${BOLD_IS_BRIGHT}"

  gsettings_set "${profile_schema}" cursor-colors-set "${CURSOR_COLORS_SET}"
  gsettings_set "${profile_schema}" cursor-background-color "${CURSOR_BACKGROUND_COLOR}"
  gsettings_set "${profile_schema}" cursor-foreground-color "${CURSOR_FOREGROUND_COLOR}"

  if [[ "${APPLY_HIGHLIGHT_OVERRIDE}" != "true" ]]; then
    gsettings_set "${profile_schema}" highlight-colors-set "${HIGHLIGHT_COLORS_SET}"
    gsettings_set "${profile_schema}" highlight-background-color "${HIGHLIGHT_BACKGROUND_COLOR}"
    gsettings_set "${profile_schema}" highlight-foreground-color "${HIGHLIGHT_FOREGROUND_COLOR}"
  fi
fi

if [[ "${SET_DEFAULT}" == "true" ]]; then
  gsettings_set "${profiles_schema}" default "'${target_uuid}'"
  echo "Profile set as default."
fi

if [[ "${DRY_RUN}" != "true" ]]; then
  persisted_palette="$(gsettings_get_quiet "${profile_schema}" palette)"

  if [[ "${persisted_palette}" != "${PALETTE}" ]]; then
    echo "ERROR: GNOME Terminal colors were not persisted in gsettings." >&2
    echo "Likely cause: command was executed outside the user's graphical DBus session (common with sudo)." >&2
    echo "Run this command in your normal terminal session (without sudo):" >&2
    cmd_suffix=()
    [[ "${SET_DEFAULT}" == "true" ]] && cmd_suffix+=(--set-default)
    [[ "${APPLY_TO_DEFAULT_PROFILE}" == "true" ]] && cmd_suffix+=(--apply-to-default-profile)
    echo "  bash scripts/install-gnome-terminal-cleanframe.sh ${cmd_suffix[*]}" >&2
    exit 1
  fi

  if [[ "${created_new_profile}" == "true" ]]; then
    persisted_list="$(gsettings_get_quiet "${profiles_schema}" list)"
    persisted_name="$(gsettings_get_quiet "${profile_schema}" visible-name)"

    if [[ "${persisted_list}" != *"${target_uuid}"* ]] || [[ "${persisted_name}" != *"${VISIBLE_NAME}"* ]]; then
      echo "ERROR: GNOME Terminal profile metadata was not persisted in gsettings." >&2
      exit 1
    fi
  fi
fi

if [[ "${created_new_profile}" == "true" ]]; then
  echo "GNOME Terminal profile installed successfully."
  echo "Original profiles were preserved."
elif [[ "${UPDATED_EXISTING_NAMED_PROFILE}" == "true" ]]; then
  echo "GNOME Terminal profile updated successfully (existing CleanFrame profile reused)."
else
  echo "GNOME Terminal default profile updated successfully (in-place)."
fi
