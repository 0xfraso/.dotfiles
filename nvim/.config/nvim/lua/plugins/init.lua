return
{
    { 'mg979/vim-visual-multi' },
    'nvim-treesitter/playground',
    'nvim-lua/plenary.nvim',

    { 'norcalli/nvim-colorizer.lua',  config = function() require("colorizer").setup() end },
    { 'kyazdani42/nvim-web-devicons', config = function() require("nvim-web-devicons").setup() end }, -- File icons
}
