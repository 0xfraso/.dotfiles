#!/bin/bash

PRIMARY_OUTPUT=`xrandr | grep -w primary | cut -d ' ' -f 1`
N_CONNECTED=`xrandr | grep -w connected -c`
RATE=$@

rofi_cmd="rofi -dmenu -p 'select output >'"

if [[ $N_CONNECTED == 1 && -n $RATE ]]; then
  xrandr --output $PRIMARY_OUTPUT --mode 1920x1080 --rate $RATE
fi


