return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")

      -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        window = {
          completion = {
            border = {
              { "󱐋", "WarningMsg" },
              { "─", "FloatBorder" },
              { "╮", "FloatBorder" },
              { "│", "FloatBorder" },
              { "╯", "FloatBorder" },
              { "─", "FloatBorder" },
              { "╰", "FloatBorder" },
              { "│", "FloatBorder" },
            },
            scrollbar = false,
          },
          documentation = {
            border = {
              { "", "DiagnosticHint" },
              { "─", "FloatBorder" },
              { "╮", "FloatBorder" },
              { "│", "FloatBorder" },
              { "╯", "FloatBorder" },
              { "─", "FloatBorder" },
              { "╰", "FloatBorder" },
              { "│", "FloatBorder" },
            },
            scrollbar = false,
          },
        },

        completion = {
          completeopt = "menu,menuone,preview,noinsert",
        },

        snippet = {
          expand = function(args)
            vim.snippet.expand(args.body)
          end,
        },

        mapping = {
          ["<down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<CR>"] = cmp.mapping(
            cmp.mapping.confirm({
              behavior = cmp.ConfirmBehavior.Insert,
              select = true,
            }),
            { "i", "c" }
          ),
        },

        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
          { name = "lazydev", group_index = 0 },
        }),

        -- configure lspkind for vs-code like pictograms in completion menu
        formatting = {
          format = lspkind.cmp_format({
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
      })

      vim.keymap.set({ "i", "s" }, "<C-k>", function()
        if luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        end
      end, { silent = true })
    end,
  },
  { "mfussenegger/nvim-jdtls" },
  {
    {
      "folke/trouble.nvim",
      opts = {},
      cmd = "Trouble",
      keys = {
        { "<leader>xx", "<cmd>Trouble diagnostics toggle focus=true filter.buf=0<cr>", desc = "Diagnostics (Trouble)", },
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
          local opts_buffer = { noremap = true, silent = true, buffer = bufnr }
          vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
          -- Mappings: LSP
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          -- vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts_buffer)
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
          vim.keymap.set("n", "<leader>xn", vim.diagnostic.goto_next)
          vim.keymap.set("n", "<leader>xp", vim.diagnostic.goto_prev)
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

        require("lspconfig").angularls.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = cmd,
          on_new_config = function(new_config, new_root_dir)
            new_config.cmd = cmd
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
            virtual_text = { spacing = 4, prefix = "●" },
            update_in_insert = true,
            severity_sort = true,
          })

        vim.diagnostic.config({
          virtual_text = {
            prefix = '●'
          },
          update_in_insert = true,
          -- float = {
          --   source = "always", -- Or "if_many"
          -- },
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
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    enabled = false,
    config = function()
      require('tiny-inline-diagnostic').setup({
        signs = {
          left = "",
          right = "",
          diag = "●",
          arrow = "    ",
          up_arrow = "    ",
          vertical = " │",
          vertical_end = " └"
        },
        hi = {
          error = "DiagnosticError",
          warn = "DiagnosticWarn",
          info = "DiagnosticInfo",
          hint = "DiagnosticHint",
          arrow = "NonText",
          background = "CursorLine", -- Can be a highlight or a hexadecimal color (#RRGGBB)
          mixing_color = "None",   -- Can be None or a hexadecimal color (#RRGGBB). Used to blend the background color with the diagnostic background color with another color.
        },
        blend = {
          factor = 0.27,
        },
        options = {
          -- Throttle the update of the diagnostic when moving cursor, in milliseconds.
          -- You can increase it if you have performance issues.
          -- Or set it to 0 to have better visuals.
          throttle = 20,

          -- The minimum length of the message, otherwise it will be on a new line.
          softwrap = 15,

          -- If multiple diagnostics are under the cursor, display all of them.
          multiple_diag_under_cursor = false,

          overflow = {
            -- Manage the overflow of the message.
            --    - wrap: when the message is too long, it is then displayed on multiple lines.
            --    - none: the message will not be truncated, and will be displayed on a single line.
            mode = "wrap",
          },

          --- Enable it if you want to always have message with `after` characters length.
          break_line = {
            enabled = false,
            after = 30,
          },

          virt_texts = {
            priority = 8048,
          }
        }
      })
    end
  },
  {
    "backdround/global-note.nvim",
    opts = {
      filename = "TODO.md",
      directory = "~/"
    },
    keys = {
      { "<leader>nt", ":lua require('global-note').toggle_note()<cr>", desc = "Global note" }
    }
  },
  {
    "mg979/vim-visual-multi",
    event = "BufEnter"
  },
  {
    "mangelozzi/rgflow.nvim",
    opts = {},
    keys = {
      { "<leader>rg", ":lua require('rgflow').open()<cr>", desc = "Rgflow open" }
    }
  }
}
