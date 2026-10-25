{
  v2_6 = {
    version = "2.6.10";
    src-hash = "sha256-youaF9YERkGUwN0sg6IzV8OAyahSDbFt0psn/p4iOVY=";
    cargo-hash = "sha256-goaqxj8Y5Gqo4et4AkyZ3Uv74Q3M3V0VExUA/AMYNMI=";
    librusty-v8-version = "145.0.0";
    librusty-v8-hashes = {
      x86_64-linux = "sha256-chV1PAx40UH3Ute5k3lLrgfhih39Rm3KqE+mTna6ysE=";
      aarch64-linux = "sha256-4IivYskhUSsMLZY97+g23UtUYh4p5jk7CzhMbMyqXyY=";
      aarch64-darwin = "sha256-yHa1eydVCrfYGgrZANbzgmmf25p7ui1VMas2A7BhG6k=";
    };
    build-features = [ "__vendored_zlib_ng" ];
  };

  v2_9 = {
    version = "2.9.6";
    src-hash = "sha256-4X7IfQk9NJizhZKqH2EuDnSfk8axkKFyiZEv1FOfWTM=";
    cargo-hash = "sha256-EKRC+wqIos9O0GHaxjmb/ghyzV6oCi1qwhO2tjszWR4=";
    librusty-v8-version = "150.4.0";
    librusty-v8-hashes = {
      x86_64-linux = "sha256-9IdiyhDR8fxgWkQcWuQw7Izh6egPFNePvELLh4wwtHY=";
      aarch64-linux = "sha256-U54oOBWjlqV5bzKFi0LlF7hY66rqqtBdAykO6MhkpSc=";
      aarch64-darwin = "sha256-Wu/9jVoMG3msHXCvg9WxkJllX9nGRaeU3EPxAfd5g4w=";
    };
    build-features = [ "v8" ];
  };
}
