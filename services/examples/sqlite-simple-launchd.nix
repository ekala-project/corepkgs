# SQLite service example configured for launchd (macOS)
# This demonstrates cross-platform service definitions with launchd-specific options
{
  pkgs ? import ../../. { },
}:

let
  services = import ../default.nix { inherit pkgs; };

  # A simple script that periodically writes to SQLite
  sqliteLogger = pkgs.writeShellScript "sqlite-logger" ''
    DB_PATH="''${SQLITE_DB:-$HOME/.local/share/sqlite-logger/log.db}"
    mkdir -p "$(dirname "$DB_PATH")"

    # Initialize database
    ${pkgs.sqlite}/bin/sqlite3 "$DB_PATH" "
      CREATE TABLE IF NOT EXISTS logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        message TEXT
      );
    "

    echo "SQLite logger started. Database: $DB_PATH"

    # Log a message every 10 seconds
    while true; do
      MESSAGE="Service running at $(date)"
      ${pkgs.sqlite}/bin/sqlite3 "$DB_PATH" \
        "INSERT INTO logs (message) VALUES ('$MESSAGE');"
      echo "$MESSAGE"

      # Show last 5 entries
      echo "Last 5 log entries:"
      ${pkgs.sqlite}/bin/sqlite3 "$DB_PATH" \
        "SELECT datetime(timestamp, 'localtime'), message FROM logs ORDER BY id DESC LIMIT 5;"

      sleep 10
    done
  '';

  serviceConfig = {
    sqlite-logger = {
      enable = true;
      description = "SQLite Logger - Periodic logging to SQLite database";

      command = sqliteLogger;

      environment = {
        SQLITE_DB = "$HOME/.local/share/sqlite-logger/log.db";
      };

      path = with pkgs; [
        sqlite
        coreutils
      ];

      restartPolicy = "always";

      preStart = ''
        echo "Starting SQLite logger..."
        mkdir -p $HOME/.local/share/sqlite-logger
      '';

      # Launchd-specific options
      launchd = {
        # Custom label using reverse DNS notation
        label = "com.example.sqlite-logger";

        # Start immediately when loaded
        runAtLoad = true;

        # Always keep the service running
        keepAlive = true;

        # Standard process type (normal priority)
        processType = "Standard";

        # Set working directory
        # workingDirectory = "$HOME/.local/share/sqlite-logger";

        # Resource limits
        softResourceLimits = {
          NumberOfFiles = 256;
          NumberOfProcesses = 64;
        };

        # Extra launchd options
        extraConfig = {
          # Use legacy timers for compatibility
          LegacyTimers = true;

          # Wait 5 seconds between restart attempts
          ThrottleInterval = 5;
        };
      };

      # Also include systemd config for cross-platform compatibility
      systemd = {
        wantedBy = [ "default.target" ];

        serviceConfig = {
          RestartSec = 5;
          PrivateTmp = true;
          NoNewPrivileges = true;
        };
      };
    };
  };

in
{
  # Build the launchd plist file for user agents
  launchdUserAgent = services.buildLaunchdUserAgents serviceConfig;

  # Also build systemd version for comparison
  systemdService = services.buildSystemdUserServices serviceConfig;

  # Export for inspection
  inherit serviceConfig sqliteLogger;
}
