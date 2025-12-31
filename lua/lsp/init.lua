local M = {}
M.capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
if ok then
    M.capabilities = cmp_lsp.default_capabilities(M.capabilities)
end

M.my_lsp_attach = function(client, buffer)
    -- goto mode
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<Leader>cr', builtin.lsp_references, {
        buffer = buffer, desc = "find references",
    })
    vim.keymap.set('n', 'gd', builtin.lsp_definitions, {
        buffer = buffer, desc = "goto definition",
    })
    vim.keymap.set('n', 'gi', builtin.lsp_implementations, {
        buffer = buffer, desc = "goto implementation",
    })
    -- show docs
    vim.keymap.set('n', '<Leader>K', vim.lsp.buf.hover, {
        buffer = buffer, desc = "show docs",
    })
    vim.keymap.set('n', '<Leader>r', vim.lsp.buf.rename, {
        buffer = buffer, desc = 'rename symbols',
    })
    vim.keymap.set('n', '<Leader>s', function()
        local ok, telescope = pcall(require, 'telescope.builtin')
        if ok then
            telescope.lsp_document_symbols()
        else
            local ok_mini, _ = pcall(require, 'mini.extra')
            if ok_mini then
                vim.cmd('Pick lsp scope="document_symbol"')
            else
                vim.lsp.buf.document_symbol()
            end
        end
    end, { buffer = buffer, desc = 'LSP Document Symbols' })
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, {
        buffer = buffer, desc = "goto prev disgnostic"
    })
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, {
        buffer = buffer, desc = "goto next disgnostic"
    })
    vim.keymap.set('n', '[e', function()
        vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
    end, { buffer = buffer, desc = "goto prev err" })
    vim.keymap.set('n', ']e', function()
        vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
    end, { buffer = buffer, desc = "goto next err" })
    vim.keymap.set('n', '<Leader>cf', function()
        vim.lsp.buf.format({ async = true })
    end, { buffer = buffer, desc = 'format code' })
    vim.api.nvim_create_autocmd("CursorHold", {
        buffer = buffer,
        callback = function()
            local win_width = vim.api.nvim_win_get_width(0)
            vim.diagnostic.open_float(nil, {
                focusable = false,
                close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
                border = 'rounded',
                source = 'always',
                prefix = ' ',
                scope = 'cursor',
                relative = 'win',
                anchor = 'NE',
                row = 0,
                col = win_width,
            })
        end,
    })
end

M.setup_buffer = function(args)
    if args.indent then
        vim.opt_local.tabstop = args.indent
        vim.opt_local.shiftwidth = args.indent
        vim.opt_local.softtabstop = args.indent
        vim.opt_local.expandtab = true
    end
    if args.make then
        vim.opt_local.makeprg = args.make
    end
    if args.lsp then
        local cmd = args.lsp.cmd
        if args.indent and args.lsp.name == 'clangd' then
            table.insert(cmd, string.format('--fallback-style={IndentWidth: %d}', args.indent))
        end
        local found_root = vim.fs.find(args.lsp.root, { upward = true })[1]
        local root_dir = found_root and vim.fs.dirname(found_root) or vim.fn.getcwd()
        vim.lsp.start({
            name = args.lsp.name,
            cmd = cmd,
            root_dir = root_dir,
            on_attach = M.my_lsp_attach,
            capabilities = M.capabilities,
        })
    end
end

require('lsp.servers')(M)
return M
