{
  v1_11 = rec {
    version = "1.11.1";
    src-hash = "sha256-LvV/Fi2ARXBkfyA1paCRmLUwCh/rTyz+tGMg2/qEepI=";
    buildDocs = false;
  };

  v1_13 = rec {
    version = "1.13.1";
    src-hash = "sha256-GhAF5wUT19E02ZekW+ywsCMVGYrt56hES+MHCH4lNG4=";
    buildDocs = false;
  };

  withDocs = {
    buildDocs = true;
  };
}
