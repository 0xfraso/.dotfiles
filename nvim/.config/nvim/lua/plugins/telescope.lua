return {
    'nvim-telescope/telescope.nvim',
    config = function()
        local telescope = require("telescope")
        local actions = require('telescope.actions')
        local actions_layout = require('telescope.actions.layout')
        local builtin = require("telescope.builtin")

        telescope.setup({
            pickers = {
                find_files = {
                    no_ignore = false,
                    hidden = true,
                }
            },
            defaults = {
                prompt_prefix = "   ",
                selection_caret = "  ",
                entry_prefix = "  ",
                initial_mode = "insert",
                selection_strategy = "reset",
                sorting_strategy = "descending",
                layout_strategy = "horizontal",
                layout_config = {
                    horizontal = {
                        prompt_position = "bottom",
                        preview_width = 0.55,
                        results_width = 0.8,
                    },
                    vertical = {
                        mirror = false,
                    },
                    width = 0.87,
                    height = 0.95,
                    preview_cutoff = 120,
                },

                file_sorter = require("telescope.sorters").get_fuzzy_file,
                file_ignore_patterns = { "node_modules" },
                generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
                path_display = { "truncate" },
                winblend = 0,
                border = {},
                borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                color_devicons = true,
                set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
                file_previewer = require("telescope.previewers").vim_buffer_cat.new,
                grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
                qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
                -- Developer configurations: Not meant for general override
                buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,

                mappings = {
                    i = {
                        ["<ESC>"] = actions.close,
                        ["<C-J>"] = actions.move_selection_next,
                        ["<C-K>"] = actions.move_selection_previous,
                        ["<C-p>"] = actions_layout.toggle_preview,
                    },
                    n = i,
                },
            },
            extensions = {},
        })

        vim.keymap.set('n', '<leader>ff',
            function()
                builtin.find_files()
            end)
        vim.keymap.set('n', '<leader>fr', function()
            builtin.registers()
        end)
        vim.keymap.set('n', '<leader>fg', function()
            builtin.live_grep()
        end)
        vim.keymap.set('n', '<leader>fh', function()
            builtin.help_tags()
        end)
        vim.keymap.set('n', '<leader>fe', function()
            builtin.diagnostics()
        end)
        vim.keymap.set('n', '<leader>fw', function()
            builtin.current_buffer_fuzzy_find()
        end)
        vim.keymap.set('n', '<leader>fc', function()
            builtin.colorscheme()
        end)
    end
}
