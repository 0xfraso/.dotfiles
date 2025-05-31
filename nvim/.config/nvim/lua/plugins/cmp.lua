return {
  "saghen/blink.cmp",
  build = "cargo build --release",
  opts_extend = {
    "sources.completion.enabled_providers",
    "sources.default",
  },
  dependencies = {
    "rafamadriz/friendly-snippets",
    {
      "saghen/blink.compat",
      lazy = true,
      opts = {},
      config = function()
        -- monkeypatch cmp.ConfirmBehavior for Avante
        require("cmp").ConfirmBehavior = {
          Insert = "insert",
          Replace = "replace",
        }
      end,
    },
    'kristijanhusak/vim-dadbod-completion'
  },
  event = "InsertEnter",

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = function()
    local border = "single"
    return {
      appearance = {
        -- sets the fallback highlight groups to nvim-cmp's highlight groups
        -- useful for when your theme doesn't support blink.cmp
        -- will be removed in a future release, assuming themes add support
        use_nvim_cmp_as_default = false,
        -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- adjusts spacing to ensure icons are aligned
        nerd_font_variant = "mono",
      },
      completion = {
        accept = {
          -- experimental auto-brackets support
          auto_brackets = {
            enabled = true,
          },
        },
        menu = {
          draw = {
            treesitter = { "lsp" },
          },
          border = border
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = border }
        },
        ghost_text = {
          enabled = true,
        },
      },

      -- experimental signature help support
      -- signature = { enabled = true },

      sources = {
        -- adding any nvim-cmp sources here will enable them
        default = {
          "lsp",
          "path",
          "snippets",
          "buffer",
          "dadbod",
        },
        providers = {
          cmdline = {
            enabled = false
          },
          buffer = {
            enabled = false
          },
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
        }
      },

      keymap = {
        preset = "enter",
        ["<C-y>"] = { "select_and_accept" },
        ['<C-k>'] = { 'select_prev', 'fallback' },
        ['<C-j>'] = { 'select_next', 'fallback' },
      },
    }
  end,
}
