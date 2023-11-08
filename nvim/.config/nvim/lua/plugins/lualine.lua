return {
    'nvim-lualine/lualine.nvim', -- Statusline
    config = function()
        require("lualine").setup {
            options = {
                icons_enabled = true,
                theme = 'auto',

                section_separators = { left = '', right = '' },
                component_separators = { left = '', right = '' },

                -- section_separators = { left = '', right = ''},
                -- component_separators = { left = '', right = ''},
                -- section_separators = { left = '', right = '' },
                -- component_separators = { left = '', right = '' },
                disabled_filetypes = {}
            },
            sections = {
                lualine_a = {
                    'mode',
                    {
                        'filename',
                        file_status = true, -- displays file status (readonly status, modified status)
                        path = 0            -- 0 = just filename, 1 = relative path, 2 = absolute path
                    } },
                lualine_b = { 'diff', 'progress' },
                lualine_c = { 'location',
                    {
                        require("noice").api.statusline.mode.get_hl,
                        cond = require("noice").api.statusline.mode.has,
                    }
                },
                lualine_x = {
                    {
                        function()
                            local msg = 'No Active Lsp'
                            local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
                            local clients = vim.lsp.get_active_clients()
                            if next(clients) == nil then
                                return msg
                            end
                            for _, client in ipairs(clients) do
                                local filetypes = client.config.filetypes
                                if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                                    return client.name
                                end
                            end
                            return msg
                        end,
                        icon = ' :'
                    },
                    {
                        'diagnostics',
                        sources = { "nvim_diagnostic" },
                        symbols = { error = ' ', warn = ' ', info = ' ' },
                    },
                    { 'encoding', fmt = string.upper },
                    'filetype',
                },
                lualine_y = {},
                lualine_z = { 'branch' }
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = { {
                    'filename',
                    file_status = true, -- displays file status (readonly status, modified status)
                    path = 1            -- 0 = just filename, 1 = relative path, 2 = absolute path
                } },
                lualine_x = {},
                lualine_y = {},
                lualine_z = {}
            },
            tabline = {},
            extensions = {}
        }
    end
}
