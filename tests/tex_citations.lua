local function run()
  local source = require("config.tex_citations")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo.filetype = "tex"
  local bibliography = {
    [[\bibitem{sandve2013ten} Sandve et al. Reproducible research.]],
    [[\bibitem[Smith(2020)]{smith:2020-v2} Smith. Example reference.]],
    [[\bibitem]],
    [=[  [Jones {et al.}(2021)]]=],
    [[  {jones2021} Jones. Another reference.]],
    [[\bibitem{sandve2013ten} Duplicate key.]],
    [[% \bibitem{commented} Hidden reference.]],
    [[\\% \bibitem{also_commented} Hidden after escaped backslash.]],
    [[\bibitemize{not_a_reference} Another command.]],
  }

  local function complete(prefix)
    local before = vim.split(prefix, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.list_extend(vim.deepcopy(before), bibliography))
    local context = {
      bufnr = buf,
      cursor = { row = #before },
      cursor_before_line = before[#before],
      cache = require("cmp.utils.cache").new(),
    }
    local result
    source:complete({ context = context }, function(response) result = response end)
    assert(result, "completion callback missing")
    local labels = vim.tbl_map(function(item) return item.label end, result.items)
    table.sort(labels)
    return labels, source.filter_generic(nil, context), result.items
  end

  for _, prefix in ipairs({
    [[\cite{]],
    [[\citep{]],
    [[\citet*{]],
    [[\Citep{]],
    [[\parencite[see][p. 2]{]],
    [[\citeauthor{]],
    [[\nocite{]],
    [[\cite{sandve2013ten, sm]],
    "\\cite{\n  sm",
    "\\citep\n[see]\n[p. 2]\n{sm",
    [[100\% reproducible: \cite{]],
  }) do
    local labels, generic, items = complete(prefix)
    assert(vim.deep_equal(labels, { "jones2021", "sandve2013ten", "smith:2020-v2" }),
      prefix .. ": " .. vim.inspect(labels))
    assert(not generic, "generic suggestions inside " .. prefix)
    assert(items[1].documentation == "Sandve et al. Reproducible research.")
  end

  for _, prefix in ipairs({
    "ordinary text",
    [[\ref{]],
    [[\cite{sandve2013ten} ordinary text]],
    [[\citep[see]],
    [[% \cite{]],
    "text % comment\nordinary text",
    "% \\cite{\nordinary text",
    "\\cite{\n% commented citation key",
  }) do
    local labels, generic = complete(prefix)
    assert(#labels == 0, "citation suggestions outside argument: " .. prefix)
    assert(generic, "generic suggestions disabled outside argument: " .. prefix)
  end

  bibliography = { [[\bibitem{unsaved_new_key} Newly edited reference.]] }
  local labels = complete([[\cite{]])
  assert(vim.deep_equal(labels, { "unsaved_new_key" }), "unsaved bibliography edit not reflected")

  bibliography = {}
  local empty, generic = complete([[\cite{]])
  assert(#empty == 0 and not generic, "empty citation falls back to generic suggestions")

  vim.bo.filetype = "python"
  assert(not source:is_available(), "inline citation source enabled for Python")
  local sources = require("cmp").get_config().sources
  assert(sources[1].name == "nvim_lsp" and sources[2].name == "luasnip")
  assert(sources[1].group_index == 1 and sources[2].group_index == 1 and sources[4].group_index == 2)
  vim.api.nvim_buf_delete(buf, { force = true })
  print("TeX citation regression checks passed")
end

local ok, err = pcall(run)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
end
