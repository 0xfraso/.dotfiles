return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
          xml = {'sonarlint'},
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
    "mg979/vim-visual-multi",
    event = "BufEnter"
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
    opts = {},
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
    },
  }
}
