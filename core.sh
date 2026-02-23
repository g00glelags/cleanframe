
REPO_DIR="$(dirname "$(readlink -m "${0}")")"
SRC_DIR="$REPO_DIR/src"

ROOT_UID=0
DEST_DIR=

MY_USERNAME="${SUDO_USER:-$(logname 2> /dev/null || echo "${USER}")}"
MY_HOME=$(getent passwd "${MY_USERNAME}" | cut -d: -f6)

# Destination directory
if [[ "$UID" -eq "$ROOT_UID" ]]; then
  DEST_DIR="/usr/share/themes"
elif [[ -n "$XDG_DATA_HOME" ]]; then
  DEST_DIR="$XDG_DATA_HOME/themes"
elif [[ -d "$HOME/.themes" ]]; then
  DEST_DIR="$HOME/.themes"
elif [[ -d "$HOME/.local/share/themes" ]]; then
  DEST_DIR="$HOME/.local/share/themes"
else
  DEST_DIR="$HOME/.themes"
fi

SASSC_OPT="-M -t expanded"
SASS_OPT="--no-source-map --style=expanded --silence-deprecation=import,global-builtin,color-functions,slash-div,if-function,strict-unary"

THEME_NAME=CleanFrame-Light

ctype=
icon='-default'

# Check command availability
function has_command() {
  command -v $1 > /dev/null
}

detect_sass_compiler() {
  if has_command sass; then
    SASS_COMPILER="sass"
  elif has_command npx && npx sass --version > /dev/null 2>&1; then
    SASS_COMPILER="npx-sass"
  elif has_command sassc; then
    SASS_COMPILER="sassc"
  else
    SASS_COMPILER=""
  fi
}

compile_scss() {
  local input="$1"
  local output="$2"

  case "${SASS_COMPILER:-}" in
    sass)
      sass $SASS_OPT "$input:$output"
      ;;
    npx-sass)
      npx sass $SASS_OPT "$input:$output"
      ;;
    sassc)
      sassc $SASSC_OPT "$input" "$output"
      ;;
    *)
      echo "No SCSS compiler available. Install Dart Sass ('sass' or 'npx sass') or sassc."
      exit 1
      ;;
  esac
}

normalize_gtk3_css() {
  local css_file="$1"

  [[ -f "$css_file" ]] || return 0

  # GTK3 parser does not accept selector lists inside :not(...).
  # Convert ":not(a, b)" -> ":not(a):not(b)" iteratively.
  if has_command perl; then
    perl -0pi -e '1 while s/:not\(([^()]*?),\s*([^()]+?)\)/:not($1):not($2)/g' "$css_file"
  fi
}

normalize_gtk4_css() {
  local css_file="$1"

  [[ -f "$css_file" ]] || return 0

  # GTK4 parser compatibility pass for older/libadwaita runtimes:
  # - remove unsupported custom property blocks and declarations
  # - split selector lists inside :not(...)
  # - replace newer pseudo-classes with broader fallbacks
  if has_command perl; then
    perl -0pi -e '
      s/^:root\s*\{.*?\}\s*//s;
      1 while s/:not\(([^()]*?),\s*([^()]+?)\)/:not($1):not($2)/g;
      s/:focus-within/:focus/g;
      s/:focus-visible/:focus/g;
      s/^\h*-gtk-outline-radius:\h*[^;]+;\h*\n//mg;
      s/^\h*--[a-zA-Z0-9_-]+:\h*[^;]+;\h*\n//mg;
      s/^\h*[a-zA-Z_-][a-zA-Z0-9_-]*\h*:\h*(?:(?![{}]).)*?\bvar\(--(?:(?![{}]).)*?;\h*\n//msg;
      s/^\h*[a-zA-Z_-][a-zA-Z0-9_-]*\h*:\h*(?:(?![{}]).)*?\bcolor-mix\((?:(?![{}]).)*?;\h*\n//msg;
    ' "$css_file"
  fi
}

detect_sass_compiler

install() {
  local dest="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"
  local ctype="$6"
  local icon="$7"

  local THEME_DIR="${1}/${2}${3}${4}${5}${6}"

  # Ensure a fully clean target before installing to avoid stale assets.
  rm -rf "$THEME_DIR" "$THEME_DIR-hdpi" "$THEME_DIR-xhdpi"

  echo "Installing '$THEME_DIR'..."

  mkdir -p                                                                                   "$THEME_DIR"
  cp -r "$REPO_DIR/COPYING"                                                                  "$THEME_DIR"

  echo "[Desktop Entry]" >>                                                                  "$THEME_DIR/index.theme"
  echo "Type=X-GNOME-Metatheme" >>                                                           "$THEME_DIR/index.theme"
  echo "Name=${2}${3}${4}${5}${6}" >>                                                        "$THEME_DIR/index.theme"
  echo "Comment=An flat Materia Gtk+ theme based on Elegant Design" >>                       "$THEME_DIR/index.theme"
  echo "Encoding=UTF-8" >>                                                                   "$THEME_DIR/index.theme"
  echo "" >>                                                                                 "$THEME_DIR/index.theme"
  echo "[X-GNOME-Metatheme]" >>                                                              "$THEME_DIR/index.theme"
  echo "GtkTheme=${2}${3}${4}${5}${6}" >>                                                    "$THEME_DIR/index.theme"
  echo "MetacityTheme=${2}${3}${4}${5}${6}" >>                                               "$THEME_DIR/index.theme"
  echo "IconTheme=Tela-circle" >>                                                            "$THEME_DIR/index.theme"
  echo "CursorTheme=Vimix" >>                                                                "$THEME_DIR/index.theme"
  echo "ButtonLayout=close,minimize,maximize:menu" >>                                        "$THEME_DIR/index.theme"

  mkdir -p                                                                                   "$THEME_DIR/gnome-shell"
  cp -r "$SRC_DIR/gnome-shell/pad-osd.css"                                                   "$THEME_DIR/gnome-shell"
  compile_scss "$SRC_DIR/gnome-shell/shell-$GS_VERSION/gnome-shell$size.scss" "$THEME_DIR/gnome-shell/gnome-shell.css"

  cp -r "$SRC_DIR/gnome-shell/common-assets"                                                 "$THEME_DIR/gnome-shell/assets"
  cp -r "$SRC_DIR/gnome-shell/assets/"*.svg                                    "$THEME_DIR/gnome-shell/assets"

  cp -r "$SRC_DIR/gnome-shell/theme$theme$ctype/more-results.svg"              "$THEME_DIR/gnome-shell/assets/more-results.svg"
  cp -r "$SRC_DIR/gnome-shell/theme$theme$ctype/toggle-on.svg"                 "$THEME_DIR/gnome-shell/assets/toggle-on.svg"

  cp -r "$SRC_DIR/gnome-shell/activities/activities${icon}.svg"                              "$THEME_DIR/gnome-shell/assets/activities.svg"

  cd "$THEME_DIR/gnome-shell"
  ln -s assets/no-events.svg no-events.svg
  ln -s assets/process-working.svg process-working.svg
  ln -s assets/no-notifications.svg no-notifications.svg

  mkdir -p                                                                                   "$THEME_DIR/gtk-2.0"
  cp -r "$SRC_DIR/gtk-2.0/common/"{apps.rc,hacks.rc,main.rc}                                 "$THEME_DIR/gtk-2.0"
  cp -r "$SRC_DIR/gtk-2.0/gtkrc"                                                             "$THEME_DIR/gtk-2.0"
  cp -r "$SRC_DIR/gtk-2.0/assets-folder/assets"                                              "$THEME_DIR/gtk-2.0/assets"

  mkdir -p                                                                                   "$THEME_DIR/gtk-3.0"
  cp -r "$SRC_DIR/gtk/assets$theme$ctype"                                                    "$THEME_DIR/gtk-3.0/assets"
  cp -r "$SRC_DIR/gtk/scalable"                                                              "$THEME_DIR/gtk-3.0/assets"
  cp -r "$SRC_DIR/gtk/thumbnails/thumbnail$theme$ctype.png"                    "$THEME_DIR/gtk-3.0/thumbnail.png"
  compile_scss "$SRC_DIR/gtk/3.0/gtk$color$size.scss"                                        "$THEME_DIR/gtk-3.0/gtk.css"
  normalize_gtk3_css "$THEME_DIR/gtk-3.0/gtk.css"

  mkdir -p                                                                                   "$THEME_DIR/gtk-4.0"
  cp -r "$SRC_DIR/gtk/assets$theme$ctype"                                                    "$THEME_DIR/gtk-4.0/assets"
  cp -r "$SRC_DIR/gtk/scalable"                                                              "$THEME_DIR/gtk-4.0/assets"
  compile_scss "$SRC_DIR/gtk/4.0/gtk$color$size.scss"                                        "$THEME_DIR/gtk-4.0/gtk.css"
  echo "Normalizing GTK4 CSS for parser compatibility..."
  normalize_gtk4_css "$THEME_DIR/gtk-4.0/gtk.css"

  mkdir -p                                                                                   "$THEME_DIR/xfwm4"
  cp -r "$SRC_DIR/xfwm4/xpm/assets/"*.xpm                                                    "$THEME_DIR/xfwm4"
  cp -r "$SRC_DIR/xfwm4/themerc"                                                             "$THEME_DIR/xfwm4/themerc"
  mkdir -p                                                                                   "$THEME_DIR-hdpi/xfwm4"
  cp -r "$SRC_DIR/xfwm4/xpm/assets-hdpi/"*.xpm                                               "$THEME_DIR-hdpi/xfwm4"
  cp -r "$SRC_DIR/xfwm4/themerc"                                                             "$THEME_DIR-hdpi/xfwm4/themerc"
  mkdir -p                                                                                   "$THEME_DIR-xhdpi/xfwm4"
  cp -r "$SRC_DIR/xfwm4/svg/assets-xhdpi/"*.svg                               "$THEME_DIR-xhdpi/xfwm4"
  cp -r "$SRC_DIR/xfwm4/xpm/assets-xhdpi/"*.xpm                                              "$THEME_DIR-xhdpi/xfwm4"
  cp -r "$SRC_DIR/xfwm4/themerc"                                                             "$THEME_DIR-xhdpi/xfwm4/themerc"

  cp -r "$SRC_DIR/xfwm4/svg/assets/"*.svg                                   "$THEME_DIR/xfwm4"
  cp -r "$SRC_DIR/xfwm4/svg/assets-hdpi/"*.svg                              "$THEME_DIR-hdpi/xfwm4"
  cp -r "$SRC_DIR/xfwm4/svg/assets-xhdpi/"*.svg                             "$THEME_DIR-xhdpi/xfwm4"

  mkdir -p                                                                                   "$THEME_DIR/cinnamon"
  cp -r "$SRC_DIR/cinnamon/common-assets"                                                    "$THEME_DIR/cinnamon/assets"
  cp -r "$SRC_DIR/cinnamon/assets/"*.svg                                       "$THEME_DIR/cinnamon/assets"
  cp -r "$SRC_DIR/cinnamon/theme$theme$ctype/add-workspace-active.svg"         "$THEME_DIR/cinnamon/assets/add-workspace-active.svg"
  cp -r "$SRC_DIR/cinnamon/theme$theme$ctype/corner-ripple.svg"                "$THEME_DIR/cinnamon/assets/corner-ripple.svg"
  cp -r "$SRC_DIR/cinnamon/theme$theme$ctype/toggle-on.svg"                    "$THEME_DIR/cinnamon/assets/toggle-on.svg"

  compile_scss "$SRC_DIR/cinnamon/cinnamon$size.scss"                                         "$THEME_DIR/cinnamon/cinnamon.css"

  cp -r "$SRC_DIR/cinnamon/thumbnails/thumbnail$theme$ctype.png"               "$THEME_DIR/cinnamon/thumbnail.png"

  mkdir -p                                                                                   "$THEME_DIR/metacity-1"
  cp -r "$SRC_DIR/metacity-1/metacity-theme-3.xml"                                         "$THEME_DIR/metacity-1"
  cp -r "$SRC_DIR/metacity-1/assets"                                                       "$THEME_DIR/metacity-1"
  cp -r "$SRC_DIR/metacity-1/thumbnail.png"                                  "$THEME_DIR/metacity-1/thumbnail.png"

  (
    cd "$THEME_DIR/metacity-1" && ln -s metacity-theme-3.xml metacity-theme-2.xml && ln -s metacity-theme-3.xml metacity-theme-1.xml
  )

  mkdir -p                                                                                   "$THEME_DIR/plank"
  cp -r "$SRC_DIR/plank/"*                                                                   "$THEME_DIR/plank"
}

uninstall() {
  local dest="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"
  local ctype="$6"

  local THEME_DIR="${1}/${2}${3}${4}${5}${6}"

  [[ -d "$THEME_DIR" ]] && rm -rf "$THEME_DIR"{'','-hdpi','-xhdpi'} && echo -e "Uninstalling "$THEME_DIR" ..."
}

uninstall_link() {
  rm -rf "${HOME}/.config/gtk-4.0/"{assets,gtk.css}
  echo -e "\nRemoving ${HOME}/.config/gtk-4.0 links..."
}

link_libadwaita() {
  local dest="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"
  local ctype="$6"

  local THEME_DIR="${1}/${2}${3}${4}${5}${6}"

  echo -e "\nLink '$THEME_DIR/gtk-4.0' to '${HOME}/.config/gtk-4.0' for libadwaita..."

  [[ ! -d "${HOME}/.config/gtk-4.0" ]] && mkdir -p                              "${HOME}/.config/gtk-4.0"
  rm -rf "${HOME}/.config/gtk-4.0/"{assets,gtk.css}
  ln -sf "${THEME_DIR}/gtk-4.0/assets"                                          "${HOME}/.config/gtk-4.0/assets"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk.css"                                         "${HOME}/.config/gtk-4.0/gtk.css"
}

#  Install needed packages
install_package() {
  if [ -z "${SASS_COMPILER:-}" ]; then
    echo "Sass compiler not found. Install Dart Sass ('sass') or sassc to generate the css."
    if has_command zypper; then
      sudo zypper in sassc
    elif has_command apt; then
      sudo apt install sassc
    elif has_command apt-get; then
      sudo apt-get install sassc
    elif has_command dnf; then
      sudo dnf install sassc
    elif has_command yum; then
      sudo yum install sassc
    elif has_command pacman; then
      sudo pacman -S --noconfirm sassc
    fi
  fi
}

check_shell() {
  if [[ "$shell" == "38" ]]; then
    GS_VERSION="3-28"
    echo "Install for gnome-shell version < 40.0"
  elif [[ "$shell" == "40" ]]; then
    GS_VERSION="40-0"
    echo "Install for gnome-shell version = 40.0"
  elif [[ "$shell" == "42" ]]; then
    GS_VERSION="42-0"
    echo "Install for gnome-shell version = 42.0"
  elif [[ "$shell" == "44" ]]; then
    GS_VERSION="44-0"
    echo "Install for gnome-shell version = 44.0"
  elif [[ "$shell" == "46" ]]; then
    GS_VERSION="46-0"
    echo "Install for gnome-shell version = 46.0"
  elif [[ "$shell" == "47" ]]; then
    GS_VERSION="47-0"
    echo "Install for gnome-shell version = 47.0"
  elif [[ "$shell" == "48" ]]; then
    GS_VERSION="48-0"
    echo "Install for gnome-shell version = 48.0"
  elif [[ "$shell" == "49" ]]; then
    GS_VERSION="49-0"
    echo "Install for gnome-shell version = 49.0"
  elif [[ "$(command -v gnome-shell)" ]]; then
    gnome-shell --version
    GNOME_SHELL="true"
    SHELL_VERSION="$(gnome-shell --version | cut -d ' ' -f 3 | cut -d . -f -1)"
    if [[ "${SHELL_VERSION:-}" -ge "49" ]]; then
      GS_VERSION="49-0"
    elif [[ "${SHELL_VERSION:-}" -ge "48" ]]; then
      GS_VERSION="48-0"
    elif [[ "${SHELL_VERSION:-}" -ge "47" ]]; then
      GS_VERSION="47-0"
    elif [[ "${SHELL_VERSION:-}" -ge "46" ]]; then
      GS_VERSION="46-0"
    elif [[ "${SHELL_VERSION:-}" -ge "44" ]]; then
      GS_VERSION="44-0"
    elif [[ "${SHELL_VERSION:-}" -ge "42" ]]; then
      GS_VERSION="42-0"
    elif [[ "${SHELL_VERSION:-}" -ge "40" ]]; then
      GS_VERSION="40-0"
    else
      GS_VERSION="3-28"
    fi
  else
    echo "'gnome-shell' not found, using styles for last gnome-shell version available."
    GS_VERSION="49-0"
    GNOME_SHELL="false"
  fi
}



backup_file() {
  if [[ -f "${1}.bak" || -d "${1}.bak" ]]; then
    case "${2}" in
      sudo)
        sudo rm -rf "${1}" ;;
      *)
        rm -rf "${1}" ;;
    esac
  fi

  if [[ -f "${1}" || -d "${1}" ]]; then
    case "${2}" in
      sudo)
        sudo mv -n "${1}"{"",".bak"} ;;
      *)
        mv -n "${1}"{"",".bak"} ;;
    esac
  fi
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

apply_flatpak_theme_override() {
  local theme_name="$1"

  if ! has_command flatpak; then
    return
  fi

  echo -e "\nApplying Flatpak theme override (GTK_THEME=${theme_name})..."

  flatpak override --user --env=GTK_THEME="${theme_name}" 2> /dev/null || true

  # Let sandboxed apps reuse host GTK config and theme directories when allowed.
  flatpak override --user --filesystem=xdg-config/gtk-3.0:ro 2> /dev/null || true
  flatpak override --user --filesystem=xdg-config/gtk-4.0:ro 2> /dev/null || true
  flatpak override --user --filesystem=xdg-data/themes:ro 2> /dev/null || true
  flatpak override --user --filesystem="${HOME}/.themes:ro" 2> /dev/null || true
}

apply_snap_theme_preset() {
  local theme_name="$1"
  local envd_dir="${HOME}/.config/environment.d"
  local preset_file="${envd_dir}/99-cleanframe-theme.conf"

  mkdir -p "${envd_dir}"
  rm -f "${envd_dir}/90-cleanframe-theme.conf" 2> /dev/null || true

  local conflict_files=""
  conflict_files="$(grep -RIl '^[[:space:]]*GTK_THEME=' "${envd_dir}" 2> /dev/null | grep -vFx "${preset_file}" || true)"
  if [[ -n "${conflict_files}" ]]; then
    echo "WARNING: conflicting GTK_THEME preset(s) detected in '${envd_dir}':"
    echo "${conflict_files}" | sed 's/^/  - /'
    echo "         '${preset_file##*/}' will override on next login/session reload."
  fi

  cat > "${preset_file}" << EOF
# Generated by CleanFrame install.sh
GTK_THEME=${theme_name}
EOF

  echo -e "\nSnap preset written to '${preset_file}'."
  echo "Log out and log back in to propagate GTK_THEME to desktop-launched snaps."
}

apply_sandbox_theme_preset() {
  local theme_name="$1"

  if [[ "${apply_flatpak_preset:-false}" == "true" ]]; then
    apply_flatpak_theme_override "${theme_name}"
  fi

  if [[ "${apply_snap_preset:-false}" == "true" ]]; then
    apply_snap_theme_preset "${theme_name}"
  fi
}

install_theme() {
  check_shell

  for theme in "${themes[@]}"; do
    for color in "${colors[@]}"; do
      for size in "${sizes[@]}"; do
        install "${dest:-$DEST_DIR}" "${_name:-$THEME_NAME}" "$theme" "$color" "$size" "$ctype" "$icon"
      done
    done
  done

  if has_command xfce4-popup-whiskermenu; then
    echo -e "\nFor the rounded float whiskermenu, you need set your whiskermenu background opacity to 0 !"

    if has_command notify-send; then
      notify-send "You need set your whiskermenu background opacity to 0 !" -i dialog-warning-symbolic
    fi

    if $(sed -i "s|.*menu-opacity=.*|menu-opacity=0|" "$HOME/.config/xfce4/panel/whiskermenu"*".rc" &> /dev/null); then
      sed -i "s|.*menu-opacity=.*|menu-opacity=0|" "$HOME/.config/xfce4/panel/whiskermenu"*".rc"
    fi

    if (pgrep xfce4-session &> /dev/null); then
      xfce4-panel -r
    fi
  fi

  local DASH_TO_DOCK_STYLESHEET="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/stylesheet.css"

  if [[ -f "$DASH_TO_DOCK_STYLESHEET" ]]; then
    mv "$DASH_TO_DOCK_STYLESHEET" "$DASH_TO_DOCK_STYLESHEET".bak
  fi

  local selected_theme_name="${_name:-$THEME_NAME}${themes[0]}${colors[0]}${sizes[0]}${ctype}"
  apply_sandbox_theme_preset "${selected_theme_name}"

  refresh_theme "${selected_theme_name}"
}

uninstall_theme() {
  echo -e "\nRemoving old CleanFrame themes..."
  rm -rf "${dest:-$DEST_DIR}/CleanFrame"*

  local DASH_TO_DOCK_STYLESHEET_BAK="$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/stylesheet.css.bak"

  if [[ -f "$DASH_TO_DOCK_STYLESHEET_BAK" ]]; then
    mv "$DASH_TO_DOCK_STYLESHEET_BAK" "${DASH_TO_DOCK_STYLESHEET_BAK%.bak}"
  fi
}

clean_theme() {
  echo -e "\nRemoving old CleanFrame themes..."
  rm -rf "${dest:-$DEST_DIR}/CleanFrame"*
}

link_theme() {
  for theme in "${themes[@]}"; do
    for color in "${lcolors[@]}"; do
      for size in "${sizes[0]}"; do
        link_libadwaita "${dest:-$DEST_DIR}" "${_name:-$THEME_NAME}" "$theme" "$color" "$size" "$ctype"
      done
    done
  done
}
