#!/usr/bin/env bash

# CSS Performance Auditor for CleanFrame
# Usage: ./scripts/audit-css-performance.sh [OPTIONS]

set -e

REPO_DIR="$(dirname "$(dirname "$(readlink -m "${BASH_SOURCE[0]}")")")"
BUILD_DIR="${REPO_DIR}/build"

show_usage() {
    cat << EOF
CSS Performance Auditor for CleanFrame

Usage: $0 [OPTIONS]

Options:
  --max-size=SIZE       Maximum CSS file size (e.g., 3MB, 500KB)
  --max-duplicates=N    Maximum duplicate rules allowed
  --max-colors=N        Maximum unique hex colors allowed
  --output=FORMAT       Output format: text (default), json, markdown
  --file=FILE           Specific CSS file to audit
  --help                Show this help

Examples:
  $0 --max-size=3MB
  $0 --max-duplicates=100 --max-colors=50
  $0 --output=json
EOF
}

parse_size() {
    local size="$1"
    if [[ "$size" =~ ^([0-9]+)([KM]?B)$ ]]; then
        local num="${BASH_REMATCH[1]}"
        local unit="${BASH_REMATCH[2]}"
        case "$unit" in
            MB) echo $((num * 1024 * 1024)) ;;
            KB) echo $((num * 1024)) ;;
            B)  echo "$num" ;;
            *)  echo "$num" ;;
        esac
    else
        echo "$size"
    fi
}

audit_css_file() {
    local css_file="$1"
    local output_format="${2:-text}"
    
    [ -f "$css_file" ] || {
        echo "❌ File not found: $css_file"
        return 1
    }
    
    local filename="$(basename "$css_file")"
    local dirname="$(basename "$(dirname "$css_file")")"
    local full_path="${dirname}/${filename}"
    
    # Collect metrics
    local file_size=$(stat -c%s "$css_file")
    local line_count=$(wc -l < "$css_file")
    local unique_selectors=$(grep -o "[^{]*{" "$css_file" | sed 's/{$//' | sort -u | wc -l)
    local duplicate_rules=$(awk '/\{/,/\}/' "$css_file" | sort | uniq -d | wc -l)
    local unique_colors=$(grep -o "#[0-9a-fA-F]\{6\}\b" "$css_file" | sort -u | wc -l)
    
    # Check for unused Material colors (if gtk.css)
    local unused_material_colors=0
    if [[ "$filename" == "gtk.css" ]] && grep -q "@define-color" "$css_file" 2>/dev/null; then
        unused_material_colors=$(grep -c "@define-color.*_\([0-9]\{3\}\)" "$css_file" 2>/dev/null || echo 0)
    fi
    
    # Common property counts
    local bg_color_count=$(grep -c "background-color:" "$css_file")
    local color_count=$(grep -c "color:" "$css_file")
    local border_radius_count=$(grep -c "border-radius:" "$css_file")
    
    # Output based on format
    case "$output_format" in
        json)
            cat << EOF
{
  "file": "$full_path",
  "size_bytes": $file_size,
  "size_human": "$(numfmt --to=si --suffix=B "$file_size")",
  "lines": $line_count,
  "unique_selectors": $unique_selectors,
  "duplicate_rules": $duplicate_rules,
  "unique_colors": $unique_colors,
  "unused_material_colors": $unused_material_colors,
  "property_counts": {
    "background-color": $bg_color_count,
    "color": $color_count,
    "border-radius": $border_radius_count
  }
}
EOF
            ;;
        markdown)
            cat << EOF
### ${full_path}
| Metric | Value |
|--------|-------|
| Size | $(numfmt --to=si --suffix=B "$file_size") |
| Lines | $line_count |
| Unique Selectors | $unique_selectors |
| Duplicate Rules | $duplicate_rules |
| Unique Colors | $unique_colors |
| Unused Material Colors | $unused_material_colors |
| background-color occurrences | $bg_color_count |
| color occurrences | $color_count |
| border-radius occurrences | $border_radius_count |
EOF
            ;;
        *)
            # Default text output
            echo "[PERF] ${full_path}:"
            printf "  Size:           %s\n" "$(numfmt --to=si --suffix=B "$file_size")"
            printf "  Lines:          %d\n" "$line_count"
            printf "  Unique Selectors: %d\n" "$unique_selectors"
            printf "  Duplicate Rules:  %d\n" "$duplicate_rules"
            printf "  Unique Colors:    %d\n" "$unique_colors"
            if [ "$unused_material_colors" -gt 0 ]; then
                printf "  Unused Material Colors: %d ⚠️\n" "$unused_material_colors"
            fi
            printf "  Common Properties:\n"
            printf "    background-color: %d\n" "$bg_color_count"
            printf "    color:            %d\n" "$color_count"
            printf "    border-radius:    %d\n" "$border_radius_count"
            echo ""
            ;;
    esac
    
    return 0
}

check_thresholds() {
    local css_file="$1"
    local max_size="$2"
    local max_duplicates="$3"
    local max_colors="$4"
    
    [ -f "$css_file" ] || return 0
    
    local filename="$(basename "$css_file")"
    local issues=0
    
    # Check file size
    if [ -n "$max_size" ]; then
        local max_size_bytes=$(parse_size "$max_size")
        local file_size=$(stat -c%s "$css_file")
        
        if [ "$file_size" -gt "$max_size_bytes" ]; then
            echo "❌ ${filename}: Size $(numfmt --to=si --suffix=B "$file_size") exceeds limit $(numfmt --to=si --suffix=B "$max_size_bytes")"
            issues=$((issues + 1))
        fi
    fi
    
    # Check duplicate rules
    if [ -n "$max_duplicates" ]; then
        local duplicate_rules=$(awk '/\{/,/\}/' "$css_file" | sort | uniq -d | wc -l)
        
        if [ "$duplicate_rules" -gt "$max_duplicates" ]; then
            echo "❌ ${filename}: $duplicate_rules duplicate rules exceed limit $max_duplicates"
            issues=$((issues + 1))
        fi
    fi
    
    # Check unique colors
    if [ -n "$max_colors" ]; then
        local unique_colors=$(grep -o "#[0-9a-fA-F]\{6\}\b" "$css_file" | sort -u | wc -l)
        
        if [ "$unique_colors" -gt "$max_colors" ]; then
            echo "❌ ${filename}: $unique_colors unique colors exceed limit $max_colors"
            issues=$((issues + 1))
        fi
    fi
    
    return $issues
}

main() {
    local max_size=""
    local max_duplicates=""
    local max_colors=""
    local output_format="text"
    local specific_file=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --max-size=*)
                max_size="${1#*=}"
                shift
                ;;
            --max-duplicates=*)
                max_duplicates="${1#*=}"
                shift
                ;;
            --max-colors=*)
                max_colors="${1#*=}"
                shift
                ;;
            --output=*)
                output_format="${1#*=}"
                shift
                ;;
            --file=*)
                specific_file="${1#*=}"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check if build directory exists
    if [ ! -d "$BUILD_DIR" ]; then
        echo "⚠️  Build directory not found. Running 'make build' first..."
        make build > /dev/null 2>&1 || {
            echo "❌ Failed to build theme"
            exit 1
        }
    fi
    
    echo "=== CSS Performance Audit ==="
    echo ""
    
    local css_files=()
    
    # Find CSS files to audit
    if [ -n "$specific_file" ]; then
        if [ -f "$specific_file" ]; then
            css_files=("$specific_file")
        elif [ -f "$BUILD_DIR/$specific_file" ]; then
            css_files=("$BUILD_DIR/$specific_file")
        else
            echo "❌ CSS file not found: $specific_file"
            exit 1
        fi
    else
        # Find all CSS files in build directory
        while IFS= read -r -d '' file; do
            css_files+=("$file")
        done < <(find "$BUILD_DIR" -name "*.css" -type f -print0)
    fi
    
    if [ ${#css_files[@]} -eq 0 ]; then
        echo "❌ No CSS files found to audit"
        exit 1
    fi
    
    local total_issues=0
    
    # Audit each file
    for css_file in "${css_files[@]}"; do
        relative_path="${css_file#$BUILD_DIR/}"
        
        if [ "$output_format" = "json" ] && [ ${#css_files[@]} -gt 1 ]; then
            if [ "$css_file" = "${css_files[0]}" ]; then
                echo "["
            else
                echo ","
            fi
            audit_css_file "$css_file" "json"
        else
            audit_css_file "$css_file" "$output_format"
        fi
        
        # Check thresholds
        if [ -n "$max_size" ] || [ -n "$max_duplicates" ] || [ -n "$max_colors" ]; then
            check_thresholds "$css_file" "$max_size" "$max_duplicates" "$max_colors"
            total_issues=$((total_issues + $?))
        fi
    done
    
    if [ "$output_format" = "json" ] && [ ${#css_files[@]} -gt 1 ]; then
        echo "]"
    fi
    
    # Summary
    if [ "$output_format" = "text" ]; then
        echo "=== Summary ==="
        printf "Files audited: %d\n" "${#css_files[@]}"
        
        if [ $total_issues -gt 0 ]; then
            printf "Issues found: %d ❌\n" "$total_issues"
            echo ""
            echo "Recommendations:"
            echo "1. Run 'scripts/audit-color-leaks.sh --strict'"
            echo "2. Review unused Material colors in _colors-public.scss"
            echo "3. Consider CSS minification in build pipeline"
            exit 1
        else
            echo "All checks passed ✅"
        fi
    fi
}

main "$@"