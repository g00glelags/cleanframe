#!/usr/bin/env bash

# Build helpers for SCSS compilation and asset preparation.

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

  # GTK3 parser compatibility pass:
  # - split selector lists inside :not(...)
  # - drop !important (common GTK3 parser warning in Electron/Chromium apps)
  # - replace Dart Sass infinity calc artifacts in border-image slices/widths
  if has_command perl; then
    perl -0pi -e '
      1 while s/:not\(([^()]*?),\s*([^()]+?)\)/:not($1):not($2)/g;
      s/\h+!important(?=\h*;)/ /g;
      s/calc\(\s*infinity\s*\*\s*1px\s*\)/9999px/g;
      s/calc\(\s*-infinity\s*\*\s*1px\s*\)/-9999px/g;
    ' "$css_file"
  fi
}

normalize_gtk4_css() {
  local css_file="$1"

  [[ -f "$css_file" ]] || return 0

  # GTK4 parser compatibility pass for older/libadwaita runtimes.
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

resolve_gtk2_asset_fallback() {
  local missing="$1"
  local assets_dir="$2"
  local candidate=""
  local base="${missing%.png}"

  if [[ -f "${assets_dir}/${missing}" ]]; then
    printf '%s\n' "${missing}"
    return 0
  fi

  case "${missing}" in
    button*.png) candidate="entry-active.png" ;;
    flat-button*.png) candidate="entry-active.png" ;;
    border.png) candidate="entry-active.png" ;;
    frame*.png) candidate="entry-active.png" ;;
    focus.png) candidate="entry-active.png" ;;
    checkbox-unchecked*.png) candidate="${missing/checkbox-unchecked/checkbox-mixed}" ;;
    radio-unchecked*.png) candidate="${missing/radio-unchecked/radio-mixed}" ;;
    menu-checkbox-unchecked*.png) candidate="${missing/menu-checkbox-unchecked/menu-checkbox-mixed}" ;;
    menu-radio-unchecked*.png) candidate="${missing/menu-radio-unchecked/menu-radio-mixed}" ;;
    combo-left-entry*.png) candidate="combo-left-entry-active.png" ;;
    combo-right-entry*.png) candidate="combo-right-entry-active.png" ;;
    entry*.png) candidate="entry-active.png" ;;
    spin-ltr-up*.png) candidate="spin-ltr-up-active.png" ;;
    spin-ltr-down*.png) candidate="spin-ltr-down-active.png" ;;
    spin-rtl-up*.png) candidate="spin-rtl-up-active.png" ;;
    spin-rtl-down*.png) candidate="spin-rtl-down-active.png" ;;
    scale-horz-trough*.png) candidate="scale-horz-trough-active.png" ;;
    scale-vert-trough*.png) candidate="scale-vert-trough-active.png" ;;
    scrollbar-*.png) candidate="scale-slider-active.png" ;;
    pan-*.png) candidate="scale-slider-active.png" ;;
    treeview-*.png) candidate="entry-active.png" ;;
    scale-slider-disabled.png) candidate="scale-slider.png" ;;
    progressbar-trough.png) candidate="progressbar-progress.png" ;;
  esac

  if [[ -n "${candidate}" && -f "${assets_dir}/${candidate}" ]]; then
    printf '%s\n' "${candidate}"
    return 0
  fi

  if [[ "${base}" == *-hover || "${base}" == *-active || "${base}" == *-disabled ]]; then
    candidate="${base%-hover}.png"
    [[ -f "${assets_dir}/${candidate}" ]] && { printf '%s\n' "${candidate}"; return 0; }
    candidate="${base%-active}.png"
    [[ -f "${assets_dir}/${candidate}" ]] && { printf '%s\n' "${candidate}"; return 0; }
    candidate="${base%-disabled}.png"
    [[ -f "${assets_dir}/${candidate}" ]] && { printf '%s\n' "${candidate}"; return 0; }
  fi

  if [[ -f "${assets_dir}/entry-active.png" ]]; then
    printf '%s\n' "entry-active.png"
    return 0
  fi

  if [[ -f "${assets_dir}/scale-slider-active.png" ]]; then
    printf '%s\n' "scale-slider-active.png"
    return 0
  fi

  if [[ -f "${assets_dir}/scale-slider.png" ]]; then
    printf '%s\n' "scale-slider.png"
    return 0
  fi

  printf '%s\n' ""
}

create_gtk2_asset_fallbacks() {
  local target_gtk2_dir="$1"
  local assets_dir="${target_gtk2_dir}/assets"
  local rc_main="${target_gtk2_dir}/main.rc"
  local rc_apps="${target_gtk2_dir}/apps.rc"
  local refs
  local ref
  local fallback
  local created=0

  [[ -d "${assets_dir}" && -f "${rc_main}" && -f "${rc_apps}" ]] || return 0

  refs="$(
    sed -n 's/.*assets\/\([A-Za-z0-9._-]\+\.png\).*/\1/p' "${rc_main}" "${rc_apps}" \
      | sort -u
  )"

  while IFS= read -r ref; do
    [[ -n "${ref}" ]] || continue
    [[ -f "${assets_dir}/${ref}" ]] && continue

    fallback="$(resolve_gtk2_asset_fallback "${ref}" "${assets_dir}")"
    [[ -n "${fallback}" ]] || continue

    ln -sfn "${fallback}" "${assets_dir}/${ref}"
    created=$((created + 1))
  done <<< "${refs}"

  if [[ "${created}" -gt 0 ]]; then
    echo "GTK2 asset fallbacks created: ${created}"
  fi
}
