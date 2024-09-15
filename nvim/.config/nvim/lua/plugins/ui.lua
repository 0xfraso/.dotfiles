return {
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
    "nvim-tree/nvim-web-devicons",
  },
  {
    "folke/which-key.nvim",
    opts = {}
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    config = function()
      require("noice").setup({
        lsp = {
          progress = {
            enabled = false
          },
          -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        -- you can enable a preset for easier configuration
        presets = {
          bottom_search = true,         -- use a classic bottom cmdline for search
          command_palette = false,      -- position the cmdline and popupmenu together
          long_message_to_split = true, -- long messages will be sent to a split
          inc_rename = false,           -- enables an input dialog for inc-rename.nvim
          lsp_doc_border = true,        -- add a border to hover docs and signature help
        }
      })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
    }
  },
  { "stevearc/dressing.nvim", lazy = false, opts = {} }
}
