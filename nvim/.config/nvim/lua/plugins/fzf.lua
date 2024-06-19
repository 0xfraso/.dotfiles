return {
  "ibhagwan/fzf-lua",
  lazy = false,
  config = function ()
    require("fzf-lua").setup({
      keymap = {
        fzf = {
          ["ctrl-l"] = "select-all+accept",
        },
      }
    })
  end,
  keys = {
    { "<leader>F",  ":FzfLua<CR>", desc = "FzfLua" },
    { "<leader>ff", ":FzfLua files<CR>", desc = "files" },
    { "<leader><space>", function()
      require("fzf-lua").buffers({
        cmd = "rg --files",
        winopts = { preview = { hidden = "hidden" } }
      })
    end, desc = "buffers" },
    { "<leader>fg", ":FzfLua live_grep<CR>", desc = "live_grep" },
    { "<leader>fw", ":FzfLua grep_cword<CR>", desc = "grep_cword" },
    { "<leader>gs", ":FzfLua git_status<CR>", desc = "git_status" },
    { "<leader>fR", ":FzfLua resume<CR>", desc = "resume" },
    { "<leader>fc", ":lua require('fzf-lua').files({ cwd = '~/.config/nvim' })<CR>", desc = "config files" },
    { "<leader>gc", ":FzfLua git_commits<CR>", desc = "git commits" },
    { "<leader>gC", ":FzfLua git_bcommits<CR>", desc = "git back commits" },
  },
}
