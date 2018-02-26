{ config, pkgs, lib, ... }:

let
  name       = "signage_nixos-test";
  tz         = "Australia/Sydney";
  url        = "https://acaprojects.com";
  # Note: hashed passwords can be generate via `mkpasswd -m sha-512`
  passwords  =
    { root   = "$6$l7vmQlDD.9Oy6u6X$8m1bKq2MWX3cUB0/NoJVF2c8UjLgrB6uKTXG8rmVYQ4.TcopDBL8TLrQUXNsnp9KBNNUDlutuU4HAHW.9VLab0";
      aca    = "$6$F/2jG2EcteE05H8o$Ux1/OrpGaka1Efg7aHAXpqetGR1IwM1sRr.Z1Z.5.mBrCZeSOK5YqGwkVDwH5N2aOYmJZnEAOpNaHjV0zIB4.1";
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
      unstable.teleport
      xorg.xrandr
    ];

  services.openssh.enable = true;

  networking =
    { hostName = name;

      # Ensure we always have NIC's names eth0 and eth1, regardless of hardware
      usePredictableInterfaceNames = false;
      bridges.br0.interfaces = [ "eth0" "eth1" ];

      firewall.allowedTCPPorts = [ 22 ];
    };

  services.xserver =
    { enable = true;

      displayManager.xserverArgs = [ "-nocursor" ];

      xrandrHeads =
        [
          { output = "DP1";
            monitorConfig = ''
              Option "Rotate" "left"
            '';
          }
        ];

      displayManager.slim =
        { enable = true;
          autoLogin = true;
          defaultUser = config.users.users.player.name;
        };

      desktopManager.xterm.enable = false;
      desktopManager.default = "none";

      # Load up chromium directly onto X
      windowManager = rec
        { default = (builtins.head session).name;
          session = lib.singleton
            { name = "CoTag";
              start = ''
                # Disable blanking
                xset s off
                xset -dpms
                xset s noblank

                # If Chromium crashes, clear warnings
                sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' ~/.config/chromium/Default/Preferences
                sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' ~/.config/chromium/Default/Preferences

                # Lookup the available render area
                read screen_w _ screen_h <<<$(xrandr -q | grep -oP "Screen 0:.*current \K\d+ x \d+")

                # Launch chromium
                ${pkgs.chromium}/bin/chromium-browser ${url} \
                  --start-fullscreen \
                  --kiosk \
                  --noerrdialogs \
                  --window-position=0,0 \
                  --window-size=$screen_w,$screen_h \
                  &
                waitPID=$!
              '';
            };
        };
    };

  security.sudo =
    { enable = true;
      wheelNeedsPassword = false;
    };

  users =
    { mutableUsers = false;

      users.root.hashedPassword = passwords.root;

      groups.aca.gid = 1000;

      # Service account for admin tasks
      users.aca =
        { uid = 1000;
          group = "aca";
          extraGroups = [ "adm" "wheel" "disk" "audio" "video" "networkmanager" "systemd-journal" ];
          createHome = true;
          home = "/home/aca";
          shell = pkgs.bashInteractive;
          hashedPassword = passwords.aca;
        };

      # Limited account for running the browser session
      users.player =
        { uid = 1001;
          isNormalUser = true;
        };
    };
}
