return {
    'hrsh7th/nvim-cmp', -- Completion
    dependencies = {
        'hrsh7th/cmp-buffer', -- nvim-cmp source for buffer words
        'hrsh7th/cmp-path', -- nvim-cmp source for buffer words
        'hrsh7th/cmp-nvim-lsp', -- nvim-cmp source for neovim built-in LSP
        'saadparwaiz1/cmp_luasnip',
    },
    config = function()
        local status, cmp = pcall(require, "cmp")
        if (not status) then return end

        local luasnip_status, luasnip = pcall(require, "luasnip")
        if (not luasnip_status) then return end

        local lspkind = require 'lspkind'

        local opts = {
            -- winhighlight = "FloatBorder:FloatBorder"
        }

        require("cmp").setup({
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
                ['<C-d>'] = cmp.mapping.scroll_docs( -4),
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
                        else
                            fallback()
                        end
                    end
                ),
                ['<C-k>'] = cmp.mapping(
                    function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        else
                            fallback()
                        end
                    end
                ),
--                ["<Tab>"] = cmp.mapping(function(fallback)
--                    if cmp.visible() then
--                        cmp.select_next_item()
--                    elseif luasnip.expand_or_jumpable() then
--                        luasnip.expand_or_jump()
--                    else
--                        fallback()
--                    end
--                end, { "i", "s" }),
--
--                ["<S-Tab>"] = cmp.mapping(function(fallback)
--                    if cmp.visible() then
--                        cmp.select_prev_item()
--                    elseif luasnip.jumpable( -1) then
--                        luasnip.jump( -1)
--                    else
--                        fallback()
--                    end
--                end, { "i", "s" }),
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
            experimental = {
                ghost_text = {
                    hl_group = 'CmpItemKindUnit'
                },
            },
        })
    end
}
