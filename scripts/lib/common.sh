#!/usr/bin/env bash

# Shared command/runtime helpers used by install and validation flows.

has_command() {
  command -v "$1" > /dev/null
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

backup_file() {
  if [ -f "${1}.bak" ] || [ -d "${1}.bak" ]; then
    case "${2}" in
      sudo)
        sudo rm -rf "${1}" ;;
      *)
        rm -rf "${1}" ;;
    esac
  fi

  if [ -f "${1}" ] || [ -d "${1}" ]; then
    case "${2}" in
      sudo)
        sudo mv -n "${1}" "${1}.bak" ;;
      *)
        mv -n "${1}" "${1}.bak" ;;
    esac
  fi
}

# Validation and dependency checking functions
validate_prerequisites() {
  echo "[VALIDATION] Checking system prerequisites..."
  
  local missing_tools=""
  local warnings=""
  
  # Critical tools (build will fail without these)
  if ! has_command sass && ! has_command sassc && ! (has_command npx && npx sass --version > /dev/null 2>&1); then
    missing_tools="${missing_tools}sass/sassc (Dart Sass or libsass)"$'\n'
  fi
  
  # Important tools (features will be limited)
  if ! has_command perl; then
    warnings="${warnings}perl (CSS normalization will be limited)"$'\n'
  fi
  
  # Check bash version if BASH_VERSION is set
  if [ -n "${BASH_VERSION}" ] && [ "${BASH_VERSION%%.*}" -lt 4 ]; then
    warnings="${warnings}bash 4+ (some features may not work optimally)"$'\n'
  fi
  
  # Display results
  if [ -n "$missing_tools" ]; then
    echo "❌ MISSING CRITICAL TOOLS:"
    echo "$missing_tools" | while IFS= read -r tool; do
      [ -n "$tool" ] && echo "   - $tool"
    done
    echo ""
    echo "Install missing tools before proceeding:"
    
    if has_command apt-get; then
      echo "  sudo apt-get install sassc perl"
    elif has_command dnf; then
      echo "  sudo dnf install sassc perl"
    elif has_command pacman; then
      echo "  sudo pacman -S sassc perl"
    elif has_command zypper; then
      echo "  sudo zypper in sassc perl"
    elif has_command brew; then
      echo "  brew install sass/sass/sass perl"
    else
      echo "  Install Dart Sass (sass) or sassc and perl manually"
    fi
    
    return 1
  fi
  
  if [ -n "$warnings" ]; then
    echo "⚠️  WARNINGS (will proceed with limited functionality):"
    echo "$warnings" | while IFS= read -r warning; do
      [ -n "$warning" ] && echo "   - $warning"
    done
    echo ""
  fi
  
  # Check SCSS compiler availability
  detect_sass_compiler
  if [ -z "${SASS_COMPILER:-}" ]; then
    echo "❌ No SCSS compiler detected after validation"
    return 1
  fi
  
  echo "✅ Using SCSS compiler: $SASS_COMPILER"
  
  return 0
}

# Function to check if we can use Perl-based normalization
can_use_perl_normalization() {
  if has_command perl; then
    return 0
  else
    echo "[INFO] Perl not available, using limited CSS normalization"
    return 1
  fi
}

# Display system information for debugging
show_system_info() {
  echo "[SYSTEM INFO]"
  echo "  OS: $(uname -s) $(uname -r)"
  echo "  Bash: ${BASH_VERSION}"
  
  if has_command lsb_release; then
    echo "  Distro: $(lsb_release -ds 2>/dev/null || echo "Unknown")"
  fi
  
  # Tool versions
  if has_command sass; then
    echo "  Sass: $(sass --version 2>/dev/null || echo "Present")"
  elif has_command sassc; then
    echo "  Sassc: $(sassc --version 2>/dev/null || echo "Present")"
  fi
  
  if has_command perl; then
    echo "  Perl: $(perl -v 2>/dev/null | head -2 | tail -1 | cut -d' ' -f2,3,4,5)"
  fi
  
  echo ""
}
