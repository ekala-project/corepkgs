{
  v1_24 = {
    version = "1.24.0";
    src-hash = "sha256-gokkh6Aa1nszTsqDtUMXp8hqA6ic+trP71IR8RpdBTY=";
    patches = [ ./darwin.patch ];
  };
  scanner = {
    isScanner = true;
  };
}
