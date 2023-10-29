return {
    'nvim-telescope/telescope.nvim',
    dependencies = {
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build =
            "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build"
        }
    },
    config = function()
        local telescope, builtin, actions, actions_layout, theme = require("telescope"), require("telescope.builtin"),
            require('telescope.actions'), require('telescope.actions.layout'), require("telescope.themes")

        require('telescope.pickers.layout_strategies').my_bottom_pane = function(picker, max_columns, max_lines, layout_config)
            local layout = require('telescope.pickers.layout_strategies').bottom_pane(picker, max_columns, max_lines, layout_config)
            layout.results.title = ''
            layout.preview.title = ''
            return layout
        end

        local opts = theme.get_ivy({
            results_title = false,
            layout_strategy = "my_bottom_pane"
        })

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
                fzf = {
                    fuzzy = true,                   -- false will only do exact matching
                    override_generic_sorter = true, -- override the generic sorter
                    override_file_sorter = true,    -- override the file sorter
                    case_mode = "smart_case",       -- or "ignore_case" or "respect_case" the default case_mode is "smart_case"
                }
            },
        })

        telescope.load_extension("fzf")
        telescope.load_extension("git_worktree")

        local worktrees = function()
            telescope.extensions.git_worktree.git_worktrees()
        end

        vim.keymap.set("n", '<leader>ff', function() builtin.find_files(opts) end)
        vim.keymap.set("n", '<leader>fb', function() builtin.buffers(opts) end)
        vim.keymap.set("n", '<leader>fr', function() builtin.resume(opts) end)
        vim.keymap.set("n", '<leader>fg', function() builtin.grep_string(opts) end)
        vim.keymap.set("n", '<leader>fh', function() builtin.help_tags(opts) end)
        vim.keymap.set("n", '<leader>fe', function() builtin.diagnostics(opts) end)
        vim.keymap.set("n", '<leader>fw', function() builtin.current_buffer_fuzzy_find(opts) end)
        vim.keymap.set("n", '<leader>fc', function() builtin.highlights(opts) end)
        vim.keymap.set("n", '<leader>gs', function() builtin.git_status(opts) end)

        vim.keymap.set("n", '<leader>gw', worktrees)

        vim.api.nvim_create_user_command('GitBranches', function() builtin.git_branches(opts) end, {})
        vim.api.nvim_create_user_command("GitWorktrees", worktrees, {})
        vim.api.nvim_create_user_command("GitWorktreesCreate", function() telescope.extensions.git_worktree.create_git_worktree() end, {})
    end,
}
