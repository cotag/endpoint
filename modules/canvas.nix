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
        { options = lib.mapAttrs (name: desc: mkAxis desc) axes; };

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

      offset = mkOption
        { type = types.nullOr (coords
            { left = "horizontal offset";
              top = "vertical offset";
            });
          default = null;
          description = "Display offset within the overal render.";
        };

      rotate = mkOption
        { type = types.enum [ "normal" "left" "right" "inverted" ];
          default = "normal";
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
        let
          ifDefined = x: s: optionalString (! isNull x) s;

          displayToXrandr = display:
            { output = display.output;
              monitorConfig = ''
                ${ifDefined display.resolution ''
                Option "PreferredMode" "${toString display.resolution.x}x${toString display.resolution.y}"
                ''}
                ${ifDefined display.offset ''
                Option "Position"      "${toString display.offset.left} ${toString display.offset.top}"
                ''}
                Option "Rotate"        "${display.rotate}"
              '';
            };
        in
          builtins.map displayToXrandr cfg.displays;
    };
}
