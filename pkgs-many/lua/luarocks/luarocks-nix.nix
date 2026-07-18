{
  luarocks_bootstrap,
  fetchFromGitHub,
  file,
  nurl,
}:

luarocks_bootstrap.overrideAttrs (old: {
  pname = "luarocks-nix";
  version = "nix_v3.5.0-1-unstable-2026-03-31";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "luarocks-nix";
    rev = "3a9f4bff6cdda670f866fb9f755d548a714f680a";
    hash = "sha256-6DLy1scf6K1fWDgrORcd1gtymgxtPwwAMIzMG2Bn1Pw=";
  };

  propagatedNativeBuildInputs = old.propagatedNativeBuildInputs ++ [
    file
    nurl
  ];

  patches = [ ];

  doInstallCheck = false;

  meta = {
    inherit (old.meta)
      description
      license
      platforms
      ;
    homepage = "https://github.com/nix-community/luarocks-nix";
    mainProgram = "luarocks";
  };
})
