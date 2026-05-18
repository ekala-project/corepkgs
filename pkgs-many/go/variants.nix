{
  v1_24 = {
    version = "1.24.11";
    src-hash = "sha256-/9+XdmpMSxNc1TgJcTl46e4alDssjiitIhpUKd4w4hA=";
    bootstrap = ./bootstrap/bootstrap122.nix;
    iana-patch = ./patches/1.23/iana-etc-1.17.patch;
    buildGoModuleSuffix = "124";
  };

  v1_25 = {
    version = "1.25.4";
    src-hash = "sha256-FgBDt/F7bWC1A2lDaRf9qNUDRkC6Oa4kMca5WoicyYw=";
    bootstrap = ./bootstrap/bootstrap122.nix;
    iana-patch = ./patches/1.25/iana-etc-1.25.patch;
    buildGoModuleSuffix = "125";
  };

  v1_26 = {
    version = "1.26.3";
    src-hash = "sha256-HGRoddCqh5kTMYTtV895/yS97+jIggRwYCqdPW2Rkrg=";
    bootstrap = ./bootstrap/bootstrap122.nix;
    iana-patch = ./patches/1.25/iana-etc-1.25.patch;
    buildGoModuleSuffix = "126";
    bootstrapGo = buildPackages: buildPackages.go.v1_25;
  };

}
