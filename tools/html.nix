/**
 * Tools for generating HTML markup from within Nix expressions.
 */
{lib}:

with builtins;
with lib;

let
  kvToString = { transform ? toString, seperator ? "=" }: key: val:
    "${key}${seperator}${transform val}";

  attrsToString = { mkKeyVal ? kvToString {} }: sep: attrs:
    concatStringsSep sep (mapAttrsToList mkKeyVal attrs);
in

rec {
  attrsToCSS =
    let
      mkKeyVal = kvToString
        { transform = x: "${toString x};";
          seperator = ": ";
        };
    in
      attrsToString { inherit mkKeyVal; };

  inlineCSS = attrsToCSS " ";

  attrsToHTMLAttributes =
    let
      quote = x: "\"${escape [ "\"" ] x}\"";
      mkKeyVal = kvToString
        { transform = x: quote (toString x);
          seperator = "=";
        };
    in
      attrsToString { inherit mkKeyVal; } " ";

  element = tag: attributes: content:
    let
      attrStr = attrsToHTMLAttributes
        (if attributes ? style && isAttrs attributes.style
          then attributes // { style = inlineCSS attributes.style; }
          else attributes);
    in
      "<${tag}${optionalString (attributes != {}) " ${attrStr}"}>${content}</${tag}>";

  iframe = src: attrs: element "iframe" (attrs // { inherit src; }) "";
}
