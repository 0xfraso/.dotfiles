return {
    "akinsho/toggleterm.nvim",
    config = function()
        require("toggleterm").setup({
            size = function()
                return vim.o.columns * 0.5
            end,
            shade_terminals = false,
            shell = vim.o.shell,
            start_in_insert = true,
            direction = "vertical",
            autochdir = true
        })
    end,
    keys = {
        { "<leader>t",  ":ToggleTerm<CR>",                                         desc = "ToggleTerm" },
        { "<leader>cc", '<Cmd>lua require("fraso/terminal").exec_last()<CR>',      desc = "ToggleTerm" },
        { "<leader>cp", '<Cmd>lua require("fraso/terminal").prompt_command()<CR>', desc = "ToggleTerm" },
        { "<leader>cl", '<Cmd>lua require("fraso/terminal").select_command()<CR>', desc = "ToggleTerm" },
    }
}
