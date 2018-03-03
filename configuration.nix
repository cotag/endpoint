{ config, pkgs, lib, ... }:

let
  tools = lib.genAttrs [ "compositor" "paths" ]
    (name: import (./tools + "/${name}.nix") { inherit lib; } );
in

{
  imports =
    [ ./hardware-configuration.nix
    ] ++ tools.paths.nixFilesIn ./modules;

  system.stateVersion = "17.09";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Australia/Sydney";

  services.openssh.enable = true;

  services.bootToBrowser =
    { enable = true;
      url = "file://" + tools.compositor.makeLayout
        [
          { url = https://www.acaprojects.com;
            width = "50%";
          }
          { url = https://www.acaprojects.com;
            width = "50%";
            right = 0;
          }
        ];
    };

  services.xserver.canvas.displays =
    [
      { output = "HDMI3";
        resolution.x = 3840;
        resolution.y = 600;
        rotate = "normal";
      }
    ];

  networking =
    { hostName = "signage_nixos-test";

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

      users.root.hashedPassword = "$6$l7vmQlDD.9Oy6u6X$8m1bKq2MWX3cUB0/NoJVF2c8UjLgrB6uKTXG8rmVYQ4.TcopDBL8TLrQUXNsnp9KBNNUDlutuU4HAHW.9VLab0";

      groups.aca.gid = 1000;

      # Service account
      users.aca =
        { uid = 1000;
          group = "aca";
          extraGroups = [ "adm" "wheel" "disk" "audio" "video" "networkmanager" "systemd-journal" ];
          createHome = true;
          home = "/home/aca";
          shell = pkgs.bashInteractive;
          hashedPassword = "$6$F/2jG2EcteE05H8o$Ux1/OrpGaka1Efg7aHAXpqetGR1IwM1sRr.Z1Z.5.mBrCZeSOK5YqGwkVDwH5N2aOYmJZnEAOpNaHjV0zIB4.1";
        };
    };
}
