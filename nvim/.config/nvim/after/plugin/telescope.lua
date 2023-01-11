local status, telescope = pcall(require, "telescope")
if (not status) then return end
local actions = require('telescope.actions')
local actions_layout = require('telescope.actions.layout')
local action_state = require('telescope.actions.state')
local builtin = require("telescope.builtin")

local function telescope_buffer_dir()
    return vim.fn.expand('%:p:h')
end

local dropdown = require('telescope.themes').get_dropdown {
    previewer = false,
}

local fb_actions = require 'telescope'.extensions.file_browser.actions
telescope.setup {
    pickers = {
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
                prompt_position = "top",
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
            mappings = {
                -- your custom insert mode mappings
                ["i"] = {
                },
                ["n"] = {
                    -- your custom normal mode mappings
                    ["N"] = fb_actions.create,
                    ["h"] = fb_actions.goto_parent_dir,
                },
            },
        },
    },
}

telescope.load_extension("file_browser")
telescope.load_extension("luasnip")

vim.keymap.set('n', '<leader>f',
    function()
        builtin.find_files({
            no_ignore = false,
            hidden = true
        })
    end)
vim.keymap.set('n', '<leader>r', function()
    builtin.registers()
end)
vim.keymap.set('n', '<leader>g', function()
    builtin.live_grep()
end)
vim.keymap.set('n', '<leader>b', function()
    builtin.buffers()
end)
vim.keymap.set('n', '<leader>h', function()
    builtin.help_tags()
end)
vim.keymap.set('n', '<leader>.', function()
    builtin.resume()
end)
vim.keymap.set('n', '<leader>e', function()
    builtin.diagnostics(dropdown)
end)
vim.keymap.set("n", "<leader>d", function()
    telescope.extensions.file_browser.file_browser({
        path = "%:p:h",
        cwd = telescope_buffer_dir(),
        respect_gitignore = false,
        hidden = true,
        grouped = true,
        previewer = false,
        theme = "dropdown",
        initial_mode = "normal",
    })
end)
vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(dropdown)
end)
