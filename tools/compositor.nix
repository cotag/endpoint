/**
 * Generate a light-weight wrapper to enable compositing multiple windows
 * within a larger canvas.
 *
 * Accepts a list of windows a output's an appropriate static page into the nix
 * store, returning it's path for loading into a browser session.
 *
 * Each window attrSet must contain a "url" key. It may then use any valid CSS
 * layout attributes to define it's position (either as absolute pixel
 * positions or relative). CSS transforms may also be used to provide
 * perspective distortion and rotation. Similarly, CSS filters may be applied
 * for colour correction, brightness and contrast compensation.
 *
 * For example, to generate a vertical split:
 *
 *   compositor.makeLayout [
 *     { url = https://www.acaprojects.com;
 *       width = "50%";
 *     }
 *     { url = https://www.acaprojects.com;
 *       width = "50%";
 *       right = 0;
 *     }
 *   ];
 */
{lib}:

with builtins;
with lib;
with import ./html.nix { inherit lib; };

let
  removeKey = key: filterAttrs (n: v: n != key);

  windowToIframe = window: iframe window.url
    { style = removeKey "url" window;
      frameborder = 0;
      scrolling = "no";
    };
in

{
  makeLayout = windows: toFile "compositor.html" ''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Composite Layout</title>
      <style type="text/css">
        html, body, iframe {
          margin: 0;
          padding: 0;
          width: 100%;
          height: 100%;
        }
        iframe {
          position: absolute;
        }
      </style>
    </head>
    <body>
      ${concatStringsSep "\n  " (map windowToIframe windows)}
    </body>
    </html>
  '';
}
