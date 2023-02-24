local api = vim.api
local augroup = api.nvim_create_augroup
local autocmd = api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40
        })
    end
})

api.nvim_create_user_command("Autorun", function()
    --local current_bufnr = api.nvim_get_current_buf()
    --local pattern = vim.fn.input 'Pattern: '
    local bufnr = api.nvim_create_buf(false, true)
    -- enable zsh colors
    api.nvim_buf_set_option(bufnr, "filetype", "zsh")
    local command = vim.split(vim.fn.input 'Command: ', ' ')
    api.nvim_command('split | b' .. bufnr)
    api.nvim_create_autocmd("BufWritePost", {
        group = api.nvim_create_augroup("fraso-automagic", { clear = true }),
        --pattern = pattern,
        callback = function()
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
    })
end, {})

-- get hightlight under cursor
api.nvim_create_user_command("HightlightUnderCursor", function()
    local result = vim.treesitter.get_captures_at_cursor(0)
    print(vim.inspect(result))
end, {})

vim.keymap.set("n", "<leader>z", '<Cmd>Autorun<CR>')
