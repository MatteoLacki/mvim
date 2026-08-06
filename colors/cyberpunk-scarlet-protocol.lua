-- Cyberpunk Scarlet Protocol for Neovim.
-- Mirrors the Ghostty theme palette, including the local pure-black override.

vim.opt.background = "dark"
vim.cmd.highlight("clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd.syntax("reset")
end
vim.g.colors_name = "cyberpunk-scarlet-protocol"

local c = {
  bg = "#000000",
  bg_alt = "#101116",
  fg = "#e41951",
  selection = "#c1deff",
  black = "#101116",
  red = "#ff0051",
  green = "#01dc84",
  yellow = "#faf945",
  blue = "#0271b6",
  magenta = "#c930c7",
  cyan = "#00c5c7",
  white = "#c7c7c7",
  gray = "#686868",
  bright_red = "#ff6e67",
  bright_green = "#60fa68",
  bright_yellow = "#fffc67",
  bright_blue = "#6871ff",
  bright_magenta = "#bd35ec",
  bright_cyan = "#60fdff",
  bright_white = "#ffffff",
  cursor = "#76ff9f",
}

local function hi(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

hi("Normal", { fg = c.fg, bg = c.bg })
hi("NormalNC", { fg = c.fg, bg = c.bg })
hi("NormalFloat", { fg = c.fg, bg = c.bg_alt })
hi("FloatBorder", { fg = c.red, bg = c.bg_alt })
hi("FloatTitle", { fg = c.bright_yellow, bg = c.bg_alt, bold = true })
hi("ColorColumn", { bg = c.bg_alt })
hi("Cursor", { fg = c.bg, bg = c.cursor })
hi("lCursor", { link = "Cursor" })
hi("CursorIM", { link = "Cursor" })
hi("CursorColumn", { bg = c.bg_alt })
hi("CursorLine", { bg = c.bg_alt })
hi("CursorLineNr", { fg = c.bright_yellow, bg = c.bg_alt, bold = true })
hi("LineNr", { fg = c.gray, bg = c.bg })
hi("SignColumn", { fg = c.gray, bg = c.bg })
hi("FoldColumn", { fg = c.gray, bg = c.bg })
hi("Folded", { fg = c.cyan, bg = c.bg_alt })
hi("VertSplit", { fg = c.gray, bg = c.bg })
hi("WinSeparator", { fg = c.gray, bg = c.bg })
hi("EndOfBuffer", { fg = c.bg, bg = c.bg })
hi("NonText", { fg = c.gray })
hi("Whitespace", { fg = c.gray })
hi("SpecialKey", { fg = c.gray })
hi("Visual", { fg = c.bg, bg = c.selection })
hi("VisualNOS", { fg = c.bg, bg = c.selection })
hi("Search", { fg = c.bg, bg = c.yellow })
hi("CurSearch", { fg = c.bg, bg = c.red, bold = true })
hi("IncSearch", { link = "CurSearch" })
hi("Substitute", { fg = c.bg, bg = c.bright_magenta })
hi("MatchParen", { fg = c.bright_white, bg = c.blue, bold = true })
hi("StatusLine", { fg = c.bg, bg = c.red, bold = true })
hi("StatusLineNC", { fg = c.white, bg = c.bg_alt })
hi("TabLine", { fg = c.white, bg = c.bg_alt })
hi("TabLineFill", { fg = c.gray, bg = c.bg_alt })
hi("TabLineSel", { fg = c.bg, bg = c.red, bold = true })
hi("WinBar", { fg = c.bright_red, bg = c.bg, bold = true })
hi("WinBarNC", { fg = c.gray, bg = c.bg })
hi("Pmenu", { fg = c.fg, bg = c.bg_alt })
hi("PmenuSel", { fg = c.bg, bg = c.red, bold = true })
hi("PmenuSbar", { bg = c.gray })
hi("PmenuThumb", { bg = c.bright_red })
hi("WildMenu", { fg = c.bg, bg = c.cyan })
hi("Question", { fg = c.bright_green, bold = true })
hi("MoreMsg", { fg = c.bright_green })
hi("ModeMsg", { fg = c.bright_yellow, bold = true })
hi("WarningMsg", { fg = c.bright_yellow, bold = true })
hi("ErrorMsg", { fg = c.bright_red, bold = true })
hi("Title", { fg = c.bright_red, bold = true })
hi("Directory", { fg = c.bright_blue, bold = true })

hi("Comment", { fg = c.gray, italic = true })
hi("Constant", { fg = c.bright_yellow })
hi("String", { fg = c.green })
hi("Character", { fg = c.bright_green })
hi("Number", { fg = c.bright_yellow })
hi("Boolean", { fg = c.bright_yellow, bold = true })
hi("Float", { link = "Number" })
hi("Identifier", { fg = c.fg })
hi("Function", { fg = c.bright_cyan })
hi("Statement", { fg = c.bright_magenta })
hi("Conditional", { fg = c.magenta, bold = true })
hi("Repeat", { link = "Conditional" })
hi("Label", { fg = c.bright_red })
hi("Operator", { fg = c.bright_white })
hi("Keyword", { fg = c.red, bold = true })
hi("Exception", { fg = c.bright_red, bold = true })
hi("PreProc", { fg = c.bright_magenta })
hi("Include", { fg = c.magenta })
hi("Define", { fg = c.bright_magenta })
hi("Macro", { fg = c.bright_magenta })
hi("PreCondit", { fg = c.magenta })
hi("Type", { fg = c.cyan })
hi("StorageClass", { fg = c.bright_cyan })
hi("Structure", { fg = c.bright_cyan })
hi("Typedef", { fg = c.cyan })
hi("Special", { fg = c.bright_red })
hi("SpecialChar", { fg = c.bright_green })
hi("Tag", { fg = c.bright_blue })
hi("Delimiter", { fg = c.white })
hi("SpecialComment", { fg = c.bright_cyan, italic = true })
hi("Debug", { fg = c.bright_red })
hi("Underlined", { fg = c.bright_blue, underline = true })
hi("Ignore", { fg = c.gray })
hi("Error", { fg = c.bright_white, bg = c.red, bold = true })
hi("Todo", { fg = c.bg, bg = c.bright_yellow, bold = true })

hi("DiffAdd", { fg = c.bright_green, bg = c.bg_alt })
hi("DiffChange", { fg = c.bright_yellow, bg = c.bg_alt })
hi("DiffDelete", { fg = c.bright_red, bg = c.bg_alt })
hi("DiffText", { fg = c.bg, bg = c.bright_yellow, bold = true })
hi("Added", { fg = c.bright_green })
hi("Changed", { fg = c.bright_yellow })
hi("Removed", { fg = c.bright_red })

hi("DiagnosticError", { fg = c.bright_red })
hi("DiagnosticWarn", { fg = c.bright_yellow })
hi("DiagnosticInfo", { fg = c.bright_blue })
hi("DiagnosticHint", { fg = c.bright_cyan })
hi("DiagnosticOk", { fg = c.bright_green })
hi("DiagnosticUnderlineError", { sp = c.bright_red, undercurl = true })
hi("DiagnosticUnderlineWarn", { sp = c.bright_yellow, undercurl = true })
hi("DiagnosticUnderlineInfo", { sp = c.bright_blue, undercurl = true })
hi("DiagnosticUnderlineHint", { sp = c.bright_cyan, undercurl = true })
hi("DiagnosticUnderlineOk", { sp = c.bright_green, undercurl = true })

hi("@variable", { fg = c.fg })
hi("@variable.builtin", { fg = c.bright_red, italic = true })
hi("@variable.parameter", { fg = c.bright_red })
hi("@constant", { link = "Constant" })
hi("@constant.builtin", { fg = c.bright_yellow, bold = true })
hi("@module", { fg = c.bright_blue })
hi("@string", { link = "String" })
hi("@string.escape", { fg = c.bright_green })
hi("@character", { link = "Character" })
hi("@number", { link = "Number" })
hi("@boolean", { link = "Boolean" })
hi("@function", { link = "Function" })
hi("@function.builtin", { fg = c.cyan })
hi("@function.call", { fg = c.bright_cyan })
hi("@constructor", { fg = c.cyan })
hi("@keyword", { link = "Keyword" })
hi("@keyword.function", { fg = c.magenta, bold = true })
hi("@keyword.return", { fg = c.red, bold = true })
hi("@operator", { link = "Operator" })
hi("@type", { link = "Type" })
hi("@type.builtin", { fg = c.bright_cyan })
hi("@property", { fg = c.bright_blue })
hi("@punctuation", { fg = c.white })
hi("@comment", { link = "Comment" })
hi("@tag", { fg = c.red })
hi("@tag.attribute", { fg = c.bright_yellow })

hi("LspReferenceText", { bg = c.bg_alt })
hi("LspReferenceRead", { bg = c.bg_alt })
hi("LspReferenceWrite", { bg = c.bg_alt, underline = true })

local terminal = {
  c.black,
  c.red,
  c.green,
  c.yellow,
  c.blue,
  c.magenta,
  c.cyan,
  c.white,
  c.gray,
  c.bright_red,
  c.bright_green,
  c.bright_yellow,
  c.bright_blue,
  c.bright_magenta,
  c.bright_cyan,
  c.bright_white,
}
for index, color in ipairs(terminal) do
  vim.g["terminal_color_" .. (index - 1)] = color
end
