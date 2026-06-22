SHELL := /bin/bash

NVIM_VERSION ?= v0.12.3
BIN_NAME ?= mvim
INSTALL_BIN ?= $(HOME)/.local/bin
INSTALL_ROOT ?= $(HOME)/.local/share/mvim
MVIM := $(INSTALL_BIN)/$(BIN_NAME)

.PHONY: install setup sync check doctor uninstall

install setup:
	NVIM_VERSION=$(NVIM_VERSION) BIN_NAME=$(BIN_NAME) INSTALL_BIN=$(INSTALL_BIN) INSTALL_ROOT=$(INSTALL_ROOT) ./install.sh

sync:
	$(MVIM) --headless "+Lazy! sync" "+MasonInstall pyright" +qa

check:
	bash -n install.sh
	$(MVIM) --headless +qa

doctor:
	@printf 'Executable: '; command -v $(BIN_NAME) || true
	@printf 'Version: '; $(MVIM) --version | head -n 1
	@printf 'Config: '; if command -v readlink >/dev/null 2>&1; then readlink "$$HOME/.config/nvim" || true; fi
	@tmux -V || true
	@python3 --version

uninstall:
	rm -f "$(MVIM)"
	rm -rf "$(INSTALL_ROOT)"
	@if [ "$$(readlink "$$HOME/.config/nvim" 2>/dev/null)" = "$$(pwd)" ]; then rm -f "$$HOME/.config/nvim"; fi
