return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    enabled = true,
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build =
        "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
      },
      { "OliverChao/telescope-picker-list.nvim" },
    },
    keys = {
      -- find
      { "<leader><space>", ":Telescope buffers theme=ivy previewer=false sort_mru=true sort_lastused=true<cr>", desc = "Buffers" },
      { "<leader>ff",      ":Telescope find_files theme=ivy<cr>",                                               desc = "Find Files" },
      { "<leader>fg",      ":Telescope live_grep theme=ivy<cr>",                                                desc = "Grep (Root Dir)" },
      -- git
      { "<leader>gs",      ":Telescope git_status theme=ivy<CR>",                                               desc = "Status" },
      { "<leader>gc",      ":Telescope git_commits theme=ivy<CR>",                                              desc = "Commits" },
      { "<leader>gC",      ":Telescope git_bcommits theme=ivy<CR>",                                             desc = "Current file back commits" },
      -- lsp
      { "<leader>xx",      ":Telescope diagnostics theme=ivy previewer=false<CR>",                              desc = "Workspace diagnostics" },
      -- misc
      { "<leader>fC",      ":Telescope commands theme=ivy<cr>",                                                 desc = "Find commands" },
      { "<leader>fc",      ":Telescope find_files theme=ivy cwd=~/.config/nvim<cr>",                            desc = "Find config files" },
    },
    config = function()
      local actions = require("telescope.actions")

      local function find_command()
        if 1 == vim.fn.executable("rg") then
          return { "rg", "--files", "--color", "never", "-g", "!.git" }
        elseif 1 == vim.fn.executable("fd") then
          return { "fd", "--type", "f", "--color", "never", "-E", ".git" }
        elseif 1 == vim.fn.executable("fdfind") then
          return { "fdfind", "--type", "f", "--color", "never", "-E", ".git" }
        elseif 1 == vim.fn.executable("find") and vim.fn.has("win32") == 0 then
          return { "find", ".", "-type", "f" }
        elseif 1 == vim.fn.executable("where") then
          return { "where", "/r", ".", "*" }
        end
      end

      require("telescope").setup({
        defaults = vim.tbl_extend(
          "force",
          require('telescope.themes').get_ivy(), -- or get_cursor, get_ivy
          {
            prompt_prefix = "» ",
            selection_caret = " ",
            mappings = {
              i = {
                ["<Esc>"] = actions.close,
                ["<C-j>"] = actions.move_selection_next,
                ["<C-k>"] = actions.move_selection_previous,
                ["<C-s>"] = actions.select_horizontal,
                ["<C-v>"] = actions.select_vertical,
                ["<C-l>"] = actions.smart_send_to_qflist + actions.open_qflist
              },
              n = {
                ["q"] = actions.close,
              },
            },
          }
        ),
        pickers = {
          find_files = {
            find_command = find_command,
            hidden = true
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,                   -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true,    -- override the file sorter
            case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
          },
          picker_list = {},
        }
      })
      vim.keymap.set("n", "<leader>fh", require('telescope').extensions.picker_list.picker_list)

      require('telescope').load_extension('fzf')
      require("telescope").load_extension("picker_list") -- must be the last one
    end,
  },
}
