return function(lsp_manager)
    -- C/C++ (clangd)
    vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'c', 'cpp', 'objc', 'objcpp' },
        callback = function()
            lsp_manager.setup_buffer({
                indent = 2,
                make = "cmake --build build",
                lsp = {
                    name = 'clangd',
                    cmd = { 'clangd' },
                    root = { 'compile_commands.json', '.git' },
                },
            })
        end,
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
end
