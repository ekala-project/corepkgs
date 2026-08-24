{
  v1_24 = {
    version = "1.24.0";
    src-hash = "sha256-gokkh6Aa1nszTsqDtUMXp8hqA6ic+trP71IR8RpdBTY=";
    patches = [ ./darwin.patch ];
  };
  v1_26 = {
    version = "1.26.0";
    src-hash = "sha256-ZBduqkbklpkD4ob45e+DMa/8F/3wOsm1g4HSsjFit6M=";
    patches = [ ./darwin.patch ];
  };
  scanner = {
    isScanner = true;
  };
}
