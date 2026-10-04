#!/usr/bin/env bash

set -Eeuo pipefail
set -x

echo "============================================================"
echo " ScentiaOS: Bazzite DX developer layer"
echo " Base: Bazzite NVIDIA Open testing"
echo "============================================================"

# ============================================================
# Core Bazzite DX developer tooling
# ============================================================

dnf5 install -y \
    android-tools \
    bcc \
    bpftop \
    bpftrace \
    ccache \
    flatpak-builder \
    git-subtree \
    google-noto-sans-fonts \
    nicstat \
    numactl \
    podman-machine \
    podman-tui \
    python3-ramalama \
    restic \
    rclone \
    sysprof \
    tiptop \
    usbmuxd \
    waypipe \
    zsh


# ============================================================
# ROCm developer stack
# Matches what Bazzite DX provides
# ============================================================

if rpm -q mesa-libOpenCL >/dev/null 2>&1; then
    dnf5 remove -y mesa-libOpenCL
fi

dnf5 --setopt=install_weak_deps=False install -y \
    rocm-hip \
    rocm-opencl \
    rocm-clinfo \
    rocm-smi


# ============================================================
# Virtualization stack
#
# Use current testing-repo EDK2 packages instead of DX's
# Fedora-version-pinned RPM URLs.
# ============================================================

dnf5 --setopt=install_weak_deps=False install -y \
    qemu \
    qemu-kvm \
    libvirt \
    virt-manager \
    edk2-tools \
    edk2-ovmf \
    guestfs-tools


# ============================================================
# Universal Blue developer setup services
# ============================================================

dnf5 install \
    --enable-repo="copr:copr.fedorainfracloud.org:ublue-os:packages" \
    -y \
    ublue-setup-services

dnf5 install \
    --enable-repo="copr:copr.fedorainfracloud.org:ublue-os:bazzite" \
    -y \
    ds-inhibit


# ============================================================
# Visual Studio Code
# ============================================================

if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
    dnf5 config-manager addrepo \
        --from-repofile="https://packages.microsoft.com/yumrepos/vscode/config.repo"
fi

dnf5 config-manager setopt vscode-yum.enabled=0

dnf5 install \
    --enable-repo="vscode-yum" \
    -y \
    code


# ============================================================
# Docker CE
# ============================================================

if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
    dnf5 config-manager addrepo \
        --from-repofile="https://download.docker.com/linux/fedora/docker-ce.repo"
fi

dnf5 config-manager setopt docker-ce-stable.enabled=0

dnf5 install \
    --enable-repo="docker-ce-stable" \
    -y \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin


# ============================================================
# Docker-in-Docker networking
# ============================================================

mkdir -p /etc/modules-load.d

cat > /etc/modules-load.d/ip_tables.conf <<'MODULES'
iptable_nat
MODULES


# ============================================================
# Restore developer-oriented Bazzite services where available
# ============================================================

for unit in \
    input-remapper.service \
    uupd.timer \
    tuned.service \
    tuned-ppd.service \
    ds-inhibit.service
do
    if systemctl cat "${unit}" >/dev/null 2>&1; then
        systemctl enable "${unit}"
    fi
done

if systemctl cat powerstation.service >/dev/null 2>&1; then
    systemctl mask powerstation.service
fi


echo
echo "============================================================"
echo " ScentiaOS DX layer installed successfully"
echo "============================================================"
