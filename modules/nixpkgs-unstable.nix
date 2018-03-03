/**
 * Provide an 'unstable' namespace within pkgs for references packages from the
 * bleeding edge.
 *
 * Note: the NixOS unstable channel must be available. This can be added with:
 *
 *   nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
 *   nix-channel --update
 *   
 */
{ config, ... }:

{
  # Enable pulling packages from the unstable branch via unstable.name
  nixpkgs.config.packageOverrides = pkgs:
  { unstable =
      import <nixos-unstable>
      { # Propogate `allowUnfree` to our unstable packages
        config = config.nixpkgs.config;
      };
  };
}
