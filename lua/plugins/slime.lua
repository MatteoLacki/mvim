return {
  {
    "jpalardy/vim-slime",
    init = function()
      vim.g.slime_target = "tmux"
      vim.g.slime_default_config = {
        socket_name = "default",
        target_pane = "{last}",
      }
      vim.g.slime_dont_ask_default = 1
      vim.g.slime_bracketed_paste = 1
      vim.g.slime_python_ipython = 1
      vim.g.slime_cell_delimiter = "^# %%"
      vim.g.slime_no_mappings = 1
    end,
    config = function()
      local function indent_width(line)
        local spaces = line:match("^%s*") or ""
        return #spaces:gsub("\t", "    ")
      end

      local function is_blank(line)
        return line:match("^%s*$") ~= nil
      end

      local function line_at(line_nr)
        return vim.api.nvim_buf_get_lines(0, line_nr - 1, line_nr, false)[1] or ""
      end

      local opening_brackets = { ["("] = true, ["["] = true, ["{"] = true }
      local closing_brackets = { [")"] = true, ["]"] = true, ["}"] = true }
      local continuation_clauses = { ["else"] = true, elif = true, except = true, finally = true }

      local function bracket_delta(line, string_state)
        local delta = 0
        local index = 1

        while index <= #line do
          local char = line:sub(index, index)
          if string_state.quote then
            if string_state.triple then
              local marker = string_state.quote:rep(3)
              if line:sub(index, index + 2) == marker then
                string_state.quote = nil
                string_state.triple = false
                index = index + 3
              elseif char == "\\" then
                index = index + 2
              else
                index = index + 1
              end
            elseif string_state.escaped then
              string_state.escaped = false
              index = index + 1
            elseif char == "\\" then
              string_state.escaped = true
              index = index + 1
            elseif char == string_state.quote then
              string_state.quote = nil
              index = index + 1
            else
              index = index + 1
            end
          elseif char == "#" then
            break
          elseif char == "\"" or char == "'" then
            string_state.quote = char
            string_state.triple = line:sub(index, index + 2) == char:rep(3)
            index = index + (string_state.triple and 3 or 1)
          elseif opening_brackets[char] then
            delta = delta + 1
            index = index + 1
          elseif closing_brackets[char] then
            delta = delta - 1
            index = index + 1
          else
            index = index + 1
          end
        end

        return delta
      end

      local function logical_line_end(first, last)
        local depth = 0
        local string_state = { quote = nil, triple = false, escaped = false }

        for line_nr = first, last do
          depth = depth + bracket_delta(line_at(line_nr), string_state)
          if depth <= 0 then
            return line_nr
          end
        end

        return last
      end

      local function find_python_chunk()
        local current = vim.api.nvim_win_get_cursor(0)[1]
        local last = vim.api.nvim_buf_line_count(0)
        local current_line = line_at(current)

        if is_blank(current_line) then
          return current, current
        end

        local base_indent = indent_width(current_line)
        local stop = logical_line_end(current, last)
        local line_nr = stop + 1

        while line_nr <= last do
          local line = line_at(line_nr)
          if is_blank(line) then
            line_nr = line_nr + 1
          else
            local indent = indent_width(line)
            local first_word = line:match("^%s*([%a_]+)")
            local continues_clause = indent == base_indent and continuation_clauses[first_word] == true
            if indent <= base_indent and not continues_clause then
              break
            end

            stop = logical_line_end(line_nr, last)
            line_nr = stop + 1
          end
        end

        return current, stop
      end

      local function first_tmux_window(session)
        local windows = vim.fn.systemlist({ "tmux", "list-windows", "-t", session, "-F", "#{window_index}" })
        if vim.v.shell_error ~= 0 or #windows == 0 then
          return nil
        end
        return session .. ":" .. windows[1]
      end

      local function first_tmux_session()
        local sessions = vim.fn.systemlist({ "tmux", "list-sessions", "-F", "#{session_name}" })
        if vim.v.shell_error ~= 0 or #sessions == 0 then
          return nil
        end
        return sessions[1]
      end

      local function tmux_target_pane()
        local panes = vim.fn.systemlist({
          "tmux",
          "list-panes",
          "-a",
          "-F",
          "#{pane_id}\t#{session_attached}\t#{window_active}\t#{pane_active}",
        })

        if vim.v.shell_error ~= 0 or #panes == 0 then
          return nil
        end

        local fallback = nil
        for _, pane in ipairs(panes) do
          local pane_id, session_attached, window_active, pane_active = pane:match("^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)$")
          if pane_id then
            fallback = pane_id
            if session_attached ~= "0" and window_active == "1" and pane_active == "1" then
              return pane_id
            end
          end
        end

        return fallback
      end

      local function tmux_send_text(text)
        local target = tmux_target_pane()
        if not target then
          vim.notify("No tmux session found. Start tmux or press <leader>rp first.", vim.log.levels.WARN)
          return false
        end

        vim.fn.system({ "tmux", "load-buffer", "-" }, text)
        if vim.v.shell_error ~= 0 then
          vim.notify("tmux load-buffer failed", vim.log.levels.ERROR)
          return false
        end

        vim.fn.system({ "tmux", "paste-buffer", "-d", "-p", "-t", target })
        if vim.v.shell_error ~= 0 then
          vim.notify("tmux paste-buffer failed", vim.log.levels.ERROR)
          return false
        end

        vim.fn.system({ "tmux", "send-keys", "-t", target, "Enter" })
        if vim.v.shell_error ~= 0 then
          vim.notify("tmux send-keys Enter failed", vim.log.levels.ERROR)
          return false
        end

        return true
      end

      local function python_repl_text(lines)
        local text = table.concat(lines, "\n")
        if #lines > 1 then
          return text .. "\n\n"
        end
        return text .. "\n"
      end

      local function send_range(first, stop)
        local lines = vim.api.nvim_buf_get_lines(0, first - 1, stop, false)
        if #lines == 0 then
          return false
        end

        if vim.bo.filetype == "python" then
          return tmux_send_text(python_repl_text(lines))
        end

        return tmux_send_text(table.concat(lines, "\n") .. "\n")
      end

      local function send_text(text)
        if text == "" then
          return false
        end

        if vim.bo.filetype == "python" then
          return tmux_send_text(python_repl_text(vim.split(text, "\n", { plain = true })))
        end

        return tmux_send_text(text .. "\n")
      end

      local function move_cursor_after(stop)
        local line_count = vim.api.nvim_buf_line_count(0)
        local target = math.min(stop + 1, line_count)
        local target_line = line_at(target)
        local column = #(target_line:match("^%s*") or "")
        vim.api.nvim_win_set_cursor(0, { target, column })
      end

      local function send_line()
        local current = vim.api.nvim_win_get_cursor(0)[1]
        if send_range(current, current) then
          move_cursor_after(current)
        end
      end

      local function send_python_chunk_or_line()
        if vim.bo.filetype ~= "python" then
          return send_line()
        end

        local first, stop = find_python_chunk()
        if send_range(first, stop) then
          move_cursor_after(stop)
        end
      end

      local function send_visual()
        local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
        return send_text(table.concat(lines, "\n"))
      end

      local function send_cell()
        local current = vim.api.nvim_win_get_cursor(0)[1]
        local last = vim.api.nvim_buf_line_count(0)
        local first = current

        while first > 1 do
          local line = vim.api.nvim_buf_get_lines(0, first - 2, first - 1, false)[1]
          if line:match("^%s*#%s*%%%%") then
            break
          end
          first = first - 1
        end

        local stop = current
        while stop < last do
          local line = vim.api.nvim_buf_get_lines(0, stop, stop + 1, false)[1]
          if line:match("^%s*#%s*%%%%") then
            break
          end
          stop = stop + 1
        end

        send_range(first, stop)
      end

      local function start_ipython()
        local session = first_tmux_session()
        if not session then
          vim.fn.system({ "tmux", "new-session", "-d", "-s", "python", "python3", "-m", "IPython" })
          if vim.v.shell_error == 0 then
            vim.notify("Started detached tmux session 'python' with IPython")
          else
            vim.notify("Failed to start tmux IPython session", vim.log.levels.ERROR)
          end
          return
        end

        local window = first_tmux_window(session)
        if not window then
          vim.notify("Could not find a tmux window in session " .. session, vim.log.levels.ERROR)
          return
        end

        vim.fn.system({
          "tmux",
          "split-window",
          "-t",
          window,
          "-h",
          "-l",
          "40%",
          "python3",
          "-m",
          "IPython",
        })
      end

      local send_keys = {
        "<F5>",
        "<leader>s",
        "<C-Space>",
        "<Nul>",
        "<C-CR>",
        "<C-Enter>",
        "<Esc>[13;5u",
        "<Esc>[13;5~",
        "<Esc>[27;5;13~",
        "<Esc>[57414;5u",
        "<Esc>\r",
        "<Esc>\n",
      }

      for _, key in ipairs(send_keys) do
        vim.keymap.set("n", key, send_python_chunk_or_line, { desc = "Send Python line/block to tmux" })
        vim.keymap.set("x", key, send_visual, { desc = "Send selected text to tmux" })
      end
      vim.keymap.set("n", "<leader><CR>", send_cell, { desc = "Send Python cell to tmux" })
      vim.keymap.set("n", "<leader>rp", start_ipython, { desc = "Start IPython tmux pane" })
    end,
  },
}
