/**
 * Env info.
 */
{lib, ...}:

with lib;
with builtins;

let
  requireEnv = name: errMsg:
    let v = getEnv name;
    in if v != "" then v else abort "${name} not set\n${errMsg}";
in

rec {
  serialNumber = requireEnv "SYSTEM_SERIAL_NUMBER" ''
    System serial number must be available as an env variable. Reading this
    value from DMI requires elevated privelages and as such, must be performed
    outside of the nix build process.

    export SYSTEM_SERIAL_NUMBER=$(nix-shell --run "sudo dmidecode -s system-serial-number" -p dmidecode)
  '';
}
