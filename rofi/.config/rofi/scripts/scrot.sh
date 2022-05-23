#!/bin/bash

o1="screen"
o2="area"
o3="window"

options="$o1\n$o2\n$o3"

selection="$(echo -e "$options" | rofi -lines 3 -dmenu -p "  screenshot to clipboard")"

notify() {
  notify-send "scrot savedo to clipboard."
}

case $selection in
    $o1)
      sleep 0.5 && scrot '/tmp/%F_%T_$wx$h.png' -e 'xclip -selection clipboard -target image/png -i $f && rm $f' && notify
        ;;
    $o2)
      sleep 0.5 && scrot -s '/tmp/%F_%T_$wx$h.png' -e 'xclip -selection clipboard -target image/png -i $f && rm $f' && notify
        ;;
    $o3)
      sleep 0.5 && scrot -u '/tmp/%F_%T_$wx$h.png' -e 'xclip -selection clipboard -target image/png -i $f && rm $f' && notify
        ;;
esac
