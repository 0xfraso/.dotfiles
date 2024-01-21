return {
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
            "nvim-treesitter/nvim-treesitter-angular"
        },
        build = ':TSUpdate',
        config = function()
            local status, ts = pcall(require, "nvim-treesitter.configs")
            if (not status) then return end

            ts.setup {
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ["af"] = "@function.outer",
                            ["if"] = "@function.inner"
                        },
                        include_surrounding_whitespace = false
                    }
                },
                highlight = {
                    enable = true,
                    disable = {},
                },
                indent = {
                    enable = true,
                    disable = {},
                },
                ensure_installed = {
                    "tsx",
                    "javascript",
                    "typescript",
                    "rust",
                    --"php",
                    "json",
                    "css",
                    "html",
                    "lua",
                    "python",
                    "bash",
                    "c",
                    "sql",
                    "java",
                    "markdown",
                    "markdown_inline",
                    "http"
                },
                autotag = {
                    enable = true,
                },
            }

            local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
            parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }
        end
    },
    {
        "nvim-treesitter/nvim-treesitter-context",
        config = function()
            vim.keymap.set("n", "U", function()
                require("treesitter-context").go_to_context()
            end, { silent = true })
        end
    },
}
