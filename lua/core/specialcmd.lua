-- auto save when focus lost
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "WinLeave" }, {
    callback = function()
        if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
            vim.cmd("silent update")
            vim.notify("Auto-saved: " .. vim.fn.expand("%:t"),
                vim.log.levels.INFO, { title = "nvim" }
            )
        end
    end,
})

-- restore cursor position on file reopen
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lnum = mark[1]
        local col = mark[2]
        if lnum > 0 and lnum <= vim.api.nvim_buf_line_count(0) then
            pcall(vim.api.nvim_win_set_cursor, 0, { lnum, col })
        end
    end,
})
