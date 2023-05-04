#!/usr/bin/env bash

reload_dunst() {
    killall -q dunst && notify-send "dunst reloaded!"
}

reload_dunst
