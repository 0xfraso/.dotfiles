local api = vim.api

local M = {}

COMPILE_COMMAND = {}

function M.compile_command()
    COMPILE_COMMAND = vim.split(vim.fn.input('Command: '), ' ', {})

    if table.concat(COMPILE_COMMAND, " ") == '' then
        print("empty command")
        return
    end
end

function M.compile()
    local bufnr = api.nvim_create_buf(false, true)
    -- enable zsh colors
    api.nvim_buf_set_option(bufnr, "filetype", "zsh")

    if table.concat(COMPILE_COMMAND, " ") == '' then
        M.compile_command()
    end

    api.nvim_command('split | b' .. bufnr)

    local append_data = function(job_id, data)
        vim.api.nvim_create_autocmd('BufLeave', {
            group = vim.api.nvim_create_augroup("fraso-automagic", { clear = true }),
            pattern = '*',
            callback = function()
                vim.fn.jobstop(job_id)
            end
        })
        if data then
            api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
        end
    end


    api.nvim_buf_set_lines(bufnr, 0, -1, false,
        { string.format("Command: `%s`:", table.concat(COMPILE_COMMAND, " ")) })
    api.nvim_buf_set_lines(bufnr, -1, -1, false, { "" })

    local result = vim.fn.jobstart(COMPILE_COMMAND, {
        stdout_buffered = true,
        on_stdout = append_data,
        on_stderr = append_data,
        on_exit = function(_, exit_code)
            local hi_cmd
            if exit_code == 0 then
                hi_cmd =
                    vim.fn.printf('call matchadd("%s", "%s")', "String", "finished")
                api.nvim_buf_set_lines(bufnr, -1, -1, false, { "Compilation finished" })
            else
                api.nvim_buf_set_lines(bufnr, -1, -1, false, { "Compilation exited with code: " .. exit_code })
                hi_cmd =
                    vim.fn.printf('call matchadd("%s", "%s")', "WarningMsg", "exited")
            end
            vim.cmd(hi_cmd)
        end
    })

    if result == -1 then
        COMPILE_COMMAND = {}
    end
end

return M
