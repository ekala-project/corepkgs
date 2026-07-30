{
  v1_17 = {
    version = "1.17.3";
    # Elixir 1.17 (Compatible with OTP 25-27)
    # NOTE: Currently has build issues with reference escaping
    src-hash = "sha256-YRbBTV5h7DASQM6+rL+elxJaTUXNkHHmXguVjV6/OJA=";
    minimumOTPVersion = "25";
  };

  v1_18 = {
    version = "1.20.2";
    # Elixir 1.18 (Latest, Compatible with OTP 25-27)
    # NOTE: Requires Erlang 27 (incompatible with Erlang 28 due to reference escaping issues)
    src-hash = "sha256-GiW7+akBZlH8My7swCu5aB0LjnIsLiVuc924j7zm5rA=";
    minimumOTPVersion = "25";
  };
}
