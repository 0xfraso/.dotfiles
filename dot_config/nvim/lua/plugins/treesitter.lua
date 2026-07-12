return {
  "nvim-treesitter/nvim-treesitter",
  version = false,
  build = ":TSUpdate",
  lazy = false,
  config = function()
    require("nvim-treesitter").setup {}

    local parsers = {
      "angular", "bash", "c", "diff", "html", "java", "javascript", "jsdoc",
      "json", "jsonc", "lua", "luadoc", "luap", "markdown", "markdown_inline",
      "printf", "python", "query", "regex", "toml", "tsx", "typescript",
      "vim", "vimdoc", "xml", "yaml",
    }
    require("nvim-treesitter").install(parsers):wait(300000)
  end,
}
