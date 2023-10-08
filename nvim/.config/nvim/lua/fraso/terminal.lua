local api = vim.api

local M = {}

COMMAND = {}

local status, toggleterm = pcall(require, "toggleterm")
if (not status) then return end

function M.prompt_command()
    COMMAND = vim.split(vim.fn.input('Command: '), ' ', {})

    if table.concat(COMMAND, " ") == '' then
        print("empty command")
        return
    end
end

function M.exec()
    if table.concat(COMMAND, " ") == '' then
        M.prompt_command()
    end

    local direction = "vertical"

    local opts      = {
        cmd = table.concat(COMMAND, " "), -- command to execute when creating the terminal e.g. 'top'
        direction = direction,            -- the layout for the terminal, same as the main config options
        close_on_exit = false,
        float_opts = {
            border = "single"
        },
        auto_scroll = true -- automatically scroll to the bottom on terminal output
    }
    local Terminal  = require('toggleterm.terminal').Terminal
    local term      = Terminal:new(opts)
    term:toggle()
end

return M
