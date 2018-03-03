{lib}:

with builtins;
with lib;
with import ./html.nix { inherit lib; };

let
  removeKey = key: filterAttrs (n: v: n != key);

  mkIframe = window: iframe window.url
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
      ${concatStringsSep "\n  " (map mkIframe windows)}
    </body>
    </html>
  '';
}
