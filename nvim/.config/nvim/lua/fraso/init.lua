require('fraso.base')
require('fraso.auto')
require('fraso.maps')
require('fraso.lazy')

local has = function(x)
    return vim.fn.has(x) == 1
end
local is_mac = has "macunix"
local is_win = has "win32"

if is_mac then
    vim.opt.clipboard:append { 'unnamedplus' }
end
if is_win then
    vim.opt.clipboard:prepend { 'unnamed', 'unnamedplus' }
end

vim.cmd.colorscheme(require("last-color").recall())
