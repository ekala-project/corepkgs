{
  v3_10 = {
    version = "3.10.19";
    src-hash = "sha256-yPSlllciAdgd19+R9w4XfhmnDx1ImWi1S1+78pqXwHY=";
  };

  v3_11 = {
    version = "3.11.14";
    src-hash = "sha256-jT7Y7FyIwclfXlWGEqclRQ0kUoE92tXlj9saU7Egm3g=";
  };

  v3_12 = {
    version = "3.12.12";
    src-hash = "sha256-+4WhNBSwKMSboYu9UjwtBVowtWsYuSzkVOosUe3GVsQ=";
  };

  v3_13 = {
    version = "3.13.9";
    src-hash = "sha256-7V7zTNo2z6Lzo0DwfKx+eBT5HH88QR9tNWIyOoZsXGY=";
  };

  v3_14 = {
    version = "3.14.0";
    src-hash = "sha256-Ipna5ULTlc44g6ygDTyRAwfNaOCy9zNgmMjnt+7p8+k=";
  };

  v3_15 = {
    version = "3.15.0a2";
    suffix = "a2";
    src-hash = "sha256-2KCi9Kfz1wkM8ZXoGBTv6V9wVUlVVX9A4UnYaUpmJ1E=";
  };

  minimal = {
    withMinimalDeps = true;
    pythonAttr = "python3Minimal";
  };
}
