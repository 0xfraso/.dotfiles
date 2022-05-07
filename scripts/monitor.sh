#!/bin/bash

INTERNAL_OUTPUT=`xrandr | grep -w primary | cut -d ' ' -f 1` 
EXTERNAL_OUTPUT=`xrandr | grep -w connected | grep -v primary | cut -d ' ' -f 1` 

o0="cancel"
o1="internal only"
o2="external only"
o3="extend"
o4="clone"

options="$o0\n$o1\n$o2\n$o3\n$o4"

selection="$(echo -e "$options" | rofi -lines 5 -width 15 -location 5 -xoffset -15 -yoffset -15 -dmenu -p "monitor")"


case $selection in
    $o1)
        xrandr --output $INTERNAL_OUTPUT --auto --output $EXTERNAL_OUTPUT --off
        ;;
    $o2)
        xrandr --output $INTERNAL_OUTPUT --off --output $EXTERNAL_OUTPUT --mode 3440x1440 --rate 120
        ;;
    $o3)
        xrandr --output $INTERNAL_OUTPUT --auto --output $EXTERNAL_OUTPUT --mode 3440x1440 --rate 120 --above $INTERNAL_OUTPUT
        ;;
    $o4)
        xrandr --output $INTERNAL_OUTPUT --auto --output $EXTERNAL_OUTPUT --mode 3440x1440 --rate 120 --same-as $INTERNAL_OUTPUT
        ;;
esac

