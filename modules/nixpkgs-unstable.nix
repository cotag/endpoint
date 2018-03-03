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
