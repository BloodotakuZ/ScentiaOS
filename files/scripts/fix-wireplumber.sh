#!/usr/bin/env bash
set -euo pipefail

echo "=== ScentiaOS: replacing Terra WirePlumber with Fedora WirePlumber ==="

echo "Before:"
rpm -q terra-wireplumber terra-wireplumber-libs wireplumber wireplumber-libs || true

# Bazzite testing currently replaces Fedora WirePlumber with Terra's build.
# Disable Terra as a package source for this transaction and swap back.
dnf5 -y swap --allowerasing \
    --disable-repo='*terra*' \
    terra-wireplumber \
    wireplumber

echo
echo "After:"
rpm -q wireplumber wireplumber-libs
wireplumber --version

# Do not allow the image to build successfully if Terra's WirePlumber remains.
if rpm -q terra-wireplumber >/dev/null 2>&1; then
    echo "ERROR: terra-wireplumber is still installed"
    exit 1
fi

echo "Fedora WirePlumber replacement successful."
