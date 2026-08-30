{
  v1_17 = {
    version = "1.17.3";
    # Elixir 1.17 (Compatible with OTP 25-27)
    src-hash = "sha256-YRbBTV5h7DASQM6+rL+elxJaTUXNkHHmXguVjV6/OJA=";
    minimumOTPVersion = "25";
    # The default erlang (v27) is actually OTP 29, which is incompatible.
    # Pin to erlang v26 (OTP 26) which is within the supported range.
    erlangVariant = "v26";
  };

  v1_18 = {
    version = "1.20.3";
    # Elixir 1.18 (Latest, Compatible with OTP 25-27)
    # NOTE: Requires Erlang 27 (incompatible with Erlang 28 due to reference escaping issues)
    src-hash = "sha256-/yKolLEwYxRD2xoZO06MtHYvaXEoVm5D2oSP0Ww3d70=";
    minimumOTPVersion = "25";
    # The default erlang (v27) is actually OTP 29, which is incompatible.
    # Pin to erlang v26 (OTP 26) which is within the supported range.
    erlangVariant = "v26";
  };
}
