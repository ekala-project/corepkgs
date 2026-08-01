{
  v1_24 = {
    version = "1.24.11";
    src-hash = "sha256-/9+XdmpMSxNc1TgJcTl46e4alDssjiitIhpUKd4w4hA=";
    bootstrap = ./bootstrap/bootstrap122.nix;
    iana-patch = ./patches/1.23/iana-etc-1.17.patch;
    buildGoModuleSuffix = "124";
  };

  v1_25 = {
    version = "1.25.12";
    src-hash = "sha256-+Q3O5L0CP6N2N06gpabr5VNTeznEJv/YxolGm0VRmTI=";
    bootstrap = ./bootstrap/bootstrap122.nix;
    iana-patch = ./patches/1.25/iana-etc-1.25.patch;
    buildGoModuleSuffix = "125";
  };

  v1_26 = {
    version = "1.26.5";
    src-hash = "sha256-SVvkvIcXasVnOS5bQRar2YRm0z17SdQedkzMaXay3EI=";
    bootstrap = ./bootstrap/bootstrap122.nix;
    iana-patch = ./patches/1.25/iana-etc-1.25.patch;
    buildGoModuleSuffix = "126";
    bootstrapGo = buildPackages: buildPackages.go.v1_25;
  };

}
