local M = {}

local function path_exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function dirname(path)
  return vim.fs.dirname(vim.fs.normalize(path))
end

local function find_project_black(start_path)
  local dir = dirname(start_path)

  while dir do
    local black = dir .. "/.venv/bin/black"
    if path_exists(black) then
      return black
    end

    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end

  return nil
end

local function buffer_text(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = table.concat(lines, "\n")

  if vim.bo[bufnr].endofline then
    text = text .. "\n"
  end

  return text
end

local function replace_buffer_text(bufnr, text)
  local view = vim.fn.winsaveview()
  local lines = vim.split(text, "\n", { plain = true })

  if lines[#lines] == "" then
    table.remove(lines)
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.fn.winrestview(view)
end

local function find_active_venv_black()
  local venv = vim.env.VIRTUAL_ENV
  if not venv then
    return nil
  end

  local black = venv .. "/bin/black"
  if path_exists(black) then
    return black
  end

  return nil
end

local function black_format(bufnr)
  if vim.g.mvim_black_on_save == false then
    return
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" then
    return
  end

  local black = find_project_black(filename) or find_active_venv_black()
  if not black then
    return
  end

  local result = vim.system({
    black,
    "--quiet",
    "--stdin-filename",
    filename,
    "-",
  }, {
    stdin = buffer_text(bufnr),
    text = true,
  }):wait()

  if result.code ~= 0 then
    vim.notify("black failed: " .. vim.trim(result.stderr or ""), vim.log.levels.WARN)
    return
  end

  replace_buffer_text(bufnr, result.stdout or "")
end

function M.setup()
  if vim.g.mvim_black_on_save == nil then
    vim.g.mvim_black_on_save = true
  end

  local group = vim.api.nvim_create_augroup("MvimFormat", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    pattern = "*.py",
    callback = function(event)
      black_format(event.buf)
    end,
  })
end

return M
