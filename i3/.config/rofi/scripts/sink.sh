#!/bin/bash

rofi_command="rofi -dmenu -p   -theme ~/.config/rofi/config.rasi"

move_sink_inputs() {
    sink="$1"
    [ -n "$sink" ] || return 1

    sink_inputs=$(pactl list sink-inputs) || return 1

    while read -r sink_input; do
        index=$(echo "$sink_input" | grep -oP "\d+$")
        pactl move-sink-input "$index" "$sink" || return 1
    done < <(echo "$sink_inputs" | grep "Sink Input")
}

list_sinks() {
    sinks=$(pactl list sinks short) || return 1
    echo "$sinks" | sed -e "s/\t/\ /g"
}

select_sink() {
    sink="$(list_sinks | $rofi_command)" || return 1
    sink="$(echo "$sink" | cut -f 1 -d " ")"
    [ -n "$sink" ] || return 1

    pactl set-default-sink $sink || return 1
    move_sink_inputs $sink || return 1
}

case "$1" in
	list) list_sinks || exit 1;;
    current);;
	*) select_sink || exit 1;;
esac

exit 0
