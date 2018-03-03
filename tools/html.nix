{lib}:

with builtins;
with lib;

let
  kvToString = { mkVal ? toString }: sep: key: val:
    "${key}${sep}${mkVal val}";

  attrsToString = { mkKeyVal ? kvToString {} "=" }: attrSep: attrs:
    concatStringsSep attrSep (mapAttrsToList mkKeyVal attrs);

  attrsToCss =
    let
      mkVal = x: "${toString x};";
      mkKeyVal = kvToString { inherit mkVal; } ": ";
    in
      attrsToString { inherit mkKeyVal; };

  inlineCss = attrsToCss " ";

  attrsToHTMLAttributes =
    let
      quote = x: "\"${escape [ "\"" ] x}\"";
      mkVal = x: quote (toString x);
      mkKeyVal = kvToString { inherit mkVal; } "=";
    in
      attrsToString { inherit mkKeyVal; } " ";
in

rec {
  element = tag: attributes: content:
    let
      attrStr = attrsToHTMLAttributes
        (if attributes ? style && isAttrs attributes.style
          then attributes // { style = inlineCss attributes.style; }
          else attributes);
    in
      "<${tag}${optionalString (attributes != {}) " ${attrStr}"}>${content}</${tag}>";

  iframe = src: attrs: element "iframe" (attrs // { inherit src; }) "";
}
