return {
  "ibhagwan/fzf-lua",
  lazy = false,
  config = function()
    require("fzf-lua").setup({
      "default-title",
      winopts = {
        fullscreen = true
      },
      keymap = {
        fzf = {
          ["ctrl-l"] = "select-all+accept",
        },
      }
    })
  end,
  keys = {
    { "<leader>F",  ":FzfLua<CR>",       desc = "FzfLua" },
    { "<leader>ff", ":FzfLua files<CR>", desc = "files" },
    {
      "<leader><space>",
      function()
        require("fzf-lua").buffers({
          cmd = "rg --files",
          winopts = { preview = { hidden = "hidden" } }
        })
      end,
      desc = "buffers"
    },
    { "<leader>ge", ":FzfLua lsp_references<CR>",                                                     desc = "lsp_references" },
    { "<leader>fg", ":FzfLua live_grep<CR>",                                                          desc = "live_grep" },
    { "<leader>fw", ":FzfLua grep_cword<CR>",                                                         desc = "grep_cword" },
    { "<leader>gs", ":FzfLua git_status<CR>",                                                         desc = "git_status" },
    { "<leader>fr", ":FzfLua resume<CR>",                                                             desc = "resume" },
    { "<leader>fc", ":lua require('fzf-lua').files({ cwd = '~/.config/nvim' })<CR>",                  desc = "config files" },
    { "<leader>fp", ":FzfLua commands<CR>",                                                           desc = "commands" },
    { "<leader>gc", ":lua require('fzf-lua').git_commits({ winopts = {  fullscreen = true } })<CR>",  desc = "git commits" },
    { "<leader>gC", ":lua require('fzf-lua').git_bcommits({ winopts = {  fullscreen = true } })<CR>", desc = "git back commits" },
  },
}
