.PHONY: help format format-check format-lua format-sh format-web install-tools lint

# Default target
help:
	@echo "Dotfiles Formatter and Linter"
	@echo ""
	@echo "Available targets:"
	@echo "  help          - Show this help message"
	@echo "  install-tools - Install required formatting tools"
	@echo "  format        - Format all files (Lua, Shell, JSON, YAML, Markdown)"
	@echo "  format-check  - Check if files are formatted correctly (dry-run)"
	@echo "  format-lua    - Format Lua files with StyLua"
	@echo "  format-sh     - Format shell scripts with shfmt"
	@echo "  format-web    - Format JSON, YAML, Markdown with Prettier"
	@echo "  lint          - Run linters (shellcheck for shell scripts)"
	@echo ""
	@echo "Note: Run 'make install-tools' first to install formatters"

# Install required tools
install-tools:
	@echo "Installing formatting tools..."
	@command -v stylua >/dev/null 2>&1 || (echo "Installing StyLua..." && cargo install stylua)
	@command -v shfmt >/dev/null 2>&1 || (echo "Installing shfmt... (requires Go or download binary)" && echo "Please install shfmt: https://github.com/mvdan/sh")
	@command -v prettier >/dev/null 2>&1 || (echo "Installing Prettier..." && npm install -g prettier)
	@command -v shellcheck >/dev/null 2>&1 || (echo "Installing ShellCheck... (use your package manager)")
	@echo "Done! Verify installations:"
	@command -v stylua >/dev/null 2>&1 && echo "  ✓ StyLua installed" || echo "  ✗ StyLua not found"
	@command -v shfmt >/dev/null 2>&1 && echo "  ✓ shfmt installed" || echo "  ✗ shfmt not found"
	@command -v prettier >/dev/null 2>&1 && echo "  ✓ Prettier installed" || echo "  ✗ Prettier not found"
	@command -v shellcheck >/dev/null 2>&1 && echo "  ✓ ShellCheck installed" || echo "  ✗ ShellCheck not found"

# Format all files
format: format-lua format-sh format-web
	@echo "All files formatted successfully!"

# Check formatting (dry-run)
format-check:
	@echo "Checking Lua formatting..."
	@stylua --check .config/nvim/ .config/yazi/plugins/ || (echo "Lua files need formatting! Run 'make format-lua'" && exit 1)
	@echo "Checking shell script formatting..."
	@shfmt -d .config/aconfmgr/*.sh .config/.zsh/custom/*.sh || (echo "Shell scripts need formatting! Run 'make format-sh'" && exit 1)
	@echo "Checking JSON/YAML/Markdown formatting..."
	@prettier --check "**/*.{json,yaml,yml,md}" || (echo "Web files need formatting! Run 'make format-web'" && exit 1)
	@echo "All files are properly formatted!"

# Format Lua files with StyLua
format-lua:
	@echo "Formatting Lua files with StyLua..."
	@stylua .config/nvim/ .config/yazi/plugins/ 2>/dev/null || echo "Note: Some Lua paths may not exist"
	@echo "Lua formatting complete!"

# Format shell scripts with shfmt
format-sh:
	@echo "Formatting shell scripts with shfmt..."
	@find . -name "*.sh" -type f ! -path "./.git/*" -exec shfmt -w -i 4 -ci {} \; || echo "Note: shfmt may not be installed"
	@echo "Shell script formatting complete!"

# Format JSON, YAML, Markdown with Prettier
format-web:
	@echo "Formatting JSON, YAML, and Markdown files with Prettier..."
	@prettier --write "**/*.{json,yaml,yml,md}" || echo "Note: Prettier may not be installed"
	@echo "Web file formatting complete!"

# Lint shell scripts
lint:
	@echo "Linting shell scripts with ShellCheck..."
	@find . -name "*.sh" -type f ! -path "./.git/*" -exec shellcheck {} \; || echo "ShellCheck found issues or is not installed"
	@echo "Linting complete!"
