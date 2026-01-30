local c_cpp_setup = function(lsp_manager)
    return function()
        local bufnr = vim.api.nvim_get_current_buf()

        -- detect compile_commands.json (upward) or common build/compile_commands.json
        local comp_file = vim.fs.find('compile_commands.json', { upward = true })[1]
        local found_root = vim.fs.find({ 'compile_commands.json', '.git' }, { upward = true })[1]
        local root_dir = found_root and vim.fs.dirname(found_root) or vim.fn.getcwd()
        local build_comp = root_dir and (vim.loop.fs_stat(root_dir .. '/build/compile_commands.json'))

        if comp_file or build_comp then
            -- project has compile_commands.json -> use normal clangd config
            lsp_manager.setup_buffer({
                indent = 2,
                lsp = {
                    name = 'clangd',
                    cmd = { 'clangd' },
                    root = { 'compile_commands.json', '.git' },
                },
            })
            return
        end

        -- No compile_commands.json found: use ctags-based fallback
        if root_dir == nil then root_dir = vim.fn.getcwd() end
        local tagfile = root_dir .. '/tags'

        -- generate tags asynchronously if ctags available and tags missing
        if not vim.loop.fs_stat(tagfile) and vim.fn.executable('ctags') == 1 then
            vim.fn.jobstart({ 'ctags', '-R', '-f', tagfile, root_dir }, {
                on_exit = function(_, code)
                    vim.schedule(function()
                        if code == 0 then
                            vim.notify('ctags generated: ' .. tagfile, vim.log.levels.INFO)
                        else
                            vim.notify('ctags failed (exit ' .. code .. ')', vim.log.levels.WARN)
                        end
                    end)
                end,
            })
        end

        if vim.loop.fs_stat(tagfile) then
            vim.opt_local.tags = tagfile
        end

-- helper: escape a string for use in Vim regex
    local function escape_vim_regex(s)
        if not s or s == '' then return '' end
        -- use Vim's escape() to safely escape characters for a Vim regex
        return vim.fn.escape(s, '\\/.*$^~[]')
    end

    local function resolve_tag_lnum(t)
        local fname = t.filename
        local cmd = t.cmd or ''
        -- numeric cmd -> direct line
        local n = tonumber(cmd)
        if n then return n end
        -- /pattern/ -> search in file
        if cmd:match('^/.*/$') or cmd:match('^/.*') then
            local pat = cmd:gsub('^/', ''):gsub('/$', '')
            -- load buffer
            local bufn = vim.fn.bufadd(fname)
            pcall(vim.fn.bufload, bufn)
            local lines = vim.api.nvim_buf_get_lines(bufn, 0, -1, false)
            local ok, re = pcall(vim.regex, pat)
            if ok and re then
                for i, line in ipairs(lines) do
                    if re:match_str(line) then return i end
                end
            end
        end
        return 1
    end

    -- gd: go to definition via tags (use anchored taglist to avoid listing entire tags file)
    vim.keymap.set('n', 'gd', function()
        local sym = vim.fn.expand('<cword>')
        local pattern = '^' .. escape_vim_regex(sym) .. '$'
        local tag_entries = vim.fn.taglist(pattern)
        if #tag_entries == 0 then
            -- no tags: fallback to grep (telescope.grep_string preferred)
            local ok, telescope = pcall(require, 'telescope.builtin')
            if ok then
                telescope.grep_string({ search = sym })
            else
                vim.cmd('vimgrep /\\<' .. sym .. '\\>/j **/*')
                vim.cmd('copen')
            end
            return
        elseif #tag_entries == 1 then
            -- single tag: jump directly
            local t = tag_entries[1]
            if tonumber(t.cmd) then
                pcall(vim.cmd, 'edit ' .. t.filename)
                pcall(vim.fn.cursor, tonumber(t.cmd), 0)
            else
                pcall(vim.cmd, 'tag ' .. sym)
            end
            return
        else
            -- multiple tags: show a telescope picker built from tag_entries
            local ok_t, telescope = pcall(require, 'telescope')
            if ok_t then
                local pickers = require('telescope.pickers')
                local finders = require('telescope.finders')
                local actions = require('telescope.actions')
                local action_state = require('telescope.actions.state')
                local conf = require('telescope.config').values

                local items = {}
                for _, t in ipairs(tag_entries) do
                    local lnum = resolve_tag_lnum(t)
                    local bufn = vim.fn.bufadd(t.filename)
                    pcall(vim.fn.bufload, bufn)
                    local preview = ''
                    local ok_line, line = pcall(vim.api.nvim_buf_get_lines, bufn, lnum - 1, lnum, false)
                    if ok_line and line and line[1] then preview = vim.trim(line[1]) end
                    table.insert(items, { display = string.format('%s — %s:%d', t.name, t.filename, lnum), filename = t.filename, lnum = lnum, text = preview })
                end

                pickers.new({}, {
                    prompt_title = 'Tags: ' .. sym,
                    finder = finders.new_table {
                        results = items,
                        entry_maker = function(entry)
                            return {
                                value = entry,
                                display = entry.display,
                                ordinal = entry.display,
                                filename = entry.filename,
                                lnum = entry.lnum,
                                text = entry.text,
                            }
                        end,
                    },
                    previewer = conf.qflist_previewer({}),
                    sorter = conf.generic_sorter({}),
                    attach_mappings = function(prompt_bufnr, map)
                        actions.select_default:replace(function()
                            local selection = action_state.get_selected_entry().value
                            actions.close(prompt_bufnr)
                            vim.cmd('edit ' .. selection.filename)
                            vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
                        end)
                        return true
                    end,
                }):find()
                return
            else
                -- fallback: open quickfix with tag locations
                local qf = {}
                for _, t in ipairs(tag_entries) do
                    local lnum = resolve_tag_lnum(t)
                    table.insert(qf, { filename = t.filename, lnum = lnum, text = t.name })
                end
                vim.fn.setqflist({}, ' ', { title = 'Tag definitions: ' .. sym, items = qf })
                vim.cmd('copen')
                return
            end
        end
    end, { buffer = bufnr, desc = 'Goto (tags) definition' })

    -- <Leader>cr: show references via tags database (prefer a telescope picker built from taglist)
    vim.keymap.set('n', '<Leader>cr', function()
        local sym = vim.fn.expand('<cword>')
        local pattern = '^' .. escape_vim_regex(sym) .. '$'
        local tag_entries = vim.fn.taglist(pattern)
        if #tag_entries == 0 then
            -- fallback to grep_string
            local ok, telescope = pcall(require, 'telescope.builtin')
            if ok then
                telescope.grep_string({ search = sym })
            else
                vim.cmd('vimgrep /\\<' .. sym .. '\\>/j **/*')
                vim.cmd('copen')
            end
            return
        end

        local ok_t, telescope = pcall(require, 'telescope')
        if ok_t then
            local pickers = require('telescope.pickers')
            local finders = require('telescope.finders')
            local actions = require('telescope.actions')
            local action_state = require('telescope.actions.state')
            local conf = require('telescope.config').values

            local items = {}
            for _, t in ipairs(tag_entries) do
                local lnum = resolve_tag_lnum(t)
                local bufn = vim.fn.bufadd(t.filename)
                pcall(vim.fn.bufload, bufn)
                local preview = ''
                local ok_line, line = pcall(vim.api.nvim_buf_get_lines, bufn, lnum - 1, lnum, false)
                if ok_line and line and line[1] then preview = vim.trim(line[1]) end
                table.insert(items, { display = string.format('%s — %s:%d', t.name, t.filename, lnum), filename = t.filename, lnum = lnum, text = preview })
            end

            pickers.new({}, {
                prompt_title = 'References: ' .. sym,
                finder = finders.new_table {
                    results = items,
                    entry_maker = function(entry)
                        return {
                            value = entry,
                            display = entry.display,
                            ordinal = entry.display,
                            filename = entry.filename,
                            lnum = entry.lnum,
                            text = entry.text,
                        }
                    end,
                },
                previewer = conf.qflist_previewer({}),
                sorter = conf.generic_sorter({}),
                attach_mappings = function(prompt_bufnr, map)
                    actions.select_default:replace(function()
                        local selection = action_state.get_selected_entry().value
                        actions.close(prompt_bufnr)
                        vim.cmd('edit ' .. selection.filename)
                        vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
                    end)
                    return true
                end,
            }):find()
            return
        else
            -- fallback: build quickfix from taglist
            local qf = {}
            for _, t in ipairs(tag_entries) do
                local lnum = resolve_tag_lnum(t)
                table.insert(qf, { filename = t.filename, lnum = lnum, text = t.name })
            end
            if #qf > 0 then
                vim.fn.setqflist({}, ' ', { title = 'Tag references: ' .. sym, items = qf })
                vim.cmd('copen')
                return
            end
        end
    end, { buffer = bufnr, desc = 'Find references (tags/grep)' })

        -- <Leader>s: list symbols in current file (prefer LSP, fallback to current buffer tags)
        vim.keymap.set('n', '<Leader>s', function()
            local ok, telescope = pcall(require, 'telescope.builtin')
            if ok then
                local status = pcall(telescope.lsp_document_symbols)
                if not status then
                    pcall(telescope.current_buffer_tags)
                end
            else
                vim.cmd('echo "No telescope available"')
            end
        end, { buffer = bufnr, desc = 'List symbols (buffer)' })

        -- Start clangd but in a restricted mode: keep semantic/highlight but disable completion/goto/diagnostics
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        local ok_cmp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
        if ok_cmp then capabilities = cmp_lsp.default_capabilities(capabilities) end

        local on_attach = function(client, buffer)
            -- disable capabilities that provide completion/goto/rename/formatting
            client.server_capabilities.completionProvider = nil
            client.server_capabilities.definitionProvider = nil
            client.server_capabilities.referencesProvider = nil
            client.server_capabilities.renameProvider = nil
            client.server_capabilities.implementationProvider = nil
            client.server_capabilities.documentFormattingProvider = nil
            client.server_capabilities.documentRangeFormattingProvider = nil

            -- suppress diagnostics from this clangd instance
            client.handlers['textDocument/publishDiagnostics'] = function() end

            -- do NOT call the global LSP attach (we want tags mappings)
        end

        vim.lsp.start({
            name = 'clangd',
            cmd = { 'clangd' },
            root_dir = root_dir,
            on_attach = on_attach,
            capabilities = capabilities,
        })
    end
end


return function(lsp_manager)
    -- C/C++ (clangd) with tags fallback
    vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'c', 'cpp', 'objc', 'objcpp' },
        callback = c_cpp_setup(lsp_manager),
    })

    -- Rust (rust-analyzer)
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'rust',
        callback = function()
            lsp_manager.setup_buffer({
                indent = 4,
                make = "cargo build",
                lsp = {
                    name = 'rust-analyzer',
                    cmd = { 'rust-analyzer' },
                    root = { 'Cargo.toml', '.git' },
                },
            })
        end,
    })

    -- CMake (neocmakelsp)
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'cmake',
        callback = function()
            lsp_manager.setup_buffer({
                indent = 2,
                lsp = {
                    name = 'neocmakelsp',
                    cmd = { 'neocmakelsp', 'stdio' },
                    root = { 'CMakeLists.txt' },
                }
            })
        end,
    })

    -- lua (lua-language-server)
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'lua',
        callback = function()
            lsp_manager.setup_buffer({
                indent = 4,
                lsp = {
                    name = 'lua-language-server',
                    cmd = { 'lua-language-server' },
                    root = { 'lua', 'stylua.toml', '.luarc.json', 'selene.toml' },
                },
            })
        end,
    })

    -- zig (zls)
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'zig',
        callback = function()
            lsp_manager.setup_buffer({
                indent = 4,
                make = "zig build",
                lsp = {
                    name = 'zls',
                    cmd = { 'zls' },
                    root = { 'build.zig', '.git' },
                },
            })
        end,
    })
end

