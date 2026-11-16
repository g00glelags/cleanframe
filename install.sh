#! /usr/bin/env bash

REPO_DIR="$(dirname "$(readlink -m "${0}")")"
source "${REPO_DIR}/core.sh"

usage() {
cat << EOF
Usage: $0 [OPTION]...

OPTIONS:
  -d, --dest DIR          Specify destination directory (Default: $DEST_DIR)
  -s, --shell VERSION     Force GNOME Shell style version (38,40,42,44,46,47,48,49)
  -A, --all               Install with full preset (--shell 49 + --sandbox + GNOME Terminal profile + --libadwaita)
  -l, --libadwaita, --link Link theme to ~/.config/gtk-4.0 for Libadwaita apps
      --gnome-terminal-colors          Install/update CleanFrame GNOME Terminal color preset (selectable profile, no duplicates on reinstall)
      --gnome-terminal-colors-default  Install/update color preset and set as GNOME Terminal default (enabled by default)
      --gnome-terminal-colors-inplace  Apply CleanFrame GNOME Terminal colors to existing default profile (no new profile)
      --gnome-terminal-profile         Alias for --gnome-terminal-colors
      --gnome-terminal-profile-default Alias for --gnome-terminal-colors-default
      --no-terminal,
      --no-gnome-terminal              Skip GNOME Terminal light profile configuration
      --flatpak           Apply Flatpak override preset (GTK_THEME + filesystem access)
      --snap              Create Snap/session env preset with GTK_THEME
      --sandbox           Apply both --flatpak and --snap presets
      --optimize          Apply CSS optimizations (minification, duplicate removal)
      --no-optimize       Skip CSS optimizations (for compatibility testing)
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
link_libadwaita_enabled="false"
install_gnome_terminal_profile="true"
set_default_gnome_terminal_profile="true"
apply_gnome_terminal_colors_inplace="false"
ENABLE_CSS_OPTIMIZATION="false"

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
      link_libadwaita_enabled="true"
      install_gnome_terminal_profile="true"
      shift
      ;;
    -l|--libadwaita|--link)
      link_libadwaita_enabled="true"
      shift
      ;;
    --gnome-terminal-colors|--gnome-terminal-profile)
      install_gnome_terminal_profile="true"
      shift
      ;;
    --gnome-terminal-colors-default|--gnome-terminal-profile-default)
      install_gnome_terminal_profile="true"
      set_default_gnome_terminal_profile="true"
      shift
      ;;
    --gnome-terminal-colors-inplace)
      install_gnome_terminal_profile="true"
      apply_gnome_terminal_colors_inplace="true"
      shift
      ;;
    --no-terminal|--no-gnome-terminal)
      install_gnome_terminal_profile="false"
      set_default_gnome_terminal_profile="false"
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
    --optimize)
      ENABLE_CSS_OPTIMIZATION="true"
      shift
      ;;
    --no-optimize)
      ENABLE_CSS_OPTIMIZATION="false"
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
  uninstall_link
else
  # Validate prerequisites before proceeding with build/install flows
  if ! validate_prerequisites; then
    echo "❌ Prerequisites validation failed. Please install required tools."
    exit 1
  fi

  # Show system information for debugging
  show_system_info

  # Export optimization flag for child scripts
  export ENABLE_CSS_OPTIMIZATION

  uninstall_theme
  install_theme
  if [[ "${link_libadwaita_enabled}" == "true" ]]; then
    link_theme
  fi
  if [[ "${install_gnome_terminal_profile}" == "true" ]]; then
    install_gnome_terminal_profile_from_project "${set_default_gnome_terminal_profile}" "${apply_gnome_terminal_colors_inplace}"
  fi
fi

print_sandbox_usage

echo
echo "Done."
