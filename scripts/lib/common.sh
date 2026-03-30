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
