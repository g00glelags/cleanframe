#! /usr/bin/env bash

set -Ee -o pipefail

on_install_error() {
  local exit_code="$1"
  local line_no="$2"
  local cmd="${3:-unknown}"

  echo
  echo "ERROR: install.sh aborted (exit=${exit_code})"
  echo "Line: ${line_no}"
  echo "Command: ${cmd}"
  echo "Hint: check permissions in '~/.themes' and '~/.config/environment.d' if the failure mentions 'Permission denied'."
}

trap 'on_install_error "$?" "$LINENO" "$BASH_COMMAND"' ERR

REPO_DIR="$(dirname "$(readlink -m "${0}")")"
source "${REPO_DIR}/core.sh"

usage() {
cat << EOF
Usage: $0 [OPTION]...

OPTIONS:
  -d, --dest DIR          Specify destination directory (Default: $DEST_DIR)
  -s, --shell VERSION     Force GNOME Shell style version (38,40,42,44,46,47,48,49)
  -A, --all               Install with full preset (--shell 49 + --sandbox)
      --flatpak           Apply Flatpak override preset (GTK_THEME + filesystem access)
      --snap              Create Snap/session env preset with GTK_THEME
      --sandbox           Apply both --flatpak and --snap presets
  -r, --remove,
  -u, --uninstall         Uninstall/Remove installed themes

  -h, --help              Show help

Como usar:

  ./install.sh -A

  ou:

  ./install.sh --shell 49 --sandbox

  ou separado:

  ./install.sh --flatpak
  ./install.sh --snap
EOF
}

print_sandbox_usage() {
  cat << EOF

Como usar:

  ./install.sh -A

  ou:

  ./install.sh --shell 49 --sandbox

  ou separado:

  ./install.sh --flatpak
  ./install.sh --snap
EOF
}

themes=('')
colors=('')
sizes=('')
apply_flatpak_preset="false"
apply_snap_preset="false"

while [[ "$#" -gt 0 ]]; do
  case "${1:-}" in
    -d|--dest)
      dest="$2"
      mkdir -p "$dest"
      shift 2
      ;;
    -s|--shell)
      case "${2:-}" in
        38|40|42|44|46|47|48|49)
          shell="$2"
          ;;
        *)
          echo "ERROR: Unsupported --shell value '${2:-}'."
          echo "Valid values: 38, 40, 42, 44, 46, 47, 48, 49."
          exit 1
          ;;
      esac
      shift 2
      ;;
    -A|--all)
      shell="49"
      apply_flatpak_preset="true"
      apply_snap_preset="true"
      shift
      ;;
    -r|--remove|-u|--uninstall)
      remove="true"
      shift
      ;;
    --flatpak)
      apply_flatpak_preset="true"
      shift
      ;;
    --snap)
      apply_snap_preset="true"
      shift
      ;;
    --sandbox)
      apply_flatpak_preset="true"
      apply_snap_preset="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unrecognized installation option '$1'."
      echo "Try '$0 --help' for more information."
      exit 1
      ;;
  esac
done

if [[ ${remove} == 'true' ]]; then
  uninstall_theme
else
  clean_theme
  install_theme
fi

print_sandbox_usage

echo
echo "Done."
