#!/bin/bash

APP_NAME="Pebble"
REPO="Ramad96/Pebble"
INSTALL_DIR="/Applications"
TMP_DIR="$(mktemp -d)"

echo ""
echo "  🪨 Pebble Installer"
echo "  Every pebble, a remembrance."
echo ""

# ── Get the download URL from the latest release ─────────────────────
echo "  → Finding latest release..."
API_RESPONSE="$(curl -sL "https://api.github.com/repos/${REPO}/releases/latest")"

DOWNLOAD_URL="$(echo "$API_RESPONSE" | /usr/bin/python3 -c "
import sys, json
data = json.load(sys.stdin)
assets = data.get('assets', [])
for a in assets:
    url = a.get('browser_download_url', '')
    if url.endswith('.zip'):
        print(url)
        break
" 2>/dev/null)"

if [ -z "$DOWNLOAD_URL" ]; then
    echo "  ✗ No release found. Create one at:"
    echo "    https://github.com/${REPO}/releases/new"
    rm -rf "$TMP_DIR"
    exit 1
fi

# ── Download ──────────────────────────────────────────────────────────
echo "  → Downloading..."
curl -sL "$DOWNLOAD_URL" -o "${TMP_DIR}/Pebble.zip"

if [ ! -s "${TMP_DIR}/Pebble.zip" ]; then
    echo "  ✗ Download failed."
    rm -rf "$TMP_DIR"
    exit 1
fi

# ── Unzip ─────────────────────────────────────────────────────────────
echo "  → Unpacking..."
unzip -qo "${TMP_DIR}/Pebble.zip" -d "${TMP_DIR}"

# ── Find the .app ─────────────────────────────────────────────────────
APP_BUNDLE="$(find "$TMP_DIR" -name "*.app" -type d | head -1)"

if [ -z "$APP_BUNDLE" ]; then
    echo "  ✗ No .app found in the zip. Contents:"
    ls -R "$TMP_DIR"
    rm -rf "$TMP_DIR"
    exit 1
fi

echo "  → Found: $(basename "$APP_BUNDLE")"

# ── Install ───────────────────────────────────────────────────────────
if [ -d "${INSTALL_DIR}/${APP_NAME}.app" ]; then
    echo "  → Replacing previous installation..."
    rm -rf "${INSTALL_DIR}/${APP_NAME}.app"
fi

echo "  → Copying to ${INSTALL_DIR}..."
if ! cp -R "$APP_BUNDLE" "${INSTALL_DIR}/${APP_NAME}.app"; then
    echo "  ✗ Failed to copy. Trying with sudo..."
    sudo cp -R "$APP_BUNDLE" "${INSTALL_DIR}/${APP_NAME}.app"
fi

# Verify it landed
if [ ! -d "${INSTALL_DIR}/${APP_NAME}.app" ]; then
    echo "  ✗ Installation failed — app not found in ${INSTALL_DIR}."
    rm -rf "$TMP_DIR"
    exit 1
fi

xattr -rd com.apple.quarantine "${INSTALL_DIR}/${APP_NAME}.app" 2>/dev/null || true

# Force Spotlight to re-index so the app shows up in search
mdimport "${INSTALL_DIR}/${APP_NAME}.app" 2>/dev/null || true

echo ""
echo "  ✓ Pebble installed to ${INSTALL_DIR}/${APP_NAME}.app"
echo ""

# ── Launch ────────────────────────────────────────────────────────────
open "${INSTALL_DIR}/${APP_NAME}.app"
echo "  🪨 Pebble is running in your menu bar."
echo "     Grant Accessibility access when prompted, then press F13 to count."

# ── Cleanup ───────────────────────────────────────────────────────────
rm -rf "$TMP_DIR"
echo ""
