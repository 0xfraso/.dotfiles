return {
    'epwalsh/obsidian.nvim',
    ft = "markdown",
    config = function()
        local obsidian = require('obsidian')
        obsidian.setup({
            dir = "~/vault",
            completion = {
                nvim_cmp = true
            }
        })

        vim.keymap.set("n", "gf", function()
                if obsidian.util.cursor_on_markdown_link() then
                    return "<cmd>ObsidianFollowLink<CR>"
                else
                    return "gf"
                end
            end,
            { noremap = false, expr = true }
        )
    end
}
