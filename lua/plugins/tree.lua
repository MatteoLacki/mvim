return {
  {
    "nvim-tree/nvim-tree.lua",
    cmd = {
      "NvimTreeFindFile",
      "NvimTreeFocus",
      "NvimTreeToggle",
    },
    keys = {
      { "<leader>t", "<cmd>NvimTreeToggle<cr>", desc = "Toggle project tree" },
      { "<leader>T", "<cmd>NvimTreeFindFile<cr>", desc = "Reveal file in project tree" },
    },
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    opts = {
      diagnostics = {
        enable = true,
      },
      git = {
        enable = true,
      },
      renderer = {
        icons = {
          show = {
            file = false,
            folder = false,
            folder_arrow = false,
            git = false,
          },
        },
      },
      update_focused_file = {
        enable = true,
      },
      view = {
        width = 30,
      },
    },
  },
}
