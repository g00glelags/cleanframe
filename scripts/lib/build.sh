#!/usr/bin/env bash

# Build helpers for SCSS compilation and asset preparation.

# Source common helpers if available
if [[ -f "${BASH_SOURCE[0]%/*}/common.sh" ]]; then
  source "${BASH_SOURCE[0]%/*}/common.sh"
fi

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
  if can_use_perl_normalization; then
    echo "[NORMALIZE] Applying GTK3 CSS normalization (full Perl)"
    perl -0pi -e '
      1 while s/:not\(([^()]*?),\s*([^()]+?)\)/:not($1):not($2)/g;
      s/\h+!important(?=\h*;)/ /g;
      s/calc\(\s*infinity\s*\*\s*1px\s*\)/9999px/g;
      s/calc\(\s*-infinity\s*\*\s*1px\s*\)/-9999px/g;
    ' "$css_file"
  else
    # Use fallback implementation
    if [[ $(type -t normalize_css_fallback) == "function" ]]; then
      normalize_css_fallback "$css_file" "gtk3"
    else
      echo "[WARNING] No CSS normalization available for GTK3"
    fi
  fi
}

normalize_gtk4_css() {
  local css_file="$1"

  [[ -f "$css_file" ]] || return 0

  # GTK4 parser compatibility pass for older/libadwaita runtimes.
  if can_use_perl_normalization; then
    echo "[NORMALIZE] Applying GTK4 CSS normalization (full Perl)"
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
  else
    # Use fallback implementation
    if [[ $(type -t normalize_css_fallback) == "function" ]]; then
      normalize_css_fallback "$css_file" "gtk4"
    else
      echo "[WARNING] No CSS normalization available for GTK4"
    fi
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

# CSS optimization functions
optimize_css() {
  local css_file="$1"
  local backup_file="${css_file}.backup"
  
  [ -f "$css_file" ] || return 0
  
  echo "[OPTIMIZE] Applying CSS optimizations to $(basename "$css_file")"
  
  # Backup original
  cp "$css_file" "$backup_file"
  
  # Remove duplicate rules (exact duplicates)
  remove_duplicate_css_rules "$css_file"
  
  # Remove empty rules (rules with only braces)
  remove_empty_css_rules "$css_file"
  
  # Basic minification (preserve CSS custom properties)
  minify_css_basic "$css_file"
  
  rm -f "$backup_file"
  echo "[OPTIMIZE] CSS optimizations applied"
}

remove_duplicate_css_rules() {
  local css_file="$1"
  local temp_file="${css_file}.tmp"
  local backup_file="${css_file}.backup"
  
  # This is a simple approach - for exact duplicate blocks
  # More advanced deduplication would require a CSS parser
  awk '/^[^{]+{$/ {
    rule = $0
    getline
    while ($0 != "}") {
      rule = rule "\n" $0
      getline
    }
    rule = rule "\n}"
    
    if (!seen[rule]++) {
      print rule
    }
    next
  }
  { print }' "$css_file" > "$temp_file" && mv "$temp_file" "$css_file"
  
  local duplicates_removed=$(( $(wc -l < "$backup_file") - $(wc -l < "$css_file") ))
  if [ "$duplicates_removed" -gt 0 ]; then
    echo "[OPTIMIZE] Removed approximately $duplicates_removed lines of duplicate rules"
  fi
}

remove_empty_css_rules() {
  local css_file="$1"
  local temp_file="${css_file}.tmp"
  
  # Remove rules that only contain {}
  awk '
  /^[^{]+{$/ {
    selector = $0
    getline
    if ($0 == "}") {
      # Empty rule, skip it
      next
    } else {
      # Not empty, print selector and continue
      print selector
      print $0
    }
    next
  }
  { print }
  ' "$css_file" > "$temp_file" && mv "$temp_file" "$css_file"
}

minify_css_basic() {
  local css_file="$1"
  
  # Only minify if file is reasonably small (< 5MB)
  local file_size=$(stat -c%s "$css_file" 2>/dev/null || echo 0)
  if [ "$file_size" -gt 5000000 ]; then
    echo "[OPTIMIZE] Skipping minification for large file ($(numfmt --to=si --suffix=B "$file_size"))"
    return 0
  fi
  
  # Basic minification steps
  # 1. Remove comments (but keep CSS custom property definitions)
  # 2. Remove extra whitespace
  # 3. Preserve @define-color and custom properties
  
  # Create a temporary file for processing
  local temp_file="${css_file}.min"
  
  # Simple minification using sed (more reliable than complex awk)
  # Keep @define-color lines intact
  # Remove single-line CSS comments
  # Collapse multiple spaces to one
  sed '
    # Keep @define-color lines as-is
    /^@define-color/ b
    # Remove CSS comments (single line only for safety)
    s|/\*.*\*/||g
    # Remove leading/trailing whitespace
    s/^[[:space:]]*//
    s/[[:space:]]*$//
    # Collapse multiple spaces/tabs to single space
    s/[[:space:]]\+/ /g
    # Remove spaces before and after braces/semicolons
    s/[[:space:]]*{[[:space:]]*/{/g
    s/[[:space:]]*}[[:space:]]*/}/g
    s/[[:space:]]*;[[:space:]]*/;/g
    s/[[:space:]]*:[[:space:]]*/:/g
    # Remove empty lines
    /^$/d
  ' "$css_file" > "$temp_file"
  
  # Only replace if minification actually reduced size
  local original_size=$(stat -c%s "$css_file")
  local minified_size=$(stat -c%s "$temp_file")
  
  if [ "$minified_size" -lt "$original_size" ]; then
    local reduction=$(echo "scale=1; 100 * ($original_size - $minified_size) / $original_size" | bc)
    echo "[OPTIMIZE] Basic minification: $(numfmt --to=si --suffix=B "$original_size") → $(numfmt --to=si --suffix=B "$minified_size") (${reduction}%)"
    mv "$temp_file" "$css_file"
  else
    rm -f "$temp_file"
  fi
}

# Function to optionally run CSS optimizations
maybe_optimize_css() {
  local css_file="$1"
  
  [ -f "$css_file" ] || return 0
  
  # Check if optimization is enabled
  if [ "${ENABLE_CSS_OPTIMIZATION:-false}" = "true" ]; then
    optimize_css "$css_file"
  fi
}
