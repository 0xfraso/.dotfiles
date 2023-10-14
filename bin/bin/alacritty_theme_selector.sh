#!/bin/bash

DIR=$HOME/.dotfiles/alacritty/.config/alacritty/themes
THEMES=$(ls $DIR)
SELECTED_THEME=$(echo $THEMES | tr -s '[:space:]' '\n' | fzf)

CONFIG_TEMPLATE="window:\n opacity: 0.9\nfont:\n size: 18\nimport:\n - ~/.config/alacritty/themes/${SELECTED_THEME}"

echo -e $CONFIG_TEMPLATE > ~/.alacritty.local.yml
