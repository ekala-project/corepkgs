self: super: with self; {

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

  libxslt =
    (toPythonModule (
      pkgs.libxslt.override {
        pythonSupport = true;
        python3 = python;
        inherit (self) libxml2;
      }
    )).py;

  meson = toPythonModule (
    (pkgs.meson.override { python3 = python; }).overridePythonAttrs (oldAttrs: {
      # We do not want the setup hook in Python packages because the build is performed differently.
      setupHook = null;
    })
  );

  numpy_2 = callPackage ./pkgs/numpy/2.nix { };
  numpy_1 = callPackage ./pkgs/numpy/1.nix { };
  numpy = self.numpy_2;
}
