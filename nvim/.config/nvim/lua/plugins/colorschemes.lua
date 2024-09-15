return {
  { "raddari/last-color.nvim",          lazy = true },
  {
    "blazkowolf/gruber-darker.nvim",
    lazy = true,
    opts = {
      bold = true,
      invert = {
        signs = false,
        tabline = false,
        visual = false,
      },
      italic = {
        strings = false,
        comments = false,
        operators = false,
        folds = true,
      },
      undercurl = true,
      underline = true,
    }
  },
  { "olimorris/onedarkpro.nvim",        lazy = true }, 
  { "aktersnurra/no-clown-fiesta.nvim", lazy = true },
  { "catppuccin/nvim",                  lazy = true },
  { "NTBBloodbath/doom-one.nvim",       lazy = true },
  {
    "craftzdog/solarized-osaka.nvim",
    lazy = true,
    opts = function()
      local transparent = true
      return {
        transparent = true,
        on_highlights = function(hi, col)
          hi.Whitespace = { fg = "#384347" }
          hi.NonText = { fg = "#384347" }
        end,
        styles = {
          -- Style to be applied to different syntax groups
          -- Value is any valid attr-list value for `:help nvim_set_hl`
          comments = { italic = true },
          keywords = { italic = true },
          functions = {},
          variables = {},
          -- Background styles. Can be "dark", "transparent" or "normal"
          sidebars = transparent and "transparent" or "dark",
          floats = transparent and "transparent" or "dark",
        },
      }
    end,
  },
}
