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

      local function is_block_header(line)
        return line:match("^%s*.*:%s*$") ~= nil or line:match("^%s*.*:%s*#") ~= nil
      end

      local function find_python_chunk()
        local current = vim.api.nvim_win_get_cursor(0)[1]
        local last = vim.api.nvim_buf_line_count(0)
        local current_line = line_at(current)

        if is_blank(current_line) then
          return current, current
        end

        local current_indent = indent_width(current_line)
        local first = current

        if not is_block_header(current_line) then
          for line_nr = current - 1, 1, -1 do
            local line = line_at(line_nr)
            if not is_blank(line) then
              local indent = indent_width(line)
              if indent < current_indent and is_block_header(line) then
                first = line_nr
                break
              elseif indent < current_indent then
                break
              end
            end
          end
        end

        while first > 1 do
          local prev = line_at(first - 1)
          if prev:match("^%s*@") then
            first = first - 1
          else
            break
          end
        end

        local header_line = line_at(first)
        local base_indent = indent_width(header_line)
        local stop = first
        local saw_body = false

        for line_nr = first + 1, last do
          local line = line_at(line_nr)
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

        while stop > first and is_blank(line_at(stop)) do
          stop = stop - 1
        end

        return first, stop
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

      local function send_line()
        if vim.bo.filetype == "python" then
          local first, stop = find_python_chunk()
          if send_range(first, stop) then
            vim.api.nvim_win_set_cursor(0, { math.min(stop + 1, vim.api.nvim_buf_line_count(0)), 0 })
          end
        else
          local current = vim.api.nvim_win_get_cursor(0)[1]
          if send_range(current, current) then
            vim.cmd("normal! j")
          end
        end
      end

      local function send_visual()
        local start_line = vim.fn.getpos("'<")[2]
        local end_line = vim.fn.getpos("'>")[2]
        send_range(start_line, end_line)
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
        vim.keymap.set("n", key, send_line, { desc = "Send line/block to tmux" })
        vim.keymap.set("x", key, send_visual, { desc = "Send selection to tmux" })
      end
      vim.keymap.set("n", "<leader><CR>", send_cell, { desc = "Send Python cell to tmux" })
      vim.keymap.set("n", "<leader>rp", start_ipython, { desc = "Start IPython tmux pane" })
    end,
  },
}
