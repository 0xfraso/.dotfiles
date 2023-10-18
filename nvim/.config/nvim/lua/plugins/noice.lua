return {
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        config = function()
            require("noice").setup({
                lsp = {
                    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
                    override = {
                        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                        ["vim.lsp.util.stylize_markdown"] = true,
                        ["cmp.entry.get_documentation"] = true,
                    },
                },
                -- you can enable a preset for easier configuration
                presets = {
                    bottom_search = true,         -- use a classic bottom cmdline for search
                    command_palette = true,       -- position the cmdline and popupmenu together
                    long_message_to_split = true, -- long messages will be sent to a split
                    inc_rename = false,           -- enables an input dialog for inc-rename.nvim
                    lsp_doc_border = true,        -- add a border to hover docs and signature help
                },
                views = {
                    mini = {
                        backend = "mini",
                        relative = "editor",
                        align = "message-right",
                        timeout = 3000,
                        reverse = false,
                        focusable = true,
                        position = {
                            row = -2,
                            col = "100%",
                            -- col = 0,
                        },
                        size = "auto",
                        border = {
                            style = "rounded",
                            padding = { 0, 0 },
                        },
                        zindex = 60,
                        win_options = {
                            winblend = 0,
                            winhighlight = {
                                Normal = "NormalFloat",
                                IncSearch = "",
                                CurSearch = "",
                                Search = "",
                            },
                        },
                    }
                }
            })
        end,
        dependencies = {
            "MunifTanjim/nui.nvim",
        }
    },
}
