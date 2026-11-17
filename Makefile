.PHONY: help validate build build-optimized check check-strict lint scss-smoke audit-colors audit-colors-strict install uninstall css-audit package

NPM ?= npm
INSTALL_ARGS ?=

help:
	@echo "Targets:"
	@echo "  make validate      - Check system prerequisites and dependencies"
	@echo "  make check         - lint + color audit (default) + SCSS smoke compile"
	@echo "  make check-strict  - lint + color audit (strict) + SCSS smoke compile"
	@echo "  make build         - assemble staged theme artifacts under build/"
	@echo "  make build-optimized - build with CSS optimization (smaller files)"
	@echo "  make package       - assemble and create distribution archives in dist/"
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
	bash scripts/build-theme.sh

build-optimized:
	ENABLE_CSS_OPTIMIZATION=true bash scripts/build-theme.sh

package:
	bash scripts/package-release.sh

check: audit-colors scss-smoke
	@if command -v $(NPM) >/dev/null 2>&1; then \
		$(NPM) run lint:scss; \
	else \
		echo "ℹ️  npm not found, skipping stylelint check (SCSS & color audits passed)"; \
	fi

check-strict: audit-colors-strict scss-smoke
	@if command -v $(NPM) >/dev/null 2>&1; then \
		$(NPM) run lint:scss; \
	else \
		echo "ℹ️  npm not found, skipping stylelint check (SCSS & strict color audits passed)"; \
	fi

lint:
	$(NPM) run lint:scss

scss-smoke:
	bash scripts/scss-smoke.sh

audit-colors:
	bash scripts/audit-color-leaks.sh

audit-colors-strict:
	bash scripts/audit-color-leaks.sh --strict

install:
	bash ./install.sh $(INSTALL_ARGS)

uninstall:
	bash ./install.sh --uninstall $(INSTALL_ARGS)

css-audit:
	bash scripts/audit-css-performance.sh
