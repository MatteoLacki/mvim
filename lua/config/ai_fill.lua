local M = {}

local function line_at(bufnr, line_nr)
  return vim.api.nvim_buf_get_lines(bufnr, line_nr - 1, line_nr, false)[1] or ""
end

local function indent_width(line)
  local spaces = line:match("^%s*") or ""
  return #spaces:gsub("\t", "    ")
end

local function is_blank(line)
  return line:match("^%s*$") ~= nil
end

local function is_python_block_header(line)
  return line:match("^%s*.*:%s*$") ~= nil or line:match("^%s*.*:%s*#") ~= nil
end

local function parse_marker(line)
  local provider, instruction = line:match("^%s*#%s*([%w_-]+)%s*:%s*(.+)$")
  if not provider then
    provider, instruction = line:match("^%s*#%s*([%w_-]+)%s+(.+)$")
  end
  if (provider == "claude" or provider == "codex") and instruction and instruction ~= "" then
    return provider, instruction
  end
  return nil, nil
end

local function find_marker(bufnr)
  local current = vim.api.nvim_win_get_cursor(0)[1]
  local first = math.max(1, current - 80)
  local last = math.min(vim.api.nvim_buf_line_count(bufnr), current + 80)

  for line_nr = current, first, -1 do
    local provider, instruction = parse_marker(line_at(bufnr, line_nr))
    if provider then
      return line_nr, provider, instruction
    end
  end

  for line_nr = current + 1, last do
    local provider, instruction = parse_marker(line_at(bufnr, line_nr))
    if provider then
      return line_nr, provider, instruction
    end
  end

  return nil, nil, nil
end

local function find_python_chunk(bufnr, current)
  local last = vim.api.nvim_buf_line_count(bufnr)
  local current_line = line_at(bufnr, current)

  if is_blank(current_line) then
    return current, current
  end

  local current_indent = indent_width(current_line)
  local first = current

  if not is_python_block_header(current_line) then
    for line_nr = current - 1, 1, -1 do
      local line = line_at(bufnr, line_nr)
      if not is_blank(line) then
        local indent = indent_width(line)
        if indent < current_indent and is_python_block_header(line) then
          first = line_nr
          break
        elseif indent < current_indent then
          break
        end
      end
    end
  end

  while first > 1 do
    local prev = line_at(bufnr, first - 1)
    if prev:match("^%s*@") then
      first = first - 1
    else
      break
    end
  end

  local base_indent = indent_width(line_at(bufnr, first))
  local stop = first
  local saw_body = false

  for line_nr = first + 1, last do
    local line = line_at(bufnr, line_nr)
    if is_blank(line) then
      if saw_body then
        stop = line_nr
      end
    else
      local indent = indent_width(line)
      if indent > base_indent then
        saw_body = true
        stop = line_nr
      else
        break
      end
    end
  end

  while stop > first and is_blank(line_at(bufnr, stop)) do
    stop = stop - 1
  end

  return first, stop
end

local function strip_code_fence(text)
  local stripped = text:gsub("^%s*```[%w_-]*\n", ""):gsub("\n```%s*$", "")
  stripped = stripped:gsub("^%s*`%s*", ""):gsub("%s*`%s*$", "")
  return stripped
end

local function split_lines(text)
  text = strip_code_fence(text):gsub("\r\n", "\n"):gsub("\r", "\n")
  text = text:gsub("\n+$", "")
  return vim.split(text, "\n", { plain = true })
end

local function build_prompt(path, filetype, instruction, chunk_lines, buffer_lines)
  return table.concat({
    "You are editing an existing code block inside a Neovim buffer.",
    "Treat the target block as existing user code that must be respected.",
    "Make the smallest change that satisfies the instruction.",
    "Preserve existing behavior, names, structure, comments, formatting style, and imports unless the instruction explicitly asks to change them.",
    "Do not blindly replace working code with a fresh implementation.",
    "Return only the complete replacement text for the target block.",
    "Do not include Markdown fences, explanations, diffs, or surrounding prose.",
    "Remove the #claude/#codex instruction comment from the returned code only if it was consumed.",
    "",
    "File: " .. path,
    "Filetype: " .. filetype,
    "",
    "Instruction:",
    instruction,
    "",
    "Target block:",
    "```" .. filetype,
    table.concat(chunk_lines, "\n"),
    "```",
    "",
    "Full buffer for context:",
    "```" .. filetype,
    table.concat(buffer_lines, "\n"),
    "```",
  }, "\n")
end

local function command_for(provider, cwd, output_file)
  if provider == "claude" then
    return {
      "claude",
      "-p",
      "--output-format",
      "text",
      "--permission-mode",
      "dontAsk",
      "--tools",
      "",
    }
  end

  return {
    "codex",
    "exec",
    "--sandbox",
    "read-only",
    "--ask-for-approval",
    "never",
    "--ephemeral",
    "--cd",
    cwd,
    "--output-last-message",
    output_file,
    "-",
  }
end

local function read_file(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local text = fd:read("*a")
  fd:close()
  return text
end

function M.fill(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local marker_line, marker_provider, instruction = find_marker(bufnr)
  local provider = opts and opts.provider or marker_provider

  if not marker_line then
    vim.notify("Put #claude: ... or #codex: ... above the code to fill.", vim.log.levels.WARN)
    return
  end

  if provider ~= "claude" and provider ~= "codex" then
    vim.notify("AI provider must be claude or codex.", vim.log.levels.ERROR)
    return
  end

  if vim.fn.executable(provider) ~= 1 then
    vim.notify(provider .. " CLI is not executable on PATH.", vim.log.levels.ERROR)
    return
  end

  local first, stop = find_python_chunk(bufnr, marker_line)
  local chunk_lines = vim.api.nvim_buf_get_lines(bufnr, first - 1, stop, false)
  local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local original = table.concat(chunk_lines, "\n")
  local cwd = vim.fn.getcwd()
  local output_file = vim.fn.tempname()
  local prompt = build_prompt(vim.api.nvim_buf_get_name(bufnr), vim.bo[bufnr].filetype, instruction, chunk_lines, buffer_lines)

  vim.notify("Running " .. provider .. " for lines " .. first .. "-" .. stop .. "...")

  vim.system(command_for(provider, cwd, output_file), { stdin = prompt, text = true, cwd = cwd }, function(result)
    local output = result.stdout or ""
    if provider == "codex" then
      output = read_file(output_file) or output
      os.remove(output_file)
    end

    vim.schedule(function()
      if result.code ~= 0 then
        local stderr = (result.stderr or ""):gsub("%s+$", "")
        vim.notify(provider .. " failed: " .. stderr, vim.log.levels.ERROR)
        return
      end

      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      local current = table.concat(vim.api.nvim_buf_get_lines(bufnr, first - 1, stop, false), "\n")
      if current ~= original then
        vim.notify("Buffer changed while " .. provider .. " was running; not applying result.", vim.log.levels.WARN)
        return
      end

      local replacement = split_lines(output)
      if #replacement == 0 or (#replacement == 1 and replacement[1] == "") then
        vim.notify(provider .. " returned no replacement code.", vim.log.levels.WARN)
        return
      end

      vim.api.nvim_buf_set_lines(bufnr, first - 1, stop, false, replacement)
      vim.notify("Applied " .. provider .. " replacement.")
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("AIFill", function(args)
    local provider = args.args ~= "" and args.args or nil
    M.fill({ provider = provider })
  end, {
    nargs = "?",
    complete = function()
      return { "claude", "codex" }
    end,
    desc = "Replace the current Python block using a #claude/#codex instruction",
  })

  vim.keymap.set("n", "<leader>af", function()
    M.fill({})
  end, { desc = "AI fill #claude/#codex block" })
end

return M
