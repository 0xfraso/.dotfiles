function get_config(name) return string.format('require("%s")', name) end

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'
  use {'tzachar/cmp-tabnine', run='./install.sh', requires = 'hrsh7th/nvim-cmp'}
  use {'lewis6991/impatient.nvim'}
	use { 'tami5/lspsaga.nvim' }
  -- debug plugin
  use { 'mfussenegger/nvim-dap' }

  use { 'junegunn/fzf.vim' }

  use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }

  -- colorschemes
  use {
    "thedenisnikulin/vim-cyberpunk",
    "rafi/awesome-vim-colorschemes",
    'rose-pine/neovim',
    'folke/tokyonight.nvim',
    'Mofiqul/dracula.nvim',
    'overcache/NeoSolarized',
    'sainnhe/edge',
    'Everblush/everblush.vim'
  }

  use {'nvim-treesitter/nvim-treesitter', run = ":TSUpdate", event = "BufWinEnter", config = get_config('treesitter-config')}
  use {'hoob3rt/lualine.nvim', requires = {'kyazdani42/nvim-web-devicons', opt = true}, event = "BufWinEnter", config = get_config('lualine-config')}
  use {'akinsho/bufferline.nvim', requires = 'kyazdani42/nvim-web-devicons', event = "BufWinEnter", config = get_config('bufferline-config')}
  use {'kyazdani42/nvim-tree.lua', requires = 'kyazdani42/nvim-web-devicons', cmd = "NvimTreeToggle", config = get_config('nvim-tree-config')}
  use {'windwp/nvim-ts-autotag', event = "InsertEnter", after = "nvim-treesitter"}
  use {'p00f/nvim-ts-rainbow', after = "nvim-treesitter"}
  use {'windwp/nvim-autopairs', config = get_config('autopairs-config'), after = "nvim-cmp"}
  use {'folke/which-key.nvim', event = "BufWinEnter", config = get_config('whichkey-config')}

  use {'davidgranstrom/nvim-markdown-preview'}

  use {
    'nvim-telescope/telescope.nvim',
    requires = {
      {'nvim-lua/plenary.nvim'},
    },
    cmd = "Telescope",
    event = "BufWinEnter",
    config = get_config('telescope-config')
  }

  use {'neovim/nvim-lspconfig', config = get_config('lsp')}
  use {'saadparwaiz1/cmp_luasnip'}
  use {'rafamadriz/friendly-snippets'}
  use { 'L3MON4D3/LuaSnip', config = get_config('luasnip-config') }

  use({
    "hrsh7th/nvim-cmp",
    requires = {
      { 'hrsh7th/cmp-look' },
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-nvim-lua" },
      { "hrsh7th/cmp-buffer" },
      { "hrsh7th/cmp-path" },
      { "hrsh7th/cmp-cmdline" },
    },
    config = get_config('cmp'),
  })
  use {'onsails/lspkind-nvim'}
  use {'norcalli/nvim-colorizer.lua', config = get_config('colorizer-config'), event = "BufRead"}
  use { 'benfowler/telescope-luasnip.nvim' }
  use { 'lewis6991/gitsigns.nvim', requires = {'nvim-lua/plenary.nvim'}, config = function() require('gitsigns').setup {current_line_blame = true} end }
  use {"lukas-reineke/indent-blankline.nvim", config = get_config('blankline-config'), event = "BufRead"}
  use {"akinsho/toggleterm.nvim", config = get_config('toggleterm-config')}
  use {'williamboman/nvim-lsp-installer'}
  use {'tomlion/vim-solidity'}
end)
