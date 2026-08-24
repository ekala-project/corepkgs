{
  # Version variants
  v4 = {
    version = "4.4.6";
    src-hash = "sha256-IM+1+WJWHuUNHZCVs+eKlmaEkfbvay4vQ2I/GbV1fqk=";
  };

  v6 = {
    version = "6.1.3";
    src-hash = "sha256-NQnPOfiNmurY+L9/B7eVQc2JpOi0jhv5g9kVWsTzpis=";
  };

  v7 = {
    version = "7.1.2";
    src-hash = "sha256-MF/0oSOhxGWuOu6Yat7O68iOvgZ+wKjpQ8zSkwpWXqQ=";
  };

  v8 = {
    version = "8.1.2";
    src-hash = "sha256-wJ3c8VVo/tK84K7bKYs/UWcln4mSO+tf/w5NLNjKhiI=";
  };

  # Build-type variants
  small.ffmpegVariant = "small";
  headless.ffmpegVariant = "headless";
  full.ffmpegVariant = "full";
}
