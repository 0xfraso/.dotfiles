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

        require("nvim-listchars.api").set_listchars_color("#ddd000")
    end,
    lazy = false,
    priority = 0,
    keys = {
        { "<leader>ll", '<Cmd>:ListcharsToggle<CR>',        desc = "Toggle listchars" },
        { "<leader>lu", '<Cmd>:ListcharsLightenColors<CR>', desc = "Lighten listchars" },
        { "<leader>ld", '<Cmd>:ListcharsDarkenColors<CR>',  desc = "Darken listchars" },
    },
}
