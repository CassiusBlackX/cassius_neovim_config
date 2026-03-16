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

-- optimized for huge files
vim.api.nvim_create_autocmd({ "BufReadPre" }, {
    pattern = { "*.log" },
    callback = function()
        local max_filesize = 100 * 1024 -- 1KB
        local check_stats = vim.loop.fs_stat(vim.api.nvim_buf_get_name(0))
        if check_stats and check_stats.size > max_filesize then
            vim.opt_local.syntax = "off"
            vim.opt_local.undoreload = 0
            vim.opt_local.swapfile = false
            vim.opt_local.loadplugins = false
            vim.opt_local.foldmethod = "manual"
            vim.opt_local.undolevels = -1
            print("Large file detected: Performance optimizations applited")
        end
    end,
})

-- make run user cmd
vim.api.nvim_create_user_command('MakeRun', function()
    local bufname = vim.fn.expand('%:t:r')  -- get current buffer name
    if bufname == '' then
        vim.notify('no file name detected', vim.log.levels.ERROR)
        return
    end
    vim.env.TARGET_EXE = bufname
    vim.cmd('make run')
end, { desc = "run exe corresponding to the current.c file"})
--[[ ========= makefile template =========
.PHONY: build clean run

build: setup
	cmake --build build

setup: build/CMakeCache.txt

build/CMakeCache.txt: CMakeLists.txt
	cmake -B build -S . -G Ninja

clean:
	rm -rf build

run:
	@if [ -z "$(TARGET_EXE)" ]; then \
		echo "Error: TARGET_EXE not set. Use ':MakeRun' in Neovim."; \
		exit 1; \
	fi; \
	if [ -x "./build/$(TARGET_EXE)" ]; then \
		echo "Running: ./build/$(TARGET_EXE)"; \
		./build/$(TARGET_EXE); \
	else \
		echo "Error: Executable './build/$(TARGET_EXE)' not found."; \
		exit 1; \
	fi25k
========makefile template end ====== --]]

