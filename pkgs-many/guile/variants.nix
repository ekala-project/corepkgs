{
  v1_8 = {
    version = "1.8.8";
    src-hash = "sha256-w0cf7S5y5bBK0TO7qvFjaeg2AoNnm88ZgAvBs4ECQFA=";
    setupHook = ./setup-hook-1.8.sh;
  };

  v2_0 = {
    version = "2.0.13";
    src-hash = "sha256-N0TyrdwoKg3mJ6rvBI8GKYK0RWTVSsMf9SF5clKe2Is=";
    setupHook = ./setup-hook-2.0.sh;
  };

  v2_2 = {
    version = "2.2.7";
    src-hash = "sha256-zfd26l8pQwsSWCCWMFVb7qbSvlSB+dpNZJhrB3/zdQQ=";
    setupHook = ./setup-hook-2.2.sh;
  };

  v3_0 = {
    version = "3.0.10";
    src-hash = "sha256-vXFoUX/VJjM0RtT3q4FlJ5JWNAlPvTcyLhfiuNjnY4g=";
    setupHook = ./setup-hook-3.0.sh;
  };
}
