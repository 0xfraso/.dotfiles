return {
    '0xfraso/nvim-listchars',
    config = function()
        require("nvim-listchars").setup({
            save_state = true,
            listchars = {
                trail = '-',
                tab = '» ',
                space = '·',
                nbsp = '␣',
                --eol = '↴',
            },

        })

        vim.keymap.set("n", "<leader>ll", '<Cmd>:ListcharsToggle<CR>')
        vim.keymap.set("n", "<leader>lu", '<Cmd>:ListcharsLightenColors<CR>')
        vim.keymap.set("n", "<leader>ld", '<Cmd>:ListcharsDarkenColors<CR>')
    end
}
