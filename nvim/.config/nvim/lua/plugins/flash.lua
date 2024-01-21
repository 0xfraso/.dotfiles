return {
    "folke/flash.nvim",
    config = function()
        -- highlights
        local FlashColors = {
            FlashBackdrop = { link = "Comment" },
            FlashMatch = { link = "Search" },
            FlashCurrent = { link = "IncSearch" },
            FlashLabel = { link = "Error" },
            FlashPrompt = { link = "MsgArea" },
            FlashPromptIcon = { link = "Special" },
            FlashCursor = { link = "Cursor" },
        }

        for hl, col in pairs(FlashColors) do
            vim.api.nvim_set_hl(0, hl, col)
        end

        -- gruber-darker specific hl
        if (vim.g.colors_name == "gruber-darker") then
            vim.api.nvim_set_hl(0, "FlashBackdrop", { link = "GruberDarkerBg4" })
        end
    end,
    cmd = {"Flash"},
    keys = {
        { "<leader>/", mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
    },
}
