local telescope = require('telescope')
local builtin = require('telescope.builtin')
local actions = require('telescope.actions')

telescope.setup({
    -- make preview more beautiful
    defaults = {
        prompt_prefix = " 🔍 ",
        selection_caret = "  ",
        path_display = { "truncate" },
        sorting_strategy = "ascending",
        layout_config = {
            horizontal = {
                prompt_position = "top",
                preview_width = 0.55,
            },
            vertical = {
                mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
        },
        file_ignore_patterns = {
            "node_modules/",
            "build/",
            "%.obj",
            "%.exe",
            "%.git",
            "target/",
            ".cache/",
        },
        mappings = {
            i = {
                ['<Tab>'] = actions.move_selection_next,
                ['<S-Tab>'] = actions.move_selection_previous,
            },
            n = {
                ['<Tab>'] = actions.move_selection_next,
                ['<S-Tab>'] = actions.move_selection_previous,
            },
        },
        vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "--glob!=**/*.git/*"
        },
        pickers = {
            find_files = {
                find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
            },
        },
    },
})

-- keybindings
vim.keymap.set('n', '<Leader>ff', builtin.find_files, { desc = "Find Files (CWD)" })

vim.keymap.set('n', '<Leader>fa', function()
    builtin.find_files({
        no_ignore = true,
        hidden = true,
    })
end, { desc = "Search All files (including ignored)" })

vim.keymap.set('n', '<Leader>fF', function()
    local root = vim.fs.dirname(vim.fs.find({ '.git' }, { upward = true })[1])
    if root == nil then
        root = vim.fs.dirname(vim.fs.find({ 'CMakeLists.txt', 'Makefile', 'Cargo.toml', 'package.json', 'pyproject.toml' },
            {
                upward = true,
                stop = vim.uv.os_homedir(),
            })[1])
    end
    local opts = {
        cwd = root or vim.fn.getcwd()
    }
    builtin.find_files(opts)
end, { desc = "Find Files (Project Root)" })

vim.keymap.set('n', '<Leader>fb', builtin.buffers, { desc = "Telescope: Buffers" })

vim.keymap.set('n', '<Leader>fg', builtin.live_grep, { desc = "Telescope: Live Grep" })
vim.keymap.set('n', '<Leader>/', builtin.live_grep, { desc = "Telescope: Live Grep" })

vim.keymap.set('n', '<Leader>s', builtin.lsp_document_symbols, { desc = "Telescope: LSP Symbols" })

vim.keymap.set('n', '<Leader>fr', builtin.oldfiles, { desc = "Telescope: Recent Files" })


local telescope_group = vim.api.nvim_create_augroup("TelescopeStart", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
    group = telescope_group,
    callback = function()
        local stats = vim.loop.fs_stat(vim.api.nvim_buf_get_name(0))
        if stats and stats.type == 'directory' then
            local buffer = vim.api.nvim_get_current_buf()
            vim.schedule(function()
                vim.api.nvim_buf_delete(buffer, { force = true })
                require('telescope.builtin').find_files()
            end)
        end
    end,
})
