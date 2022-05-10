### i3-gnome 
```
https://github.com/i3-gnome/i3-gnome
```

### Solve lag on second monitor 

add

``` sh
LIBGL_DRI3_DISABLE=true` in `/etc/environment
```

### Notifications software 

``` sh
herbe
```

### Remove no-bitmaps fonts restriction

``` sh
sudo rm /etc/fonts/conf.d/70-no-bitmaps.conf 
sudo ln -s /etc/fonts/conf.avail/70-yes-bitmaps.conf /etc/fonts/conf.d/70-yes-bitmaps.conf
```

### cargo build dependencies 

```
sudo apt-get install libgtk-3-dev
```

### alacritty theme selector

```
sudo npm i -g alacritty-themes
```

### system info fetch 

```
rxfetch
```

### image preview ranger

in ~/.config/ranger/rc.conf
```
set preview_images true
set preview_images_method ueberzug
```
#### dependencies 

```
pip3 install ueberzug
libx11-dev libxtst-dev python3-docopt python3-xlib python3-pil python3-attr
```
## bat (cat clone with syntax highlighting)

`export MANPAGER="sh -c 'col -bx | bat -l man -p'"`
