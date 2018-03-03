{lib}:

with lib;
with builtins;

rec {
  isNix = hasSuffix ".nix";

  absolute = path: file: path + "/${file}";

  filenamesIn = path: attrNames (readDir path);

  filesIn = path: map (absolute path) (filenamesIn path);

  nixFilesIn = path: filter isNix (filesIn path);
}
