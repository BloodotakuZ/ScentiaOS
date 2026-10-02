# ScentiaOS

ScentiaOS is a custom Linux image built with BlueBuild on top of Bazzite.

## Base image

ghcr.io/ublue-os/bazzite-nvidia-open:testing

## Container image

ghcr.io/bloodotakuz/scentia-cachy

## Build recipe

recipes/recipe-cachy.yml

## Build status

https://github.com/BloodotakuZ/ScentiaOS/actions

## Building locally

bluebuild build recipes/recipe-cachy.yml

## Verification

Images are signed using Sigstore Cosign.

The public key is included in this repository as cosign.pub.

Verify with:

cosign verify --key cosign.pub ghcr.io/bloodotakuz/scentia-cachy

## Upstream projects

ScentiaOS builds on and uses software from:

- Bazzite
- BlueBuild
- Universal Blue
- Fedora
- Hyprland
- CachyOS

ScentiaOS is an independent custom image and is not an official Bazzite, Universal Blue, Fedora, CachyOS, or BlueBuild project.

Each upstream project and bundled component retains its respective license.

## License

Original material in this repository is licensed under the Apache License 2.0.

See LICENSE for details.
