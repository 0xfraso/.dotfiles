local wezterm = require 'wezterm'

local config = {}
config.font = wezterm.font 'Iosevka Nerd Font Mono'
config.font_size = 16
config.color_scheme = "carbonfox"
config.enable_wayland = false
config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = 0.9

return config

