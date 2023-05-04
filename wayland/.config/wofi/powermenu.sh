#!/usr/bin/env bash
wofi_command="wofi --show=dmenu --columns=1 --location=bottom --y=-50 --width=300"

uptime=$(uptime -p | sed -e 's/up //g')

# Options
if [[ "$DIR" == "powermenus" ]]; then
	shutdown=""
	reboot=""
	lock=""
	suspend=""
	logout=""
else

# For some reason the Icons are mess up I don't know why but to fix it uncomment section 2 and comment section 1 but if the section 1 icons are mess up uncomment section 2 and comment section 1

	# Buttons
	layout=`cat $HOME/.config/rofi/config.rasi | grep BUTTON | cut -d'=' -f2 | tr -d '[:blank:],*/'`
	if [[ "$layout" == "TRUE" ]]; then
  # Section 1

		shutdown=""
		reboot=""
		lock=""
		suspend=""
		logout=""
  # Section 2
#		shutdown="襤"
#		reboot="ﰇ"
#		lock=""
#		suspend="鈴"
#		logout=" "


	else
  # Section 1
		shutdown=" Shutdown"
		reboot=" Restart"
		lock=" Lock"
		suspend=" Sleep"
		logout=" Logout"
  # Section 2
#		shutdown="襤Shutdown"
#		reboot="ﰇ Restart"
#		lock=" Lock"
#		suspend="鈴Sleep"
#		logout=" Logout"
	fi
fi

# Variable passed to rofi
options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"

chosen="$(echo -e "$options" | $wofi_command -p "UP - $uptime" -dmenu -selected-row 0)"
case $chosen in
    $shutdown)
        systemctl poweroff
        ;;
    $reboot)
        systemctl reboot
        exit
        ;;
    $lock)
        sh $HOME/.local/bin/lock
        ;;
    $suspend)
        mpc -q pause
        amixer set Master mute
        sh $HOME/.local/bin/lock
        systemctl suspend
        ;;
    $logout)
        bspc quit
        exit
        ;;
esac
