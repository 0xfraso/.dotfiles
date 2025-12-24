return {
  {
    "mason-org/mason.nvim",
    opts = {}
  },
  {
    "nvim-java/nvim-java",
    lazy = false,
    dependencies = {
      "nvim-java/lua-async-await",
    },
    config = function ()
      require("java").setup({
        jdk = {
          auto_install = true,
        },
        jdtls = {
          version = "1.54.0"
        },
        spring_boot_tools = { enable = true },
        java_test = { enable = false }
      })
      vim.lsp.enable('jdtls')
    end
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'onsails/lspkind-nvim',
      'saghen/blink.cmp',
      "neovim/nvim-lspconfig",
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      "MunifTanjim/nui.nvim",
      "mfussenegger/nvim-dap",
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc, silent = true })
          end

          map('K', function () vim.lsp.buf.hover({ border = 'rounded' }) end, '[K] Hover')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('gr', ":FzfLua lsp_references<CR>", '[G]oto [R]eferences')
          map('gi', ":FzfLua lsp_implementations<CR>", '[G]oto [I]mplementation')
          map('gd', ":FzfLua lsp_definitions<CR>", '[G]oto [D]efinition')
          map('gW', ":FzfLua lsp_live_workspace_symbols<CR>", 'Open Workspace Symbols')
          map('<leader>xx', ":lua vim.diagnostic.setqflist()<CR>", 'Open diagnostics')

          map('<leader>cu', function()
            vim.lsp.buf.code_action({
              apply = true,
              context = {
                only = { "source.removeUnused.ts" },
                diagnostics = {},
              },
            })
          end, "Clear unused imports")

          -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
          ---@param client vim.lsp.Client
          ---@param method vim.lsp.protocol.Method
          ---@param bufnr? integer some lsp support methods only in specific files
          ---@return boolean
          local function client_supports_method(client, method, bufnr)
            if vim.fn.has 'nvim-0.11' == 1 then
              return client:supports_method(method, bufnr)
            else
              return client.supports_method(method, { bufnr = bufnr })
            end
          end

          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- Diagnostic Config
      -- See :help vim.diagnostic.Opts
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            local diagnostic_message = {
              [vim.diagnostic.severity.ERROR] = '',
              [vim.diagnostic.severity.WARN]  = '',
              [vim.diagnostic.severity.INFO]  = '',
              [vim.diagnostic.severity.HINT]  = '',
            }
            return diagnostic_message[diagnostic.severity]
          end,
        },
      }

      local capabilities = require('blink.cmp').get_lsp_capabilities()

      -- must `npm i @angular/language-service typescript` in this path
      local languageServerPath = vim.fn.stdpath("data") .. "/mason/packages/angular-language-server/"
      local cmd = { "ngserver", "--stdio", "--tsProbeLocations", languageServerPath, "--ngProbeLocations",
        languageServerPath }

      local original_servers_table = {
        lemminx = {},
        angularls = {
          cmd = cmd,
          on_new_config = function(new_config)
            new_config.cmd = cmd
          end,
        },
        ts_ls = {},
        gopls = {},
        cssls = {},
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim", "require" } },
              workspace = { library = vim.api.nvim_get_runtime_file("", true) },
              telemetry = { enable = false },
            },
          },
        },
      }

      for key, value in pairs(original_servers_table) do
        require('lspconfig')[key].setup(value)
      end
    end
  },
  {
    "andreshazard/vim-freemarker",
    config = function() return {} end
  }
}
