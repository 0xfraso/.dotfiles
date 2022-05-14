#!/bin/bash

PRIMARY_OUTPUT=`xrandr | grep -w primary | cut -d ' ' -f 1`

STATUS="$(cat /sys/class/power_supply/BAT1/status)"

if [[ $STATUS == "Discharging" ]]; then
  xrandr --output $PRIMARY_OUTPUT --mode 1920x1080 --rate 60
	notify-send --urgency=normal -t 3000 "$(echo -e 'Battery mode\nRefresh rate 60hz\nScreen brightness 50%')"
  light -S 50
else
  xrandr --output $PRIMARY_OUTPUT --mode 1920x1080 --rate 144
  notify-send --urgency=normal -t 3000 "$(echo -e 'AC mode\nRefresh rate 144hz\nScreen brightness 100%')"
  light -S 100
fi
