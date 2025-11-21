return {
  {
    "NickvanDyke/opencode.nvim",
    dependencies = {
      -- Recommended for `ask()` and `select()`.
      -- Required for `toggle()`.
      { "folke/snacks.nvim", opts = { input = {}, picker = {} } },
    },
    config = function()
      vim.g.opencode_opts = {
        -- Your configuration, if any — see `lua/opencode/config.lua`
      }

      -- Required for `vim.g.opencode_opts.auto_reload`
      vim.opt.autoread = true

      -- Recommended/example keymaps
      vim.keymap.set("n", "<leader>oa", function() require("opencode").ask("", { submit = true }) end,
        { desc = "Ask" })
      vim.keymap.set("x", "<leader>oa", function() require("opencode").ask("@selection: ", { submit = true }) end,
        { desc = "Ask about selection" })
      vim.keymap.set("n", "<leader>ob", function() require("opencode").ask("@buffer: ", { submit = true }) end,
        { desc = "Ask about buffer" })
      vim.keymap.set({ "n", "x" }, "<leader>os", function() require("opencode").select() end, { desc = "Select prompt" })
      vim.keymap.set("n", "<leader>ot", function() require("opencode").toggle() end, { desc = "Toggle embedded" })
      vim.keymap.set("n", "<leader>oc", function() require("opencode").command() end, { desc = "Select command" })
      vim.keymap.set("n", "<leader>o<tab>", function() require("opencode").command("agent_cycle") end,
        { desc = "Cycle selected agent" })
      vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("messages_half_page_up") end,
        { desc = "Messages half page up" })
      vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("messages_half_page_down") end,
        { desc = "Messages half page down" })
    end,
  }
}
