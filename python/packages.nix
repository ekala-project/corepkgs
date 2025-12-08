self: super: with self; let
  inherit (super) pkgs;
in {

  bootstrap = lib.recurseIntoAttrs {
    flit-core = toPythonModule (callPackage ./bootstrap/flit-core { });
    installer = toPythonModule (callPackage ./bootstrap/installer { inherit (bootstrap) flit-core; });
    build = toPythonModule (
      callPackage ./bootstrap/build {
        inherit (bootstrap) flit-core installer;
      }
    );
    packaging = toPythonModule (
      callPackage ./bootstrap/packaging {
        inherit (bootstrap) flit-core installer;
      }
    );
  };


  libxml2 =
    (toPythonModule (
      pkgs.libxml2.override {
        pythonSupport = true;
        python3 = python;
      }
      )).py;


}
