#! /usr/bin/env bash

for theme in ''; do
  for color in ''; do
    for type in '' '-Nord' '-Dracula'; do
      theme_color='#1a73e8'
      background_color='#F2F2F2'
      base_color='#FFFFFF'

      if [[ "$type" == '-Nord' ]]; then
        theme_color='#5e81ac'
        background_color='#f0f1f4'
        base_color='#f8fafc'
      fi

      if [[ "$type" == '-Dracula' ]]; then
        theme_color='#5d70ac'
        background_color='#f0f1f4'
        base_color='#f9f9fb'
      fi

      if [[ "$type" != '' ]]; then
        cp -r "assets${color}.svg" "assets${theme}${color}${type}.svg"
        sed -i "s/#1a73e8/${theme_color}/g" "assets${theme}${color}${type}.svg"

        cp -r "assets-common${color}.svg" "assets-common${color}${type}.svg"
        sed -i "s/#F2F2F2/${background_color}/g" "assets-common${color}${type}.svg"
        sed -i "s/#FFFFFF/${base_color}/g" "assets-common${color}${type}.svg"
      fi
    done
  done
done

echo -e "DONE!"
