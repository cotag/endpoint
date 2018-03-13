/**
 * Scheduled task to run a nightly system reboot.
 */
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nightlyReboot;
in

{
  options =
    { services.nightlyReboot =
      { enable = mkOption
          { default = false;
            type = types.bool;
            description = "Enable a nightly machine reboot";
          };

        time = mkOption
          { default = "03:00:00";
            type =
              with types;
              let
                validTime = "^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$";
              in
                strMatching validTime;
            description = "Reboot time";
          };
      };
    };

  config = mkIf cfg.enable
    { systemd.services.nightlyReboot =
        { description = "Nightly machine reboot";

          serviceConfig =
            { type = "simple";
              ExecStart = "${pkgs.systemd}/bin/systemctl --force reboot";
            };

          startAt = "*-*-* ${cfg.time}";

          wantedBy = [ "multi-user.target" ];
        };
    };
}
