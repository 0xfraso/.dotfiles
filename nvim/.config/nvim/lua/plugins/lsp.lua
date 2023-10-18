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
        end

        -- Set up completion using nvim_cmp with LSP source
        local capabilities = require('cmp_nvim_lsp').default_capabilities(
            vim.lsp.protocol.make_client_capabilities()
        )

        mason.setup()

        local servers_settings = {
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
            lightbulb = {
                enable = true,
                sign = false,
                debounce = 10,
                sign_priority = 40,
                virtual_text = true,
                enable_in_insert = true,
            },
        })

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
    end,
    keys = {
        { 'gn', '<Cmd>Lspsaga diagnostic_jump_next<CR>', desc = "Lspsaga" },
        { 'gp', '<Cmd>Lspsaga diagnostic_jump_prev<CR>', desc = "Lspsaga" },
        { 'H',  '<Cmd>Lspsaga hover_doc<CR>',            desc = "Lspsaga" },
        { 'gh', '<Cmd>Lspsaga peek_definition<CR>',      desc = "Lspsaga" },
        { 'gH', '<Cmd>Lspsaga goto_definition<CR>',      desc = "Lspsaga" },
        { 'gd', '<Cmd>Lspsaga finder<CR>',               desc = "Lspsaga" },
        { 'gs', '<Cmd>Lspsaga show_buf_diagnostics<CR>', desc = "Lspsaga" },
        { 'gr', '<Cmd>Lspsaga rename<CR>',               desc = "Lspsaga" },
        { 'ga', '<Cmd>Lspsaga code_action<CR>',          desc = "Lspsaga" },
        { 'go', '<Cmd>Lspsaga outline<CR>',              desc = "Lspsaga" },
    }

}
