# Simple development shell example with a single HTTP server service
{ pkgs ? import ../../. { } }:

pkgs.mkDevShell {
  # Service configuration using ekaos modules
  modules = [
    {
      services.http-server = {
        enable = true;
        description = "Simple HTTP Server for Development";

        # Use Python's built-in HTTP server
        command = "${pkgs.python3}/bin/python3";
        args = [ "-m" "http.server" "8080" "--bind" "127.0.0.1" ];

        workingDirectory = toString ./.;

        environment = {
          PORT = "8080";
        };

        restartPolicy = "always";

        # Lifecycle hooks
        preStart = ''
          echo "Starting HTTP server on http://127.0.0.1:8080"
          mkdir -p ./www
          echo "<h1>Hello from mkDevShell!</h1>" > ./www/index.html
        '';
      };
    }
  ];

  # Development tools
  packages = with pkgs; [
    curl
  ];

  # Custom shell hook
  shellHook = ''
    echo "Simple HTTP Server Example"
    echo ""
    echo "The server will run on: http://127.0.0.1:8080"
    echo ""
    echo "Try:"
    echo "  1. Start the server: pc-up"
    echo "  2. Test it: curl http://127.0.0.1:8080/index.html"
    echo "  3. Stop the server: Ctrl+C or pc-down"
    echo ""
  '';

  # Process compose configuration
  processCompose = {
    tui = true;
    autoStart = false;
    logDir = "./.dev/logs";
    dataDir = "./.dev/data";
  };
}
