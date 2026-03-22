{
  minimal = {
    # Basic features only
    opensslSupport = true;
    zlibSupport = true;
    http2Support = true;
    # Explicitly disable extra features
    idnSupport = false;
    pslSupport = false;
    zstdSupport = false;
    http3Support = false;
    c-aresSupport = false;
    brotliSupport = false;
    gssSupport = false;
  };

  v8_17 = rec {
    version = "8.17.0";
    hash = "sha256-lV9ucprWs1ZiYOj+9oYg52ujwxrPChhSRBahhaz3eZI=";
    idnSupport = true;
    pslSupport = true;
    zstdSupport = true;
    http3Support = true;
    c-aresSupport = true;
    brotliSupport = true;
  };

  full = { };

  gnutls = {
    # Use gnutls instead of openssl
    gnutlsSupport = true;
    opensslSupport = false;
  };
}
