local cmp = require('cmp')
cmp.setup({
    completion = { autocomplete = { cmp.TriggerEvent.TextChanged },},
    sources = {
        { name = 'nvim_lsp' },
        { name = 'path' },
        { name = 'buffer' },
    },

    -- fuzzy match
    matching = {
        disallow_fuzzy_matching = false,
        disallow_full_fuzzy_matching = false,
        disallow_partial_fuzzy_matching = false,
        disallow_partial_matching = false,
        disallow_prefix_unmatching = false,
    },

    -- shortcut key bindings
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end, {'i', 's'}),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end, { 'i', 's' }),
    }),

    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
})

