# CLAUDE.md

This repository contains a small, reproducible Python-focused Neovim setup installed as `mvim`.

## Project Shape

- `Makefile` is the main setup interface.
- `install.sh` detects Linux/macOS architecture, downloads Neovim, and installs it as `~/.local/bin/mvim` by default.
- `init.lua` loads config modules under `lua/config/`.
- Plugin specs live under `lua/plugins/`.
- `lazy-lock.json` is tracked for reproducible plugin versions.

## Commands

Run checks before committing config changes:

```bash
make check
```

Install or refresh a local setup:

```bash
make install
make sync
```

Inspect local installation state:

```bash
make doctor
```

## Editing Guidance

- Keep the config minimal and Python-focused.
- Prefer small Lua modules over adding framework-style abstractions.
- Preserve `mvim` as the installed executable name; do not switch the project back to installing `nvim`.
- Keep Linux and macOS install paths working when changing `install.sh`.
- Do not store API keys or local secrets in the repo. AI completion reads `OPENAI_API_KEY` from the environment.
- The Python send workflow should work when `mvim` runs outside tmux and sends to an existing tmux pane.

## Key Behaviors To Preserve

- Pyright starts for Python files.
- `Ctrl+Space`, `F5`, and `<leader>s` send the current Python line/block to tmux.
- Visual `Ctrl+Space` and visual `F5` send the selected block.
- `<leader><Enter>` sends the current `# %%` cell.
- `<leader>rp` starts IPython in tmux.
- `<leader>t` toggles the project tree, `<leader>T` reveals the current file in it, and `Ctrl-w h` / `Ctrl-w l` move between the tree and file windows.
- Bracket/quote autopairs work in insert mode.

## Verification

At minimum, run:

```bash
make check
```

For send-code changes, manually test with:

```bash
tmux
python3 -m IPython
```

Then open `mvim file.py` outside tmux and send a single line plus a function definition.
