#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

check_priv() {
  [[ "${EUID}" == 0 ]] || (echo "Please run as root" && false)
}

confirm() {
  read -r -p "This will override the existing system config. Are you sure? [y/N] " response
  [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
}

setup() {
  echo "-- Adding nixos-unstable channel"
  nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
  nix-channel --update

  echo "-- Copying config"
  find -name "*.nix" | xargs cp -v --parents --target-directory=/etc/nixos
  chown --recursive root:root /etc/nixos/**/*.nix
  chmod --recursive 744 /etc/nixos/**/*.nix

  echo "-- Switching in new config"
  nixos-rebuild switch
}

check_priv && confirm && setup
