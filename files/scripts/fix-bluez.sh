#!/usr/bin/env bash
set -euo pipefail

echo "=== ScentiaOS: replacing Bazzite BlueZ with Fedora BlueZ ==="

echo "Before:"
rpm -q bluez bluez-libs bluez-cups bluez-obexd || true

# Bazzite version-locks its patched BlueZ packages.
# Remove those locks so Fedora Updates can supply the newer snapshot.
dnf5 versionlock delete \
    bluez \
    bluez-libs \
    bluez-cups \
    bluez-obexd || true

# Only operate on BlueZ packages that are already installed.
pkgs=()

for pkg in bluez bluez-libs bluez-cups bluez-obexd; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
        pkgs+=("$pkg")
    fi
done

dnf5 -y distro-sync \
    --allowerasing \
    --from-repo=fedora,updates \
    "${pkgs[@]}"

echo
echo "After:"
rpm -q "${pkgs[@]}"

echo
rpm -q --qf '%{NAME}: %{VERSION}-%{RELEASE} [%{VENDOR}]\n' "${pkgs[@]}"

# Refuse to build an image that still contains the Bazzite BlueZ release.
if rpm -q bluez | grep -qi bazzite; then
    echo "ERROR: Bazzite BlueZ is still installed"
    exit 1
fi

echo "Fedora BlueZ replacement successful."
