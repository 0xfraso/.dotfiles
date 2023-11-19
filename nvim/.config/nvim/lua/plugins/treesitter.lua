return {
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        config = function()
            local status, ts = pcall(require, "nvim-treesitter.configs")
            if (not status) then return end

            ts.setup {
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
                    "markdown_inline"
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
        "/nvim-treesitter/nvim-treesitter-context",
        config = function()
            vim.keymap.set("n", "U", function()
                require("treesitter-context").go_to_context()
            end, { silent = true })
        end
    }
}
