#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

if [[ "${EUID}" > 0 ]]
  then echo "Please run as root"
  exit
fi

echo "-- Adding nixos-unstable channel"
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --update

echo "-- Copying config"
mv -v /etc/nixos/configuration.nix /etc/nixos/configuration.nix.old
cp -v ./configuration.nix /etc/nixos/configuration.nix
chown root:root /etc/nixos/configuration.nix
chmod 744 /etc/nixos/configuration.nix

echo "-- Switching in new config"
nixos-rebuild switch
