/**
 * Bare-bones window manager for loading a fullscreen Chromium window directly
 * onto X11.
 */
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.xserver.windowManager.chromiumKiosk;
in

{
  options =
    { services.xserver.windowManager.chromiumKiosk =
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
                validUrl = "^(file|https?):\\/\\/[^\\\s$.?#]\\\S+$";
              in
                uniq (strMatching validUrl);
            description = "The URL to load.";
            example = "https://www.example.com/";
          };

        package = mkOption
          { type = types.package;
            default = pkgs.chromium;
            defaultText = "pkgs.chromium";
            description = "Chromium browser derivation to use.";
          };
      };
    };

  config = mkIf cfg.enable
    { services.xserver.windowManager = rec
        { default = (builtins.head session).name;
          session = singleton
            { name = "chromium";
              start = ''
                # If Chromium crashes, clear warnings
                ${pkgs.gnused}/bin/sed -i \
                  's/"exited_cleanly":false/"exited_cleanly":true/' \
                  ~/.config/chromium/Default/Preferences
                ${pkgs.gnused}/bin/sed -i \
                  's/"exit_type":"Crashed"/"exit_type":"Normal"/' \
                  ~/.config/chromium/Default/Preferences

                # Lookup the available render area
                read screen_w _ screen_h \
                  <<<$( \
                    ${pkgs.xorg.xrandr}/bin/xrandr -q | \
                    ${pkgs.gnugrep}/bin/grep -oP "Screen 0:.*current \K\d+ x \d+" \
                  )

                # Launch chromium
                ${cfg.package}/bin/chromium-browser ${cfg.url} \
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

      environment.systemPackages =
        with pkgs;
        [ cfg.package
          gnugrep
          gnused
          xorg.xrandr
        ];
    };
}
