{pkgs, ...}:

let
  dmi = with pkgs; string:
    import (
      runCommand "dmi_${string}"
      { buildInputs = [ nix dmidecode ];
        dummy = builtins.currentTime;
      }
      ''
        dmidecode -s ${string} > $out
      ''
    );
in

{
  serial = dmi "system-serial-number";
}
