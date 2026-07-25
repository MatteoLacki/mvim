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

      local function read_json_file(path)
        local f = io.open(path, "r")
        if not f then
          return nil
        end
        local content = f:read("*a")
        f:close()
        local ok, decoded = pcall(vim.json.decode, content)
        if ok then
          return decoded
        end
        return nil
      end

      -- Find `.venvmap.json` walking upward from `start_dir` (inclusive).
      -- Returns (map_dir, map_table) or (nil, nil).
      local function find_venvmap(start_dir)
        local dir = start_dir
        while dir and dir ~= "" do
          local candidate = dir .. "/.venvmap.json"
          if path_exists(candidate) then
            local map = read_json_file(candidate)
            if map then
              return dir, map
            end
          end
          local parent = vim.fs.dirname(dir)
          if parent == dir then
            break
          end
          dir = parent
        end
        return nil, nil
      end

      -- Resolve `root_dir` against an explicit `.venvmap.json` (see
      -- find_venvmap above): each key is a path relative to the map file's
      -- own directory, each value a venv directory (containing bin/python)
      -- also relative to that same directory. The longest matching key
      -- wins, so a more specific sub-repo entry overrides a shorter one.
      -- This exists because some multi-repo checkouts use more than one
      -- venv for different subtrees, keyed by directory rather than by a
      -- guessable venv directory name (".venv"/"venv" aren't the only
      -- convention -- e.g. "venvs/common").
      local function resolve_from_venvmap(root_dir)
        local map_dir, map = find_venvmap(root_dir)
        if not map then
          return nil
        end

        local rel = root_dir == map_dir and "." or root_dir:sub(#map_dir + 2)

        local best_key, best_len = nil, -1
        for key, _ in pairs(map) do
          local matches = rel == key or (key ~= "." and rel:sub(1, #key + 1) == key .. "/")
          if matches and #key > best_len then
            best_key, best_len = key, #key
          end
        end
        if not best_key then
          return nil
        end

        local python = map_dir .. "/" .. map[best_key] .. "/bin/python"
        if path_exists(python) then
          return python
        end
        return nil
      end

      -- Walk upward from `start_dir` (inclusive) looking for a `.venv`/`venv`.
      -- Needed because pyright's `root_dir` stops at the nearest project
      -- marker (pyproject.toml, .git, ...) -- inside a multi-repo checkout
      -- (a top-level venv with several vendored sub-repos each their own git
      -- clone underneath), that marker is often a sub-repo with no venv of
      -- its own, well below the real project venv.
      local function find_venv_upwards(start_dir)
        local dir = start_dir
        while dir and dir ~= "" do
          for _, name in ipairs({ ".venv", "venv" }) do
            local python = dir .. "/" .. name .. "/bin/python"
            if path_exists(python) then
              return python
            end
          end
          local parent = vim.fs.dirname(dir)
          if parent == dir then
            break
          end
          dir = parent
        end
        return nil
      end

      local function project_python(root_dir)
        -- 1. An explicit, versioned `.venvmap.json` is the most reliable
        -- signal when a project declares one -- see resolve_from_venvmap.
        local mapped = resolve_from_venvmap(root_dir)
        if mapped then
          return mapped
        end

        -- 2. Otherwise, file location still wins over whatever happens to
        -- be active in the shell: some checkouts (e.g. a multi-repo
        -- project with several vendored sub-repos, each needing a
        -- different venv) use more than one venv for different subtrees,
        -- so a single globally-activated $VIRTUAL_ENV is not a reliable
        -- match for any given buffer.
        local found = find_venv_upwards(root_dir)
        if found then
          return found
        end

        local venv = vim.env.VIRTUAL_ENV
        if venv and venv ~= "" then
          local python = venv .. "/bin/python"
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

      -- Symlinked files (e.g. a top-level `pipeline.py` pointing into a
      -- vendored sub-repo) keep the symlink's own apparent location as
      -- their buffer name -- Neovim does not resolve it -- so marker-based
      -- root_dir search would stop at the symlink's own directory instead
      -- of the real file's project. Resolve to the real path first.
      local root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "pyrightconfig.json", ".git" }
      local function resolved_root_dir(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local real = vim.uv.fs_realpath(fname) or fname
        on_dir(vim.fs.root(real, root_markers) or vim.fn.getcwd())
      end

      vim.lsp.config("pyright", {
        capabilities = capabilities,
        root_dir = resolved_root_dir,
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
