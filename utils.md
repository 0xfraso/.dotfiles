### i3-gnome 
```
https://github.com/i3-gnome/i3-gnome
```

### Solve lag on second monitor 

add

``` sh
LIBGL_DRI3_DISABLE=true in /etc/environment
```

## bat (cat clone with syntax highlighting)

`export MANPAGER="sh -c 'col -bx | bat -l man -p'"`

## bluetooth default sink and profile

add to `/etc/pulse/default.pa` to automatically switch pulseaudio sink to bluez

```
.ifexists module-bluetooth-discover.so
load-module module-bluetooth-discover
load-module module-switch-on-connect  # Add this
.endif
```

add to `/etc/pulse/default.pa` to remember audio profile set on the bluetooth device

```
load-module module-card-restore restore_bluetooth_profile=true
```
