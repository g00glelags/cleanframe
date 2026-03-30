#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${REPO_DIR}/core.sh"

shell="${1:-49}"
dest="${2:-${BUILD_ROOT_DIR}}"

themes=('')
colors=('')
sizes=('')

check_shell
build_theme_artifacts "${dest}" "${_name:-$THEME_NAME}" "${themes[0]}" "${colors[0]}" "${sizes[0]}" "${ctype}" "${icon}"

echo
echo "Build artifacts generated at: ${dest}"
