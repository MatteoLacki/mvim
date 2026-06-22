# betternvim

Small Python-focused Neovim config, installed as `mvim`.

## Install from GitHub

```bash
git clone <your-github-url> betternvim
cd betternvim
make install
```

`make install` downloads Neovim `v0.12.3` to `~/.local/bin/mvim`, links this
repo to `~/.config/nvim`, installs plugins, and installs Pyright through Mason.

Make sure `~/.local/bin` is on `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then start the editor with:

```bash
mvim file.py
```

Useful make targets:

```bash
make install   # install mvim and sync plugins/tools
make sync      # resync plugins and Pyright
make check     # syntax/startup check
make doctor    # show executable/config/tool status
make uninstall # remove ~/.local/bin/mvim and this repo's ~/.config/nvim link
```

## Python REPL sending

You do not need to run `mvim` inside tmux. There only needs to be a tmux pane to
receive code.

One simple setup:

```bash
tmux
python3 -m IPython
```

Detach with `Ctrl-b d`, then open a Python file elsewhere:

```bash
mvim file.py
```

Or ask `mvim` to start IPython in tmux with:

```text
<leader>rp
```

Send code to the active pane in an attached tmux session, falling back to the last listed tmux pane:

- `<F5>`, `<leader>s`, `<C-Space>`, or `<C-Enter>` if your terminal supports it: current Python line or enclosing indented block, then move past it
- visual `<F5>` or `<C-Space>`: selected block
- `<leader><Enter>`: current `# %%` cell

`<F5>` is the reliable fallback because many terminals do not send a distinct
Ctrl+Enter key code. Sending targets an explicit tmux pane id, so `mvim` can run
outside tmux.

## LSP

Pyright is installed by Mason. Useful keys:

- `gd`: definition
- `gr`: references
- `K`: hover
- `<leader>rn`: rename
- `<leader>ca`: code action

## Optional AI completion

AI completion uses `minuet-ai.nvim` only when `OPENAI_API_KEY` is present in the
environment. It is API-billed and separate from Codex subscription credits.
