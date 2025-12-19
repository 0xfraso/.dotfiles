return {
  {
    "mbbill/undotree",
    opts = {},
    keys = {
      { "<leader>uu", vim.cmd.UndotreeToggle, desc = "open undotree" }
    }
  },
  {
    "backdround/global-note.nvim",
    opts = {},
    keys = {
      { "<leader>nt", ":lua require('global-note').toggle_note()<cr>", desc = "Global note" }
    }
  },
  {
    "echasnovski/mini.align",
    opts = {}
  },
  {
    "echasnovski/mini.hipatterns",
    event = "BufReadPre",
    config = function()
      local hipatterns = require("mini.hipatterns")
      hipatterns.setup({
        highlighters = {
          -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
          fixme     = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
          hack      = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
          todo      = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
          note      = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },

          -- Highlight hex color strings (`#rrggbb`) using that color
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      })
    end,
    {
      "mistweaverco/kulala.nvim",
      opts = {},
      filetype = "http",
      keys = {
        { "<leader>kr", ":lua require('kulala').run()<CR>", { desc = "Kulala Run" } },
        { "<leader>kc", ":lua require('kulala').copy()<CR>", { desc = "Kulala Copy as curl" } }
      }
    }
  },
  {
    "nvzone/timerly",
    dependencies = {
      "nvzone/volt",
    },
    cmd = "TimerlyToggle",
    opts = {
      on_finish = function()
        os.execute [[notify-send "Timerly: time's up!"]]
      end,
    },
    keys = {
      { "<leader>tt", ":TimerlyToggle<CR>", { desc = "TimerlyToggle" } }
    }
  },

  { "uhs-robert/sshfs.nvim", opts = {} }
}
