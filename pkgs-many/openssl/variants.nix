{
  v1_1 = {
    version = "1.1.1w";
    src-hash = "sha256-zzCYlQy02FOtlcCEHx+cbT3BAtzPys1SHZOSUgi3asg=";
    nix-ssl-cert-file-patch = ./1.1/nix-ssl-cert-file.patch;
    use-etc-ssl-certs-patch = ./use-etc-ssl-certs.patch;
    use-etc-ssl-certs-darwin-patch = ./use-etc-ssl-certs-darwin.patch;
    withDocs = true;
    extraMeta = {
      knownVulnerabilities = [
        "OpenSSL 1.1 is reaching its end of life on 2023/09/11 and cannot be supported through the NixOS 23.11 release cycle. https://www.openssl.org/blog/blog/2023/03/28/1.1.1-EOL/"
      ];
    };
  };

  v3_0 = {
    version = "3.0.18";
    src-hash = "sha256-2Aw09c+QLczx8bXfXruG0DkuNwSeXXPfGzq65y5P/os=";
    nix-ssl-cert-file-patch = ./3.0/nix-ssl-cert-file.patch;
    kernel-detection-patch = ./3.0/openssl-disable-kernel-detection.patch;
    use-etc-ssl-certs-patch = ./use-etc-ssl-certs.patch;
    use-etc-ssl-certs-darwin-patch = ./use-etc-ssl-certs-darwin.patch;
    withDocs = true;
    extraMeta = { };
  };

  v3_6 = {
    version = "3.6.0";
    src-hash = "sha256-tqX0S362nj+jXb8VUkQFtEg3pIHUPYHa3d4/8h/LuOk=";
    nix-ssl-cert-file-patch = ./3.0/nix-ssl-cert-file.patch;
    kernel-detection-patch = ./3.0/openssl-disable-kernel-detection.patch;
    use-etc-ssl-certs-patch = ./3.5/use-etc-ssl-certs.patch;
    use-etc-ssl-certs-darwin-patch = ./3.5/use-etc-ssl-certs-darwin.patch;
    mingw-linking-patch = ./3.5/fix-mingw-linking.patch;
    withDocs = true;
    extraMeta = { };
  };
}
