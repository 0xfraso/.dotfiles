local M = {}

M.search_dotfiles = function ()
  require("telescope.builtin").find_files({
    prompt_title = "< .dotfiles >",
    cwd = vim.env.DOTFILES,
    hidden = true,
  })
end

return M
