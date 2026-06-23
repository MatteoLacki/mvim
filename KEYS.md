# Key Reference

Leader key is `Space`.

## Files and Basics

| Key | Mode | Action |
| --- | --- | --- |
| `Space w` | normal | Write current file |
| `Space q` | normal | Quit current window |
| `Space h` | normal | Clear search highlight |
| `Space t` | normal | Toggle project tree |
| `Space T` | normal | Reveal current file in project tree |
| `Ctrl-w h` | normal | Move focus to the left window, usually the project tree |
| `Ctrl-w l` | normal | Move focus to the right window, usually the file |

## Python Send To IPython/tmux

| Key | Mode | Action |
| --- | --- | --- |
| `Ctrl-Space` | normal | Send current Python line or enclosing indented block |
| `F5` | normal | Same as `Ctrl-Space`; reliable terminal fallback |
| `Space s` | normal | Same as `Ctrl-Space`; mnemonic fallback |
| `Ctrl-Enter` | normal | Same as `Ctrl-Space` when terminal emits a distinct key code |
| `Ctrl-Space` | visual | Send selected block |
| `F5` | visual | Send selected block |
| `Space s` | visual | Send selected block |
| `Space Enter` | normal | Send current `# %%` cell |
| `Space r p` | normal | Start IPython in tmux |

`Ctrl-Enter` support depends on the terminal. If it does nothing, use `Ctrl-Space`, `F5`, or `Space s`.

## Python LSP

| Key | Mode | Action |
| --- | --- | --- |
| `gd` | normal | Go to definition |
| `gr` | normal | Show references |
| `K` | normal | Hover documentation |
| `Space rn` | normal | Rename symbol |
| `Space ca` | normal/visual | Code action |
| `Ctrl-o` | normal | Jump back |
| `Ctrl-i` | normal | Jump forward |

## Diagnostics

| Key | Mode | Action |
| --- | --- | --- |
| `Space e` | normal | Show diagnostic under cursor |
| `[d` | normal | Previous diagnostic |
| `]d` | normal | Next diagnostic |

## Completion

| Key | Mode | Action |
| --- | --- | --- |
| `Ctrl-Space` | insert | Open completion menu |
| `Tab` | insert/select | Next completion item or snippet jump |
| `Shift-Tab` | insert/select | Previous completion item or snippet jump back |
| `Enter` | insert | Confirm selected completion item |
| `Ctrl-e` | insert | Abort completion menu |

## Brackets and Quotes

Bracket and quote pairs are inserted automatically in insert mode by `nvim-autopairs`.
