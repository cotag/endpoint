{ config, pkgs, lib, ... }:

let
  name       = "signage_nixos-test";
  tz         = "Australia/Sydney";
  url        = "https://acaprojects.com";
  displays =
    [
      { output = "HDMI3";
        resolution.x = 3840;
        resolution.y = 600;
        rotate = "normal";
      }
    ];
  # Note: hashed passwords can be generate via `mkpasswd -m sha-512`
  passwords  =
    { root   = "$6$l7vmQlDD.9Oy6u6X$8m1bKq2MWX3cUB0/NoJVF2c8UjLgrB6uKTXG8rmVYQ4.TcopDBL8TLrQUXNsnp9KBNNUDlutuU4HAHW.9VLab0";
      aca    = "$6$F/2jG2EcteE05H8o$Ux1/OrpGaka1Efg7aHAXpqetGR1IwM1sRr.Z1Z.5.mBrCZeSOK5YqGwkVDwH5N2aOYmJZnEAOpNaHjV0zIB4.1";
    };
in

{
  imports =
    [ ./hardware-configuration.nix
      ./boot-to-browser.nix
      ./canvas.nix
      ./teleport.nix
    ];

  system.stateVersion = "17.09";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = tz;

  services.openssh.enable = true;

  services.bootToBrowser =
    { enable = true;
      url = url;
    };

  services.xserver.canvas.displays = displays;

  networking =
    { hostName = name;

      # Ensure we always have NIC's names eth0 and eth1, regardless of hardware
      usePredictableInterfaceNames = false;
      bridges.br0.interfaces = [ "eth0" "eth1" ];

      firewall.allowedTCPPorts = [ 22 ];
    };

  security.sudo =
    { enable = true;
      wheelNeedsPassword = false;
    };

  users =
    { mutableUsers = false;

      users.root.hashedPassword = passwords.root;

      groups.aca.gid = 1000;

      # Service account
      users.aca =
        { uid = 1000;
          group = "aca";
          extraGroups = [ "adm" "wheel" "disk" "audio" "video" "networkmanager" "systemd-journal" ];
          createHome = true;
          home = "/home/aca";
          shell = pkgs.bashInteractive;
          hashedPassword = passwords.aca;
        };
    };
}
