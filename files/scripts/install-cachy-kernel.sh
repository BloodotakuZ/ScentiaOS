#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " ScentiaOS: Installing CachyOS kernel"
echo "============================================================"

KERNEL_INSTALL_DIR="/usr/lib/kernel/install.d"

# ------------------------------------------------------------
# Temporarily suppress kernel-install/dracut hooks.
#
# CachyOS kernels currently hit rpm-ostree/dracut too early
# inside bootc/Podman builds. Bazzite itself uses this same
# basic technique when replacing its kernel.
# ------------------------------------------------------------

restore_hooks() {
    for hook in 05-rpmostree.install 50-dracut.install; do
        if [ -e "${KERNEL_INSTALL_DIR}/${hook}.scentia-backup" ]; then
            mv -f \
                "${KERNEL_INSTALL_DIR}/${hook}.scentia-backup" \
                "${KERNEL_INSTALL_DIR}/${hook}"
        fi
    done
}

trap restore_hooks EXIT

for hook in 05-rpmostree.install 50-dracut.install; do
    if [ -e "${KERNEL_INSTALL_DIR}/${hook}" ]; then
        mv \
            "${KERNEL_INSTALL_DIR}/${hook}" \
            "${KERNEL_INSTALL_DIR}/${hook}.scentia-backup"
    fi

    printf '%s\n' '#!/bin/sh' 'exit 0' \
        > "${KERNEL_INSTALL_DIR}/${hook}"

    chmod +x "${KERNEL_INSTALL_DIR}/${hook}"
done


# ------------------------------------------------------------
# CachyOS kernel repository
# ------------------------------------------------------------

dnf5 -y copr enable bieszczaders/kernel-cachyos


# ------------------------------------------------------------
# Make sure the NVIDIA repository used by Bazzite is available.
#
# Bazzite/Universal Blue already uses Negativo17 for its
# NVIDIA-open builds, so this keeps us in the same packaging
# family instead of replacing the whole NVIDIA userspace.
# ------------------------------------------------------------

if ! dnf5 repolist --all | grep -q 'fedora-nvidia'; then
    dnf5 config-manager addrepo \
        --from-repofile=https://negativo17.org/repos/fedora-nvidia.repo
fi


# ------------------------------------------------------------
# Remove kernel-specific KMODs for the old Bazzite/OGC kernel.
#
# Those binaries cannot be used with the CachyOS kernel.
# ------------------------------------------------------------

mapfile -t OLD_KMODS < <(
    rpm -qa | grep '^kmod-' || true
)

if [ "${#OLD_KMODS[@]}" -gt 0 ]; then
    echo "Removing old prebuilt kernel modules:"
    printf '  %s\n' "${OLD_KMODS[@]}"

    for pkg in "${OLD_KMODS[@]}"; do
        rpm --erase "$pkg" --nodeps || true
    done
fi


# ------------------------------------------------------------
# Remove Bazzite's OGC kernel.
#
# This follows the same broad approach Bazzite itself uses
# when swapping kernels during its image build.
# ------------------------------------------------------------

for pkg in \
    kernel \
    kernel-core \
    kernel-modules \
    kernel-modules-core \
    kernel-modules-extra
do
    if rpm -q "$pkg" >/dev/null 2>&1; then
        rpm --erase "$pkg" --nodeps
    fi
done

rm -rf /usr/lib/modules/*


# ------------------------------------------------------------
# Install latest CachyOS kernel available from the COPR
# ------------------------------------------------------------

dnf5 -y install \
    kernel-cachyos \
    kernel-cachyos-devel-matched


# ------------------------------------------------------------
# NVIDIA Open
#
# Negativo17's akmod package contains both kernel variants.
# Force kernel-open for the RTX 4090.
# ------------------------------------------------------------

dnf5 -y install \
    akmods \
    akmod-nvidia

mkdir -p /etc/nvidia
printf '%s\n' 'kernel-open' > /etc/nvidia/kernel.conf


# ------------------------------------------------------------
# Locate CachyOS kernel
# ------------------------------------------------------------

KERNEL_VERSION="$(
    find /usr/lib/modules \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -printf '%f\n' |
    grep 'cachy' |
    sort -V |
    tail -n1
)"

if [ -z "${KERNEL_VERSION}" ]; then
    echo "ERROR: No CachyOS kernel found in /usr/lib/modules"
    exit 1
fi

echo
echo "CachyOS kernel:"
echo "  ${KERNEL_VERSION}"
echo


# ------------------------------------------------------------
# Generate module dependency database before akmods
# ------------------------------------------------------------

depmod -a "${KERNEL_VERSION}"


# ------------------------------------------------------------
# Build NVIDIA specifically for the CachyOS kernel
# ------------------------------------------------------------

echo "Building NVIDIA Open module for ${KERNEL_VERSION}..."

akmods \
    --force \
    --rebuild \
    --kernels "${KERNEL_VERSION}" \
    --akmod nvidia

depmod -a "${KERNEL_VERSION}"


# ------------------------------------------------------------
# HARD validation.
#
# If NVIDIA did not build for this exact kernel, fail the whole
# Scentia image rather than producing something unsafe to boot.
# ------------------------------------------------------------

echo
echo "Validating NVIDIA modules..."

modinfo -k "${KERNEL_VERSION}" nvidia >/dev/null
modinfo -k "${KERNEL_VERSION}" nvidia_drm >/dev/null
modinfo -k "${KERNEL_VERSION}" nvidia_modeset >/dev/null
modinfo -k "${KERNEL_VERSION}" nvidia_uvm >/dev/null

echo
echo "NVIDIA module:"
modinfo -k "${KERNEL_VERSION}" nvidia |
    grep -E '^(filename|version|license):' || true

echo
echo "SUCCESS:"
echo "  CachyOS kernel: ${KERNEL_VERSION}"
echo "  NVIDIA module:  PRESENT"
echo


# ------------------------------------------------------------
# Required by CachyOS for loading external kernel modules
# under SELinux.
# ------------------------------------------------------------

setsebool -P domain_kernel_load_modules on


# Restore proper boot hooks.
restore_hooks
trap - EXIT

dnf5 -y copr disable bieszczaders/kernel-cachyos

echo "============================================================"
echo " CachyOS kernel + NVIDIA Open validation successful"
echo "============================================================"
