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
    end,
    lazy = false,
    keys = {
        { "<leader>ll", '<Cmd>:ListcharsToggle<CR>',        desc = "Toggle listchars" },
        { "<leader>lu", '<Cmd>:ListcharsLightenColors<CR>', desc = "Lighten listchars" },
        { "<leader>ld", '<Cmd>:ListcharsDarkenColors<CR>',  desc = "Darken listchars" },
    },
}
