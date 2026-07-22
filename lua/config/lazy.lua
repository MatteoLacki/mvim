local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  require("plugins.lsp"),
  require("plugins.tree"),
  require("plugins.treesitter"),
  require("plugins.completion"),
  require("plugins.autopairs"),
  require("plugins.slime"),
  require("plugins.ai"),
}, {
  change_detection = { notify = false },
})
