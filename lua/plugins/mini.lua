require('mini.basics').setup()

require('mini.statusline').setup()

require('mini.icons').setup()

require('mini.snippets').setup()

require('mini.starter').setup()

require('mini.files').setup({
    options = {
        use_as_default_explorer = false,
    },
})
vim.keymap.set('n', '<Leader>e', function()
    require('mini.files').open()
end, { desc = "open file pickers" })

require('mini.cmdline').setup()

require('mini.pairs').setup()

require('mini.git').setup()

require('mini.diff').setup({
    view = {
        style = 'sign',
        signs = { add = '+', change = '~', delete = '-' },
    }
})

require('mini.surround').setup()

require('mini.comment').setup()
vim.keymap.set('n', '<C-/>', 'gcc', { remap = true, desc = 'Toggle comment line' })
vim.keymap.set('n', '<C-_>', 'gcc', { remap = true, desc = 'Toggle comment line' })
vim.keymap.set('n', '<Leader>cc', 'gcc', { remap = true, desc = 'Toggle comment line' })
vim.keymap.set('x', '<C-c>', 'gc', { remap = true, desc = 'Toggle comment selection' })

require('mini.tabline').setup({
    show_icons = true,
    format = function(buf_id, label)
        return MiniTabline.default_format(buf_id, label)
    end,
})

require('mini.bufremove').setup()
vim.keymap.set('n', '<Leader>bcc', function()
    require('mini.bufremove').delete(0, false)
end, { desc = "close current buffer" })
vim.keymap.set('n', '<Leader>bco', function()
    local current_buf = vim.api.nvim_get_current_buf()
    local all_bufs = vim.api.nvim_list_bufs()
    for _, buf_id in ipairs(all_bufs) do
        if vim.api.nvim_buf_is_valid(buf_id)
            and vim.bo[buf_id].buflisted
            and buf_id ~= current_buf then
                require('mini.bufremove').delete(buf_id, false)
        end
    end
    vim.notify("other buffers are closed", vim.log.levels.INFO)
end, { desc = "Close other buffer"})

require('mini.jump2d').setup({
    allowed_windows = { current = true, not_current = false },
    mappings = { start_jumping = '', },
    view = { n_steps_ahead = 1, },
})
local jump_to_words = function()
    require('mini.jump2d').start({
        spotter = require('mini.jump2d').gen_spotter.pattern('%w+'),
    })
end
vim.keymap.set('n', 'gw', jump_to_words, { desc = 'jump to word starts' })
vim.keymap.set('x', 'gw', jump_to_words, { desc = 'jump in visual mode' })
vim.keymap.set('o', 'gw', jump_to_words, { desc = 'jump in operator-pending mode' })

require('mini.clue').setup()
local miniclue = require('mini.clue')
miniclue.setup({
    triggers = {
        -- leader trigger
        { mode = 'n', keys = '<Leader>' },
        { mode = 'x', keys = '<Leader>' },
        -- internal
        { mode = 'n', keys = 'g' },
        { mode = 'x', keys = 'g' },
        { mode = 'n', keys = '[' },
        { mode = 'n', keys = ']' },
        { mode = 'x', keys = '[' },
        { mode = 'x', keys = ']' },
        { mode = 'n', keys = 'c' },
        { mode = 'n', keys = 'd' },
        { mode = 'n', keys = 'y' },
        -- window
        { mode = 'n', keys = '<C-w>' },
        -- motion
        { mode = 'n', keys = 'z' },
        { mode = 'x', keys = 'z' },
        -- register
        { mode = 'n', keys = '"' },
        { mode = 'x', keys = '"' },
        -- surround
        { mode = 'n', keys = 's' },
        -- mark
        { mode = 'n', keys = "'" },
        { mode = 'n', keys = "`" },
        { mode = 'x', keys = "'" },
        { mode = 'x', keys = "`" },
        -- match
        { mode = 'n', keys = "mm" },
    },
    clues = {
        miniclue.gen_clues.builtin_completion(),
        miniclue.gen_clues.g(),
        miniclue.gen_clues.marks(),
        miniclue.gen_clues.registers(),
        miniclue.gen_clues.windows(),
        miniclue.gen_clues.z(),
        { mode = 'n', keys = '<Leader>y',  desc = 'copy to system clipboard' },
        { mode = 'n', keys = '<Leader>w',  desc = 'window related cmds' },
        { mode = 'n', keys = '<Leader>b',  desc = 'buffer related cmds' },
        { mode = 'n', keys = '<Leader>cf', desc = 'format current code buffer' },
        { mode = 'n', keys = '<Leader>ff', desc = 'search files (cwd)' },
        { mode = 'n', keys = '<Leader>fF', desc = 'search files (project root)' },
        { mode = 'n', keys = '<Leader>a',  desc = 'copy whole file' },
        { mode = 'n', keys = '<Leader>e',  desc = 'show fs' },
        { mode = 'n', keys = '<Leader>r',  desc = 'rename symbol' },
        { mode = 'n', keys = '<Leader>tt', desc = 'open terminal' },
        { mode = 'n', keys = '<Leader>tw', desc = 'Toggle line wrapping' },
        { mode = 'n', keys = 'mm',         desc = 'jump to match' },
        { mode = 'n', keys = 'gd',         desc = 'goto definition' },
        { mode = 'n', keys = 'gi',         desc = 'goto implementation' },
    },
    window = {
        delay = 100,
        config = { border = 'rounded' },
    },
})

