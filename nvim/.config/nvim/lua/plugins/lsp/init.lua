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
        local status_neodev, neodev = pcall(require, "mason-lspconfig")
        if (not status_neodev) then return end

        neodev.setup()
        mason.setup()

        local protocol = require('vim.lsp.protocol')

        -- Use an on_attach function to only map the following keys
        -- after the language server attaches to the current buffer
        local on_attach = function(client, bufnr)
            vim.keymap.set("n", "<space>l", function()
                if client.server_capabilities.inlayHintProvider then
                    vim.lsp.inlay_hint.enable(bufnr, not vim.lsp.inlay_hint.is_enabled())
                end
            end)
        end

        -- Set up completion using nvim_cmp with LSP source
        local capabilities = require('cmp_nvim_lsp').default_capabilities(
            vim.lsp.protocol.make_client_capabilities()
        )

        local servers_settings = {
            tsserver = {
                javascript = {
                    inlayHints = {
                        includeInlayEnumMemberValueHints = true,
                        includeInlayFunctionLikeReturnTypeHints = true,
                        includeInlayFunctionParameterTypeHints = true,
                        includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
                        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                        includeInlayPropertyDeclarationTypeHints = true,
                        includeInlayVariableTypeHints = false,
                    },
                },

                typescript = {
                    inlayHints = {
                        includeInlayEnumMemberValueHints = true,
                        includeInlayFunctionLikeReturnTypeHints = true,
                        includeInlayFunctionParameterTypeHints = true,
                        includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
                        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                        includeInlayPropertyDeclarationTypeHints = true,
                        includeInlayVariableTypeHints = false,
                    },
                },
            },
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
                    hint = { enable = true }
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
