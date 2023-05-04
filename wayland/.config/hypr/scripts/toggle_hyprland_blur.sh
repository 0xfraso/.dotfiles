#!/usr/bin/env bash

if [[ "$(hyprctl getoption decoration:blur_size | grep int | cut -d ' ' -f2)" == 0 ]]; then
    hyprctl keyword decoration:blur_size 10
else 
    hyprctl keyword decoration:blur_size 0
fi
