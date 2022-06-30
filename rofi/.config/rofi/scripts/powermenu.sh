#!/bin/bash

#### Options ###
power_off="襤 Power off"
reboot="勒 Reboot"
suspend=" Sleep"
log_out="﫼 Logout"
# Variable passed to rofi
options="$power_off\n$reboot\n$suspend\n$log_out"

chosen="$(printf "$options" | rofi -dmenu -p powermenu)"
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
