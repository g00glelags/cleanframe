# CSS Normalization in CleanFrame

## Overview

CleanFrame performs post-processing CSS normalization to ensure compatibility with various GTK parsers and runtime environments. This document explains what problems each normalization step solves and why they are necessary.

## Why Normalization is Needed

GTK CSS parsers (especially older versions and libadwaita) have limitations and quirks that can cause:
- Parse errors with modern CSS syntax
- Visual regressions or missing styling
- Warning messages in app logs
- Incompatibility with Electron/Chromium-based apps

## GTK3 Normalization (`normalize_gtk3_css()`)

### Problem 1: Multiple Selectors in `:not()`
**Code:** `:not(.class1, .class2)`
**Issue:** GTK3 parser doesn't support comma-separated selectors inside `:not()`
**Fix:** Split into `:not(.class1):not(.class2)`
**Location:** `scripts/lib/build.sh:37`

### Problem 2: `!important` Declarations
**Code:** `color: red !important;`
**Issue:** Causes warnings in Electron/Chromium apps and some GTK3 parsers
**Fix:** Remove `!important` keyword
**Location:** `scripts/lib/build.sh:38`

### Problem 3: Infinity Calc Artifacts
**Code:** `calc(infinity * 1px)` or `calc(-infinity * 1px)`
**Issue:** Dart Sass sometimes generates infinity values for border-image calculations
**Fix:** Replace with `9999px` or `-9999px`
**Location:** `scripts/lib/build.sh:39-40`

## GTK4 Normalization (`normalize_gtk4_css()`)

### Problem 1: `:root` Block
**Code:** `:root { --custom-prop: value; }`
**Issue:** Older libadwaita/GTK4 runtimes don't handle `:root` properly
**Fix:** Remove entire `:root` block
**Location:** `scripts/lib/build.sh:53`

### Problem 2: Modern Pseudo-classes
**Code:** `:focus-within`, `:focus-visible`
**Issue:** Not supported in older GTK4/libadwaita versions
**Fix:** Replace with `:focus`
**Location:** `scripts/lib/build.sh:55-56`

### Problem 3: Custom GTK Properties
**Code:** `-gtk-outline-radius: value;`
**Issue:** Proprietary GTK properties not widely supported
**Fix:** Remove the declaration
**Location:** `scripts/lib/build.sh:57`

### Problem 4: CSS Custom Properties (Variables)
**Code:** `--custom-var: value;`
**Issue:** Variable declarations can cause parse errors in some runtimes
**Fix:** Remove custom property declarations
**Location:** `scripts/lib/build.sh:58`

### Problem 5: `var()` Function Usage
**Code:** `property: var(--custom-var);`
**Issue:** Variable usage not supported in target environments
**Fix:** Remove declarations using `var()`
**Location:** `scripts/lib/build.sh:59`

### Problem 6: `color-mix()` Function
**Code:** `color: color-mix(in srgb, red 50%, blue);`
**Issue:** Modern CSS color function not supported
**Fix:** Remove declarations using `color-mix()`
**Location:** `scripts/lib/build.sh:60`

## Fallback Behavior

When Perl is not available, CleanFrame uses a limited fallback implementation (`scripts/lib/perl-fallback.sh`) that provides basic normalization:

### GTK3 Fallback:
- Removes `!important` (simple pattern)
- Replaces infinity calc artifacts

### GTK4 Fallback:
- Removes `:root` blocks (simple implementation)
- Replaces modern pseudo-classes with `:focus`

**Limitation:** The fallback cannot handle complex regex patterns like `:not()` selector splitting.

## When to Update Normalization Rules

Update normalization rules when:

1. **New GTK version releases** with parser changes
2. **Bug reports** about CSS parse errors
3. **Dart Sass updates** that change output format
4. **Adding support** for new runtime environments

## Testing Normalization

To test normalization:

```bash
# Run the SCSS smoke test (includes normalization)
npm run build:scss:smoke

# Check normalization output
grep -n "!important\|:not(.*,.*)\|:root\|:focus-\|var(--" build/gtk-3.0/gtk.css
```

## Adding New Normalization Rules

1. Identify the problematic CSS pattern
2. Test if it causes issues in target environments
3. Add a regex pattern to the appropriate normalization function
4. Document the problem and solution in this file
5. Update the fallback implementation if possible

## References

- GTK CSS Properties: https://docs.gtk.org/gtk4/css-properties.html
- Dart Sass Output: https://sass-lang.com/documentation/js-api
- libadwaita Compatibility: https://gnome.pages.gitlab.gnome.org/libadwaita/doc/