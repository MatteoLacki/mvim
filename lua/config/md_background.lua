-- Tint the background of Markdown prose slightly violet; fenced code stays untinted.
local M = {}

local ns = vim.api.nvim_create_namespace("mvim_md_background")
local violet = { 0x8a, 0x5c, 0xf6 }
local strength = 0.3

local function set_highlight()
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  if not bg then
    return
  end
  local channels = { math.floor(bg / 65536) % 256, math.floor(bg / 256) % 256, bg % 256 }
  local mixed = {}
  for i = 1, 3 do
    mixed[i] = math.floor(channels[i] * (1 - strength) + violet[i] * strength + 0.5)
  end
  vim.api.nvim_set_hl(0, "MvimMarkdownProse", { bg = string.format("#%02x%02x%02x", mixed[1], mixed[2], mixed[3]) })
end

local function paint(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  set_highlight()
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local in_code = false
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line:match("^%s*```") then
      in_code = not in_code
    elseif not in_code then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { line_hl_group = "MvimMarkdownProse", priority = 1 })
    end
  end
end

function M.setup()
  set_highlight()
  local group = vim.api.nvim_create_augroup("MvimMarkdownBackground", { clear = true })
  -- Colourschemes run `highlight clear`, so re-create the group whenever they might have.
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlight })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      vim.schedule(function()
        set_highlight()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[buf].filetype == "markdown" then
            paint(buf)
          end
        end
      end)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = group,
    pattern = "*.md",
    callback = set_highlight,
  })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "markdown",
    callback = function(event)
      paint(event.buf)
      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        group = group,
        buffer = event.buf,
        callback = function()
          paint(event.buf)
        end,
      })
    end,
  })
end

return M
