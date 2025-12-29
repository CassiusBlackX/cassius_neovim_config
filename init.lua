-- ===================================================================== --
--                              basic configuration 
-- ========================================================================== --
vim.g.mapleader = ' '          
vim.g.maplocalleader = ' '
vim.opt.number = true           
vim.opt.relativenumber = true   
vim.opt.mouse = 'a'           
vim.opt.tabstop = 4            
vim.opt.shiftwidth = 4          
vim.opt.expandtab = true      
vim.opt.cursorline = false     
vim.opt.termguicolors = true    
vim.opt.clipboard = "unnamedplus" 

-- ========================================================================== --
--                                clip board                           
-- ========================================================================== --
if vim.fn.exists('##TextYankPost') == 1 then
    vim.api.nvim_create_autocmd('TextYankPost', {
        callback = function()
            if vim.v.event.operator == 'y' then
                require('vim.ui.clipboard.osc52').copy('+')(vim.v.event.regcontents)
            end
        end,
    })
end

-- ========================================================================== --
--                                Tokyonight                        --
-- ========================================================================== --
vim.cmd([[colorscheme tokyonight-storm]]) 

-- ========================================================================== --
--                                mini.nvim                        --
-- ========================================================================== --
require('mini.basics').setup()   
require('mini.statusline').setup() 
require('mini.icons').setup()
require('mini.snippets').setup()
require('mini.starter').setup()   
require('mini.files').setup()    
require('mini.cmdline').setup()
require('mini.pairs').setup()
require('mini.surround').setup()
require('mini.clue').setup()
require('mini.pick').setup()
require('mini.completion').setup({
    fallback_action = '',
    lsp_completion = {
        snippet_insert = require('mini.completion').default_snippet_insert,
    },
    delay = { completion = 50, info = 100, signature = 50},
})

-- mini.files key bindings
vim.keymap.set('n', '<Leader>e', function() require('mini.files').open() end)
-- mini.pick key bindings
vim.keymap.set('n', '<Leader>ff', function() vim.cmd('Pick files') end)
vim.keymap.set('n', '<Leader>fb', function() vim.cmd('Pick buffers') end)
vim.keymap.set('n', '<Leader>fg', function() vim.cmd('Pick grep') end)
-- mini.completion
vim.keymap.set('i', '<Tab>', function()
    if vim.fn.pumvisible() == 1 then
        return '<C-n>'
    else
        return '<Tab>'
    end
end, { expr = true })
vim.keymap.set('i', '<S-Tab>', function()
    if vim.fn.pumvisible() == 1 then
        return '<C-p>'
    else
        return '<S-Tab>'
    end
end, { expr = true })
vim.keymap.set('i', '<CR>', function()
    if vim.fn.pumvisible() == 1 then
        local info = vim.fn.complete_info({ 'selected' })
        if info.selected ~= -1 then
            return '<C-y>'
        end
    end
    return '<CR>'
end, { expr = true })

-- ========================================================================== --
-- cursor memory
-- ========================================================================== --
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lnum = mark[1]
        local col = mark[2]

        -- make sure line number is valid
        if lnum > 0 and lnum <= vim.api.nvim_buf_line_count(0) then
            pcall(vim.api.nvim_win_set_cursor, 0, { lnum, col })
        end
    end,
})

-- ========================================================================== --
--                                LSP manual configure
-- ========================================================================== --

local function my_lsp_attach(client, bufnr)
    local opts = { buffer = bufnr }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)      
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)           
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)      
end

-- C/C++ (clangd)
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'c', 'cpp', 'objc', 'objcpp' },
    callback = function()
        vim.lsp.start({
            name = 'clangd',
            cmd = { 'clangd' }, 
            root_dir = vim.fs.dirname(vim.fs.find({ 'compile_commands.json', '.git' }, { upward = true })[1]),
            on_attach = my_lsp_attach,
        })
    end,
})

-- Rust (rust-analyzer)
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'rust',
    callback = function()
        vim.lsp.start({
            name = 'rust-analyzer',
            cmd = { 'rust-analyzer' },
            root_dir = vim.fs.dirname(vim.fs.find({ 'Cargo.toml' }, { upward = true })[1]),
            on_attach = my_lsp_attach,
        })
    end,
})

-- CMake (neocmakelsp)
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'cmake',
    callback = function()
        vim.lsp.start({
            name = 'neocmakelsp',
            cmd = { 'neocmakelsp' , 'stdio'},
            root_dir = vim.fs.dirname(vim.fs.find({ 'CMakeLists.txt' }, { upward = true })[1]),
            on_attach = my_lsp_attach,
        })
    end,
})

