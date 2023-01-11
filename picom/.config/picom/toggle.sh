#!/bin/bash

if pgrep "picom" 
then
  killall -q picom
else
  picom --config ~/.config/picom/picom.conf
fi
