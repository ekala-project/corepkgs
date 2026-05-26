{
  openssh = {
    pname = "openssh";
    version = "10.2p1";
    src-hash = "sha256-zMQsBBmTeVkmP6Hb0W2vwYxWuYTANWLSk3zlamD3mLI=";
    etcDir = "/etc/ssh";
  };

  kerberos = {
    pname = "openssh";
    version = "10.2p1";
    src-hash = "sha256-zMQsBBmTeVkmP6Hb0W2vwYxWuYTANWLSk3zlamD3mLI=";
    etcDir = "/etc/ssh";
    enableKerberos = true;
  };

  hpn = {
    pname = "openssh-with-hpn";
    version = "10.2p1";
    src-hash = "sha256-zMQsBBmTeVkmP6Hb0W2vwYxWuYTANWLSk3zlamD3mLI=";
    extraDesc = " with high performance networking patches";
    variant = "hpn";
    etcDir = "/etc/ssh";
  };

  hpn-kerberos = {
    pname = "openssh-with-hpn";
    version = "10.2p1";
    src-hash = "sha256-zMQsBBmTeVkmP6Hb0W2vwYxWuYTANWLSk3zlamD3mLI=";
    extraDesc = " with high performance networking patches";
    variant = "hpn";
    etcDir = "/etc/ssh";
    enableKerberos = true;
  };

  gssapi = {
    pname = "openssh-with-gssapi";
    version = "10.2p1";
    src-hash = "sha256-zMQsBBmTeVkmP6Hb0W2vwYxWuYTANWLSk3zlamD3mLI=";
    extraDesc = " with GSSAPI support";
    variant = "gssapi";
    etcDir = "/etc/ssh";
    enableKerberos = true;
  };
}
