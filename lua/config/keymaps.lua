local map = vim.keymap.set

local colorscheme_state_file = vim.fn.stdpath("state") .. "/mvim-colorscheme"

local function persist_colorscheme(colorscheme)
  vim.fn.mkdir(vim.fn.fnamemodify(colorscheme_state_file, ":h"), "p")
  if vim.fn.writefile({ colorscheme }, colorscheme_state_file) ~= 0 then
    vim.notify("Could not save colorscheme preference", vim.log.levels.ERROR)
  end
end

local function restore_colorscheme()
  if vim.fn.filereadable(colorscheme_state_file) == 0 then
    return
  end

  local colorscheme = vim.fn.readfile(colorscheme_state_file, "", 1)[1]
  if colorscheme and vim.tbl_contains(vim.fn.getcompletion("", "color"), colorscheme) then
    pcall(vim.cmd.colorscheme, colorscheme)
  end
end

vim.api.nvim_create_autocmd("VimEnter", { callback = restore_colorscheme })

local function choose_colorscheme()
  local colorschemes = vim.fn.getcompletion("", "color")
  if #colorschemes == 0 then
    vim.notify("No colorschemes are installed", vim.log.levels.WARN)
    return
  end

  table.sort(colorschemes)
  local original_colorscheme = vim.g.colors_name or "default"
  local index = 1
  for i, colorscheme in ipairs(colorschemes) do
    if colorscheme == original_colorscheme then
      index = i
      break
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local widest_name = 0
  for _, colorscheme in ipairs(colorschemes) do
    widest_name = math.max(widest_name, vim.fn.strdisplaywidth(colorscheme))
  end
  local width = math.max(1, math.min(widest_name + 2, vim.o.columns - 4))
  local height = math.max(1, math.min(#colorschemes, vim.o.lines - 4))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2 - 1),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Colorscheme: Enter save, Esc restore ",
    title_pos = "center",
  })

  local function render()
    local lines = {}
    for i, colorscheme in ipairs(colorschemes) do
      lines[i] = (i == index and "> " or "  ") .. colorscheme
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_win_set_cursor(win, { index, 0 })
  end

  local function preview()
    local ok, err = pcall(vim.cmd.colorscheme, colorschemes[index])
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
    render()
  end

  local function close(save_selection)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if save_selection then
      persist_colorscheme(colorschemes[index])
    else
      vim.cmd.colorscheme(original_colorscheme)
    end
  end

  local function move(delta)
    index = (index - 1 + delta) % #colorschemes + 1
    preview()
  end

  local options = { buffer = buf, nowait = true, silent = true }
  map("n", "<Up>", function() move(-1) end, options)
  map("n", "<Down>", function() move(1) end, options)
  map("n", "k", function() move(-1) end, options)
  map("n", "j", function() move(1) end, options)
  map("n", "<Tab>", function() move(1) end, options)
  map("n", "<S-Tab>", function() move(-1) end, options)
  map("n", "<CR>", function() close(true) end, options)
  map("n", "<Esc>", function() close(false) end, options)
  map("n", "q", function() close(false) end, options)

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  render()
end

vim.api.nvim_create_user_command("Colorscheme", choose_colorscheme, {})

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<leader>c", choose_colorscheme, { desc = "Choose colorscheme" })

map("v", "<Tab>", ">gv", { desc = "Indent selection" })
map("v", "<S-Tab>", "<gv", { desc = "Outdent selection" })

map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
