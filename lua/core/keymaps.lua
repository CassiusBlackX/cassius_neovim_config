local map = vim.keymap.set

map({ 'n', 'x', 'o' }, 'gl', '$', { desc = "goto end of line" })
map({ 'n', 'x', 'o' }, 'gh', '0', { desc = "goto the head of line" })
map({ 'n', 'x', 'o' }, 'ge', 'G', { desc = "goto the end of file" })
map('n', 'gn', '<cmd>bnext<CR>', { desc = "goto next buffer" })
map('n', '<Leader>bn', '<cmd>bnext<CR>', { desc = "go to next buffer" })
map('n', 'gp', '<cmd>bprev<CR>', { desc = "goto prev buffer" })
map('n', '<Leader>bp', '<cmd>bprev<CR>', { desc = "go to next buffer" })
map('n', 'U', '<C-r>', { desc = "Redo" })
map('n', '<Leader>w', '<C-w>', { desc = "+window" })
map('n', '<Leader>v', '<C-v>', { desc = "Enter visual block mode" })
map({ 'n', 'x' }, '<Leader>y', '"+y', { desc = "copy to system clipboard" })
map({ 'n', 'x', 'o' }, 'mm', '%', { desc = "jump to match" })

map('n', '<Leader>a', function()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd(':%y+')
    vim.api.nvim_win_set_cursor(0, cursor_pos)
    vim.notify("Entire file copied to system clipboard", vim.log.levels.INFO)
end, { desc = "copy whole file to system clipboard" })

map('n', '<Leader>tw', function()
    local current = vim.wo.wrap
    vim.wo.wrap = not current
    vim.notify("Line wrap " .. (current and "disabled" or "enabled"), vim.log.levels.INFO)
end, { desc = "Toggole line wrapping" })

-- system clipboard
if vim.env.SSH_TTY then
    vim.g.clipboard = {
        name = 'OSC 52',
        copy = {
            ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
            ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
        },
        paste = {
            ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
            ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
        }
    }
end

-- move line
map('n', '<A-j>', function()
    local count = vim.v.count1
    vim.cmd('move .+' .. count)
    vim.cmd('normal! ==')
end, { desc = 'move line down' })
map('n', '<A-k>', function()
    local count = vim.v.count1
    vim.cmd('move .-' .. (count + 1))
    vim.cmd('normal! ==')
end, { desc = 'move line down' })

-- 视觉模式 (Visual/Line-selection)
vim.keymap.set('x', '<A-j>', function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'x', true)
    local count = vim.v.count1
    vim.schedule(function()
        local cmd = string.format("'<,'>move '>+%d", count)
        pcall(vim.cmd, cmd)
        vim.cmd('normal! gv=gv')
    end)
end, { desc = 'Move selection down' })
vim.keymap.set('x', '<A-k>', function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'x', true)
    local count = vim.v.count1
    vim.schedule(function()
        local cmd = string.format("'<,'>move '<-%d", count + 1)
        pcall(vim.cmd, cmd)
        vim.cmd('normal! gv=gv')
    end)
end, { desc = 'Move selection up' })
