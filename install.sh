#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
nvim_version="${NVIM_VERSION:-v0.12.3}"
bin_name="${BIN_NAME:-mvim}"
install_bin="${INSTALL_BIN:-$HOME/.local/bin}"
install_root="${INSTALL_ROOT:-$HOME/.local/share/mvim}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
base_url="https://github.com/neovim/neovim/releases/download/${nvim_version}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    return 1
  fi
}

need_cmd bash
need_cmd curl
need_cmd git
need_cmd tar
need_cmd python3
need_cmd npm

if ! command -v tmux >/dev/null 2>&1; then
  printf 'Warning: tmux is not installed; Python send-to-REPL mappings need tmux.\n' >&2
fi

if ! python3 -c 'import IPython' >/dev/null 2>&1; then
  printf 'Warning: IPython is not installed for python3; install it for <leader>rp and REPL sending.\n' >&2
fi

os="$(uname -s)"
arch="$(uname -m)"
asset=""
kind="tar"
extracted_dir=""

case "$os:$arch" in
  Linux:x86_64|Linux:amd64)
    asset="nvim-linux-x86_64.appimage"
    kind="appimage"
    ;;
  Linux:aarch64|Linux:arm64)
    asset="nvim-linux-arm64.appimage"
    kind="appimage"
    ;;
  Darwin:x86_64)
    asset="nvim-macos-x86_64.tar.gz"
    extracted_dir="nvim-macos-x86_64"
    ;;
  Darwin:arm64)
    asset="nvim-macos-arm64.tar.gz"
    extracted_dir="nvim-macos-arm64"
    ;;
  *)
    printf 'Unsupported platform: %s %s\n' "$os" "$arch" >&2
    exit 1
    ;;
esac

mkdir -p "$install_bin" "$install_root" "$config_home"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

url="${base_url}/${asset}"
printf 'Downloading %s\n' "$url"
curl -fL "$url" -o "$tmp/$asset"

if [ "$kind" = "appimage" ]; then
  chmod u+x "$tmp/$asset"
  mv "$tmp/$asset" "$install_bin/$bin_name"
else
  if command -v xattr >/dev/null 2>&1; then
    xattr -c "$tmp/$asset" 2>/dev/null || true
  fi
  tar xzf "$tmp/$asset" -C "$tmp"
  rm -rf "$install_root/$extracted_dir"
  mv "$tmp/$extracted_dir" "$install_root/$extracted_dir"
  ln -sfn "$install_root/$extracted_dir/bin/nvim" "$install_bin/$bin_name"
fi

chmod u+x "$install_bin/$bin_name" 2>/dev/null || true

if [ -e "$config_home/nvim" ] && [ ! -L "$config_home/nvim" ]; then
  backup="$config_home/nvim.backup.$(date +%Y%m%d%H%M%S)"
  mv "$config_home/nvim" "$backup"
  printf 'Backed up existing config to %s\n' "$backup"
fi

ln -sfn "$repo_dir" "$config_home/nvim"

"$install_bin/$bin_name" --headless "+Lazy! sync" "+MasonInstall pyright" +qa
printf 'Neovim %s installed as %s\n' "$nvim_version" "$install_bin/$bin_name"
printf 'Config linked from %s to %s\n' "$repo_dir" "$config_home/nvim"
