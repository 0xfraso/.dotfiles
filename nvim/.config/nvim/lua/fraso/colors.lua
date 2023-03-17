local set_highlights = function()
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "TelescopeBorder", { link = "LineNr" })
    vim.api.nvim_set_hl(0, "FloatBorder", { link = "TelescopeBorder" })
    vim.api.nvim_set_hl(0, "SagaBorder", { link = "FloatBorder" })
    vim.api.nvim_set_hl(0, "SagaNormal", { link = "Normal" })
end

local ColorMyPencils = function(color)
    color = color or "gruvbox"
    vim.cmd.colorscheme(color)
    vim.cmd.colorscheme(color)
    set_highlights()
end

local choose_colorscheme = function()
    local actions = require "telescope.actions"
    local actions_state = require "telescope.actions.state"
    local pickers = require "telescope.pickers"
    local finders = require "telescope.finders"
    local sorters = require "telescope.sorters"
    local current_theme = require "telescope.themes".get_ivy()

    local function enter(prompt_bufnr)
        local selected = actions_state.get_selected_entry()
        ColorMyPencils(selected[1])
        actions.close(prompt_bufnr)
    end

    local function next_color(prompt_bufnr)
        actions.move_selection_next(prompt_bufnr)
        local selected = actions_state.get_selected_entry()
        ColorMyPencils(selected[1])
    end

    local function prev_color(prompt_bufnr)
        actions.move_selection_previous(prompt_bufnr)
        local selected = actions_state.get_selected_entry()
        ColorMyPencils(selected[1])
    end

    local colors = vim.fn.getcompletion("", "color")

    local opts = {
        --finder = finders.new_table {"gruvbox", "nordfox", "nightfox", "monokai", "tokyonight"},
        finder = finders.new_table(colors),
        sorter = sorters.get_generic_fuzzy_sorter({}),
        attach_mappings = function(_, map)
            map("i", "<CR>", enter)
            map("i", "<C-j>", next_color)
            map("i", "<C-k>", prev_color)
            map("n", "<CR>", enter)
            map("n", "j", next_color)
            map("n", "k", prev_color)
            return true
        end,
    }

    local colors_picker = pickers.new(current_theme, opts)

    colors_picker:find()
end

vim.api.nvim_create_user_command("Colorscheme", function()
    choose_colorscheme()
end, {})

local theme = require('last-color').recall()

ColorMyPencils(theme)
vim.keymap.set("n", "<leader>C", '<Cmd>Colorscheme<CR>')
