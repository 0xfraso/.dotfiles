return {
    'nvim-telescope/telescope.nvim',
    dependencies = {
        'nvim-telescope/telescope-file-browser.nvim',
    },
    config = function()
        local telescope = require("telescope")
        local actions = require('telescope.actions')
        local actions_layout = require('telescope.actions.layout')
        local builtin = require("telescope.builtin")

        local function telescope_buffer_dir()
            return vim.fn.expand('%:p:h')
        end

        local current_theme = function(previewer)
            return require('telescope.themes').get_ivy {
                previewer = previewer,
            }
        end

        local fb_actions = require 'telescope'.extensions.file_browser.actions
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
            extensions = {
                file_browser = {
                    -- disables netrw and use telescope-file-browser in its place
                    hijack_netrw = true,
                    theme = "ivy",
                    mappings = {
                        -- your custom insert mode mappings
                        ["i"] = {
                        },
                        ["n"] = {
                            -- your custom normal mode mappings
                            ["N"] = fb_actions.create,
                            ["-"] = fb_actions.goto_parent_dir,
                        },
                    },
                },
            },
        })

        telescope.load_extension("file_browser")

        vim.keymap.set('n', '<leader>ff',
            function()
                builtin.find_files(current_theme(true))
            end)
        vim.keymap.set('n', '<leader>fr', function()
            builtin.registers(current_theme())
        end)
        vim.keymap.set('n', '<leader>fg', function()
            builtin.live_grep(current_theme())
        end)
        vim.keymap.set('n', '<leader>fh', function()
            builtin.help_tags(current_theme(true))
        end)
        vim.keymap.set('n', '<leader>fe', function()
            builtin.diagnostics(current_theme(false))
        end)
        vim.keymap.set("n", "<leader>fd", function()
            telescope.extensions.file_browser.file_browser({
                path = "%:p:h",
                cwd = telescope_buffer_dir(),
                respect_gitignore = false,
                hidden = true,
                grouped = true,
                previewer = false,
                initial_mode = "normal",
            })
        end)
        vim.keymap.set('n', '<leader>\'', function()
            builtin.current_buffer_fuzzy_find(current_theme(true))
        end)
    end
}
