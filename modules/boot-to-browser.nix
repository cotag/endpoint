/**
 * Provide the ability to boot directly to a browser session.
 *
 * When enabled, on power up, the system will be auto-logged in as a 'player'
 * user and chromium loaded direclty onto a bare bones X11 session.
 */
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.bootToBrowser;
in

{
  imports = [ ./chromium-wm.nix ];

  options =
    { services.bootToBrowser =
      { enable = mkOption
          { default = false;
            type = types.bool;
            description = "Enable booting directly to a browser window.";
          };

        url = mkOption
          { type =
              with types;
              let
                validUrl = "^(file|https?):\\/\\/[^ $.?#]\\S+$";
              in
                uniq (strMatching validUrl);
            description = "The URL to load.";
            example = "https://www.example.com/";
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
