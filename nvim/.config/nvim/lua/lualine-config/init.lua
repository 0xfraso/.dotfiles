require('lualine').setup({
  options = {
    icons_enabled = true,
    theme = 'auto',
--    section_separators = {left = '', right = ''},
--    component_separators = {left = '', right = ''},
    component_separators = '|',
    section_separators = { left = '', right = '' },
    disabled_filetypes = {}
  }, 
  extensions = {'nvim-tree'}
})
