#!/bin/zsh

# Battery info using acpi

STATUS="$(cat /sys/class/power_supply/BAT1/status)"
ETA="$(acpi -i | grep 'Battery' | cut -d ',' -f 3 | sed '0,/ / s/ //')"
PERCENTAGE="$(acpi -i | grep 'Battery' | cut -d ',' -f 2 | sed '0,/ / s/ //')"


while [ : ]; do
  MSG="$(echo - | awk "{printf \"%.1f\", \
    $(( \
    $(cat /sys/class/power_supply/BAT1/current_now) * \
    $(cat /sys/class/power_supply/BAT1/voltage_now) \
    )) / 1000000000000 }"; echo " W ")"
  clear
  echo "$MSG"
  sleep 1
done

