return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    vscode = true,
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
      { "S",     mode = { "n", "o", "x" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
      { "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
      { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
    },
  },
  {
    "0xfraso/nvim-listchars",
    event = "BufEnter",
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
      lighten_step = 10,
    },
    keys = {
      { "<leader>ll", "<cmd>ListcharsToggle<CR>",        desc = "ListcharsToggle" },
      { "<leader>lu", "<cmd>ListcharsLightenColors<CR>", desc = "ListcharsLightenColors" },
      { "<leader>ld", "<cmd>ListcharsDarkenColors<CR>",  desc = "ListcharsDarkenColors" },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      local section_lsp = function()
        local msg = 'no lsp'
        local buf_ft = vim.api.nvim_get_option_value('filetype', {})
        local clients = vim.lsp.get_clients()
        if next(clients) == nil then
          return msg
        end
        for _, client in ipairs(clients) do
          local filetypes = client.config.filetypes
          if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
            return client.name
          end
        end
        return msg
      end

      local get_timerly_status = function()
        local status, state = pcall(require, "timerly.state")
        if not status then
          return "timerly not available"
        end
        if state.progress == 0 then
          return ""
        end

        local total = math.max(0, state.total_secs + 1) -- Add 1 to sync with timer display
        local mins = math.floor(total / 60)
        local secs = total % 60

        return string.format("%s %02d:%02d", state.mode:gsub("^%l", string.upper), mins, secs)
      end

      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = false,
          always_show_tabline = true,
          globalstatus = false,
          refresh = {
            statusline = 100,
            tabline = 100,
            winbar = 100,
          }
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { section_lsp },
          lualine_y = { get_timerly_status },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {}
      }
    end
  },
  {
    "nvim-tree/nvim-web-devicons",
  },
  {
    "folke/which-key.nvim",
    opts = {
      preset = "helix"
    }
  },
  { "stevearc/dressing.nvim", lazy = false, opts = {} },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    opts = {
      -- Style preset for diagnostic messages, options: "modern", "classic", "minimal", "powerline", "ghost", "simple", "nonerdfont", "amongus"
      preset = "modern",
    }
  }
}
