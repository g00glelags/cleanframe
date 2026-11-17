#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${REPO_DIR}/dist"
BUILD_DIR="${REPO_DIR}/build"

echo "=== CleanFrame Release Packager ==="
echo "Building theme artifacts..."

# Ensure a fresh build
rm -rf "${BUILD_DIR}"
bash "${REPO_DIR}/scripts/build-theme.sh" 49 "${BUILD_DIR}"

mkdir -p "${DIST_DIR}"
rm -f "${DIST_DIR}"/*

echo "Creating release archives in ${DIST_DIR}..."

# Create tar.xz archive with all theme variants
(
  cd "${BUILD_DIR}"
  tar -cJf "${DIST_DIR}/CleanFrame-Light.tar.xz" CleanFrame-Light CleanFrame-Light-hdpi CleanFrame-Light-xhdpi
)

# Create zip archive as well
(
  cd "${BUILD_DIR}"
  if command -v zip >/dev/null 2>&1; then
    zip -rq9 "${DIST_DIR}/CleanFrame-Light.zip" CleanFrame-Light CleanFrame-Light-hdpi CleanFrame-Light-xhdpi
  fi
)

# Generate checksums
(
  cd "${DIST_DIR}"
  sha256sum CleanFrame-Light.* > SHA256SUMS.txt
)

echo "=== Release packages generated successfully ==="
ls -lh "${DIST_DIR}"
echo
echo "Checksums:"
cat "${DIST_DIR}/SHA256SUMS.txt"
