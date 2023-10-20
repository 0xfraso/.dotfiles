return {
    'glepnir/lspsaga.nvim', -- LSP UIs
    lazy = false,
    config = function()
        local status_saga, saga = pcall(require, "lspsaga")
        if (not status_saga) then return end

        saga.setup({
            ui = {
                -- currently only round theme
                theme = 'round',
                -- border type can be single,double,rounded,solid,shadow.
                border = 'rounded',
                winblend = 0,
                expand = '',
                collaspe = '',
                preview = ' ',
                code_action = '💡',
                diagnostic = '🐞',
                incoming = ' ',
                outgoing = ' ',
                kind = {},
            },
            lightbulb = {
                enable = true,
                sign = false,
                debounce = 10,
                sign_priority = 40,
                virtual_text = true,
                enable_in_insert = true,
            },
            finder = {
                max_height = 0.5,
                left_width = 0.4,
                keys = {
                    shuttle = '[w',
                    toggle_or_open = 'o',
                    vsplit = '<C-c>v',
                    split = '<C-c>s',
                    quit = 'q',
                },
            },
            definition = {
                width = 0.6,
                height = 0.5,
                keys = {
                    edit = '<C-c>o',
                    vsplit = '<C-c>v',
                    split = '<C-c>s',
                    tabe = '<C-c>t',
                    quit = 'q',
                },
            },
        })
    end,
    keys = {
        { 'gn', '<Cmd>Lspsaga diagnostic_jump_next<CR>', desc = "Lspsaga" },
        { 'gp', '<Cmd>Lspsaga diagnostic_jump_prev<CR>', desc = "Lspsaga" },
        { 'H',  '<Cmd>Lspsaga hover_doc<CR>',            desc = "Lspsaga" },
        { 'gh', '<Cmd>Lspsaga peek_definition<CR>',      desc = "Lspsaga" },
        { 'gH', '<Cmd>Lspsaga goto_definition<CR>',      desc = "Lspsaga" },
        { 'gd', '<Cmd>Lspsaga finder<CR>',               desc = "Lspsaga" },
        { 'gs', '<Cmd>Lspsaga show_buf_diagnostics<CR>', desc = "Lspsaga" },
        { 'gr', '<Cmd>Lspsaga rename<CR>',               desc = "Lspsaga" },
        { 'ga', '<Cmd>Lspsaga code_action<CR>',          desc = "Lspsaga" },
        { 'go', '<Cmd>Lspsaga outline<CR>',              desc = "Lspsaga" },
    }
}
