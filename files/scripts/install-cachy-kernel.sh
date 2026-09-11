#!/usr/bin/env bash

set -Eeuo pipefail
set -x

KERNEL_INSTALL_DIR="/usr/lib/kernel/install.d"

echo "============================================================"
echo " ScentiaOS: CachyOS kernel + Bazzite NVIDIA Open"
echo "============================================================"

restore_hooks() {
    for hook in 05-rpmostree.install 50-dracut.install; do
        if [ -e "${KERNEL_INSTALL_DIR}/${hook}.scentia-backup" ]; then
            rm -f "${KERNEL_INSTALL_DIR}/${hook}"
            mv -f \
                "${KERNEL_INSTALL_DIR}/${hook}.scentia-backup" \
                "${KERNEL_INSTALL_DIR}/${hook}"
        fi
    done
}

trap restore_hooks EXIT

trap 'rc=$?; echo; echo "============================================================" >&2; echo "FAILED at line ${LINENO}" >&2; echo "COMMAND: ${BASH_COMMAND}" >&2; echo "EXIT CODE: ${rc}" >&2; echo "============================================================" >&2' ERR


# ============================================================
# Record the NVIDIA userspace version supplied by Bazzite.
#
# The kernel modules MUST match this version exactly.
# ============================================================

NVIDIA_VERSION="$(
    rpm -q nvidia-driver \
        --queryformat '%{VERSION}\n' |
    head -n1
)"

if [ -z "${NVIDIA_VERSION}" ]; then
    echo "ERROR: Could not determine Bazzite NVIDIA driver version"
    exit 1
fi

echo "Bazzite NVIDIA userspace version: ${NVIDIA_VERSION}"


# ============================================================
# Build requirements
# ============================================================

dnf5 -y install \
    kmod \
    gcc \
    gcc-c++ \
    make \
    elfutils-libelf-devel \
    curl \
    tar

command -v depmod
command -v gcc
command -v g++
command -v make


# ============================================================
# Temporarily disable kernel-install hooks.
#
# This mirrors the workaround Bazzite itself uses while
# replacing its kernel inside an image build.
# ============================================================

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


# ============================================================
# CachyOS repository
# ============================================================

dnf5 -y copr enable bieszczaders/kernel-cachyos


# ============================================================
# Remove kernel-specific kmod packages from the old OGC kernel.
#
# IMPORTANT:
# Only remove packages which both:
#   1. begin with kmod-
#   2. actually contain files under /usr/lib/modules
#
# This prevents us from accidentally removing kmod-libs.
# ============================================================

mapfile -t OLD_KMODS < <(
    rpm -qa --qf '%{NAME}\n' |
    sort -u |
    grep '^kmod-' |
    while read -r pkg; do
        if rpm -ql "${pkg}" 2>/dev/null |
            grep -q '^/usr/lib/modules/'
        then
            echo "${pkg}"
        fi
    done
)

if [ "${#OLD_KMODS[@]}" -gt 0 ]; then
    echo "Removing old kernel-specific kmods:"
    printf '  %s\n' "${OLD_KMODS[@]}"

    for pkg in "${OLD_KMODS[@]}"; do
        rpm --erase "${pkg}" --nodeps || true
    done
fi


# ============================================================
# Remove Bazzite OGC kernel
# ============================================================

for pkg in \
    kernel \
    kernel-core \
    kernel-modules \
    kernel-modules-core \
    kernel-modules-extra
do
    if rpm -q "${pkg}" >/dev/null 2>&1; then
        rpm --erase "${pkg}" --nodeps
    fi
done

rm -rf /usr/lib/modules/*


# ============================================================
# Install CachyOS kernel
# ============================================================

dnf5 -y install \
    kernel-cachyos \
    kernel-cachyos-devel-matched


# ============================================================
# Determine exact CachyOS kernel version
# ============================================================

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
    echo "ERROR: CachyOS kernel not found"
    exit 1
fi

echo
echo "============================================================"
echo " CachyOS kernel: ${KERNEL_VERSION}"
echo " NVIDIA version: ${NVIDIA_VERSION}"
echo "============================================================"


# ============================================================
# Make sure the kernel development tree exists
# ============================================================

if [ ! -e "/usr/lib/modules/${KERNEL_VERSION}/build/Makefile" ]; then
    echo "ERROR: CachyOS kernel build tree missing:"
    echo "/usr/lib/modules/${KERNEL_VERSION}/build"
    exit 1
fi


# ============================================================
# Generate initial module dependency database
# ============================================================

/usr/bin/depmod -a "${KERNEL_VERSION}"


# ============================================================
# Download the NVIDIA OPEN kernel module source matching
# Bazzite's existing NVIDIA userspace EXACTLY.
#
# We are NOT replacing:
#   nvidia-driver
#   nvidia-driver-libs
#   CUDA libraries
#   nvidia-settings
#   Vulkan/OpenGL libraries
#
# Only kernel .ko modules are being rebuilt.
# ============================================================

NVIDIA_BUILD="/tmp/nvidia-open-${NVIDIA_VERSION}"

rm -rf "${NVIDIA_BUILD}"
mkdir -p "${NVIDIA_BUILD}"

curl \
    --fail \
    --location \
    --retry 5 \
    "https://github.com/NVIDIA/open-gpu-kernel-modules/archive/${NVIDIA_VERSION}/open-gpu-kernel-modules-${NVIDIA_VERSION}.tar.gz" \
    -o /tmp/nvidia-open.tar.gz

tar \
    -xzf /tmp/nvidia-open.tar.gz \
    -C "${NVIDIA_BUILD}" \
    --strip-components=1


# ============================================================
# Compile NVIDIA Open directly for CachyOS
# ============================================================

echo
echo "============================================================"
echo " Building NVIDIA ${NVIDIA_VERSION}"
echo " for ${KERNEL_VERSION}"
echo "============================================================"

make \
    -C "${NVIDIA_BUILD}" \
    -j"$(nproc)" \
    KERNEL_UNAME="${KERNEL_VERSION}" \
    modules


# ============================================================
# Validate build output BEFORE installing anything
# ============================================================

for module in \
    nvidia \
    nvidia-drm \
    nvidia-modeset \
    nvidia-peermem \
    nvidia-uvm
do
    MODULE_FILE="${NVIDIA_BUILD}/kernel-open/${module}.ko"

    if [ ! -f "${MODULE_FILE}" ]; then
        echo "ERROR: Missing NVIDIA module:"
        echo "${MODULE_FILE}"
        exit 1
    fi

    echo
    echo "${module}:"
    /usr/bin/modinfo "${MODULE_FILE}" |
        grep -E '^(filename|version|license|vermagic):'
done


# ============================================================
# Install the new modules
# ============================================================

NVIDIA_MODULE_DIR="/usr/lib/modules/${KERNEL_VERSION}/extra/nvidia"

mkdir -p "${NVIDIA_MODULE_DIR}"

install -m 0644 \
    "${NVIDIA_BUILD}"/kernel-open/*.ko \
    "${NVIDIA_MODULE_DIR}/"


# ============================================================
# Module database
# ============================================================

/usr/bin/depmod -a "${KERNEL_VERSION}"


# ============================================================
# Final validation against the installed kernel tree
# ============================================================

echo
echo "============================================================"
echo " Validating installed NVIDIA modules"
echo "============================================================"

for module in \
    nvidia \
    nvidia_drm \
    nvidia_modeset \
    nvidia_peermem \
    nvidia_uvm
do
    echo
    echo "${module}:"

    /usr/bin/modinfo \
        -k "${KERNEL_VERSION}" \
        "${module}" |
        grep -E '^(filename|version|license|vermagic):'
done


# ============================================================
# Ensure kernel module version matches NVIDIA userspace
# ============================================================

MODULE_VERSION="$(
    /usr/bin/modinfo \
        -k "${KERNEL_VERSION}" \
        -F version \
        nvidia
)"

if [ "${MODULE_VERSION}" != "${NVIDIA_VERSION}" ]; then
    echo "ERROR: NVIDIA version mismatch"
    echo "Userspace: ${NVIDIA_VERSION}"
    echo "Kernel:    ${MODULE_VERSION}"
    exit 1
fi


# ============================================================
# SELinux requirement from CachyOS Fedora packaging
# ============================================================

if command -v setsebool >/dev/null 2>&1; then
    setsebool -P domain_kernel_load_modules on || true
fi


# ============================================================
# Disable Cachy repo after build
# ============================================================

dnf5 -y copr disable bieszczaders/kernel-cachyos


# ============================================================
# Restore rpm-ostree/dracut hooks
# ============================================================

restore_hooks
trap - EXIT

echo
echo "============================================================"
echo " Scentia Cachy kernel build SUCCESS"
echo
echo " Kernel:"
echo "   ${KERNEL_VERSION}"
echo
echo " NVIDIA userspace:"
echo "   ${NVIDIA_VERSION}"
echo
echo " NVIDIA kernel module:"
echo "   ${MODULE_VERSION}"
echo "============================================================"
