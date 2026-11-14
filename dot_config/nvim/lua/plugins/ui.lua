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
    "nvim-tree/nvim-web-devicons",
  },
  {
    "folke/which-key.nvim",
    opts = {
      preset = "helix"
    }
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    opts = {
      -- Style preset for diagnostic messages, options: "modern", "classic", "minimal", "powerline", "ghost", "simple", "nonerdfont", "amongus"
      preset = "modern",
    }
  }
}
