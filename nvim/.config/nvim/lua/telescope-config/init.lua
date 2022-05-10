local actions = require('telescope.actions')
local actions_layout = require('telescope.actions.layout')

require('telescope').setup {
    defaults = {
      prompt_prefix = " ",
      selection_caret = " ",
      entry_prefix = "  ",
      initial_mode = "insert",
      selection_strategy = "reset",
      sorting_strategy = "descending",
      file_sorter = require'telescope.sorters'.get_fuzzy_file,
      file_ignore_patterns = {
        "node_modules",
        "venv",
        ".cache",
        ".git"
      },
      preview = { },
      generic_sorter =require'telescope.sorters'.get_generic_fuzzy_sorter,
      path_display = {},
      winblend = 0,
      border = {},
      borderchars = {'─', '│', '─', '│', '╭', '╮', '╯', '╰'},
      color_devicons = true,
      use_less = true,
      set_env = {['COLORTERM'] = 'truecolor'}, -- default = nil,
      file_previewer = require'telescope.previewers'.vim_buffer_cat.new,
      grep_previewer = require'telescope.previewers'.vim_buffer_vimgrep.new,
      qflist_previewer = require'telescope.previewers'.vim_buffer_qflist.new,
      buffer_previewer_maker = require'telescope.previewers'.buffer_previewer_maker,
      mappings = {
          i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<esc>"] = actions.close,
              ["<CR>"] = actions.select_default + actions.center,
              ["<C-t>"] = actions_layout.toggle_preview
          },
          n = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
          }
      },
    },
    pickers = {
      find_files = {
        hidden = true,
      },
      live_grep = {
        hiddee = true,
      },
    },
    extensions = {
      fzf = {
        fuzzy = true,                    -- false will only do exact matching
        override_generic_sorter = true,  -- override the generic sorter
        override_file_sorter = true,     -- override the file sorter
        case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                         -- the default case_mode is "smart_case"
      }
    }
}

require'telescope'.load_extension('luasnip')
require'telescope'.load_extension('fzf')
