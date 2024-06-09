return {
  {
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
  },
  {
    "stevearc/oil.nvim",
    lazy = false,
    config = function()
      require("oil").setup({
        -- Id is automatically added at the beginning, and name at the end
        -- See :help oil-columns
        columns = {
          -- "permissions",
          "size",
          "mtime",
          "icon",
        },
      })
      vim.api.nvim_set_hl(0, "OilDir", { link = "Directory" })
    end,
    keys = {
      { "<leader>e", "<Cmd>Oil<CR>", desc = "Oil" },
    },
  },
  {
    "RRethy/vim-illuminate",
    config = function()
      require("illuminate").configure({
        providers = {
          "lsp",
          "treesitter",
          "regex",
        },
        delay = 100,
        should_enable = function(bufnr)
          return vim.g.illuminate
        end,
      })
    end,
  },
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = function()
      local logo = [[
███████╗██████╗  █████╗ ███████╗ ██████╗ 
██╔════╝██╔══██╗██╔══██╗██╔════╝██╔═══██╗
█████╗  ██████╔╝███████║███████╗██║   ██║
██╔══╝  ██╔══██╗██╔══██║╚════██║██║   ██║
██║     ██║  ██║██║  ██║███████║╚██████╔╝
╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ 
    ]]

      logo = string.rep("\n", 8) .. logo .. "\n\n"

      local opts = {
        theme = "doom",
        hide = {
          -- this is taken care of by lualine
          -- enabling this messes up the actual laststatus setting after loading a file
          statusline = false,
        },
        config = {
          header = vim.split(logo, "\n"),
        -- stylua: ignore
        center = {
          { action = "FzfLua files",                                    desc = " Find file",       icon = " ", key = "f" },
          { action = "ene | startinsert",                                        desc = " New file",        icon = " ", key = "n" },
          { action = "FzfLua oldfiles",                                       desc = " Recent files",    icon = " ", key = "r" },
          { action = "FzfLua live_grep",                                      desc = " Find text",       icon = " ", key = "g" },
          { action = "lua require('fzf-lua').files({ cwd = '~/.config/nvim' })", desc = " Config",          icon = " ", key = "c" },
          { action = 'lua require("persistence").load()',                        desc = " Restore Session", icon = " ", key = "s" },
          { action = "LazyExtras",                                               desc = " Lazy Extras",     icon = " ", key = "x" },
          { action = "Lazy",                                                     desc = " Lazy",            icon = "󰒲 ", key = "l" },
          { action = "qa",                                                       desc = " Quit",            icon = " ", key = "q" },
        },
          footer = function()
            local stats = require("lazy").stats()
            local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
            return { "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
          end,
        },
      }

      for _, button in ipairs(opts.config.center) do
        button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
        button.key_format = "  %s"
      end

      -- close Lazy and re-open when the dashboard is ready
      if vim.o.filetype == "lazy" then
        vim.cmd.close()
        vim.api.nvim_create_autocmd("User", {
          pattern = "DashboardLoaded",
          callback = function()
            require("lazy").show()
          end,
        })
      end

      return opts
    end,
  },
  {
    "echasnovski/mini.hipatterns",
    event = "BufReadPre",
    opts = {
      highlighters = {
        hsl_color = {
          pattern = "hsl%(%d+,? %d+%%?,? %d+%%?%)",
          group = function(_, match)
            local utils = require("solarized-osaka.hsl")
            --- @type string, string, string
            local nh, ns, nl = match:match("hsl%((%d+),? (%d+)%%?,? (%d+)%%?%)")
            --- @type number?, number?, number?
            local h, s, l = tonumber(nh), tonumber(ns), tonumber(nl)
            --- @type string
            local hex_color = utils.hslToHex(h, s, l)
            return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
          end,
        },
      },
    },
  },
  {
    "xiyaowong/transparent.nvim",
    opts = {},
  }
}
