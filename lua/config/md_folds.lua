-- Indent folding inside fenced code blocks of supported languages in Markdown.
local M = {}

local supported = { python = true, py = true, rust = true, rs = true, c = true, cpp = true, ["c++"] = true }
local cache = {}

local function fence_map(buf)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local entry = cache[buf]
  if entry and entry.tick == tick then
    return entry.map
  end

  local map, lang = {}, nil
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local fence, info = line:match("^%s*(```+)%s*([%w_+#-]*)")
    if fence then
      if lang == nil then
        lang = info:lower()
      else
        lang = nil
      end
      map[i] = false -- fence lines never fold
    else
      map[i] = lang ~= nil and supported[lang] or false
    end
  end
  cache[buf] = { tick = tick, map = map }
  return map
end

function M.foldexpr()
  local lnum = vim.v.lnum
  if not fence_map(vim.api.nvim_get_current_buf())[lnum] then
    return 0
  end
  local text = vim.fn.getline(lnum)
  if text:match("^%s*$") then
    return "-1"
  end
  return math.floor(vim.fn.indent(lnum) / vim.fn.shiftwidth())
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("MvimMarkdownFolds", { clear = true }),
    pattern = "markdown",
    callback = function()
      vim.opt_local.foldmethod = "expr"
      vim.opt_local.foldexpr = "v:lua.require'config.md_folds'.foldexpr()"
      vim.opt_local.foldlevel = 99
    end,
  })
end

return M
