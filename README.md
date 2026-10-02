# ScentiaOS

[![BlueBuild](https://github.com/BloodotakuZ/ScentiaOS/actions/workflows/build.yml/badge.svg)](https://github.com/BloodotakuZ/ScentiaOS/actions/workflows/build.yml)

ScentiaOS is a custom NVIDIA-focused Linux image built with [BlueBuild](https://blue-build.org/) on top of [Bazzite](https://bazzite.gg/).

It is designed around NVIDIA desktop hardware and uses Bazzite's NVIDIA Open image as its upstream base.

## Base image

```text
ghcr.io/ublue-os/bazzite-nvidia-open:testing
```

## Desktop

ScentiaOS uses:

- Hyprland
- Noctalia
- UWSM
- Kitty
- Thunar
- xdg-desktop-portal-hyprland

Noctalia provides the shell, launcher, control center, notifications, wallpaper interface, clipboard interface, media controls, and other desktop functionality around Hyprland.

## NVIDIA and kernel

This image is intended for NVIDIA hardware.

Rather than using the stock Bazzite kernel/NVIDIA combination, ScentiaOS installs a custom CachyOS kernel and builds the matching NVIDIA Open kernel modules for that kernel during the BlueBuild process.

The initramfs is rebuilt after the kernel and NVIDIA changes so the finished image contains the expected kernel/driver combination.

Because of this, this image should be considered NVIDIA-specific unless the recipe is modified for other hardware.

## Container image

The finished image is built remotely using GitHub Actions and published to:

```text
ghcr.io/bloodotakuz/scentia-cachy
```

The main BlueBuild recipe is:

```text
recipes/recipe-cachy.yml
```

## Rebase from Bazzite / Fedora Atomic

> [!WARNING]
> This is a custom image intended primarily for my own hardware and configuration.
> Review the recipe before rebasing another machine.

First switch to the unsigned image so the ScentiaOS signing configuration can be installed:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/bloodotakuz/scentia-cachy:latest
```

Then reboot:

```bash
systemctl reboot
```

After rebooting, switch to the signed image:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/bloodotakuz/scentia-cachy:latest
```

Then reboot again:

```bash
systemctl reboot
```

After booting into ScentiaOS, verify the deployment with:

```bash
bootc status
uname -r
nvidia-smi
```

## Updating

ScentiaOS inherits Bazzite's update tooling.

The normal Bazzite update command can therefore be used:

```bash
ujust update
```

System image updates are pulled from the ScentiaOS image being tracked, while the Bazzite update tooling continues handling the rest of the normal update workflow.

## Building locally

Install the BlueBuild CLI and run:

```bash
bluebuild build recipes/recipe-cachy.yml
```

## Remote builds

Pushes to this repository trigger a GitHub Actions BlueBuild.

The image is also rebuilt on a schedule so it can incorporate upstream Bazzite and package changes.

## Verification

Images are signed using Sigstore Cosign.

The public signing key is stored in this repository as:

```text
cosign.pub
```

Verify the image with:

```bash
cosign verify --key cosign.pub ghcr.io/bloodotakuz/scentia-cachy
```

## Upstream projects

ScentiaOS builds on and uses software from:

- [Bazzite](https://github.com/ublue-os/bazzite)
- [BlueBuild](https://github.com/blue-build)
- [Universal Blue](https://github.com/ublue-os)
- [Fedora](https://fedoraproject.org/)
- [Hyprland](https://hyprland.org/)
- [Noctalia](https://github.com/noctalia-dev/noctalia-shell)
- [CachyOS](https://cachyos.org/)

ScentiaOS is an independent custom image and is not an official Bazzite, Universal Blue, Fedora, BlueBuild, Hyprland, Noctalia, or CachyOS project.

Each upstream project and bundled component retains its respective license.

## License

Original material in this repository is licensed under the Apache License 2.0.

See [LICENSE](LICENSE) for details.

Software inherited from upstream projects retains its respective upstream license.
