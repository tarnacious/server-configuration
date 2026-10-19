#!/usr/bin/env bash
set -euo pipefail

echo "Building ownCloud configuration..."
cd "$(dirname "$0")"

export NIX_CONFIG="experimental-features = nix-command flakes"

# Build the configuration
nix build .#nixosConfigurations.owncloud.config.system.build.toplevel

# Build a disk image using nix-build
nix-build -E '
let
  pkgs = import <nixpkgs> { system = "x86_64-linux"; };
  config = import ./configuration.nix { inherit pkgs; };
  makeDiskImage = pkgs.callPackage (pkgs.path + "/nixos/lib/make-disk-image.nix") { };
  nixosLib = makeDiskImage;
in nixosLib.makeDiskImage {
  inherit pkgs;
  config = config;
  name = "owncloud";
  format = "qcow2";
  diskSize = 20 * 1024;
}'

cp result/nixos.qcow2 owncloud.qcow2

echo ""
echo "Build complete! Image: ./owncloud.qcow2"
qemu-img info ./owncloud.qcow2
