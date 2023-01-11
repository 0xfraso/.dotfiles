#!/usr/bin/env bash

reload_dunst() {
    pkill dunst
    dunst \
	-frame_width 0 &
}

reload_dunst
