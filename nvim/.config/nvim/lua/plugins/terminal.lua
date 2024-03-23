return {
  "0xfraso/command.nvim",
  opts = {}, -- see section below for configuration options
  dependencies = {
    "akinsho/toggleterm.nvim",
    "stevearc/dressing.nvim", -- optional, but recommended
  },
  keys = {
    { "<leader>tl", ":CommandSelect<CR>",     desc = "Select command" },
    { "<leader>tp", ":CommandPrompt<CR>",     desc = "Prompt command" },
    { "<leader>tP", ":CommandPromptLast<CR>", desc = "Prompt last command" },
    { "<leader>tc", ":CommandExecLast<CR>",   desc = "Exec last command" },
    { "<leader>te", ":CommandEdit<CR>",       desc = "Edit commands file" },
  }
}
