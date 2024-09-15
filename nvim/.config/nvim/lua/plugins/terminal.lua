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
        shade_terminals = false,
        shell = "zsh",
      })
    end,
    keys = {
      { "<leader>/", ":ToggleTerm<CR>", desc = "ToggleTerm" },
    }
  },
}
