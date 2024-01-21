local ok, _ = pcall(require, "toggleterm")
if (not ok) then return end

local uv = vim.loop

local M = {
    last_command = nil,
    cache_path = vim.fn.stdpath("cache") .. "/commands.json"
}

---Open the file where the toggle flag is saved.
---See `:h uv.fs_open()` for a better description of parameters.
---
---@param mode string r for read, w for write
---@return integer|nil fd
local function open(mode)
    --- 438(10) == 666(8) [owner/group/others can read/write]
    local flags = 438
    local fd, err = uv.fs_open(M.cache_path, mode, flags)
    if err then
        vim.notify(("Error opening cache file:\n\n%s"):format(err), vim.log.levels.ERROR)
    end
    return fd
end

---Reads the cache to find the the last toggle flag.
---
---@return table|nil
local read_from_file = function()
    local fd = open("r")
    if not fd then
        return nil
    end

    local stat = assert(uv.fs_fstat(fd))
    local data = assert(uv.fs_read(fd, stat.size, -1))
    assert(uv.fs_close(fd))

    local decoded = vim.json.decode(data)

    local decoded_data = {}
    for _, value in pairs(decoded) do
        table.insert(decoded_data, value)
    end

    return decoded_data
end

function M.select_command()
    local cmds = read_from_file() or {}
    if #cmds == 1 and cmds[0] == nil then
        vim.notify(string.format("No commands found in %s", M.cache_path))
        M.prompt_command()
    else
        table.sort(cmds)
        vim.ui.select(cmds, {prompt = "List of available commands: "}, function (cmd)
            if cmd ~= nil then
                M.exec(cmd)
            end
        end)
    end
end

function M.prompt_command()
    local cmd = vim.split(vim.fn.input('Command: '), ' ', {})
    if table.concat(cmd, " ") == "" or cmd == nil then
        vim.notify("Please enter a valid command.", vim.log.levels.WARN)
        return
    end
    M.exec(table.concat(cmd, " "))
end

function M.exec_last(dir)
    M.exec(M.last_command, dir)
end

function M.exec(cmd, dir)
    if cmd == nil then
        M.prompt_command()
    end

    local opts      = {
        cmd = cmd,                          -- command to execute when creating the terminal e.g. 'top'
        direction = dir or "tab",           -- the layout for the terminal, same as the main config options
        close_on_exit = false,
        float_opts = {
            border = "single"
        },
        auto_scroll = true,                  -- automatically scroll to the bottom on terminal output
        autochdir = true
    }

    if cmd == nil then return end

    M.last_command = cmd

    local Terminal  = require('toggleterm.terminal').Terminal
    local term      = Terminal:new(opts)
    term:toggle()
end

return M
