return {
    'windwp/nvim-ts-autotag',
    ft = { "html", "typescript", "javascript", "typescriptreact", "javascriptreact", "xml", "xhtml" },
    config = function() require("nvim-ts-autotag").setup() end
}
