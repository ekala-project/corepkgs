# Simple SQLite service example using just bash and sqlite3
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
        SQLITE_DB = "%h/.local/share/sqlite-logger/log.db";
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

      postStart = ''
        echo "SQLite logger is running"
      '';

      # Systemd-specific options
      systemd = {
        wantedBy = [ "default.target" ];

        serviceConfig = {
          # Restart configuration
          RestartSec = 5;

          # Basic security
          PrivateTmp = true;
          NoNewPrivileges = true;
        };
      };
    };
  };

in
{
  # Build the systemd service file
  systemdService = services.buildSystemdUserServices serviceConfig;

  # Also export for inspection
  inherit serviceConfig sqliteLogger;
}
