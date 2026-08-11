vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.autoread = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.completeopt = { "menu", "menuone", "noselect" }

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
