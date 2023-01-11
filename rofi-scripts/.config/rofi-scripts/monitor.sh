#!/bin/bash

INTERNAL_OUTPUT=`xrandr | grep -w primary | cut -d ' ' -f 1` 
EXTERNAL_OUTPUT=`xrandr | grep -w connected | grep -v primary | cut -d ' ' -f 1` 

o0="cancel"
o1="internal only"
o2="external only"
o3="extend"
o4="clone"

rofi_command="rofi -theme ~/.config/rofi/launchers/type-4/style-4.rasi -dmenu -p "monitor""

options="$o0\n$o1\n$o2\n$o3\n$o4"

selection="$(echo -e "$options" | $rofi_command )"


case $selection in
    $o1)
        xrandr --output $INTERNAL_OUTPUT --auto --output $EXTERNAL_OUTPUT --off
        ;;
    $o2)
        xrandr --output $INTERNAL_OUTPUT --off --output $EXTERNAL_OUTPUT --mode 3440x1440 --rate 144
        ;;
    $o3)
        xrandr --output $INTERNAL_OUTPUT --auto --output $EXTERNAL_OUTPUT --mode 3440x1440 --rate 144 --above $INTERNAL_OUTPUT
        ;;
    $o4)
        xrandr --output $INTERNAL_OUTPUT --auto --output $EXTERNAL_OUTPUT --mode 3440x1440 --rate 144 --same-as $INTERNAL_OUTPUT
        ;;
esac

