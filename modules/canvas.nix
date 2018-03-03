/**
 * Enable simple configuration on multi-display setups.
 *
 * All displays defined will form part of a single large virtual display (the
 * canvas). Position and rotation may be specified arbitrarily to suite
 * physical installation requirements, allowing for overlap, bezel compensation
 * or portrait in inverted mountings.
 */
{ config, lib, ... }:

with lib;

let
  cfg = config.services.xserver.canvas;

  # Create a submodule type for a coordinate system
  coords =
    let
      maxRenderArea = 32767;
      mkAxis = name: mkOption
        { type = with types; addCheck int (x: x >= 0 && x <= maxRenderArea) //
            { name = name;
              description = "${name} (0 - ${toString maxRenderArea})";
            };
          description = "${name} in pixels";
        };
    in
      axes: types.submodule
        { options = mapAttrs (name: desc: mkAxis desc) axes; };

  # Options required to define the property of a single physical monitor
  displayOptions =
    { output = mkOption
        { type = types.str;
          example = "DP1";
          description = ''
            The output name as shown in `xrandr -q`.
          '';
        };

      resolution = mkOption
        { type = types.nullOr (coords
            { x = "display width";
              y = "display height";
            });
          default = null; # auto detect
          description = "Preferred display resolution.";
        };

      position = mkOption
        { type = types.nullOr (coords
            { left = "horizontal offset";
              top = "vertical offset";
            });
          default = null;
          description = "Display position within the overall render.";
        };

      rotate = mkOption
        { type = with types; nullOr (enum
            [ "normal"
              "left"
              "right"
              "inverted"
            ]);
          default = null;
          description = "Screen rotation for portrait / inverted mountings.";
        };
    };
in

{
  options =
    { services.xserver.canvas =
      { render = mkOption
          { type = types.nullOr (coords
              { width = "virtual screen width";
                height = "virtual screen height";
              });
            description = "Force an overall size of the render area.";
          };

        displays = mkOption
          { type = with types; listOf (submodule { options = displayOptions; });
            default = [];
            description = "Physical displays and their layout within the render.";
          };
      };
    };

  config =
    { services.xserver.xrandrHeads =
        with builtins;
        let
          compact = remove null;

          option = name: f: mapNullable (x: ''Option "${name}" "${f x}"'');

          lines = x: concatStringsSep "\n" (compact x);

          displayToXrandr = display:
            { output = display.output;
              monitorConfig = lines
                [ (option "PreferredMode" (res: "${toString res.x}x${toString res.y}")      display.resolution)
                  (option "Position"      (pos: "${toString pos.left} ${toString pos.top}") display.position)
                  (option "Rotate"        id                                                display.rotate)
                ];
            };
        in
          map displayToXrandr cfg.displays;
    };
}
