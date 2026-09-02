{
  v0_13 = rec {
    version = "0.13.0";
    src-url = "https://ziglang.org/download/${version}/zig-${version}.tar.xz";
    src-hash = "sha256-Bsc1lr7sy3HMBzgFvbnA4FdkEo8WR4+lO/F9+rwdQxg=";
    llvm-major = "18";
  };

  v0_14 = rec {
    version = "0.14.1";
    src-url = "https://ziglang.org/download/${version}/zig-${version}.tar.xz";
    src-hash = "sha256-I3+KvMjD/WjHDGbNv2Pc5Pta1KLmIlrJJePVtMOI8gM=";
    llvm-major = "19";
  };

  v0_15 = rec {
    version = "0.15.2";
    src-url = "https://ziglang.org/download/${version}/zig-${version}.tar.xz";
    src-hash = "sha256-2bMMeqmD/P9e7SCE1UroPqr+f/OoTY+3VNhUFlpuUhw=";
    llvm-major = "20";
  };

  v0_16 = rec {
    version = "0.16.0";
    src-url = "https://ziglang.org/download/${version}/zig-${version}.tar.xz";
    src-hash = "sha256-QxhpWe3IfVx6G+e30qJe//0izlgHx6+ZBn+G+ZZBv98=";
    llvm-major = "21";
  };
}
