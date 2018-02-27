{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.xserver.windowManager.chromiumKiosk;
in

{
  options.services.xserver.windowManager.chromiumKiosk =
    { enable = mkOption
        { default = true;
          type = types.bool;
          description = ''
            Whether to enable running Chromium Browser directly as a WM.

            Enabling this loads up the browser window, directly onto X11 for
            use in Kiosk applications.
          '';
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

      package = mkOption
        { type = types.package;
          default = pkgs.chromium;
          defaultText = "pkgs.chromium";
          description = "Chromium package to use.";
        };
    };

  config = mkIf cfg.enable
    { services.xserver =
        { displayManager.xserverArgs = mkIf cfg.hideCursor [ "-nocursor" ];

          windowManager = rec
            { default = (builtins.head session).name;
              session = singleton
                { name = "Chromium Kiosk";
                  start =
                    with cfg;
                    ''
                      xset s off
                      xset -dpms
                      xset s noblank

                      # If Chromium crashes, clear warnings
                      sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' ~/.config/chromium/Default/Preferences
                      sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' ~/.config/chromium/Default/Preferences

                      # Lookup the available render area
                      read screen_w _ screen_h <<<$(xrandr -q | grep -oP "Screen 0:.*current \K\d+ x \d+")

                      # Launch chromium
                      ${package}/bin/chromium-browser ${url} \
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

      environment.systemPackages = [ cfg.package pkgs.xorg.xrandr ];
    };
}
