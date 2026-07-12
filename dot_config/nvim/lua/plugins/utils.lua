return {
  {
    "mbbill/undotree",
    opts = {},
    keys = {
      { "<leader>uu", vim.cmd.UndotreeToggle, desc = "open undotree" }
    }
  },

  {
    "mistweaverco/kulala.nvim",
    opts = {},
    filetype = "http",
    keys = {
      { "<leader>kr", ":lua require('kulala').run()<CR>",  { desc = "Kulala Run" } },
      { "<leader>kc", ":lua require('kulala').copy()<CR>", { desc = "Kulala Copy as curl" } }
    }
  },
  { "uhs-robert/sshfs.nvim", opts = {} }
}
