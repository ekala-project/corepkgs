{ mkManyVariants, callPackage }:

mkManyVariants {
  variants = ./variants.nix;
  aliases = { };
  name = "webrtc-audio-processing";
  eol = { };
  removed = { };
  defaultSelector = (p: p.v1);
  genericBuilder = ./generic.nix;
  inherit callPackage;
}
