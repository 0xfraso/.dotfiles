return {
  "nvim-treesitter/nvim-treesitter",
  version = false,
  build = ":TSUpdate",
  lazy = false,
  config = function()
    require("nvim-treesitter").setup {}

    local parsers = {
      "angular", "bash", "c", "diff", "html", "java", "javascript", "jsdoc",
      "json", "lua", "luadoc", "luap", "markdown", "markdown_inline",
      "printf", "python", "query", "regex", "toml", "tsx", "typescript",
      "vim", "vimdoc", "xml", "yaml",
    }
    require("nvim-treesitter").install(parsers):wait(300000)

    -- main branch only installs parsers; highlighting/folds/indent must be
    -- started via the native API (nvim 0.11+). pcall no-ops when no parser exists.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function() pcall(vim.treesitter.start) end,
    })
  end,
}
