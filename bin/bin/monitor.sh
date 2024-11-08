#!/bin/bash

DIR="${HOME}/.screenlayout/default.sh"
FILENAME=$(basename $DIR)

if [[ -f "${DIR}" ]]; then
    notify-send --urgency=normal -t 3000 "Setting screenlayout to $FILENAME"
    if [[ -x $DIR ]]; then
        echo "changin $FILENAME permissions"
        chmod +x $DIR
    fi

    sh ${DIR}
else 
	notify-send --urgency=normal -t 3000 "screenlayout file '${DIR}' not found"
    ${HOME}/.dotfiles/rofi/.config/rofi/scripts/monitor.sh
fi
