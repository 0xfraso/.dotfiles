return {
    'xiyaowong/nvim-transparent', -- Nvim transparent background toggler
    config = function()
        require("transparent").setup({
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
                "SagaNormal",
                "NoiceCmdlinePopupBorder",
                "NoiceCmdlinePrompt",
                "NoiceCmdlineIcon",
                "NoiceCmdlinePopupBorderSearch",
                "NoiceCmdlinePopupTitle",
                "NoiceCmdlineIconSearch",
                "GitSignsAdd",
                "GitSignsDelete",
                "GitSignsChange",
                "GitSignsUntracked",
            },
        })

        vim.keymap.set('n', '<leader>T', ':TransparentToggle<CR>')
    end
}
