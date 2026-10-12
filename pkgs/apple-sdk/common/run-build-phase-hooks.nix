{ }:

self: super: {
  buildPhase = ''
    ${super.buildPhase or ""}
  '';
}
