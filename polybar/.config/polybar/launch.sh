#!/usr/bin/env sh

#set var for interface
wifi=$(ip route | grep '^default' | awk '{print $5}' | head -n1)


# Terminate already running bar instances
pkill -9 polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar

if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m DEFAULT_NETWORK_INTERFACE=$wifi polybar main -c ~/.config/polybar/config.ini &
  done
else
  DEFAULT_NETWORK_INTERFACE=$wifi polybar bar -c .config/polybar/config.ini &
fi
