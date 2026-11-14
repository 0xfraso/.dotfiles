local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- This config uses LazyVim as a library, not the distro: `lazyvim.plugins` is
-- intentionally not imported (config/lazy.lua is unused). LazyVim v16's
-- import-order check assumes the distro layout, so it must be disabled here.
vim.g.lazyvim_check_order = false

local status, lazy = pcall(require, "lazy")
if (not status) then
  print("Lazy is not installed")
  return
end

lazy.setup({
  { import = "plugins" },
})
