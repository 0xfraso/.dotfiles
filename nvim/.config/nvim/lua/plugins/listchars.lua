return {
  "0xfraso/nvim-listchars",
  ---@type PluginConfig
  opts = {
    save_state = true,
    listchars = {
      trail = "-",
      tab = "» ",
      space = "·",
      nbsp = "␣",
      --eol = '↴',
    },
    notifications = false,
    exclude_filetypes = {},
    lighten_step = 10
  },
}
