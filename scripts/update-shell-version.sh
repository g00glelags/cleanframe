#!/usr/bin/env bash

# Script to help add support for new GNOME Shell versions
# Usage: ./scripts/update-shell-version.sh [MAJOR_VERSION]

set -e

REPO_DIR="$(dirname "$(dirname "$(readlink -m "${BASH_SOURCE[0]}")")")"
source "$REPO_DIR/scripts/lib/metadata.sh"

show_usage() {
    cat << EOF
Usage: $0 [MAJOR_VERSION]

Creates basic structure for a new GNOME Shell version in CleanFrame.

Arguments:
  MAJOR_VERSION    GNOME Shell major version (e.g., 50)

If no version is provided, shows current supported versions.

Examples:
  $0 50            # Create structure for GNOME Shell 50
  $0               # Show current supported versions
EOF
}

show_current_versions() {
    echo "Currently supported GNOME Shell versions:"
    echo ""
    
    for major in "${SUPPORTED_GNOME_SHELL_MAJORS[@]}"; do
        local dir="${GNOME_SHELL_DIR_BY_MAJOR[$major]}"
        local label="${GNOME_SHELL_INSTALL_LABEL_BY_MAJOR[$major]}"
        echo "  ${major} -> shell-${dir}/ (${label})"
    done
    
    echo ""
    echo "Latest supported: $(latest_supported_gnome_shell_major)"
}

validate_version() {
    local version="$1"
    
    # Check if already exists
    for major in "${SUPPORTED_GNOME_SHELL_MAJORS[@]}"; do
        if [[ "$major" == "$version" ]]; then
            echo "❌ Version $version is already supported"
            return 1
        fi
    done
    
    # Basic validation - should be a number
    if ! [[ "$version" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid version format: $version"
        return 1
    fi
    
    # Check if version is reasonable (not too old or future)
    if [[ "$version" -lt 30 ]]; then
        echo "⚠️  Warning: Version $version seems very old"
    fi
    
    if [[ "$version" -gt 60 ]]; then
        echo "⚠️  Warning: Version $version seems far in the future"
    fi
    
    return 0
}

create_shell_directory() {
    local major="$1"
    local dir_name="shell-${major}-0"
    local target_dir="$REPO_DIR/src/gnome-shell/$dir_name"
    
    echo "Creating GNOME Shell directory for version $major..."
    
    if [[ -d "$target_dir" ]]; then
        echo "❌ Directory already exists: $target_dir"
        return 1
    fi
    
    # Find the most recent version to use as template
    local latest_major="$(latest_supported_gnome_shell_major)"
    local latest_dir="${GNOME_SHELL_DIR_BY_MAJOR[$latest_major]}"
    local template_dir="$REPO_DIR/src/gnome-shell/shell-$latest_dir"
    
    if [[ ! -d "$template_dir" ]]; then
        echo "❌ Cannot find template directory: $template_dir"
        return 1
    fi
    
    # Create directory structure
    mkdir -p "$target_dir"
    
    # Copy template files
    echo "Copying template from shell-$latest_dir..."
    cp -r "$template_dir/." "$target_dir/"
    
    # Update gnome-shell.scss to use correct bundle
    local bundle_name="_bundle-${major}-0"
    sed -i "s/_bundle-${latest_dir}/$bundle_name/g" "$target_dir/gnome-shell.scss"
    
    echo "✅ Created directory: $target_dir"
}

create_scss_bundle() {
    local major="$1"
    local bundle_name="_bundle-${major}-0.scss"
    local bundle_path="$REPO_DIR/src/_sass/gnome-shell/$bundle_name"
    
    echo "Creating SCSS bundle for version $major..."
    
    if [[ -f "$bundle_path" ]]; then
        echo "❌ Bundle already exists: $bundle_path"
        return 1
    fi
    
    # Find latest bundle as template
    local latest_major="$(latest_supported_gnome_shell_major)"
    local latest_dir="${GNOME_SHELL_DIR_BY_MAJOR[$latest_major]}"
    local template_bundle="$REPO_DIR/src/_sass/gnome-shell/_bundle-${latest_dir}.scss"
    
    if [[ ! -f "$template_bundle" ]]; then
        echo "❌ Cannot find template bundle: $template_bundle"
        return 1
    fi
    
    # Copy and update bundle
    cp "$template_bundle" "$bundle_path"
    
    # Update any version-specific references in the bundle
    sed -i "s/${latest_dir}/${major}-0/g" "$bundle_path"
    
    echo "✅ Created bundle: $bundle_path"
}

update_metadata() {
    local major="$1"
    
    echo "Updating metadata for version $major..."
    
    local metadata_file="$REPO_DIR/scripts/lib/metadata.sh"
    local dir_name="${major}-0"
    local install_label="= ${major}.0"
    
    # Backup original
    cp "$metadata_file" "${metadata_file}.bak"
    
    # Update SUPPORTED_GNOME_SHELL_MAJORS array (add to beginning)
    sed -i "s/SUPPORTED_GNOME_SHELL_MAJORS=(${SUPPORTED_GNOME_SHELL_MAJORS[*]})/SUPPORTED_GNOME_SHELL_MAJORS=($major ${SUPPORTED_GNOME_SHELL_MAJORS[*]})/" "$metadata_file"
    
    # Add to GNOME_SHELL_DIR_BY_MAJOR
    local dir_line="  [$major]=\"$dir_name\""
    sed -i "/declare -Ag GNOME_SHELL_DIR_BY_MAJOR=\(/,/^)/ {
        /^)/i $dir_line
    }" "$metadata_file"
    
    # Add to GNOME_SHELL_INSTALL_LABEL_BY_MAJOR
    local label_line="  [$major]=\"$install_label\""
    sed -i "/declare -Ag GNOME_SHELL_INSTALL_LABEL_BY_MAJOR=\(/,/^)/ {
        /^)/i $label_line
    }" "$metadata_file"
    
    echo "✅ Updated metadata in $metadata_file"
    echo "   Backup created at ${metadata_file}.bak"
}

main() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        show_current_versions
        exit 0
    fi
    
    echo "=== Adding support for GNOME Shell $version ==="
    echo ""
    
    # Validate
    if ! validate_version "$version"; then
        exit 1
    fi
    
    # Check prerequisites
    if [[ ! -d "$REPO_DIR/src/gnome-shell" ]]; then
        echo "❌ Cannot find src/gnome-shell directory"
        exit 1
    fi
    
    # Create structure
    create_shell_directory "$version" || exit 1
    echo ""
    
    create_scss_bundle "$version" || exit 1
    echo ""
    
    update_metadata "$version" || exit 1
    echo ""
    
    echo "=== Summary ==="
    echo ""
    echo "✅ Successfully added basic structure for GNOME Shell $version"
    echo ""
    echo "Next steps:"
    echo "1. Review generated files in:"
    echo "   - src/gnome-shell/shell-${version}-0/"
    echo "   - src/_sass/gnome-shell/_bundle-${version}-0.scss"
    echo "2. Update any version-specific styling differences"
    echo "3. Test with: make check"
    echo "4. Commit changes"
    echo ""
    echo "Note: This script only creates basic structure."
    echo "      You may need to adjust CSS for actual version differences."
}

# Run main function
main "$@"