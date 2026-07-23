# mvim

Small Python-focused Neovim config, installed as `mvim`.

`mvim` is short for “myvim”: my Vim, my rules.

## Key Bindings

Leader key is `Space`.

### Files and Basics

| Key | Mode | Action |
| --- | --- | --- |
| `Space w` | normal | Write current file |
| `Space q` | normal | Quit current window |
| `Space h` | normal | Clear search highlight |
| `Space t` | normal | Toggle project tree |
| `Space T` | normal | Reveal current file in project tree |
| `Ctrl-w h` | normal | Move focus to the left window, usually the project tree |
| `Ctrl-w l` | normal | Move focus to the right window, usually the file |
| `Space c` | normal | Open live colorscheme navigator (`↑`/`↓` preview; `Enter` save; `Esc` restore) |
| `Tab` | visual/select | Indent the selected lines and keep them selected |
| `Shift-Tab` | visual/select | Outdent the selected lines and keep them selected |

### Multiple Cursors

Multiple-cursor editing is provided by `vim-visual-multi` with its default mappings.
Its occurrence matching is case-sensitive by default.

| Key | Mode | Action |
| --- | --- | --- |
| `Ctrl-n` | normal | Select the word under the cursor; press again to add its next occurrence |
| `Ctrl-n` | visual | Select the next occurrence of the current selection |
| `\\A` | normal/visual | Select all occurrences of the word under the cursor or the visual selection |
| `n` / `N` | multi-cursor | Add the next/previous occurrence |
| `\\c` | multi-cursor | Cycle matching from case-sensitive to case-insensitive to smart-case |
| `q` | multi-cursor | Skip the current occurrence |
| `Q` | multi-cursor | Remove the current cursor |
| `Esc` | multi-cursor | Leave multi-cursor mode |

After selecting the occurrences, use normal Vim editing commands such as `c`,
`d`, or `I`; the edit is applied to every cursor.

To include matches with different capitalization, start a multi-cursor selection
and press `\\c` once. Press it again for smart-case matching, or leave and restart
multi-cursor mode to return to the case-sensitive default.

### Python Send To IPython/tmux

| Key | Mode | Action |
| --- | --- | --- |
| `Ctrl-Space` | normal | Send the current Python line |
| `F5` | normal | Same as `Ctrl-Space`; reliable terminal fallback |
| `Space s` | normal | Same as `Ctrl-Space`; mnemonic fallback |
| `Ctrl-Enter` | normal | Same as `Ctrl-Space` when terminal emits a distinct key code |
| `Ctrl-Space` | visual | Send selected text |
| `F5` | visual | Send selected text |
| `Space s` | visual | Send selected text |
| `Space Enter` | normal | Send current `# %%` cell |
| `Space r p` | normal | Start IPython in tmux |

`Ctrl-Enter` support depends on the terminal. If it does nothing, use `Ctrl-Space`, `F5`, or `Space s`.

### Python LSP

| Key | Mode | Action |
| --- | --- | --- |
| `gd` | normal | Go to definition |
| `gr` | normal | Show references |
| `K` | normal | Hover documentation |
| `Space rn` | normal | Rename symbol |
| `Space ca` | normal/visual | Code action |
| `Ctrl-o` | normal | Jump back |
| `Ctrl-i` | normal | Jump forward |

### Python Formatting

Python files are formatted with Black on write when the project has
`.venv/bin/black`. Disable this with:

```lua
vim.g.mvim_black_on_save = false
```

### Diagnostics

| Key | Mode | Action |
| --- | --- | --- |
| `Space e` | normal | Show diagnostic under cursor |
| `[d` | normal | Previous diagnostic |
| `]d` | normal | Next diagnostic |

### Completion

| Key | Mode | Action |
| --- | --- | --- |
| `Ctrl-Space` | insert | Open completion menu |
| `Tab` | insert/select | Next completion item or snippet jump |
| `Shift-Tab` | insert/select | Previous completion item or snippet jump back |
| `Enter` | insert | Confirm selected completion item |
| `Ctrl-e` | insert | Abort completion menu |

### Brackets and Quotes

Bracket and quote pairs are inserted automatically in insert mode by `nvim-autopairs`.

### AI Block Fill

| Key | Mode | Action |
| --- | --- | --- |
| `Space a f` | normal | Replace the current Python block from a `#claude:` or `#codex:` instruction |

Write an instruction comment inside a Python block, then run `<leader>af`:

```python
def parse_row(row):
    #claude: finish this function; return a dict with id, name, and score
```

or:

```python
def parse_row(row):
    #codex: finish this function; return a dict with id, name, and score
```

`mvim` sends the current block and buffer context to the selected CLI, then
replaces only that block with the returned code. The edit stays in the buffer, so
normal undo works.

## Install from GitHub

```bash
git clone <your-github-url> mvim
cd mvim
make install
```

`make install` detects Linux/macOS and CPU architecture, downloads Neovim `v0.12.3`, installs it as `~/.local/bin/mvim`, links this repo to `~/.config/nvim`, installs plugins, and installs Pyright through Mason.

Main dependencies:

- Neovim `v0.12.3`, downloaded by `make install` as `mvim`
- `lazy.nvim`, plugin manager bootstrapped by the config
- Pyright, installed by Mason for Python LSP
- `nvim-tree.lua` for a toggleable project work-tree
- `nvim-cmp`/LuaSnip for completion and snippets
- `nvim-autopairs` for bracket/quote completion
- `vim-slime` plus tmux for send-to-REPL workflow
- Optional `minuet-ai.nvim` for OpenAI API-backed AI completion
- Optional `claude` or `codex` CLI for marker-driven block fill

Prerequisites:

- `bash`, `make`, `curl`, `git`, `tar`
- `python3`
- Node/npm, for Mason installing Pyright
- `tmux`, for Python send-to-REPL workflow
- IPython for the Python REPL workflow, installable with `python3 -m pip install ipython` if missing

Supported Neovim downloads:

- Linux x86_64 / arm64: official tarball
- macOS x86_64 / arm64: official tarball

Make sure `~/.local/bin` is on `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then start the editor with:

```bash
mvim file.py
```

To browse a project tree, start `mvim` from the project directory and press
`<leader>t`. Use `<leader>T` to reveal the current file in the tree. After
opening a file from the tree, use `Ctrl-w h` to move focus back to the tree and
`Ctrl-w l` to return to the file window.

Useful make targets:

```bash
make install   # install mvim and sync plugins/tools
make sync      # resync plugins and Pyright
make check     # syntax/startup check
make doctor    # show executable/config/tool status
make uninstall # remove ~/.local/bin/mvim, installed tarball dir, and this repo's ~/.config/nvim link
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

- `<F5>`, `<leader>s`, `<C-Space>`, or `<C-Enter>` when your terminal emits a distinct key code: current Python line, then move past it
- visual `<F5>` or `<C-Space>`: selected text
- `<leader><Enter>`: current `# %%` cell

`<F5>` is the reliable fallback because many terminals do not send a distinct
Ctrl+Enter key code. Sending targets an explicit tmux pane id, so `mvim` can run
outside tmux.

## LSP

Pyright is installed by Mason. For Python package completions, start `mvim` from
the project root and either activate a virtualenv first or keep it at `.venv/`
or `venv/` in the project root:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install numpy pandas ipython
mvim file.py
```

Pyright uses that interpreter, so imports and completions come from packages
installed in the venv. Useful keys:

- `gd`: definition
- `gr`: references
- `K`: hover
- `<leader>rn`: rename
- `<leader>ca`: code action

## Optional AI completion

AI completion uses `minuet-ai.nvim` only when `OPENAI_API_KEY` is present in the
environment. It is API-billed and separate from Codex subscription credits.

## Optional AI block fill

Install and authenticate either the `claude` or `codex` CLI, then add a marker
comment such as `#claude: implement this function` or `#codex: implement this
function` inside a Python block. Press `<leader>af` or run `:AIFill`.

You can force a provider with `:AIFill claude` or `:AIFill codex`. Codex is run
with read-only sandboxing; Claude is run in print mode with tools disabled.
