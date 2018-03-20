#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

check_priv() {
  [[ "${EUID}" == 0 ]] || (echo "Please run as root" && false)
}

confirm() {
  read -r -p "This will override the existing system config. Are you sure? [y/N] " response
  [[ "${response}" =~ ^([yY][eE][sS]|[yY])+$ ]]
}

setup() {
  echo "-- Copying config"
  find -name "*.nix" | xargs cp -v --parents --target-directory=/etc/nixos
  chown --recursive root:root /etc/nixos/**/*.nix
  chmod --recursive 744 /etc/nixos/**/*.nix

  echo "-- Extracting device serial number"
  sn=$(nix-shell --run "sudo dmidecode -s system-serial-number" -p dmidecode)
  echo "${sn}"

  echo "-- Building"
  SYSTEM_SERIAL_NUMBER="${sn}" nixos-rebuild switch

  echo "-- Reloading display"
  systemctl restart display-manager
}

check_priv && confirm && setup
