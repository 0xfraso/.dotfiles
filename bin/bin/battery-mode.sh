#!/bin/bash

PRIMARY_OUTPUT=`xrandr | grep -w primary | cut -d ' ' -f 1`
N_CONNECTED=`xrandr | grep -w connected -c`
RATE=60

if [[ $N_CONNECTED == 1 ]]; then
  xrandr --output $PRIMARY_OUTPUT --mode 1920x1080 --rate $RATE
fi

light -S 50

~/bin/battery-info.sh
