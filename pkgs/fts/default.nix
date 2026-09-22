{
  stdenv,
  musl-fts ? null,
}:
if stdenv.hostPlatform.isMusl then musl-fts else null
