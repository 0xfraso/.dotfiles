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
            direction = "float"
        })
    end
}
