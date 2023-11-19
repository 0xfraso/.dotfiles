return {
    '0xfraso/gruber-darker.nvim',
    lazy = false,
    opts = {
        bold = true,
        invert = {
            visual = false
        },
    },
    config = function ()
        vim.api.nvim_set_hl(0, "TreesitterContext", { link = "Visual" })
    end
}
