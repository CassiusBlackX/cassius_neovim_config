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

-- bufline auto show/hide
vim.api.nvim_create_autocmd({ "BufEnter", "BufAdd", "BufDelete" }, {
    callback = function()
        local n_buffers = #vim.fn.getbufinfo({ buflisted = 1 })
        if n_buffers > 1 then
            vim.opt.showtabline = 2
        else
            vim.opt.showtabline = 0
        end
    end,
})

-- integrated terminal
vim.keymap.set('n', '<Leader>tt', '<cmd>belowright split | terminal<CR>i', {
    desc = "open integrated terminal"
})
