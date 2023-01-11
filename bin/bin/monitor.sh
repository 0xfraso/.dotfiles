#!/bin/bash

PRIMARY_OUTPUT=`xrandr | grep -w connected | cut -d ' ' -f 1`
RATE144=144
RATE60=60
WIDE4K=3440x1440
FULLHD=1920x1080
DP='DP-0'
HDMI='HDMI-0'

if [[ $PRIMARY_OUTPUT == $DP ]]; then
  xrandr --output $DP --mode $WIDE4K --rate $RATE144 --primary
	notify-send --urgency=normal -t 3000 "$PRIMARY_OUTPUT - ${RATE}hz"
elif [[ $PRIMARY_OUTPUT == $HDMI ]]; then
    xrandr --output $HDMI --mode $FULLHD --rate $RATE60 --primary
else 
  exit 1;
fi
