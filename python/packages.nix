self: super: with self; {
  
  bootstrap = lib.recurseIntoAttrs {
    flit-core = toPythonModule (callPackage ./bootstrap/flit-core { });
    installer = toPythonModule (
      callPackage ./bootstrap/installer { inherit (bootstrap) flit-core; }
    );
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
}