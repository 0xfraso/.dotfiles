return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    indent = { enabled = false },
    input = { enabled = true },
    picker = {
      enabled = true,
      layouts = {
        ivy = {
          layout = {
            height = 0.8,
          }
        }
      },
      layout = {
        preset = "ivy",
        hidden = { "preview" }
      },
      actions = {
        files = {
          enter = { "edit", mode = { "n", "i" } },
          ["ctrl-s"] = "edit_split",
          ["ctrl-v"] = "edit_vsplit",
          ["ctrl-t"] = "tab",
          ["ctrl-l"] = "qflist",
        },
      },
      win = {
        input = {
          keys = {
            ["<c-l>"] = { "qflist", mode = { "n", "i" } },
          },
        },
        list = {
          keys = {
            ["<c-l>"] = "qflist",
          },
        },
      },
    },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = true },
    words = { enabled = false },
    terminal = { enabled = true },
    toggle = { enabled = true }
  },
  keys = {
    { "<leader>.",       function() Snacks.scratch() end,                                          desc = "Toggle Scratch Buffer" },
    { "<leader>S",       function() Snacks.scratch.select() end,                                   desc = "Select Scratch Buffer" },
    { "<leader>n",       function() Snacks.notifier.show_history() end,                            desc = "Notification History" },
    { "<leader>bd",      function() Snacks.bufdelete() end,                                        desc = "Delete Buffer" },
    { "<leader>cR",      function() Snacks.rename.rename_file() end,                               desc = "Rename File" },
    { "<leader>un",      function() Snacks.notifier.hide() end,                                    desc = "Dismiss All Notifications" },
    { "<leader>/",       function() Snacks.terminal() end,                                         desc = "Toggle Terminal" },

    { "<leader>F",       function() Snacks.picker() end,                                           desc = "Pickers" },
    { "<leader><space>", function() Snacks.picker.buffers() end,                                   desc = "Buffers" },
    { "<leader>ff",      function() Snacks.picker.files() end,                                     desc = "Find Files" },
    { "<leader>fr",      function() Snacks.picker.resume() end,                                    desc = "Resume" },
    { "<leader>fc",      function() Snacks.picker.files({ cwd = '~/.config/nvim' }) end,           desc = "Config files" },
    { "<leader>fg",      function() Snacks.picker.grep() end,                                      desc = "Grep (Root Dir)" },
    { "<leader>gs",      function() Snacks.picker.git_status() end,                                desc = "Status" },
    { "<leader>gc",      function() Snacks.picker.git_log() end,                                   desc = "Commits" },
    { "<leader>gC",      function() Snacks.picker.git_log_file() end,                              desc = "Current file back commits" },
    { "<leader>fw",      function() Snacks.picker.grep_word() end,                                 desc = "Grep word under cursor" },
    { "<leader>fF",      function() Snacks.picker.colorschemes() end,                              desc = "Colorschemes" },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.dim():map("<leader>uD")
      end,
    })
  end,
}
