return {
  {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle focus=true filter.buf=0<cr>", desc = "Diagnostics (Trouble)", },
      { "<leader>xw", "<cmd>Trouble diagnostics toggle focus=true filter.buf=0<cr>", desc = "Diagnostics (Trouble)", },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",            desc = "Buffer Diagnostics (Trouble)", },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=true<cr>",                  desc = "Symbols (Trouble)", },
      { "<leader>xL", "<cmd>Trouble loclist toggle focus=true<cr>",                  desc = "Location List (Trouble)", },
      { "<leader>xl", "<cmd>Trouble qflist toggle focus=true<cr>",                   desc = "Quickfix List (Trouble)", },
    },
  },
  {
    'neovim/nvim-lspconfig', -- LSP
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'onsails/lspkind-nvim', -- vscode-like pictograms
    },
    config = function()
      local status, nvim_lsp = pcall(require, "lspconfig")
      if (not status) then return end
      local status_mason, mason = pcall(require, "mason")
      if (not status_mason) then return end
      local status_mason_lspconfig, mason_lspconfig = pcall(require, "mason-lspconfig")
      if (not status_mason_lspconfig) then return end
      local status_neodev, neodev = pcall(require, "mason-lspconfig")
      if (not status_neodev) then return end

      neodev.setup()
      mason.setup()

      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      local protocol = require('vim.lsp.protocol')

      -- Use an on_attach function to only map the following keys
      -- after the language server attaches to the current buffer
      local on_attach = function(client, bufnr)
        vim.keymap.set("n", "<space>l", function()
          if client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(bufnr, not vim.lsp.inlay_hint.is_enabled())
          end
        end)
        local opts_buffer = { noremap = true, silent = true, buffer = bufnr }
        vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
        -- Mappings: LSP
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts_buffer)
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts_buffer)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts_buffer)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts_buffer)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts_buffer)
        vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, opts_buffer)
        vim.keymap.set('n', '<space>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
          opts_buffer)
        vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts_buffer)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts_buffer)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts_buffer)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts_buffer)
        vim.keymap.set('n', '<leader>cf', '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', opts_buffer)
        vim.keymap.set('n', '<leader>cu', function()
          vim.lsp.buf.code_action({
            apply = true,
            context = {
              only = { "source.removeUnused.ts" },
              diagnostics = {},
            },
          })
        end, opts_buffer)
      end

      local servers_settings = {
        tsserver = {},
        lua_ls = {
          Lua = {
            diagnostic = {
              globals = { "vim" },
            },
            workspace = {
              -- Make the server aware of Neovim runtime files
              library = vim.api.nvim_get_runtime_file("lua", true),
              checkThirdParty = false
            }
          }
        },
      }

      local server_filetypes = {
        tailwindcss = {
          "javascript", "javascriptreact", "typescript", "typescriptreact", "html", "php", "astro"
        },
      }

      -- jdtls is handled by nvim-jdtls plugin
      local ignore_servers = { "jdtls" }

      local tableContains = function(table, value)
        for i = 1, #table do
          if (table[i] == value) then
            return true
          end
        end
        return false
      end

      mason_lspconfig.setup_handlers {
        function(server_name)
          if tableContains(ignore_servers, server_name) then
            return
          end
          nvim_lsp[server_name].setup {
            capabilities = capabilities,
            on_attach = on_attach,
            settings = servers_settings[server_name] or {},
            filetypes = server_filetypes[server_name],
            root_dir = function()
              return vim.loop.cwd()
            end
          }
        end,
      }

      -- must `npm i @angular/language-service typescript` in this path
      local languageServerPath = vim.fn.stdpath("data") .. "/mason/packages/angular-language-server/"
      local cmd = { "ngserver", "--stdio", "--tsProbeLocations", languageServerPath, "--ngProbeLocations",
        languageServerPath }

      require("lspconfig").angularls.setup {
        on_attach = on_attach,
        capabilities = capabilities,
        cmd = cmd,
        on_new_config = function(new_config, new_root_dir)
          new_config.cmd = cmd
        end,
      }

      vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
        vim.lsp.diagnostic.on_publish_diagnostics, {
          underline = true,
          update_in_insert = false,
          virtual_text = { spacing = 4, prefix = "●" },
          severity_sort = true,
        })

      vim.diagnostic.config({
        virtual_text = {
          prefix = '●'
        },
        update_in_insert = true,
        float = {
          source = "always", -- Or "if_many"
        },
      })

      -- Diagnostic symbols in the sign column (gutter)
      local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      protocol.CompletionItemKind = {
        "󰉿", --Text
        "󰆧", --Method
        "󰊕", --Function
        "", --Constructor
        "󰜢", --Field
        "󰀫", --Variable
        "󰠱", --Class
        "", --Interface
        "", --Module
        "󰜢", --Property
        "󰑭", --Unit
        "󰎠", --Value
        "", --Enum
        "󰌋", --Keyword
        "", --Snippet
        "󰏘", --Color
        "󰈙", --File
        "󰈇", --Reference
        "󰉋", --Folder
        "", --EnumMember
        "󰏿", --Constant
        "󰙅", --Struct
        "", --Event
        "󰆕", --Operator
        '', -- TypeParameter
      }
    end,
  }
}
