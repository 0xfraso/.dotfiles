local status, cmp = pcall(require, "cmp")
if (not status) then return end
local lspkind = require 'lspkind'

local opts = {
    winhighlight = "FloatBorder:TelescopeBorder"
}

cmp.setup({
    window = {
        completion = cmp.config.window.bordered(opts),
        documentation = cmp.config.window.bordered(opts),
    },
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(_),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true
        }),
        ['<C-j>'] = cmp.mapping(
            function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                else fallback() end
            end
        ),
        ['<C-k>'] = cmp.mapping(
            function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                else fallback() end
            end
        )
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'nvim_lua' },
        { name = 'luasnip' },
        { name = 'buffer' },
        { name = 'path' },
    }),
    formatting = {
        fields = { "kind", "abbr", "menu" },
        format = function(entry, vim_item)
            vim_item.kind = (lspkind.symbol_map[vim_item.kind] or "?") .. " "
            vim_item.menu = ({
                nvim_lsp = "LSP",
                buffer = "Buf",
                luasnip = "luasnip",
                nvim_lua = "lua",
                path = "Path"
            })[entry.source.name]

            local function trim(text)
                local max = 40
                if text and text:len() > max then
                    text = text:sub(1, max) .. "..."
                end
                return text
            end

            vim_item.abbr = trim(vim_item.abbr)

            return vim_item
        end
    },
})
