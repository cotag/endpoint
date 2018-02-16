{ config, pkgs, ... }:

let
  name      = "signage_nixos-test";
  tz        = "Australia/Sydney";
  url       = "https://acaprojects.com";
  # Note: hashed passwords can be generate via `mkpasswd -m sha-512`
  passwords =
    { root  = "$6$l7vmQlDD.9Oy6u6X$8m1bKq2MWX3cUB0/NoJVF2c8UjLgrB6uKTXG8rmVYQ4.TcopDBL8TLrQUXNsnp9KBNNUDlutuU4HAHW.9VLab0";
      aca   = "$6$F/2jG2EcteE05H8o$Ux1/OrpGaka1Efg7aHAXpqetGR1IwM1sRr.Z1Z.5.mBrCZeSOK5YqGwkVDwH5N2aOYmJZnEAOpNaHjV0zIB4.1";
    };
in
{
  imports =
    [ ./hardware-configuration.nix
      ./teleport.nix
    ];

  system.stateVersion = "17.09";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = name;

  time.timeZone = tz;

  nixpkgs.config.allowUnfree = true;

  # Enable pulling packages from the unstable branch via unstable.name
  nixpkgs.config.packageOverrides = pkgs:
    { unstable =
        import <nixos-unstable>
        { # Propogate `allowUnfree` to our unstable packages
          config = config.nixpkgs.config;
        };
    };

  environment.systemPackages =
    with pkgs;
    [ chromium
      tightvnc
      unstable.teleport
    ];

  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts =
    [ 22    # SSH
      5900  # VNC
    ];

  services.xserver = {
    enable = true;
    layout = "us";
    displayManager.auto.enable = true;
    displayManager.auto.user = "player";
    desktopManager.default = "none";
  };

  security.sudo =
    { enable = true;
      wheelNeedsPassword = false;
    };

  users =
    { mutableUsers = false;

      extraUsers.root.hashedPassword = passwords.root;

      extraGroups.aca.gid = 1000;

      # Service account for admin tasks
      extraUsers.aca =
        { uid = 1000;
          name = "aca";
          group = "aca";
          extraGroups = [ "adm" "wheel" "disk" "audio" "video" "networkmanager" "systemd-journal" ];
          createHome = true;
          home = "/home/aca";
          shell = pkgs.bashInteractive;
          hashedPassword = passwords.aca;
        };

      # Limited account for running the browser session
      extraUsers.player =
        { uid = 1001;
          name = "player";
          isNormalUser = true;
        };
    };

  environment.etc.xinitrc =
    { target = "X11/xinit/xinitrc";
      text = ''
        xset s off
        xset -dpms
        exec ${pkgs.chromium}/bin/chromium-browser --app=${url}
      '';
    };
}
