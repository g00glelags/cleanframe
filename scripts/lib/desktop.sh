#!/usr/bin/env bash

# Desktop/session detection and refresh helpers.

check_shell() {
  local target_major=""

  if [[ -n "${shell:-}" ]]; then
    target_major="$(resolve_gnome_shell_major "$shell")"
  elif [[ "$(command -v gnome-shell)" ]]; then
    gnome-shell --version
    GNOME_SHELL="true"
    SHELL_VERSION="$(gnome-shell --version | cut -d ' ' -f 3 | cut -d . -f -1)"
    target_major="$(resolve_gnome_shell_major "${SHELL_VERSION:-}")"
  else
    echo "'gnome-shell' not found, using styles for last gnome-shell version available."
    GNOME_SHELL="false"
    target_major="$(latest_supported_gnome_shell_major)"
  fi

  GS_VERSION="$(gnome_shell_dir_from_major "$target_major")"
  echo "Install for gnome-shell version $(gnome_shell_install_label_from_major "$target_major")"
}

set_gtk3_settings_theme() {
  local theme_name="$1"
  local gtk3_dir="${HOME}/.config/gtk-3.0"
  local gtk3_settings="${gtk3_dir}/settings.ini"

  mkdir -p "$gtk3_dir"

  if [[ -f "$gtk3_settings" ]]; then
    if grep -q '^[[:space:]]*gtk-theme-name[[:space:]]*=' "$gtk3_settings"; then
      sed -i "s/^[[:space:]]*gtk-theme-name[[:space:]]*=.*/gtk-theme-name=${theme_name}/" "$gtk3_settings"
    else
      if ! grep -q '^\[Settings\]' "$gtk3_settings"; then
        printf '\n[Settings]\n' >> "$gtk3_settings"
      fi
      printf 'gtk-theme-name=%s\n' "$theme_name" >> "$gtk3_settings"
    fi
  else
    cat > "$gtk3_settings" <<EOF
[Settings]
gtk-theme-name=${theme_name}
EOF
  fi
}

refresh_theme() {
  local target_theme_name="${1:-}"
  echo -e "\nRefreshing theme settings..."

  if has_command gsettings; then
    local current_gtk_theme=""

    current_gtk_theme="${target_theme_name}"
    if [[ -z "$current_gtk_theme" ]]; then
      current_gtk_theme="$(gsettings get org.gnome.desktop.interface gtk-theme 2> /dev/null | tr -d "'" || true)"
    fi
    if [[ -n "$current_gtk_theme" ]]; then
      gsettings set org.gnome.desktop.interface gtk-theme "$current_gtk_theme" 2> /dev/null || true
      gsettings set org.cinnamon.desktop.interface gtk-theme "$current_gtk_theme" 2> /dev/null || true
      gsettings set org.cinnamon.desktop.wm.preferences theme "$current_gtk_theme" 2> /dev/null || true

      local current_cinnamon_shell_theme=""
      current_cinnamon_shell_theme="$(gsettings get org.cinnamon.theme name 2> /dev/null | tr -d "'" || true)"
      if [[ "$current_cinnamon_shell_theme" == "$current_gtk_theme" ]]; then
        gsettings set org.cinnamon.theme name 'cinnamon' 2> /dev/null || true
        gsettings set org.cinnamon.theme name "$current_gtk_theme" 2> /dev/null || true
      fi
    fi
  fi

  if has_command xfconf-query; then
    local current_xfce_theme=""

    current_xfce_theme="${target_theme_name}"
    if [[ -z "$current_xfce_theme" ]]; then
      current_xfce_theme="$(xfconf-query -c xsettings -p /Net/ThemeName 2> /dev/null || true)"
    fi
    if [[ -n "$current_xfce_theme" ]]; then
      xfconf-query -c xsettings -p /Net/ThemeName -s "$current_xfce_theme" 2> /dev/null \
        || xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "$current_xfce_theme" 2> /dev/null \
        || true
    fi
  fi

  if [[ -n "$target_theme_name" ]]; then
    set_gtk3_settings_theme "$target_theme_name"
  fi
}
