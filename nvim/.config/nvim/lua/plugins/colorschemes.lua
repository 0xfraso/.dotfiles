return {
  { "xiyaowong/transparent.nvim", opts = {} },
  {
    "blazkowolf/gruber-darker.nvim",
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
  {
    "wnkz/monoglow.nvim",
    opts = {
      on_colors = function(colors)
        colors.syntax.boolean = "#ffdd33"
      end,
      on_highlights = function(hls, c)
        hls.NeogitDiffAdd = { fg = c.git.add }
        hls.NeogitDiffChange = { fg = c.git.change }
        hls.NeogitDiffDelete = { fg = c.git.delete }
        hls.NeogitDiffAddHighlight = { bg = "#212121", fg = c.git.add }
        hls.NeogitDiffChangeHighlight = { bg = "#212121", fg = c.git.change }
        hls.NeogitDiffDeleteHighlight = { bg = "#212121", fg = c.git.delete }
      end
    }
  },
  "raddari/last-color.nvim",
  "backdround/melting",
  "olimorris/onedarkpro.nvim",
  "aktersnurra/no-clown-fiesta.nvim",
  "catppuccin/nvim",
  "NTBBloodbath/doom-one.nvim",
  "craftzdog/solarized-osaka.nvim",
}
