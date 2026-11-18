return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({ "python", "markdown", "markdown_inline", "latex", "bibtex" })
  end,
}
