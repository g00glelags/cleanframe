
REPO_DIR="$(dirname "$(readlink -m "${BASH_SOURCE[0]}")")"
SRC_DIR="$REPO_DIR/src"

ROOT_UID=0
DEST_DIR=

MY_USERNAME="${SUDO_USER:-$(logname 2> /dev/null || echo "${USER}")}"
MY_HOME=$(getent passwd "${MY_USERNAME}" | cut -d: -f6)

# Destination directory
if [[ "$UID" -eq "$ROOT_UID" ]]; then
  DEST_DIR="/usr/share/themes"
elif [[ -n "${XDG_DATA_HOME:-}" ]]; then
  DEST_DIR="$XDG_DATA_HOME/themes"
elif [[ -d "$HOME/.themes" ]]; then
  DEST_DIR="$HOME/.themes"
elif [[ -d "$HOME/.local/share/themes" ]]; then
  DEST_DIR="$HOME/.local/share/themes"
else
  DEST_DIR="$HOME/.themes"
fi

SASSC_OPT="-M -t expanded"
SASS_OPT="--no-source-map --style=expanded --silence-deprecation=import,global-builtin,color-functions,slash-div,strict-unary"

THEME_NAME=CleanFrame-Light

ctype=
icon='-default'

source "$REPO_DIR/scripts/lib/metadata.sh"
source "$REPO_DIR/scripts/lib/common.sh"
source "$REPO_DIR/scripts/lib/build.sh"
source "$REPO_DIR/scripts/lib/desktop.sh"
source "$REPO_DIR/scripts/lib/integrations.sh"
source "$REPO_DIR/scripts/lib/theme-install.sh"

detect_sass_compiler
