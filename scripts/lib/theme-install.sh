#!/usr/bin/env bash

# Theme assembly and install lifecycle helpers.

BUILD_ROOT_DIR="${REPO_DIR}/build"

theme_dir_name() {
  local name="$1"
  local theme="$2"
  local color="$3"
  local size="$4"
  local ctype="$5"

  printf '%s\n' "${name}${theme}${color}${size}${ctype}"
}

remove_theme_payload() {
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"
  local ctype="$6"
  local base_dir="$1"
  local theme_dir="${base_dir}/$(theme_dir_name "$name" "$theme" "$color" "$size" "$ctype")"

  rm -rf "$theme_dir" "$theme_dir-hdpi" "$theme_dir-xhdpi"
}

write_index_theme_file() {
  local theme_dir="$1"
  local theme_name="$2"

  cat > "${theme_dir}/index.theme" <<EOF
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=${theme_name}
Comment=CleanFrame Light - Clear, readable and predictable light desktop theme
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=${theme_name}
MetacityTheme=${theme_name}
IconTheme=Tela-circle
CursorTheme=Vimix
ButtonLayout=close,minimize,maximize:menu
EOF
}

assemble_xfwm_variants() {
  local theme_dir="$1"
  local variant_name=""
  local dir_suffix=""
  local svg_assets_dir=""
  local xpm_assets_dir=""
  local target_dir=""

  for variant in "${XFWM_VARIANTS[@]}"; do
    IFS='|' read -r variant_name dir_suffix svg_assets_dir xpm_assets_dir <<< "$variant"
    target_dir="${theme_dir}${dir_suffix}/xfwm4"

    mkdir -p "$target_dir"
    cp -r "$SRC_DIR/xfwm4/xpm/${xpm_assets_dir}/"*.xpm "$target_dir"
    cp -r "$SRC_DIR/xfwm4/svg/${svg_assets_dir}/"*.svg "$target_dir"
    cp -r "$SRC_DIR/xfwm4/themerc" "$target_dir/themerc"
  done
}

assemble_theme() {
  local dest_root="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"
  local ctype="$6"
  local icon="$7"
  local THEME_DIR="${dest_root}/$(theme_dir_name "$name" "$theme" "$color" "$size" "$ctype")"

  remove_theme_payload "$dest_root" "$name" "$theme" "$color" "$size" "$ctype"

  echo "Assembling '$THEME_DIR'..."

  mkdir -p "$THEME_DIR"
  cp -r "$REPO_DIR/COPYING" "$THEME_DIR"
  write_index_theme_file "$THEME_DIR" "$(theme_dir_name "$name" "$theme" "$color" "$size" "$ctype")"

  mkdir -p "$THEME_DIR/gnome-shell"
  cp -r "$SRC_DIR/gnome-shell/pad-osd.css" "$THEME_DIR/gnome-shell"
  compile_scss "$SRC_DIR/gnome-shell/shell-$GS_VERSION/gnome-shell$size.scss" "$THEME_DIR/gnome-shell/gnome-shell.css"
  # Apply CSS optimizations if enabled
  maybe_optimize_css "$THEME_DIR/gnome-shell/gnome-shell.css"
  cp -r "$SRC_DIR/gnome-shell/common-assets" "$THEME_DIR/gnome-shell/assets"
  cp -r "$SRC_DIR/gnome-shell/assets/"*.svg "$THEME_DIR/gnome-shell/assets"
  cp -r "$SRC_DIR/gnome-shell/theme$theme$ctype/more-results.svg" "$THEME_DIR/gnome-shell/assets/more-results.svg"
  cp -r "$SRC_DIR/gnome-shell/theme$theme$ctype/toggle-on.svg" "$THEME_DIR/gnome-shell/assets/toggle-on.svg"
  cp -r "$SRC_DIR/gnome-shell/activities/activities${icon}.svg" "$THEME_DIR/gnome-shell/assets/activities.svg"

  (
    cd "$THEME_DIR/gnome-shell" || exit 1
    ln -s assets/no-events.svg no-events.svg
    ln -s assets/process-working.svg process-working.svg
    ln -s assets/no-notifications.svg no-notifications.svg
  )

  mkdir -p "$THEME_DIR/gtk-2.0"
  cp -r "$SRC_DIR/gtk-2.0/common/"{apps.rc,hacks.rc,main.rc} "$THEME_DIR/gtk-2.0"
  cp -r "$SRC_DIR/gtk-2.0/gtkrc" "$THEME_DIR/gtk-2.0"
  cp -r "$SRC_DIR/gtk-2.0/assets-folder/assets" "$THEME_DIR/gtk-2.0/assets"
  create_gtk2_asset_fallbacks "$THEME_DIR/gtk-2.0"

  mkdir -p "$THEME_DIR/gtk-3.0"
  cp -r "$SRC_DIR/gtk/assets$theme$ctype" "$THEME_DIR/gtk-3.0/assets"
  cp -r "$SRC_DIR/gtk/scalable" "$THEME_DIR/gtk-3.0/assets"
  cp -r "$SRC_DIR/gtk/thumbnails/thumbnail$theme$ctype.png" "$THEME_DIR/gtk-3.0/thumbnail.png"
  compile_scss "$SRC_DIR/gtk/3.0/gtk$color$size.scss" "$THEME_DIR/gtk-3.0/gtk.css"
  normalize_gtk3_css "$THEME_DIR/gtk-3.0/gtk.css"
  # Apply CSS optimizations if enabled
  maybe_optimize_css "$THEME_DIR/gtk-3.0/gtk.css"
  (
    cd "$THEME_DIR/gtk-3.0" || exit 1
    ln -sf gtk.css gtk-dark.css
  )

  mkdir -p "$THEME_DIR/gtk-4.0"
  cp -r "$SRC_DIR/gtk/assets$theme$ctype" "$THEME_DIR/gtk-4.0/assets"
  cp -r "$SRC_DIR/gtk/scalable" "$THEME_DIR/gtk-4.0/assets"
  compile_scss "$SRC_DIR/gtk/4.0/gtk$color$size.scss" "$THEME_DIR/gtk-4.0/gtk.css"
  echo "Normalizing GTK4 CSS for parser compatibility..."
  normalize_gtk4_css "$THEME_DIR/gtk-4.0/gtk.css"
  # Apply CSS optimizations if enabled
  maybe_optimize_css "$THEME_DIR/gtk-4.0/gtk.css"
  (
    cd "$THEME_DIR/gtk-4.0" || exit 1
    ln -sf gtk.css gtk-dark.css
  )

  assemble_xfwm_variants "$THEME_DIR"

  mkdir -p "$THEME_DIR/cinnamon"
  cp -r "$SRC_DIR/cinnamon/common-assets" "$THEME_DIR/cinnamon/assets"
  cp -r "$SRC_DIR/cinnamon/assets/"*.svg "$THEME_DIR/cinnamon/assets"
  cp -r "$SRC_DIR/cinnamon/theme$theme$ctype/add-workspace-active.svg" "$THEME_DIR/cinnamon/assets/add-workspace-active.svg"
  cp -r "$SRC_DIR/cinnamon/theme$theme$ctype/corner-ripple.svg" "$THEME_DIR/cinnamon/assets/corner-ripple.svg"
  cp -r "$SRC_DIR/cinnamon/theme$theme$ctype/toggle-on.svg" "$THEME_DIR/cinnamon/assets/toggle-on.svg"
  compile_scss "$SRC_DIR/cinnamon/cinnamon$size.scss" "$THEME_DIR/cinnamon/cinnamon.css"
  # Apply CSS optimizations if enabled
  maybe_optimize_css "$THEME_DIR/cinnamon/cinnamon.css"
  cp -r "$SRC_DIR/cinnamon/thumbnails/thumbnail$theme$ctype.png" "$THEME_DIR/cinnamon/thumbnail.png"

  mkdir -p "$THEME_DIR/metacity-1"
  cp -r "$SRC_DIR/metacity-1/metacity-theme-3.xml" "$THEME_DIR/metacity-1"
  cp -r "$SRC_DIR/metacity-1/assets" "$THEME_DIR/metacity-1"
  cp -r "$SRC_DIR/metacity-1/thumbnail.png" "$THEME_DIR/metacity-1/thumbnail.png"

  (
    cd "$THEME_DIR/metacity-1" || exit 1
    ln -s metacity-theme-3.xml metacity-theme-2.xml
    ln -s metacity-theme-3.xml metacity-theme-1.xml
  )

  mkdir -p "$THEME_DIR/plank"
  cp -r "$SRC_DIR/plank/"* "$THEME_DIR/plank"
}

copy_theme_payload() {
  local source_root="$1"
  local dest_root="$2"
  local name="$3"
  local theme="$4"
  local color="$5"
  local size="$6"
  local ctype="$7"
  local theme_name

  theme_name="$(theme_dir_name "$name" "$theme" "$color" "$size" "$ctype")"
  remove_theme_payload "$dest_root" "$name" "$theme" "$color" "$size" "$ctype"

  mkdir -p "${dest_root}"
  echo "Installing '${dest_root}/${theme_name}' from staged artifacts..."
  cp -a "${source_root}/${theme_name}" "${dest_root}/${theme_name}"
  [[ -d "${source_root}/${theme_name}-hdpi" ]] && cp -a "${source_root}/${theme_name}-hdpi" "${dest_root}/${theme_name}-hdpi"
  [[ -d "${source_root}/${theme_name}-xhdpi" ]] && cp -a "${source_root}/${theme_name}-xhdpi" "${dest_root}/${theme_name}-xhdpi"
}

build_theme_artifacts() {
  local build_root="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"
  local ctype="$6"
  local icon="$7"

  mkdir -p "$build_root"
  assemble_theme "$build_root" "$name" "$theme" "$color" "$size" "$ctype" "$icon"
}

uninstall() {
  local dest="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"
  local ctype="$6"
  local THEME_DIR="${1}/${2}${3}${4}${5}${6}"

  [[ -d "$THEME_DIR" ]] && rm -rf "$THEME_DIR"{'','-hdpi','-xhdpi'} && echo -e "Uninstalling $THEME_DIR ..."
}

uninstall_link() {
  rm -rf "${HOME}/.config/gtk-4.0/"{assets,gtk.css,gtk-dark.css}
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

  echo -e "\nLinking '$THEME_DIR/gtk-4.0' to '${HOME}/.config/gtk-4.0' for libadwaita..."

  [[ ! -d "${HOME}/.config/gtk-4.0" ]] && mkdir -p "${HOME}/.config/gtk-4.0"
  rm -rf "${HOME}/.config/gtk-4.0/"{assets,gtk.css,gtk-dark.css}
  ln -sf "${THEME_DIR}/gtk-4.0/assets" "${HOME}/.config/gtk-4.0/assets"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk.css" "${HOME}/.config/gtk-4.0/gtk.css"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk.css" "${HOME}/.config/gtk-4.0/gtk-dark.css"
}

install_theme() {
  check_shell

  for theme in "${themes[@]}"; do
    for color in "${colors[@]}"; do
      for size in "${sizes[@]}"; do
        build_theme_artifacts "${BUILD_ROOT_DIR}" "${_name:-$THEME_NAME}" "$theme" "$color" "$size" "$ctype" "$icon"
        copy_theme_payload "${BUILD_ROOT_DIR}" "${dest:-$DEST_DIR}" "${_name:-$THEME_NAME}" "$theme" "$color" "$size" "$ctype"
      done
    done
  done

  if has_command xfce4-popup-whiskermenu; then
    echo -e "\nFor the rounded float whiskermenu, you need set your whiskermenu background opacity to 0 !"

    if has_command notify-send; then
      notify-send "You need set your whiskermenu background opacity to 0 !" -i dialog-warning-symbolic
    fi

    for rc in "$HOME/.config/xfce4/panel/whiskermenu"*.rc; do
      if [[ -f "$rc" ]]; then
        sed -i "s|.*menu-opacity=.*|menu-opacity=0|" "$rc"
      fi
    done

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
    for color in "${colors[@]}"; do
      for size in "${sizes[0]}"; do
        link_libadwaita "${dest:-$DEST_DIR}" "${_name:-$THEME_NAME}" "$theme" "$color" "$size" "$ctype"
      done
    done
  done
}
