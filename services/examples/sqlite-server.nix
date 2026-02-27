# Example: SQLite HTTP server as a systemd user service
# This demonstrates a simple service that provides a REST API for SQLite queries

{
  pkgs ? import ../../. { },
}:

let
  # Import our service system
  services = import ../default.nix { inherit pkgs; };

  # A simple Python HTTP server that handles SQLite queries
  sqliteServer = pkgs.writeScript "sqlite-server" ''
    #!${pkgs.python3}/bin/python3
    import http.server
    import sqlite3
    import json
    import os
    from urllib.parse import parse_qs, urlparse

    DB_PATH = os.environ.get('SQLITE_DB', os.path.expanduser('~/.local/share/sqlite-server/data.db'))

    # Ensure DB directory exists
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    # Initialize database
    conn = sqlite3.connect(DB_PATH)
    conn.execute('''
        CREATE TABLE IF NOT EXISTS kv_store (
            key TEXT PRIMARY KEY,
            value TEXT,
            updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

    class SQLiteHandler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            conn = sqlite3.connect(DB_PATH)
            cursor = conn.cursor()

            if self.path == '/health':
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'status': 'healthy', 'db': DB_PATH}).encode())
                return

            if self.path.startswith('/get/'):
                key = self.path.split('/get/')[1]
                cursor.execute('SELECT value FROM kv_store WHERE key = ?', (key,))
                row = cursor.fetchone()
                conn.close()

                if row:
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'key': key, 'value': row[0]}).encode())
                else:
                    self.send_response(404)
                    self.end_headers()
                    self.wfile.write(json.dumps({'error': 'Key not found'}).encode())
                return

            # List all keys
            if self.path == '/list':
                cursor.execute('SELECT key, value FROM kv_store')
                rows = cursor.fetchall()
                conn.close()

                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                data = {key: value for key, value in rows}
                self.wfile.write(json.dumps(data).encode())
                return

            self.send_response(404)
            self.end_headers()

        def do_POST(self):
            if self.path == '/set':
                content_length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(content_length)
                data = json.loads(post_data.decode())

                conn = sqlite3.connect(DB_PATH)
                cursor = conn.cursor()
                cursor.execute('''
                    INSERT OR REPLACE INTO kv_store (key, value, updated)
                    VALUES (?, ?, CURRENT_TIMESTAMP)
                ''', (data['key'], data['value']))
                conn.commit()
                conn.close()

                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'status': 'success'}).encode())
                return

            self.send_response(404)
            self.end_headers()

    PORT = int(os.environ.get('PORT', '8080'))
    print(f'Starting SQLite server on port {PORT}')
    print(f'Database: {DB_PATH}')
    httpd = http.server.HTTPServer(('127.0.0.1', PORT), SQLiteHandler)
    httpd.serve_forever()
  '';

  # Define the service
  serviceConfig = {
    sqlite-server = {
      enable = true;
      description = "SQLite HTTP Server - Simple key-value store over HTTP";

      command = sqliteServer;
      args = [ ];

      # Note: For user services, systemd automatically runs as the logged-in user
      # so we don't need to specify user/group explicitly
      environment = {
        PORT = "8080";
        SQLITE_DB = "%h/.local/share/sqlite-server/data.db"; # %h expands to home dir in systemd
      };

      path = with pkgs; [
        python3
        sqlite
      ];

      restartPolicy = "always";

      preStart = ''
        echo "Preparing SQLite server directories..."
        mkdir -p ''${HOME}/.local/share/sqlite-server
      '';

      postStart = ''
        echo "SQLite server started successfully"
      '';

      # Systemd-specific options
      systemd = {
        wantedBy = [ "default.target" ];

        serviceConfig = {
          # Restart configuration
          RestartSec = 5;

          # Security hardening
          PrivateTmp = true;
          NoNewPrivileges = true;

          # Resource limits
          MemoryMax = "256M";
          TasksMax = 10;
        };
      };
    };
  };

in
{
  # Build the systemd service file
  systemdService = services.buildSystemdUserServices serviceConfig;

  # Also export the service config for inspection
  inherit serviceConfig;

  # Provide the server script for testing
  inherit sqliteServer;
}
