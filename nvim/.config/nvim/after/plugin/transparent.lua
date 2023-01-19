require("transparent").setup({
    enable = true,
    extra_groups = { -- table/string: additional groups that should be cleared
        "BufferLineTabClose",
        "BufferlineBufferSelected",
        "BufferLineFill",
        "BufferLineBackground",
        "BufferLineSeparator",
        "BufferLineIndicatorSelected",

        "IndentBlanklineChar",

        -- make floating windows transparent
        "LspFloatWinNormal",
        "Normal",
        "NormalFloat",
        "FloatBorder",
        "TelescopeNormal",
        "TelescopeBorder",
        "TelescopePromptBorder",
        "SagaBorder",
    },
    exclude = {}, -- table: groups you don't want to clear
})

vim.keymap.set('n', '<leader>T', ':TransparentToggle<CR>')
