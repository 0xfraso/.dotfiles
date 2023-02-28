local api = vim.api

local M = {}

function M.compile()
    local bufnr = api.nvim_create_buf(false, true)
    -- enable zsh colors
    api.nvim_buf_set_option(bufnr, "filetype", "zsh")

    local command = vim.split(vim.fn.input('Command: '), ' ')

    api.nvim_command('split | b' .. bufnr)

    local append_data = function(_, data)
        if data then
            api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
        end
    end

    api.nvim_buf_set_lines(bufnr, 0, -1, false,
        { string.format("Command: `%s`: ", table.concat(command, " ")) })

    vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = append_data,
        on_stderr = append_data,
    })
end

return M
