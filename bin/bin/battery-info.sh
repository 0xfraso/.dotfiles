#!/bin/zsh

# Battery info using acpi

TIME=3000
STATUS="$(cat /sys/class/power_supply/BAT1/status)"
ETA="$(acpi -i | grep 'Charging\|Discharging' | cut -d ',' -f 3 | sed '0,/ / s/ //')"
PERCENTAGE="$(acpi -i | grep 'Charging\|Discharging\|Full' | cut -d ',' -f 2 | sed 's/ //g')" 

if [[ $STATUS -ne "Full" ]]; then
  MSG="$(echo - | awk "{printf \"%.1f\", \
    $(( \
      $(cat /sys/class/power_supply/BAT1/current_now) * \
      $(cat /sys/class/power_supply/BAT1/voltage_now) \
      )) / 1000000000000 }"; echo " W ")"
fi

notify-send -t $TIME "$(echo "Battery percentage $PERCENTAGE";echo "$STATUS $MSG"; echo "$ETA";)"
