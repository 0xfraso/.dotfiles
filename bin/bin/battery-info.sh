#!/bin/zsh

# Battery info using acpi

TIME=3000
STATUS="$(cat /sys/class/power_supply/BAT1/status)"
ETA="$(acpi -i | grep 'Battery' | cut -d ',' -f 3 | sed '0,/ / s/ //')"
PERCENTAGE="$(acpi -i | grep 'Battery' | cut -d ',' -f 2 | sed '0,/ / s/ //')"

MSG="$(echo - | awk "{printf \"%.1f\", \
  $(( \
  $(cat /sys/class/power_supply/BAT1/current_now) * \
  $(cat /sys/class/power_supply/BAT1/voltage_now) \
  )) / 1000000000000 }"; echo " W ")"

notify-send -t $TIME "$(echo "$STATUS $MSG"; echo "$ETA";echo "$PERCENTAGE")"
