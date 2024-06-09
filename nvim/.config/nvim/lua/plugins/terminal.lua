return {
  {
    "0xfraso/command.nvim",
    opts = {
      cache_file = vim.fn.stdpath("cache") .. "/commands",
      shell_file = os.getenv("HOME") .. "/.zsh_history",
    }, -- see section below for configuration options
    dependencies = {
      "akinsho/toggleterm.nvim",
      "stevearc/dressing.nvim", -- optional, but recommended
    },
    keys = {
      { "<leader>tl", ":CommandSelect<CR>", desc = "Select command" },
      { "<leader>tr", ":CommandSelectShellHistory<CR>", desc = "Select command" },
      { "<leader>tp", ":CommandPrompt<CR>", desc = "Prompt command" },
      { "<leader>tP", ":CommandPromptLast<CR>", desc = "Prompt last command" },
      { "<leader>tc", ":CommandExecLast<CR>", desc = "Exec last command" },
      { "<leader>te", ":CommandEdit<CR>", desc = "Edit commands file" },
    },
  },
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<c-\>]],
        shade_terminals = false,
        shell = "zsh",
      })
    end,
    keys = {
      { [[<C-\>]] },
      { "<leader>tt", "<cmd>ToggleTerm size=20 direction=horizontal<cr>", desc = "Terminal split" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal floating" },
    },
  },
}
