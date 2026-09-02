{
  v2_6 = {
    version = "2.6.10";
    src-hash = "sha256-youaF9YERkGUwN0sg6IzV8OAyahSDbFt0psn/p4iOVY=";
    cargo-hash = "sha256-goaqxj8Y5Gqo4et4AkyZ3Uv74Q3M3V0VExUA/AMYNMI=";
    librusty-v8-version = "145.0.0";
    librusty-v8-hashes = {
      x86_64-linux = "sha256-chV1PAx40UH3Ute5k3lLrgfhih39Rm3KqE+mTna6ysE=";
      aarch64-linux = "sha256-4IivYskhUSsMLZY97+g23UtUYh4p5jk7CzhMbMyqXyY=";
      x86_64-darwin = "sha256-1jUuC+z7saQfPYILNyRJanD4+zOOhXU2ac/LFoytwho=";
      aarch64-darwin = "sha256-yHa1eydVCrfYGgrZANbzgmmf25p7ui1VMas2A7BhG6k=";
    };
    build-features = [ "__vendored_zlib_ng" ];
  };

  v2_9 = {
    version = "2.9.6";
    src-hash = "sha256-4X7IfQk9NJizhZKqH2EuDnSfk8axkKFyiZEv1FOfWTM=";
    # TODO: compute cargoHash by building with lib.fakeHash
    cargo-hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    librusty-v8-version = "150.4.0";
    librusty-v8-hashes = {
      x86_64-linux = "sha256-WGn9twcbHyHyAKl86X0gElh34PMc2ALtmd4sU/SIsGw=";
      aarch64-linux = "sha256-txd9Uq0zNycv4NO453gjnIIalcJdWVnexiue/WVPfdM=";
      x86_64-darwin = "sha256-5ex9E/kUgT6/IB1Ee/j9J2h7exkuFsR/KCb+VBUXHyk=";
      aarch64-darwin = "sha256-zNj4FIW4IsWxiuun+d65KaM4LYasZzu/DzZvBod+axA=";
    };
    build-features = [ "v8" ];
  };
}
