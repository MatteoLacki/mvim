#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
nvim_version="${NVIM_VERSION:-v0.12.3}"
bin_name="${BIN_NAME:-mvim}"
install_bin="${INSTALL_BIN:-$HOME/.local/bin}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
nvim_url="https://github.com/neovim/neovim/releases/download/${nvim_version}/nvim-linux-x86_64.appimage"

mkdir -p "$install_bin" "$config_home"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -L "$nvim_url" -o "$tmp"
chmod u+x "$tmp"
mv "$tmp" "$install_bin/$bin_name"
trap - EXIT

if [ -e "$config_home/nvim" ] && [ ! -L "$config_home/nvim" ]; then
  backup="$config_home/nvim.backup.$(date +%Y%m%d%H%M%S)"
  mv "$config_home/nvim" "$backup"
  printf 'Backed up existing config to %s\n' "$backup"
fi

ln -sfn "$repo_dir" "$config_home/nvim"

"$install_bin/$bin_name" --headless "+Lazy! sync" "+MasonInstall pyright" +qa
printf 'Neovim %s installed as %s\n' "$nvim_version" "$install_bin/$bin_name"
printf 'Config linked from %s to %s\n' "$repo_dir" "$config_home/nvim"
