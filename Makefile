.PHONY: help validate build build-optimized check check-strict lint scss-smoke audit-colors audit-colors-strict install uninstall css-audit

NPM ?= npm
INSTALL_ARGS ?=

help:
	@echo "Targets:"
	@echo "  make validate      - Check system prerequisites and dependencies"
	@echo "  make check         - lint + color audit (default) + SCSS smoke compile"
	@echo "  make check-strict  - lint + color audit (strict) + SCSS smoke compile"
	@echo "  make build         - assemble staged theme artifacts under build/"
	@echo "  make build-optimized - build with CSS optimization (smaller files)"
	@echo "  make lint          - SCSS lint"
	@echo "  make scss-smoke    - SCSS smoke compilation"
	@echo "  make audit-colors  - Color leak audit (default)"
	@echo "  make audit-colors-strict - Color leak audit (strict)"
	@echo "  make css-audit     - CSS performance audit"
	@echo "  make install [INSTALL_ARGS='--shell 49 --sandbox']"
	@echo "  make uninstall [INSTALL_ARGS='-d ~/.local/share/themes']"

validate:
	@echo "Validating system prerequisites..."
	@if [ -f ./scripts/lib/common.sh ]; then \
		. ./scripts/lib/common.sh; \
		if validate_prerequisites; then \
			show_system_info; \
			echo "✅ Prerequisites validation passed"; \
		else \
			echo "❌ Prerequisites validation failed"; \
			exit 1; \
		fi; \
	else \
		echo "❌ Cannot find common.sh"; \
		exit 1; \
	fi

build:
	$(NPM) run build

build-optimized:
	ENABLE_CSS_OPTIMIZATION=true $(NPM) run build

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

css-audit:
	bash scripts/audit-css-performance.sh
