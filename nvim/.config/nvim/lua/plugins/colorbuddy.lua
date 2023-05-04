return
{
    { 'tjdevries/colorbuddy.nvim',   lazy = false },
    {
        'svrana/neosolarized.nvim',
        lazy = true,
        config = function()
            require("neosolarized").setup({
                comment_italics = true,
            })

            local cb = require('colorbuddy.init')
            local Color = cb.Color
            local colors = cb.colors
            local Group = cb.Group
            local groups = cb.groups
            local styles = cb.styles

            local cError = groups.Error.fg
            local cInfo = groups.Information.fg
            local cWarn = groups.Warning.fg
            local cHint = groups.Hint.fg

            Color.new('white', '#ffffff')
            Color.new('black', '#000000')
            Group.new('Normal', colors.none, colors.base03, styles.NONE)
            Group.new('CursorLine', colors.none, colors.base03, styles.NONE, colors.base1)
            Group.new('CursorLineNr', colors.yellow, colors.black, styles.NONE, colors.base1)
            Group.new('Visual', colors.none, colors.base03, styles.reverse)
            Group.new('Delimiter', colors.red, colors.none, styles.NONE)

            Group.new('NonText', colors.base0, colors.none, styles.NONE)
            Group.link('Whitespace', groups.NonText)

            Group.new("DiagnosticVirtualTextError", cError, cError:dark():dark():dark():dark(), styles.NONE)
            Group.new("DiagnosticVirtualTextInfo", cInfo, cInfo:dark():dark():dark(), styles.NONE)
            Group.new("DiagnosticVirtualTextWarn", cWarn, cWarn:dark():dark():dark(), styles.NONE)
            Group.new("DiagnosticVirtualTextHint", cHint, cHint:dark():dark():dark(), styles.NONE)
            Group.new("DiagnosticUnderlineError", colors.none, colors.none, styles.undercurl, cError)
            Group.new("DiagnosticUnderlineWarn", colors.none, colors.none, styles.undercurl, cWarn)
            Group.new("DiagnosticUnderlineInfo", colors.none, colors.none, styles.undercurl, cInfo)
            Group.new("DiagnosticUnderlineHint", colors.none, colors.none, styles.undercurl, cHint)

            Group.new("Statement", colors.green, colors.none, styles.bold)
            Group.new("Boolean", colors.yellow, colors.none, styles.bold)

            Group.new("SagaBorder", colors.cyan, colors.none, styles.NONE)

            require("nvim-listchars.api").lighten_colors(-35)

            require("lualine").setup({
                options = {
                    theme = 'solarized_dark'
                }
            })
        end
    },
}
