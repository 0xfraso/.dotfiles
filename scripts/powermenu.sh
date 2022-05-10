#!/bin/bash

rofi_command="rofi -p "power""

#### Options ###
power_off="襤 Power off"
reboot="勒 Reboot"
suspend=" Sleep"
log_out="﫼 Logout"
# Variable passed to rofi
options="$power_off\n$reboot\n$suspend\n$log_out"

chosen="$(echo -e "$options" | $rofi_command -dmenu -selected-row 2)"
case $chosen in
    $power_off)
        systemctl poweroff
        ;;
    $reboot)
        systemctl reboot
        ;;
    $suspend)
        systemctl suspend
        ;;
    $log_out)
        pkill xinit
        ;;
esac
