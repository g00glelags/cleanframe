# CleanFrame - System Requirements and Dependencies

This document outlines the system requirements, dependencies, and workarounds for building and installing the CleanFrame theme.

## Quick Start

```bash
# Check if your system has the required tools
./install.sh --help  # Will validate prerequisites

# Install missing dependencies (Ubuntu/Debian example)
sudo apt-get install sassc perl
```

## Core Dependencies

### Critical (Required for Build)

| Tool | Minimum Version | Purpose | Installation |
|------|----------------|---------|--------------|
| **SCSS Compiler** | - | Compiles SCSS to CSS | See options below |
| **Bash** | 4.0+ | Script execution | Usually pre-installed |

#### SCSS Compiler Options (choose one):
1. **Dart Sass** (Recommended): `sass` command
   ```bash
   # Install via package manager
   sudo apt-get install sass  # Ubuntu/Debian
   sudo dnf install sass      # Fedora
   sudo pacman -S sass        # Arch
   
   # Or via npm (if Node.js is available)
   npm install -g sass
   ```

2. **libsass** (via sassc): `sassc` command
   ```bash
   # Most Linux distributions
   sudo apt-get install sassc    # Ubuntu/Debian
   sudo dnf install sassc        # Fedora
   sudo pacman -S sassc          # Arch
   sudo zypper in sassc          # openSUSE
   ```

3. **npx sass** (Fallback): Uses npm's npx
   ```bash
   # Requires Node.js/npm
   # Will download Dart Sass on first run
   ```

### Important (Enhanced Features)

| Tool | Purpose | Workaround if Missing |
|------|---------|----------------------|
| **Perl** | CSS normalization (compatibility fixes) | Limited fallback available |
| **Git** | Version control operations | Manual file operations |

## Optional Dependencies

| Tool | Purpose | Notes |
|------|---------|-------|
| **Flatpak** | Sandbox theme integration | Required for `--flatpak` option |
| **Snap** | Snap app theme integration | Required for `--snap` option |
| **GNOME Terminal** | Terminal profile installation | Required for `--gnome-terminal-colors` |

## System Validation

CleanFrame includes built-in validation:

```bash
# The install.sh script validates prerequisites automatically
./install.sh

# You can also run validation separately (if needed)
source scripts/lib/common.sh
validate_prerequisites
show_system_info
```

## Common Issues and Workarounds

### 1. No SCSS Compiler Found

**Symptoms:** `"No SCSS compiler available"` error

**Solutions:**
```bash
# Option A: Install sassc (simplest)
sudo apt-get install sassc    # Ubuntu/Debian
sudo dnf install sassc        # Fedora

# Option B: Install Dart Sass via npm
npm install -g sass

# Option C: Use npx (temporary)
# The script will try npx sass automatically
```

### 2. Perl Not Available

**Symptoms:** Limited CSS normalization, but theme will still work

**What you lose:**
- Complex `:not()` selector splitting
- Advanced CSS property removal
- Some GTK4 compatibility fixes

**Workaround:** Theme still functions, but may have compatibility issues with:
- Older GTK3 parsers
- Electron/Chromium apps
- Specific GTK4 runtimes

**Install Perl:**
```bash
sudo apt-get install perl    # Ubuntu/Debian
sudo dnf install perl        # Fedora
```

### 3. Bash Version Too Old

**Symptoms:** Script errors or unexpected behavior

**Check version:**
```bash
echo $BASH_VERSION
```

**Minimum:** Bash 4.0+

**Upgrade options:**
- Update your distribution
- Install newer bash from source
- Use container/virtual environment

### 4. Flatpak/Snap Not Available

**Symptoms:** Sandbox integration options fail

**Workaround:** Install themes manually for sandboxed apps:
```bash
# For Flatpak apps
export GTK_THEME=CleanFrame-Light
flatpak run --env=GTK_THEME=CleanFrame-Light com.example.App

# For Snap apps
echo 'GTK_THEME=CleanFrame-Light' >> ~/.config/environment.d/90-cleanframe-theme.conf
# Log out and back in
```

## Platform-Specific Notes

### Ubuntu/Debian
```bash
# Full installation
sudo apt-get update
sudo apt-get install sassc perl git flatpak snapd
```

### Fedora/RHEL/CentOS
```bash
sudo dnf install sassc perl git flatpak
```

### Arch Linux
```bash
sudo pacman -Syu
sudo pacman -S sassc perl git flatpak
```

### openSUSE
```bash
sudo zypper refresh
sudo zypper in sassc perl git flatpak
```

### macOS (via Homebrew)
```bash
brew install sass/sass/sass perl
# Note: GTK themes on macOS require X11/Wayland compatibility layer
```

### Windows (WSL/Linux Subsystem)
```bash
# Use Ubuntu/Debian/Fedora package manager
# Follow Linux instructions for your WSL distribution
```

## Development Dependencies

For contributing to CleanFrame development:

```bash
# Stylelint for SCSS linting
npm install

# Optional: bats for testing bash scripts
sudo apt-get install bats    # Ubuntu/Debian
sudo dnf install bats        # Fedora
```

## Testing Your Setup

Run the validation suite:

```bash
# Basic validation
make check

# Full validation (includes strict color audit)
make check-strict

# Test build process
make build
```

## Troubleshooting

### "Command not found" errors
1. Check if the tool is installed: `which sassc`
2. Verify it's in your PATH
3. Try absolute path: `/usr/bin/sassc --version`

### Permission errors
1. Ensure you have write permissions to target directories
2. Use `sudo` for system-wide installation (`/usr/share/themes`)
3. Use regular user for user installation (`~/.themes`)

### Build failures
1. Check error messages for specific issues
2. Verify SCSS syntax: `npm run lint:scss`
3. Check for missing assets: `npm run audit:gaps`

## Support

If you encounter issues not covered here:
1. Check the [GitHub Issues](https://github.com/anomalyco/opencode/issues)
2. Review `docs/CSS_NORMALIZATION.md` for CSS compatibility issues
3. Verify your system meets the minimum requirements

## Version Compatibility

CleanFrame is tested with:
- GTK 3.24+, GTK 4.0+
- GNOME Shell 38-49
- Cinnamon 5.0+
- XFCE 4.16+
- Common Linux distributions (Ubuntu, Fedora, Arch, etc.)