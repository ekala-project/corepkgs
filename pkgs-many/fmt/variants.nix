{
  v9 = rec {
    version = "9.1.0";
    src-hash = "sha256-rP6ymyRc7LnKxUXwPpzhHOQvpJkpnRFOt2ctvUNlYI0=";
    patches = [
      {
        # Fixes the build with Clang ≥ 18.
        url = "https://github.com/fmtlib/fmt/commit/c4283ec471bd3efdb114bc1ab30c7c7c5e5e0ee0.patch";
        hash = "sha256-YyB5GY/ZqJQIhhGy0ICMPzfP/OUuyLnciiyv8Nscsec=";
      }
    ];
  };
  v10 = rec {
    version = "10.2.1";
    src-hash = "sha256-pEltGLAHLZ3xypD/Ur4dWPWJ9BGVXwqQyKcDWVmC3co=";
  };
  v11 = rec {
    version = "11.2.0";
    src-hash = "sha256-sAlU5L/olxQUYcv8euVYWTTB8TrVeQgXLHtXy8IMEnU=";
    patches = [
      {
        # Fixes the build with libc++ ≥ 21.
        url = "https://github.com/fmtlib/fmt/commit/3cabf3757b6bc00330b55975317b2c145e4c689d.patch";
        hash = "sha256-SJFzNNC0Bt2aEQJlHGc0nv9KOpPQ+TgDX5iuFMUs9tk=";
      }
    ];
  };
  v12 = rec {
    version = "12.0.0";
    src-hash = "sha256-AZDmIeU1HbadC+K0TIAGogvVnxt0oE9U6ocpawIgl6g=";
  };
}
