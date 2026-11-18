vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.cursorlineopt = "line"
vim.opt.signcolumn = "number"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.autoread = true

-- Fold selected lines with Space f.
vim.opt.foldmethod = "manual"
vim.opt.foldenable = true
vim.opt.foldlevelstart = 99

local indent_folds = vim.api.nvim_create_augroup("MvimIndentFolds", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = indent_folds,
  pattern = { "python", "rust", "c", "cpp" },
  callback = function()
    vim.opt_local.foldmethod = "indent"
    vim.opt_local.foldignore = ""
    vim.opt_local.foldlevel = 99
  end,
})

require("config.md_folds").setup()

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.completeopt = { "menu", "menuone", "noselect" }

local last_position = vim.api.nvim_create_augroup("MvimLastPosition", { clear = true })

vim.api.nvim_create_autocmd("BufReadPost", {
  group = last_position,
  callback = function(event)
    if vim.bo[event.buf].buftype ~= "" then
      return
    end

    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
      vim.cmd('normal! g`"')
    end
  end,
})

local external_changes = vim.api.nvim_create_augroup("MvimExternalChanges", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = external_changes,
  callback = function(event)
    if vim.bo[event.buf].buftype ~= "" or vim.bo[event.buf].modified then
      return
    end

    vim.cmd("silent checktime " .. event.buf)
  end,
})
