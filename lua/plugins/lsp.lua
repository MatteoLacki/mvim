return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "pyright" },
      automatic_enable = false,
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local function path_exists(path)
        return vim.uv.fs_stat(path) ~= nil
      end

      local function project_python(root_dir)
        local venv = vim.env.VIRTUAL_ENV
        if venv and venv ~= "" then
          local python = venv .. "/bin/python"
          if path_exists(python) then
            return python
          end
        end

        for _, name in ipairs({ ".venv", "venv" }) do
          local python = root_dir .. "/" .. name .. "/bin/python"
          if path_exists(python) then
            return python
          end
        end

        local python3 = vim.fn.exepath("python3")
        if python3 ~= "" then
          return python3
        end

        return vim.fn.exepath("python")
      end

      vim.lsp.config("pyright", {
        capabilities = capabilities,
        before_init = function(_, config)
          config.settings.python.pythonPath = project_python(config.root_dir or vim.fn.getcwd())
        end,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              useLibraryCodeForTypes = true,
            },
          },
        },
      })
      vim.lsp.enable("pyright")

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local opts = { buffer = event.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
          vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
          vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
        end,
      })
    end,
  },
}
