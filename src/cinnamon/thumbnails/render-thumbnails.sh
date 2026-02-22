#! /usr/bin/env bash

INKSCAPE="/usr/bin/inkscape"
OPTIPNG="/usr/bin/optipng"

./make-thumbnails.sh

theme=''
type=''
color=''
SRC_FILE="thumbnail${theme}${type}.svg"

echo
echo Rendering thumbnail${theme}${color}${type}.png
$INKSCAPE --export-id=thumbnail${color} \
          --export-id-only \
          --export-dpi=96 \
          --export-filename=thumbnail${theme}${color}${type}.png $SRC_FILE >/dev/null \
&& $OPTIPNG -o7 --quiet thumbnail${theme}${color}${type}.png

exit 0
