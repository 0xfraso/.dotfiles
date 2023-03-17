return {
    'fraso-dev/nvim-listchars',
    config = function()
        require("nvim-listchars").setup({
            enable = true,
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
    end
}
