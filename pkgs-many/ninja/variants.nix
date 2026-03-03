{
  v1_11 = rec {
    version = "1.11.1";
    src-hash = "sha256-LvV/Fi2ARXBkfyA1paCRmLUwCh/rTyz+tGMg2/qEepI=";
    buildDocs = false;
  };

  v1_13 = rec {
    version = "1.13.2";
    src-hash = "sha256-D9HsIjv8EJ1qAdXFAKy260K77cCvopgQ2Fx6uXpt6VI=";
    buildDocs = false;
  };

  withDocs = {
    buildDocs = true;
  };
}
