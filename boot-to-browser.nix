{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.bootToBrowser;
in

{
  imports = [ ./chromium-wm.nix ];

  options.services.bootToBrowser =
    { enable = mkOption
        { default = false;
          type = types.bool;
          description = "Enable booting directly to a browser window.";
        };

      url = mkOption
        { type =
            with types;
            let
              validUrl = "^https?:\\/\\/[^\\\s\\/$.?#]\\\S+$";
            in
              uniq (strMatching validUrl);
          description = "The URL to load.";
          example = "https://www.example.com/";
        };

      rotate = mkOption
        { type = types.enum [ "normal" "left" "right" "inverted" ];
          default = "normal";
          description = "Screen rotation (portrait / inverted mountings).";
        };

      alwaysOn = mkOption
        { type = types.bool;
          default = true;
          description = "Prevent the display from sleeping.";
        };

      hideCursor = mkOption
        { type = types.bool;
          default = true;
          description = "Hide the mouse cursor.";
        };
    };

  config = mkIf cfg.enable
    { services.xserver =
        { enable = true;


          displayManager =
            { xserverArgs = mkIf cfg.hideCursor [ "-nocursor" ];

              sessionCommands = mkIf cfg.alwaysOn ''
                xset s off
                xset -dpms
                xset s noblank
              '';

              slim = mkForce
                { enable = true;
                  autoLogin = true;
                  defaultUser = config.users.users.browser.name;
                };
            };

          desktopManager.xterm.enable = false;
          desktopManager.default = "none";

          windowManager.chromiumKiosk =
            { enable = true;
              url = cfg.url;
            };
        };

      # Limited account for running the browser session
      users.users.browser =
        { uid = 2000;
          isNormalUser = true;
        };
    };
}
