#!/bin/bash

rofi_command="rofi -p powermenu -dmenu"

#### Options ###
power_off="襤 Power off"
reboot="勒 Reboot"
suspend=" Sleep"
log_out="﫼 Logout"
# Variable passed to rofi
options="$power_off\n$reboot\n$suspend\n$log_out"

chosen="$(echo -e "$options" | $rofi_command)"
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
