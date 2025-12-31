local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = 'a'
opt.cursorline = false
opt.termguicolors = true
opt.timeoutlen = 300
opt.updatetime = 300
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.lsp.foldexpr()"
opt.foldlevel = 99
opt.foldcolumn = "0"
-- vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

