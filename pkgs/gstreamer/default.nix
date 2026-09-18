{
  lib,
  newScope,
}:

let
  scope = lib.makeScope newScope (
    self:
    let
      inherit (self) callPackage;
    in
    {
      gstreamer = callPackage ./core { };
      gst-plugins-base = callPackage ./base { };
      gst-plugins-good = callPackage ./good { };
      gst-plugins-bad = callPackage ./bad { };
      gst-plugins-ugly = callPackage ./ugly { };
      gst-rtsp-server = callPackage ./rtsp-server { };
      gst-libav = callPackage ./libav { };
      gst-devtools = callPackage ./devtools { };
      gst-editing-services = callPackage ./ges { };
    }
  );
in
scope.gstreamer.overrideAttrs (old: {
  passthru = old.passthru or { } // {
    plugins-base = scope.gst-plugins-base;
    plugins-good = scope.gst-plugins-good;
    plugins-bad = scope.gst-plugins-bad;
    plugins-ugly = scope.gst-plugins-ugly;
    rtsp-server = scope.gst-rtsp-server;
    libav = scope.gst-libav;
    devtools = scope.gst-devtools;
    editing-services = scope.gst-editing-services;

    # Expose scope for nixpkgs compat alias
    _scope = scope;
  };
})
