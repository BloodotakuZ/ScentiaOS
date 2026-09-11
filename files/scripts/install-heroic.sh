#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " ScentiaOS: Installing latest official Heroic"
echo "============================================================"

API="https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Get the current official Heroic release metadata
curl \
    --fail \
    --silent \
    --show-error \
    --location \
    "$API" \
    -o "$TMPDIR/release.json"

VERSION="$(
    jq -r '.tag_name' "$TMPDIR/release.json" |
    sed 's/^v//'
)"

RPM_URL="$(
    jq -r '
        .assets[]
        | select(.name | test("^Heroic-.*-linux-x86_64\\.rpm$"))
        | .browser_download_url
    ' "$TMPDIR/release.json" |
    head -n1
)"

RPM_FILENAME="$(
    jq -r '
        .assets[]
        | select(.name | test("^Heroic-.*-linux-x86_64\\.rpm$"))
        | .name
    ' "$TMPDIR/release.json" |
    head -n1
)"

if [ -z "$RPM_URL" ] || [ "$RPM_URL" = "null" ]; then
    echo "ERROR: Could not find official Heroic x86_64 RPM."
    exit 1
fi

echo
echo "Latest Heroic: $VERSION"
echo "Package:       $RPM_FILENAME"
echo

curl \
    --fail \
    --show-error \
    --location \
    --retry 5 \
    "$RPM_URL" \
    -o "$TMPDIR/heroic.rpm"

# Read actual RPM metadata before installing
PACKAGE_NAME="$(
    rpm -qp --queryformat '%{NAME}' "$TMPDIR/heroic.rpm"
)"

PACKAGE_VERSION="$(
    rpm -qp --queryformat '%{VERSION}' "$TMPDIR/heroic.rpm"
)"

echo
echo "RPM package: $PACKAGE_NAME"
echo "RPM version: $PACKAGE_VERSION"
echo

# Install/upgrade the official upstream RPM
dnf5 -y install "$TMPDIR/heroic.rpm"

# Validate
rpm -q "$PACKAGE_NAME"

echo
echo "============================================================"
echo " Heroic $PACKAGE_VERSION installed successfully"
echo "============================================================"
