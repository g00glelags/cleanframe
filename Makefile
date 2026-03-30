.PHONY: help build check check-strict lint scss-smoke audit-colors audit-colors-strict install uninstall

NPM ?= npm
INSTALL_ARGS ?=

help:
	@echo "Targets:"
	@echo "  make check         - lint + color audit (default) + SCSS smoke compile"
	@echo "  make check-strict  - lint + color audit (strict) + SCSS smoke compile"
	@echo "  make build         - assemble staged theme artifacts under build/"
	@echo "  make lint          - SCSS lint"
	@echo "  make scss-smoke    - SCSS smoke compilation"
	@echo "  make audit-colors  - Color leak audit (default)"
	@echo "  make audit-colors-strict - Color leak audit (strict)"
	@echo "  make install [INSTALL_ARGS='--shell 49 --sandbox']"
	@echo "  make uninstall [INSTALL_ARGS='-d ~/.local/share/themes']"

build:
	$(NPM) run build

check:
	$(NPM) run test

check-strict:
	$(NPM) run test:ci

lint:
	$(NPM) run lint:scss

scss-smoke:
	$(NPM) run build:scss:smoke

audit-colors:
	$(NPM) run audit:colors

audit-colors-strict:
	$(NPM) run audit:colors:strict

install:
	bash ./install.sh $(INSTALL_ARGS)

uninstall:
	bash ./install.sh --uninstall $(INSTALL_ARGS)
