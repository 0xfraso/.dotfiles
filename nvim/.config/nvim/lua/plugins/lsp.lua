return {
    'neovim/nvim-lspconfig', -- LSP
    dependencies = {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'glepnir/lspsaga.nvim', -- LSP UIs
        'onsails/lspkind-nvim', -- vscode-like pictograms
    },
    config = function()
        local status, nvim_lsp = pcall(require, "lspconfig")
        if (not status) then return end
        local status_mason, mason = pcall(require, "mason")
        if (not status_mason) then return end
        local status_mason_lspconfig, mason_lspconfig = pcall(require, "mason-lspconfig")
        if (not status_mason_lspconfig) then return end

        require('neodev').setup()

        local protocol = require('vim.lsp.protocol')

        -- Use an on_attach function to only map the following keys
        -- after the language server attaches to the current buffer
        local on_attach = function(client, bufnr)
            local formatting_enabled = false
            local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

            local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

            --Enable completion triggered by <c-x><c-o>
            buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

            -- Mappings.
            local opts = { noremap = true, silent = true }

            -- See `:help vim.lsp.*` for documentation on any of the below functions
            -- buf_set_keymap('n', 'gi', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
            --buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
            --buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
            --buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)

            -- formatting
            if client.server_capabilities.documentFormattingProvider and formatting_enabled then
                vim.api.nvim_create_autocmd("BufWritePre", {
                    group = vim.api.nvim_create_augroup("Format", { clear = true }),
                    buffer = bufnr,
                    callback = function() vim.lsp.buf.format() end
                })
            end
        end

        -- Set up completion using nvim_cmp with LSP source
        local capabilities = require('cmp_nvim_lsp').default_capabilities(
            vim.lsp.protocol.make_client_capabilities()
        )

        mason.setup()

        local servers = {
            clangd = {},
            gopls = {},
            pyright = {},
            rust_analyzer = {},
            tsserver = {},
            tailwindcss = {},
            intelephense = {},
            bashls = {},
            lua_ls = {
                Lua = {
                    diagnostic = {
                        globals = { "vim" },
                    },
                    workspace = {
                        -- Make the server aware of Neovim runtime files
                        library = vim.api.nvim_get_runtime_file("lua", true),
                        checkThirdParty = false
                    },
                }
            },
        }

        mason_lspconfig.setup {
            ensure_installed = vim.tbl_keys(servers)
        }

        mason_lspconfig.setup_handlers {
            function(server_name)
                nvim_lsp[server_name].setup {
                    capabilities = capabilities,
                    on_attach = on_attach,
                    settings = servers[server_name],
                    root_dir = function()
                        return vim.loop.cwd()
                    end
                }
            end,
        }

        vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
            vim.lsp.diagnostic.on_publish_diagnostics, {
            underline = true,
            update_in_insert = false,
            virtual_text = { spacing = 4, prefix = "●" },
            severity_sort = true,
        })

        -- Diagnostic symbols in the sign column (gutter)
        local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
        for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
        end

        vim.diagnostic.config({
            virtual_text = {
                prefix = '●'
            },
            update_in_insert = true,
            float = {
                source = "always", -- Or "if_many"
            },
        })

        protocol.CompletionItemKind = {
            '', -- Text
            '', -- Method
            '', -- Function
            '', -- Constructor
            '', -- Field
            '', -- Variable
            '', -- Class
            'ﰮ', -- Interface
            '', -- Module
            '', -- Property
            '', -- Unit
            '', -- Value
            '', -- Enum
            '', -- Keyword
            '﬌', -- Snippet
            '', -- Color
            '', -- File
            '', -- Reference
            '', -- Folder
            '', -- EnumMember
            '', -- Constant
            '', -- Struct
            '', -- Event
            'ﬦ', -- Operator
            '', -- TypeParameter
        }

        local status_saga, saga = pcall(require, "lspsaga")
        if (not status_saga) then return end

        saga.setup({
            ui = {
                -- currently only round theme
                theme = 'round',
                -- border type can be single,double,rounded,solid,shadow.
                border = 'rounded',
                winblend = 0,
                expand = '',
                collaspe = '',
                preview = ' ',
                code_action = '💡',
                diagnostic = '🐞',
                incoming = ' ',
                outgoing = ' ',
                kind = {},
            },
        })

        local opts = { noremap = true, silent = true }
        vim.keymap.set('n', 'gn', '<Cmd>Lspsaga diagnostic_jump_next<CR>', opts)
        vim.keymap.set('n', 'gp', '<Cmd>Lspsaga diagnostic_jump_prev<CR>', opts)
        vim.keymap.set('n', 'H', '<Cmd>Lspsaga hover_doc<CR>', opts)
        vim.keymap.set('n', 'gh', '<Cmd>Lspsaga peek_definition<CR>', opts)
        vim.keymap.set('n', 'gH', '<Cmd>Lspsaga goto_definition<CR>', opts)
        vim.keymap.set('n', 'gd', '<Cmd>Lspsaga lsp_finder<CR>', opts)
        vim.keymap.set('n', 'gs', '<Cmd>Lspsaga show_buf_diagnostics<CR>', opts)
        vim.keymap.set('n', 'gr', '<Cmd>Lspsaga rename<CR>', opts)
        vim.keymap.set('n', 'ga', '<Cmd>Lspsaga code_action<CR>', opts)
        vim.keymap.set('n', 'go', '<Cmd>Lspsaga outline<CR>', opts)


        local status_lspkind, lspkind = pcall(require, "lspkind")
        if (not status_lspkind) then return end

        lspkind.init({
            mode = 'symbol',
            maxwidth = 50,
            ellipsis_char = "...",
            preset = 'codicons',
            symbol_map = {
                Text = "",
                Method = "",
                Function = "",
                Constructor = "",
                Field = "ﰠ",
                Variable = "",
                Class = "ﴯ",
                Interface = "",
                Module = "",
                Property = "ﰠ",
                Unit = "塞",
                Value = "",
                Enum = "",
                Keyword = "",
                Snippet = "",
                Color = "",
                File = "",
                Reference = "",
                Folder = "",
                EnumMember = "",
                Constant = "",
                Struct = "פּ",
                Event = "",
                Operator = "",
                TypeParameter = ""
            },
        })
    end
}
