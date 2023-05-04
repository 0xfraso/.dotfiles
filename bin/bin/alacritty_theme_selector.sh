#!/bin/bash

DIR=$HOME/.dotfiles/alacritty/.config/alacritty/themes
THEMES=$(ls $DIR)
SELECTED_THEME=$(echo $THEMES | tr -s '[:space:]' '\n' | wofi --show=dmenu --columns=3 --allow-images --location=bottom --y=-50 --prompt='Select alacritty theme')

CONFIG_TEMPLATE="window:\n opacity: 0.9\nfont:\n size: 22\nimport:\n - ~/.config/alacritty/themes/${SELECTED_THEME}"

echo -e $CONFIG_TEMPLATE > ~/.alacritty.local.yml
