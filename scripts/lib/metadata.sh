#!/usr/bin/env bash

# Declarative project metadata shared by build, install and validation flows.

SUPPORTED_GNOME_SHELL_MAJORS=(49 48 47 46 44 42 40 38)

declare -Ag GNOME_SHELL_DIR_BY_MAJOR=(
  [49]="49-0"
  [48]="48-0"
  [47]="47-0"
  [46]="46-0"
  [44]="44-0"
  [42]="42-0"
  [40]="40-0"
  [38]="3-28"
)

declare -Ag GNOME_SHELL_INSTALL_LABEL_BY_MAJOR=(
  [49]="= 49.0"
  [48]="= 48.0"
  [47]="= 47.0"
  [46]="= 46.0"
  [44]="= 44.0"
  [42]="= 42.0"
  [40]="= 40.0"
  [38]="< 40.0"
)

XFWM_VARIANTS=(
  "default||assets|assets"
  "hdpi|-hdpi|assets-hdpi|assets-hdpi"
  "xhdpi|-xhdpi|assets-xhdpi|assets-xhdpi"
)

latest_supported_gnome_shell_major() {
  printf '%s\n' "${SUPPORTED_GNOME_SHELL_MAJORS[0]}"
}

resolve_gnome_shell_major() {
  local requested_major="${1:-}"
  local candidate

  for candidate in "${SUPPORTED_GNOME_SHELL_MAJORS[@]}"; do
    if [[ "$requested_major" == "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  if [[ -n "$requested_major" && "$requested_major" -lt 40 ]]; then
    printf '%s\n' "38"
    return 0
  fi

  for candidate in "${SUPPORTED_GNOME_SHELL_MAJORS[@]}"; do
    if [[ "$candidate" == "38" ]]; then
      continue
    fi

    if [[ -n "$requested_major" && "$requested_major" -ge "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  printf '%s\n' "38"
}

gnome_shell_dir_from_major() {
  local major="${1:-38}"
  printf '%s\n' "${GNOME_SHELL_DIR_BY_MAJOR[$major]}"
}

gnome_shell_install_label_from_major() {
  local major="${1:-38}"
  printf '%s\n' "${GNOME_SHELL_INSTALL_LABEL_BY_MAJOR[$major]}"
}
