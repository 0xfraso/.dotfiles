return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
          xml = { 'sonarlint' },
          javascript = { 'prettier' },
          typescript = { 'prettier' },
          html = { 'prettier' },
          json = { 'prettier' }
        }
      })
      vim.keymap.set({ "n", "v" },
        "<leader>cf",
        function()
          require("conform").format({
            lsp_fallback = true,
            async = false,
            timeout_ms = 500
          })
        end, { desc = "Format file or range (visual)" }
      )
    end,
  },
  {
    "brenton-leighton/multiple-cursors.nvim",
    version = "*", -- Use the latest tagged version
    opts = {},     -- This causes the plugin setup function to be called
    keys = {
      { "<C-j>",         "<Cmd>MultipleCursorsAddDown<CR>",          mode = { "n", "x" },      desc = "Add cursor and move down" },
      { "<C-k>",         "<Cmd>MultipleCursorsAddUp<CR>",            mode = { "n", "x" },      desc = "Add cursor and move up" },

      { "<C-Up>",        "<Cmd>MultipleCursorsAddUp<CR>",            mode = { "n", "i", "x" }, desc = "Add cursor and move up" },
      { "<C-Down>",      "<Cmd>MultipleCursorsAddDown<CR>",          mode = { "n", "i", "x" }, desc = "Add cursor and move down" },

      { "<C-LeftMouse>", "<Cmd>MultipleCursorsMouseAddDelete<CR>",   mode = { "n", "i" },      desc = "Add or remove cursor" },

      { "<Leader>m",     "<Cmd>MultipleCursorsAddVisualArea<CR>",    mode = { "x" },           desc = "Add cursors to the lines of the visual area" },

      { "<Leader>a",     "<Cmd>MultipleCursorsAddMatches<CR>",       mode = { "n", "x" },      desc = "Add cursors to cword" },
      { "<Leader>A",     "<Cmd>MultipleCursorsAddMatchesV<CR>",      mode = { "n", "x" },      desc = "Add cursors to cword in previous area" },

      { "<Leader>d",     "<Cmd>MultipleCursorsAddJumpNextMatch<CR>", mode = { "n", "x" },      desc = "Add cursor and jump to next cword" },
      { "<Leader>D",     "<Cmd>MultipleCursorsJumpNextMatch<CR>",    mode = { "n", "x" },      desc = "Jump to next cword" },

      { "<Leader>l",     "<Cmd>MultipleCursorsLock<CR>",             mode = { "n", "x" },      desc = "Lock virtual cursors" },
    },
  },
  {
    "windwp/nvim-ts-autotag",
    opts = {}
  },
  {
    "tpope/vim-dadbod",
    dependencies = {
      "kristijanhusak/vim-dadbod-ui",
      { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true }, -- Optional
      cmd = {
        'DBUI',
        'DBUIToggle',
        'DBUIAddConnection',
        'DBUIFindBuffer',
      },
      init = function()
        -- Your DBUI configuration
        vim.g.db_ui_use_nerd_fonts = 1
      end,
    },
    keys = {
      { "<leader>db", ":DBUIToggle<cr>", desc = "DBUI toggle", },
    }
  },
  {
    'stevearc/quicker.nvim',
    ft = "qf",
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {
      max_filename_width = function()
        return math.floor(math.min(30, vim.o.columns / 2))
      end,
      -- How far the header should extend to the right
      header_length = function(type, start_col)
        return vim.o.columns - start_col
      end,
    },
    keys = {
      {
        ">",
        function()
          require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
        end,
        desc = "Expand quickfix context",
      },
      {
        "<",
        function()
          require("quicker").collapse()
        end,
        desc = "Collapse quickfix context",
      },
      {
        "f",
        function()
          vim.ui.input({ prompt = "Filter pattern: " }, function(pattern)
            if pattern and pattern ~= "" then
              vim.cmd("Cfilter " .. pattern)
            end
          end)
        end,
        desc = "Filter quickfix entries",
      },
      {
        "F",
        function()
          vim.ui.input({ prompt = "Filter pattern (inverted): " }, function(pattern)
            if pattern and pattern ~= "" then
              vim.cmd("Cfilter! " .. pattern)
            end
          end)
        end,
        desc = "Filter quickfix entries (inverted)",
      },
    },
  }
}
