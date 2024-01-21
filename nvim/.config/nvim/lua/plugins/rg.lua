return
{
    "mangelozzi/rgflow.nvim",
    config = function()
        require("rgflow").setup({
            default_trigger_mappings = true,
            default_ui_mappings = true,
            default_quickfix_mappings = true,

            ui_top_line_char = "▃",

            -- WARNING !!! Glob for '-g *{*}' will not use .gitignore file: https://github.com/BurntSushi/ripgrep/issues/2252
            cmd_flags = ("--smart-case -g !*.min.js --fixed-strings --no-fixed-strings --no-ignore -M 500"
                -- Exclude globs
                .. " -g !**/.angular/"
                .. " -g !**/node_modules/"
                .. " -g !**/mocks/"
                .. " -g !**/dist/"
                .. " -g !*metadata*.xml"
            ),
            colors = {
                RgFlowQfPattern    = { link = "" },
                RgFlowHead         = { link = "" },
                RgFlowHeadLine     = { link = "FloatBorder" },
                RgFlowInputBg      = { link = "" },
                RgFlowInputFlags   = { link = "" },
                RgFlowInputPattern = { link = "" },
                RgFlowInputPath    = { link = "" },
            }
        })
    end
}
