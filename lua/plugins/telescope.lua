local telescope = require('telescope')
local builtin = require('telescope.builtin')

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
            "$.exe",
            "%.git",
            "target/",
            ".cache/",
        },
    },
})

-- keybindings
vim.keymap.set('n', '<Leader>ff', builtin.find_files, { desc = "Telescope: Find Files (CWD)" })

vim.keymap.set('n', '<Leader>fa', function()
    builtin.find_files({
        no_ignore = true,
        hidden = true,
    })
end, { desc = "Search All files (including ignored)" })

vim.keymap.set('n', '<Leader>fF', function()
    builtin.find_files({ cwd = vim.fs.dirname(vim.fs.find({'.git', 'CMakeLists.txt', 'Cargo.toml'}, { upward = true })[1]) })
end, { desc = "Telescope: Find Files (Project Root)" })

vim.keymap.set('n', '<Leader>fb', builtin.buffers, { desc = "Telescope: Buffers" })

vim.keymap.set('n', '<Leader>fg', builtin.live_grep, { desc = "Telescope: Live Grep" })
vim.keymap.set('n', '<Leader>/', builtin.live_grep, { desc = "Telescope: Live Grep" })

vim.keymap.set('n', '<Leader>s', builtin.lsp_document_symbols, { desc = "Telescope: LSP Symbols" })

vim.keymap.set('n', '<Leader>fr', builtin.oldfiles, { desc = "Telescope: Recent Files" })

