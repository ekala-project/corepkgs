# .NET SDK — binary download
#
# Simplified port: provides the .NET 10 SDK as a prebuilt binary.
# Skips the full nixpkgs scope/wrapper/NuGet infrastructure.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  zlib,
  icu,
  libkrb5,
  curl,
  openssl,
  libunwind,
  libuuid,
}:

let
  version = "10.0.400";
  runtimeVersion = "10.0.11";

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://builds.dotnet.microsoft.com/dotnet/Sdk/${version}/dotnet-sdk-${version}-linux-x64.tar.gz";
      hash = "sha512-EDOXfdg3FQ4IFM8MXVsXzrY5Jf2nuiFYtHJYpL18BIz4Lqw7wRZvMUb1MSSj9fugnbHeEmDSzpY5mGAwO0BLSA==";
    };
  };

  rpath = lib.makeLibraryPath [
    zlib
    icu
    libkrb5
    curl
    openssl
    libunwind
    libuuid
    stdenv.cc.cc.lib
  ];
in

stdenv.mkDerivation {
  pname = "dotnet-sdk";
  inherit version;

  src =
    srcs.${stdenv.hostPlatform.system} or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  # lttng-ust is optional (Linux tracing); ignore the missing .so
  autoPatchelfIgnoreMissingDeps = [ "liblttng-ust.so.0" ];

  buildInputs = [
    zlib
    icu
    libkrb5
    curl
    openssl
    libunwind
    libuuid
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/dotnet $out/bin
    cp -r . $out/share/dotnet/
    ln -s $out/share/dotnet/dotnet $out/bin/dotnet

    runHook postInstall
  '';

  # Add explicit .so references that autoPatchelfHook misses (dlopen'd at runtime)
  postFixup = ''
    patchelf --add-needed libicui18n.so $out/share/dotnet/shared/Microsoft.NETCore.App/${runtimeVersion}/libcoreclr.so
    patchelf --add-needed libicuuc.so $out/share/dotnet/shared/Microsoft.NETCore.App/${runtimeVersion}/libcoreclr.so
    patchelf --add-needed libgssapi_krb5.so $out/share/dotnet/shared/Microsoft.NETCore.App/${runtimeVersion}/libcoreclr.so
    patchelf --add-needed libssl.so $out/share/dotnet/shared/Microsoft.NETCore.App/${runtimeVersion}/libcoreclr.so
  '';

  meta = {
    description = "The .NET SDK";
    homepage = "https://dotnet.microsoft.com/";
    license = lib.licenses.mit;
    mainProgram = "dotnet";
    platforms = [ "x86_64-linux" ];
  };
}
