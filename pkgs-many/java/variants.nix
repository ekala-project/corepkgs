{
  v11 = {
    version = "11.0.25";
    build = "9";
    # OpenJDK 11 LTS
    src-hash = {
      x86_64-linux = "sha256-GRuqLgUmJ2FAIhcUAKkX0o8Jh9xU2kiq8HsG9VK7mIQ=";
      aarch64-linux = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      x86_64-darwin = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      aarch64-darwin = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };

  v17 = {
    version = "17.0.13";
    build = "11";
    # OpenJDK 17 LTS
    src-hash = {
      x86_64-linux = "sha256-hoKJL8ApZZMLkCLAZvoWTdb0WO9KXcJiAWqigzOzD0k=";
      aarch64-linux = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      x86_64-darwin = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      aarch64-darwin = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };

  v21 = {
    version = "21.0.12";
    build = "8";
    # OpenJDK 21 LTS (Latest LTS)
    src-hash = {
      x86_64-linux = "sha256-5ERv8GonYVVpdZfMDxsV2gBP8IP0lko1Jx7O5WcXc3A=";
      aarch64-linux = "sha256-66OOhxsC1AeJe/4BfqNTUt/BQg720hEkJbDGcyXKUJ0=";
    };
  };

  v23 = {
    version = "23.0.1";
    build = "11";
    # OpenJDK 23 (Latest)
    src-hash = {
      x86_64-linux = "sha256-JAAmfk6cD2rogKTXY69srxjGc3FL3uXev4OIsLXVKIY=";
      aarch64-linux = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      x86_64-darwin = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      aarch64-darwin = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };
}
