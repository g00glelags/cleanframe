#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${REPO_DIR}/dist"
BUILD_DIR="${REPO_DIR}/build"
VERSION="${1:-$(sed -n 's/.*"version": *"\(.*\)".*/\1/p' "${REPO_DIR}/package.json" | head -n1)}"
ARCHIVE_BASE="CleanFrame-Light"

if [[ -n "${VERSION}" ]]; then
  ARCHIVE_NAME="${ARCHIVE_BASE}-v${VERSION}"
else
  ARCHIVE_NAME="${ARCHIVE_BASE}"
fi

echo "=== CleanFrame Release Packager (${ARCHIVE_NAME}) ==="
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
  tar -cJf "${DIST_DIR}/${ARCHIVE_NAME}.tar.xz" CleanFrame-Light CleanFrame-Light-hdpi CleanFrame-Light-xhdpi
)

# Create zip archive as well
(
  cd "${BUILD_DIR}"
  if command -v zip >/dev/null 2>&1; then
    zip -rq9 "${DIST_DIR}/${ARCHIVE_NAME}.zip" CleanFrame-Light CleanFrame-Light-hdpi CleanFrame-Light-xhdpi
  fi
)

# Generate checksums
(
  cd "${DIST_DIR}"
  sha256sum ${ARCHIVE_BASE}* > SHA256SUMS.txt
)

echo "=== Release packages generated successfully ==="
ls -lh "${DIST_DIR}"
echo
echo "Checksums:"
cat "${DIST_DIR}/SHA256SUMS.txt"
