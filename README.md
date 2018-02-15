# CoTag Endpoint Deploy Tooling

The repo provides a [NixOS](https://nixos.org/) configuration suitable for machines intended to act as CoTag signage endpoints.

## Installation

1. [Install NixOS](https://nixos.org/nixos/manual/index.html#ch-installation) onto the target machine. Do not continue with any configuration following base OS install.
2. Set any deployment specific options at the top of `configuation.nix`.
3. Run `sudo ./setup.sh` to complete setup.
