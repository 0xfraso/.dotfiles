#!/usr/bin/env bash
rofi \
	-show drun -show-icons \
	-modi run,drun,ssh \
	-scroll-method 0 \
	-drun-match-fields all \
	-drun-display-format "{name}" \
	-no-drun-show-actions \
	-terminal alacritty \
	-kb-cancel Escape \
	-theme $HOME/.config/rofi/config.rasi
