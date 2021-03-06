#!/bin/bash

WALLPAPERDIR=~/.dotfiles/wallpapers/

if [ -z $@ ]
then
function get_themes()
{
    ls $WALLPAPERDIR
}
echo current; get_themes
else
    THEMES=$@
    if [ x"current" = x"${THEMES}" ]
    then
        exit 0
        #wal -i `cat ~/.cache/wal/wal` > /dev/null
    elif [ -n "${THEMES}" ]
    then
        wal  -i $WALLPAPERDIR${THEMES} -a 80 -o ~/.dotfiles/bin/bin/reload_dunst.sh> /dev/null
        nitrogen --set-zoom-fill $WALLPAPERDIR${THEMES} > /dev/null
    fi
fi
