local config = {
  cmd = {
    '/home/fraso/.local/share/nvim/mason/packages/jdtls/bin/jdtls',
  },
  root_dir = vim.fs.root(0, {".git", "pom.xml"}),
  settings = {
    java = {
    }
  },
  init_options = {
    bundles = {}
  },
}
require('jdtls').start_or_attach(config)
