return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local conform = require("conform")

      conform.setup({
        formatters_by_ft = {
          xml = { 'sonarlint' },
          javascript = { 'prettier' },
          typescript = { 'prettier' },
          html = { 'prettier' },
          json = { 'prettier' }
        }
      })
      vim.keymap.set({ "n", "v" },
        "<leader>rf",
        function()
          require("conform").format({
            lsp_fallback = true,
            async = false,
            timeout_ms = 500
          })
        end, { desc = "Format file or range (visual)" }
      )
    end,
  },
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()

      local set = vim.keymap.set

      -- Add or skip cursor above/below the main cursor.
      set({ "n", "x" }, "<C-up>", function() mc.lineAddCursor(-1) end)
      set({ "n", "x" }, "<C-down>", function() mc.lineAddCursor(1) end)

      -- Add or skip adding a new cursor by matching word/selection
      set({ "n", "x" }, "<leader>n", function() mc.matchAddCursor(1) end)

      set({ "n", "x" }, "<leader>a", function() mc.searchAllAddCursors() end)

      -- Add and remove cursors with control + left click.
      set("n", "<c-leftmouse>", mc.handleMouse)
      set("n", "<c-leftdrag>", mc.handleMouseDrag)
      set("n", "<c-leftrelease>", mc.handleMouseRelease)

      -- Mappings defined in a keymap layer only apply when there are
      -- multiple cursors. This lets you have overlapping mappings.
      mc.addKeymapLayer(function(layerSet)
        -- Select a different cursor as the main one.
        layerSet({ "n", "x" }, "<left>", mc.prevCursor)
        layerSet({ "n", "x" }, "<right>", mc.nextCursor)

        layerSet({ "n", "x" }, "n", function() mc.matchAddCursor(1) end)
        layerSet({ "n", "x" }, "s", function() mc.matchSkipCursor(1) end)
        layerSet({ "n", "x" }, "N", function() mc.matchAddCursor(-1) end)
        layerSet({ "n", "x" }, "S", function() mc.matchSkipCursor(-1) end)

        -- Delete the main cursor.
        layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

        -- Enable and clear cursors using escape.
        layerSet("n", "<esc>", function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          else
            mc.clearCursors()
          end
        end)
      end)

      -- Customize how cursors look.
      local hl = vim.api.nvim_set_hl
      hl(0, "MultiCursorCursor", { reverse = true })
      hl(0, "MultiCursorVisual", { link = "Visual" })
      hl(0, "MultiCursorSign", { link = "SignColumn" })
      hl(0, "MultiCursorMatchPreview", { link = "Search" })
      hl(0, "MultiCursorDisabledCursor", { reverse = true })
      hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
      hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
    end
  },
  {
    "windwp/nvim-ts-autotag",
    opts = {}
  },
  {
    "tpope/vim-dadbod",
    dependencies = {
      "kristijanhusak/vim-dadbod-ui",
      { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true }, -- Optional
      cmd = {
        'DBUI',
        'DBUIToggle',
        'DBUIAddConnection',
        'DBUIFindBuffer',
      },
      init = function()
        -- Your DBUI configuration
        vim.g.db_ui_use_nerd_fonts = 1
      end,
    },
    keys = {
      { "<leader>db", ":DBUIToggle<cr>", desc = "DBUI toggle", },
    }
  },
  {
    'stevearc/quicker.nvim',
    ft = "qf",
    config = function()
      _G.quicker_max_width = 50
      require("quicker").setup({
        -- Local options to set for quickfix
        opts = {
          buflisted = false,
          number = false,
          relativenumber = false,
          signcolumn = "auto",
          winfixheight = true,
          wrap = false,
        },
        -- Set to false to disable the default options in `opts`
        use_default_opts = true,
        -- Keymaps to set for the quickfix buffer
        keys = {
          {
            ">",
            function()
              require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
            end,
            desc = "Expand quickfix context",
          },
          {
            "<",
            function()
              require("quicker").collapse()
            end,
            desc = "Collapse quickfix context",
          },
          {
            "f",
            function()
              vim.ui.input({ prompt = "Filter pattern: " }, function(pattern)
                if pattern and pattern ~= "" then
                  vim.cmd("Cfilter " .. pattern)
                end
              end)
            end,
            desc = "Filter quickfix entries",
          },
          {
            "F",
            function()
              vim.ui.input({ prompt = "Filter pattern (inverted): " }, function(pattern)
                if pattern and pattern ~= "" then
                  vim.cmd("Cfilter! " .. pattern)
                end
              end)
            end,
            desc = "Filter quickfix entries (inverted)",
          },
          {
            '<leader>q+',
            function()
              _G.quicker_max_width = math.min(_G.quicker_max_width + 10, 200)
              require('quicker').refresh(nil, { invalidate_cache = true })
            end,
            { desc = 'Increase quicker max filename width' },
          },
          {
            '<leader>q-',
            function()
              _G.quicker_max_width = math.max(_G.quicker_max_width - 10, 0)
              require('quicker').refresh(nil, { invalidate_cache = true })
            end,
            { desc = 'Decrease quicker max filename width' },
          },
          {
            '<leader>qt', function()
              local current = _G.quicker_max_width or 40  -- Default to 40 if not set
              if current == 0 then
                -- Restore to previous width (stored in _G.quicker_prev_width)
                _G.quicker_max_width = _G.quicker_prev_width or 40
              else
                -- Save current width and set to 0
                _G.quicker_prev_width = current
                _G.quicker_max_width = 0
              end
              require('quicker').refresh(nil, { invalidate_cache = true })
            end, { desc = 'Toggle quickfix filename width (0 ↔ current)' } 
          },
        },
        -- Callback function to run any custom logic or keymaps for the quickfix buffer
        on_qf = function(bufnr) end,
        edit = {
          -- Enable editing the quickfix like a normal buffer
          enabled = true,
          -- Set to true to write buffers after applying edits.
          -- Set to "unmodified" to only write unmodified buffers.
          autosave = "unmodified",
        },
        -- Keep the cursor to the right of the filename and lnum columns
        constrain_cursor = true,
        highlight = {
          -- Use treesitter highlighting
          treesitter = true,
          -- Use LSP semantic token highlighting
          lsp = true,
          -- Load the referenced buffers to apply more accurate highlights (may be slow)
          load_buffers = false,
        },
        follow = {
          -- When quickfix window is open, scroll to closest item to the cursor
          enabled = false,
        },
        -- Map of quickfix item type to icon
        type_icons = {
          E = "󰅚 ",
          W = "󰀪 ",
          I = " ",
          N = " ",
          H = " ",
        },
        -- Border characters
        borders = {
          vert = "┃",
          -- Strong headers separate results from different files
          strong_header = "━",
          strong_cross = "╋",
          strong_end = "┫",
          -- Soft headers separate results within the same file
          soft_header = "╌",
          soft_cross = "╂",
          soft_end = "┨",
          -- Compact header mode: Show filename in header line when expanded
        },
        -- How to trim the leading whitespace from results. Can be 'all', 'common', or false
        trim_leading_whitespace = "common",
        -- Maximum width of the filename column
        max_filename_width = function()
          return math.floor(math.min(_G.quicker_max_width, vim.o.columns / 2))
        end,
        -- How far the header should extend to the right
        header_length = function(type, start_col)
          return vim.o.columns - start_col
        end,
        hard_header_filenames = true
      })
    end,
  }
}
