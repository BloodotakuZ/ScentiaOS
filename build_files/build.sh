#!/bin/bash

set -ouex pipefail

ensure_dnf_setting() {
    local key="$1"
    local value="$2"
    if ! grep -q "^${key}=" /etc/dnf/dnf.conf; then
        echo "${key}=${value}" >>/etc/dnf/dnf.conf
    fi
}

ensure_dnf_setting "max_parallel_downloads" "5"
ensure_dnf_setting "fastestmirror" "true"
ensure_dnf_setting "defaultyes" "true"

dnf5 install -y dnf5-plugins

FEDORA_VERSION="$(rpm -E %fedora)"
dnf5 install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"

COPR_REPOS=(
    sdegler/hyprland
    erikreider/SwayNotificationCenter
    errornointernet/packages
    errornointernet/quickshell
    tofik/nwg-shell
)

for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr enable "$repo"
done

restrict_copr_packages() {
    local repo="$1"
    local package="$2"
    local repo_file="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:${repo//\//:}.repo"
    if [ -f "$repo_file" ] && ! grep -q "^includepkgs=${package}" "$repo_file"; then
        printf "\nincludepkgs=%s\n" "$package" >>"$repo_file"
    fi
}

restrict_copr_packages "errornointernet/packages" "wallust"
restrict_copr_packages "tofik/nwg-shell" "nwg-displays"

dnf5 upgrade -y

dnf5 remove -y aylurs-gtk-shell dunst mako || true

PACKAGES=(
    acpi
    adobe-source-code-pro-fonts
    bc
    bluez
    bluez-tools
    blueman
    brightnessctl
    btop
    cava
    cliphist
    curl
    ffmpegthumbnailer
    fira-code-fonts
    fontawesome-fonts-all
    fastfetch
    findutils
    gawk
    git
    gnome-system-monitor
    google-droid-sans-fonts
    google-noto-sans-cjk-fonts
    google-noto-color-emoji-fonts
    google-noto-emoji-fonts
    grim
    gvfs
    gvfs-mtp
    hypridle
    hyprland
    hyprland-guiutils
    hyprlock
    hyprpaper
    hyprpolkitagent
    hyprsunset
    ImageMagick
    inxi
    jetbrains-mono-fonts
    jq
    kitty
    kvantum
    akmod-nvidia
    xorg-x11-drv-nvidia-cuda
    libva
    libva-nvidia-driver
    libnotify
    lm_sensors
    loupe
    lsd
    mercurial
    mpv
    mpv-mpris
    nano
    network-manager-applet
    nvtop
    openssl
    nwg-displays
    nwg-look
    pamixer
    pavucontrol
    pipewire-alsa
    pipewire-utils
    playerctl
    python3-cairo
    python3-pip
    python3-pyquery
    python3-requests
    qalculate-gtk
    quickshell
    qt5ct
    qt6ct
    qt6-qtdeclarative
    qt6-qtmultimedia
    qt6-qtvirtualkeyboard
    qt6-qtsvg
    rofi
    rsync
    sddm
    slurp
    SwayNotificationCenter
    swappy
    swww
    thunar
    thunar-archive-plugin
    thunar-volman
    tmux
    tumbler
    unzip
    util-linux
    waybar
    wallust
    wget
    wget2
    wl-clipboard
    wlogout
    xarchiver
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    xdg-user-dirs
    xdg-utils
    yad
    zsh
)

dnf5 install -y "${PACKAGES[@]}"

systemctl enable bluetooth.service
systemctl enable sddm.service
systemctl disable gdm.service || true
systemctl set-default graphical.target

getent group input >/dev/null || groupadd -r input

WORKDIR="$(mktemp -d)"
pushd "$WORKDIR"
git clone --depth 1 https://github.com/JaKooLit/Hyprland-Dots
git clone --depth 1 https://github.com/JaKooLit/Fedora-Hyprland
git clone --depth 1 https://github.com/JaKooLit/GTK-themes-icons
git clone --depth 1 https://github.com/JaKooLit/simple-sddm-2
popd

JAKOOLIT_ROOT=/usr/share/jakoolit-hyprland
install -d "$JAKOOLIT_ROOT"
cp -r "$WORKDIR/Hyprland-Dots" "$JAKOOLIT_ROOT/Hyprland-Dots"
rm -rf "$JAKOOLIT_ROOT/Hyprland-Dots/.git"
install -d "$JAKOOLIT_ROOT/fedora-assets"
cp -r "$WORKDIR/Fedora-Hyprland/assets/"* "$JAKOOLIT_ROOT/fedora-assets/"

install -d "$JAKOOLIT_ROOT/zsh-themes"
cp -r "$JAKOOLIT_ROOT/fedora-assets/add_zsh_theme/." "$JAKOOLIT_ROOT/zsh-themes/"

install -d /etc/skel
install -d /etc/skel/.config
rsync -aq "$JAKOOLIT_ROOT/Hyprland-Dots/config/" /etc/skel/.config/

for extra_cfg in gtk-3.0 Thunar xfce4; do
    if [ -d "$JAKOOLIT_ROOT/fedora-assets/$extra_cfg" ]; then
        install -d "/etc/skel/.config/$extra_cfg"
        rsync -aq "$JAKOOLIT_ROOT/fedora-assets/$extra_cfg/" "/etc/skel/.config/$extra_cfg/"
    fi
done

install -d /etc/skel/Pictures
rsync -aq "$JAKOOLIT_ROOT/Hyprland-Dots/wallpapers" /etc/skel/Pictures/

install -d /etc/skel/.local/share/rofi/themes
rsync -aq "$JAKOOLIT_ROOT/Hyprland-Dots/config/rofi/themes/" /etc/skel/.local/share/rofi/themes/

if [ -d /etc/skel/.config/hypr/scripts ]; then
    find /etc/skel/.config/hypr/scripts -type f -name "*.sh" -exec chmod +x {} +
fi
if [ -d /etc/skel/.config/hypr/UserScripts ]; then
    find /etc/skel/.config/hypr/UserScripts -type f -exec chmod +x {} +
fi
chmod +x /etc/skel/.config/hypr/initial-boot.sh

if [ -d /etc/skel/.config/waybar ]; then
    pushd /etc/skel/.config/waybar
    ln -sf "configs/[TOP] Default" config
    ln -sf "style/[Extra] Neon Circuit.css" style.css
    popd
fi

install -m 0644 "$JAKOOLIT_ROOT/fedora-assets/.zshrc" /etc/skel/.zshrc
install -m 0644 "$JAKOOLIT_ROOT/fedora-assets/.zprofile" /etc/skel/.zprofile

install -d /usr/local/share/fonts/JetBrainsMonoNerd
curl -L -o "$WORKDIR/JetBrainsMono.tar.xz" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
tar -xJf "$WORKDIR/JetBrainsMono.tar.xz" -C /usr/local/share/fonts/JetBrainsMonoNerd

install -d /usr/local/share/fonts/FantasqueSansMono
curl -L -o "$WORKDIR/FantasqueSansMono.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/FantasqueSansMono.zip
unzip -o -q "$WORKDIR/FantasqueSansMono.zip" -d /usr/local/share/fonts/FantasqueSansMono

install -d /usr/local/share/fonts/VictorMono
curl -L -o "$WORKDIR/VictorMonoAll.zip" https://rubjo.github.io/victor-mono/VictorMonoAll.zip
unzip -o -q "$WORKDIR/VictorMonoAll.zip" -d /usr/local/share/fonts/VictorMono

fc-cache -f

install -d /usr/share/themes
tar -xzf "$WORKDIR/GTK-themes-icons/theme/Flat-Remix-GTK-Blue-Dark.tar.gz" -C /usr/share/themes
tar -xzf "$WORKDIR/GTK-themes-icons/theme/Flat-Remix-GTK-Blue-Light.tar.gz" -C /usr/share/themes

install -d /usr/share/icons
unzip -o -q "$WORKDIR/GTK-themes-icons/icon/Flat-Remix-Blue-Dark.zip" -d /usr/share/icons
unzip -o -q "$WORKDIR/GTK-themes-icons/icon/Flat-Remix-Blue-Light.zip" -d /usr/share/icons
unzip -o -q "$WORKDIR/GTK-themes-icons/icon/Bibata-Modern-Ice.zip" -d /usr/share/icons

gtk-update-icon-cache -f /usr/share/icons/Flat-Remix-Blue-Dark || true
gtk-update-icon-cache -f /usr/share/icons/Flat-Remix-Blue-Light || true
gtk-update-icon-cache -f /usr/share/icons/Bibata-Modern-Ice || true

SDDM_THEME_DIR=/usr/share/sddm/themes/simple_sddm_2
rm -rf "$SDDM_THEME_DIR"
cp -r "$WORKDIR/simple-sddm-2" "$SDDM_THEME_DIR"
rm -rf "$SDDM_THEME_DIR/.git"
install -d "$SDDM_THEME_DIR/Backgrounds"
cp "$JAKOOLIT_ROOT/fedora-assets/sddm.png" "$SDDM_THEME_DIR/Backgrounds/default"
sed -i 's|^wallpaper=.*|wallpaper="Backgrounds/default"|' "$SDDM_THEME_DIR/theme.conf" || true

cat >/etc/sddm.conf <<'EOF'
[Theme]
Current=simple_sddm_2

[General]
InputMethod=qtvirtualkeyboard
EOF

install -d /usr/share/backgrounds/jakoolit
rsync -aq "$JAKOOLIT_ROOT/Hyprland-Dots/wallpapers/" /usr/share/backgrounds/jakoolit/

rm -rf "$WORKDIR"

systemctl enable podman.socket
