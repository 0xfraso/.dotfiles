local wk = require("which-key")
wk.setup {
  plugins = {
    marks = false,
    registers = false,
    spelling = {enabled = false, suggestions = 20},
    presets = {operators = false, motions = false, text_objects = false, windows = false, nav = false, z = false, g = false}
  }
}
local Terminal = require('toggleterm.terminal').Terminal
local toggle_float = function()
  local float = Terminal:new({direction = "float"})
  return float:toggle()
end
local toggle_lazygit = function()
  local lazygit = Terminal:new({cmd = 'lazygit', direction = "float"})
  return lazygit:toggle()
end
local mappings = {
  f = {
    name = "Telescope",
    f = {"<cmd>lua require('telescope.builtin').find_files()<cr>", "Find Files"},
    b = {"<cmd>lua require('telescope.builtin').buffers(require('telescope.themes').get_dropdown({}))<cr>", "Buffers"},
    g = {"<cmd>lua require('telescope.builtin').live_grep()<cr>", "Live Grep"},
    h = {"<cmd>lua require('telescope.builtin').help_tags()<cr>", "Help tags"},
    r = {"<cmd>lua require('telescope.builtin').registers()<cr>", "Registers"},
    c = {"<cmd>lua require('colors').choose_colorscheme()<cr>", "Colorscheme", },
    s = { "<cmd>lua require'telescope'.extensions.luasnip.luasnip()<CR>", "Snippets" },
    d = { "<cmd>lua require('telescope-config.locals').search_dotfiles()<CR>", ".dotfiles" },
  },
  q = {":q<cr>", "Quit"},
  Q = {":wq<cr>", "Save & Quit"},
  w = {":w!<cr>", "Save"},
  x = {":bdelete<cr>", "Close"},
  c = {":CommentToggle<cr>", "Comment"},
  l = {
    name = "LSP",
    f = { "<cmd>lua vim.lsp.buf.formatting()<cr>", "Format" },
    h = { "<cmd>Lspsaga hover_doc<cr>", "Hover" },
    i = { "<cmd>LspInfo<cr>", "Info" },
    I = { "<cmd>LspInstallInfo<cr>", "Installer Info" },
    j = { "<cmd>lua vim.lsp.diagnostic.goto_next()<cr>", "Next Diagnostic", },
    k = { "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>", "Prev Diagnostic", },
    l = { "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens Action" },
    r = { "<cmd>Lspsaga rename<cr>", "Rename" },
    s = { "<cmd>Telescope lsp_document_symbols<cr>", "Document Symbols" },
    S = { "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", "Workspace Symbols", },
  },
  m = {
    name = "MarkdownPreview",
    p = {":MarkdownPreview github<cr>", "Preview"},
  },
  p = {
    name = "Packer",
    s = {":PackerSync<cr>", "Packer Sync"},
    c = {":PackerClean<cr>", "Packer Clean"},
    C = {":PackerCompile<cr>", "Packer Compile"}
  },
  o = {
    name = "Options",
    t = {"<cmd>TransparentToggle<CR>", "Toggle bg transparency"},
  },
  t = {name = "Terminal", t = {":ToggleTerm<cr>", "Split Below"}, f = {toggle_float, "Floating Terminal"}, l = {toggle_lazygit, "LazyGit"}}
}
local opts = {prefix = '<leader>'}
wk.register(mappings, opts)
