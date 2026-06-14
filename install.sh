#!/bin/bash
set -euo pipefail

APP_NAME="Pebble"
REPO="Ramad96/Pebble"
INSTALL_DIR="/Applications"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo ""
echo "  🪨 Pebble Installer"
echo "  Every pebble, a remembrance."
echo ""

# ── Detect architecture ──────────────────────────────────────────────
ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ]; then
    ASSET_PATTERN="arm64"
elif [ "$ARCH" = "x86_64" ]; then
    ASSET_PATTERN="x86_64"
else
    echo "  ✗ Unsupported architecture: $ARCH"
    exit 1
fi

# ── Fetch latest release URL ─────────────────────────────────────────
echo "  → Finding latest release..."

DOWNLOAD_URL="$(curl -sL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep -o "\"browser_download_url\": *\"[^\"]*\"" \
    | grep -i "${ASSET_PATTERN}" \
    | head -1 \
    | sed 's/"browser_download_url": *"//;s/"//')"

# Fallback: if no arch-specific asset, grab the first .zip
if [ -z "$DOWNLOAD_URL" ]; then
    DOWNLOAD_URL="$(curl -sL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep -o "\"browser_download_url\": *\"[^\"]*\.zip\"" \
        | head -1 \
        | sed 's/"browser_download_url": *"//;s/"//')"
fi

if [ -z "$DOWNLOAD_URL" ]; then
    echo "  ✗ Could not find a release to download."
    echo "    Check https://github.com/Ramad96/Pebble/releases"
    exit 1
fi

FILENAME="$(basename "$DOWNLOAD_URL")"
echo "  → Downloading ${FILENAME}..."
curl -sL "$DOWNLOAD_URL" -o "${TMP_DIR}/${FILENAME}"

# ── Unpack ────────────────────────────────────────────────────────────
echo "  → Unpacking..."
if [[ "$FILENAME" == *.zip ]]; then
    unzip -qo "${TMP_DIR}/${FILENAME}" -d "${TMP_DIR}"
elif [[ "$FILENAME" == *.tar.gz || "$FILENAME" == *.tgz ]]; then
    tar -xzf "${TMP_DIR}/${FILENAME}" -C "${TMP_DIR}"
elif [[ "$FILENAME" == *.dmg ]]; then
    MOUNT_POINT="${TMP_DIR}/dmg_mount"
    mkdir -p "$MOUNT_POINT"
    hdiutil attach -quiet -nobrowse -mountpoint "$MOUNT_POINT" "${TMP_DIR}/${FILENAME}"
    cp -R "${MOUNT_POINT}/${APP_NAME}.app" "${TMP_DIR}/"
    hdiutil detach -quiet "$MOUNT_POINT"
else
    echo "  ✗ Unknown archive format: ${FILENAME}"
    exit 1
fi

# ── Locate the .app bundle ───────────────────────────────────────────
APP_BUNDLE="$(find "$TMP_DIR" -maxdepth 3 -name "${APP_NAME}.app" -type d | head -1)"

if [ -z "$APP_BUNDLE" ]; then
    echo "  ✗ Could not find ${APP_NAME}.app in the download."
    exit 1
fi

# ── Install ───────────────────────────────────────────────────────────
if [ -d "${INSTALL_DIR}/${APP_NAME}.app" ]; then
    echo "  → Removing previous installation..."
    rm -rf "${INSTALL_DIR}/${APP_NAME}.app"
fi

echo "  → Installing to ${INSTALL_DIR}..."
cp -R "$APP_BUNDLE" "${INSTALL_DIR}/"

# ── Clear quarantine so it opens without Gatekeeper warnings ──────────
xattr -rd com.apple.quarantine "${INSTALL_DIR}/${APP_NAME}.app" 2>/dev/null || true

echo ""
echo "  ✓ ${APP_NAME} installed to ${INSTALL_DIR}/${APP_NAME}.app"
echo ""

# ── Launch ────────────────────────────────────────────────────────────
read -rp "  Launch Pebble now? [Y/n] " LAUNCH
LAUNCH="${LAUNCH:-Y}"
if [[ "$LAUNCH" =~ ^[Yy]$ ]]; then
    open "${INSTALL_DIR}/${APP_NAME}.app"
    echo ""
    echo "  🪨 Pebble is running in your menu bar."
    echo "     Grant Accessibility access when prompted, then press F13 to count."
else
    echo ""
    echo "  Open Pebble anytime from your Applications folder or Spotlight."
fi

echo ""
