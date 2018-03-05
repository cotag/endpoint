# CoTag Endpoint Deploy Tooling

The repo provides a [NixOS](https://nixos.org/) configuration suitable for machines intended to act as [CoTag signage](https://www.acaprojects.com/smart-media/) endpoints.


## Installation

1. [Install NixOS](https://nixos.org/nixos/manual/index.html#ch-installation) onto the target machine. Do not continue with any configuration following base OS install.
2. Set any deployment specific options in `configuation.nix`.
3. Run `./setup.sh` as root to complete setup.


## Configuration

In addition to the base [NixOS options](https://nixos.org/nixos/options.html), system setup may be simplified using some of the included modules.

### Boot To Browser

#### `services.bootToBrowser.enable`
Toggle activation status. When enabled the machine will boot directly to a browser window.

#### `services.bootToBrowser.url`
The URL to load.

#### `services.bootToBrowser.alwaysOn`
Prevent the display from sleeping. Defaults to `true`.

#### `services.bootToBrowser.hideCursor`
Remove the cursor (e.g. for touch or non-interactive systems). Default to `true`.

### Canvas

#### `services.xserver.canvas.displays`
A list of displays to combine as a single, large virtual monitor. Position and rotation may be specified to suite physical installation requirements, allowing for overlap, bezel compensation or portrait / inverted mountings.

This may be omitted to auto-detect attached displays, mirroring output to all.

### Compositor

While the [Canvas](#Canvas) provides the ability to define a single large render area spread across multiple displays, the compositor may be used to layout multiple, discreet content sources within this (or within a single display).

Window definitions passed to the compositor will generate a light-weight, static resource which may be loaded into the root browser session.

Each window must contain a `url` key. It may then use any combination of CSS layout attributes to define it's position within the overall display. CSS transforms may also be used to provide perspective distortion and rotation. Similarly, CSS filters may be applied for colour correction, brightness and contrast compensation.

For example, a vertical split layout that will auto-size to the available screen
resolution can be generated with the following expression.

```nix
let
  defaultUrl = "https://www.acaprojects.com";
in
  { leftUrl ? defaultUrl, rightUrl ? defaultUrl }:
    "file://" + tools.compositor.makeLayout
      [
        { url = leftUrl;
          width = "50%";
        }
        { url = rightUrl;
          width = "50%";
          right = 0;
        }
      ]
```
