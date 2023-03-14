return {
    {
        'L3MON4D3/LuaSnip',
        config = function()
            return require('luasnip').config.setup()
        end
    },
    {
        'rafamadriz/friendly-snippets',
        config = function()
            require("luasnip").filetype_extend("javascript", { "javascriptreact" })
            require("luasnip").filetype_extend("javascript", { "html" })
            return require("luasnip.loaders.from_vscode").load({ paths = { "~/.local/share/nvim/lazy/friendly-snippets/snippets" } })
        end
    }
}
