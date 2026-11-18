local M = {}

local citation = vim.regex([=[\v\\\a*[Cc]ite\a*\*?\s*(\[[^]]*\]\s*)*\{[^{}]*$]=])

local function uncomment(line)
  local i = 1
  while i <= #line do
    local char = line:sub(i, i)
    if char == "%" then
      return line:sub(1, i - 1)
    end
    i = i + (char == "\\" and 2 or 1)
  end
  return line
end

local function lines(context)
  return context.cache:ensure("mvim_tex_citation_lines", function()
    return vim.tbl_map(uncomment, vim.api.nvim_buf_get_lines(context.bufnr, 0, -1, false))
  end)
end

local function in_citation(context)
  return context.cache:ensure("mvim_in_tex_citation", function()
    local prefix = uncomment(context.cursor_before_line)
    local before = vim.list_slice(lines(context), 1, context.cursor.row - 1)
    before[#before + 1] = prefix
    -- Keep comments from turning a commented-out citation into an open argument.
    if prefix ~= context.cursor_before_line then
      return false
    end
    return citation:match_str(table.concat(before, " ")) ~= nil
  end)
end

function M.filter_generic(_, context)
  return not in_citation(context)
end

function M:is_available()
  return vim.bo.filetype == "tex" or vim.bo.filetype == "plaintex"
end

function M:get_keyword_pattern()
  return [[[^[:space:],{}]+]]
end

function M:get_trigger_characters()
  return { "{", ",", " " }
end

function M:complete(params, callback)
  if not in_citation(params.context) then
    callback({ items = {} })
    return
  end

  local text = table.concat(lines(params.context), "\n")
  local items, seen = {}, {}
  for position in text:gmatch("\\bibitem()%f[^%a]") do
    local tail = text:sub(position):gsub("^%s*", ""):gsub("^%b[]%s*", "")
    local key = tail:match("^{%s*([^{}%s]+)%s*}")
    if key and not seen[key] then
      seen[key] = true
      items[#items + 1] = {
        label = key,
        kind = vim.lsp.protocol.CompletionItemKind.Reference,
        documentation = tail:match("^{[^}]*}[ \t]*([^\n]*)"),
      }
    end
  end
  callback({ items = items, isIncomplete = true })
end

return M
