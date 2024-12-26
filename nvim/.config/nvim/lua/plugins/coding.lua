return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
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
    "olimorris/codecompanion.nvim",
    config = function()
      local OLLAMA_URL = os.getenv("OLLAMA_URL")
      if not OLLAMA_URL then
        OLLAMA_URL = "localhost:11434"
      end

      vim.notify(vim.print(OLLAMA_URL), vim.log.levels.WARN)

      require("codecompanion").setup({
        strategies = {
          chat = {
            adapter = "ollama",
          },
          inline = {
            adapter = "ollama"
          },
        },
        adapters = {
          ollama = function()
            return require("codecompanion.adapters").extend("ollama", {
              env = {
                url = OLLAMA_URL,
              },
              headers = {
                ["Content-Type"] = "application/json",
              },
              parameters = {
                sync = true,
              },
            })
          end,
        },
      })
    end,
    keys = {
      { "<leader>cl", ":CodeCompanionActions<cr>", desc = "CodeCompanionActions", },
      { "<leader>cp", ":CodeCompanionChat<cr>",    desc = "CodeCompanionChat", },
    }
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
    }
  }
}
