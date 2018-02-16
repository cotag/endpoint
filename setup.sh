#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

is_root() {
  [[ "${EUID}" == 0 ]] || (echo "Please run as root" && false)
}

confirm() {
  read -r -p "This will override the existing system config. Are you sure? [y/N] " response
  [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
}

install() {
  file="$1"
  cp -v ./${file} /etc/nixos/${file}
  chown root:root /etc/nixos/${file}
  chmod 744 /etc/nixos/${file}
}

setup() {
  echo "-- Adding nixos-unstable channel"
  nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
  nix-channel --update

  echo "-- Copying config"
  install configuration.nix
  install teleport.nix

  echo "-- Switching in new config"
  nixos-rebuild switch
}

is_root && confirm && setup
