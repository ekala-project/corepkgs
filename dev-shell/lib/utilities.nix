{ lib, pkgs, processCompose, processComposeConfig, tui, logDir, dataDir }:

let
  # Helper to create a utility script
  mkUtility = name: description: script:
    pkgs.writeShellScriptBin name ''
      set -e

      # Configuration
      CONFIG="${processComposeConfig}"
      LOG_DIR="${logDir}"
      DATA_DIR="${dataDir}"

      ${script}
    '';

  # Start all services
  pc-up = mkUtility "pc-up" "Start all services" ''
    echo "Starting services..."
    echo "Config: $CONFIG"
    echo "Logs: $LOG_DIR"
    echo ""

    # Ensure directories exist
    mkdir -p "$LOG_DIR"
    mkdir -p "$DATA_DIR"

    # Start process-compose
    ${lib.optionalString tui ''
      ${processCompose}/bin/process-compose -f "$CONFIG" up
    ''}
    ${lib.optionalString (!tui) ''
      ${processCompose}/bin/process-compose -f "$CONFIG" up --tui=false
    ''}
  '';

  # Stop all services
  pc-down = mkUtility "pc-down" "Stop all services" ''
    echo "Stopping services..."

    ${processCompose}/bin/process-compose -f "$CONFIG" down 2>/dev/null || true

    echo "Services stopped."
  '';

  # Show service status
  pc-status = mkUtility "pc-status" "Show service status" ''
    ${processCompose}/bin/process-compose -f "$CONFIG" process list 2>/dev/null || {
      echo "No services are currently running."
      echo "Run 'pc-up' to start services."
      exit 0
    }
  '';

  # View logs
  pc-logs = mkUtility "pc-logs" "View service logs" ''
    if [ $# -eq 0 ]; then
      # Show all logs
      echo "Showing logs from: $LOG_DIR"
      echo ""
      if [ -d "$LOG_DIR" ] && [ "$(ls -A "$LOG_DIR" 2>/dev/null)" ]; then
        tail -f "$LOG_DIR"/*.log 2>/dev/null || {
          echo "No log files found yet."
          echo "Start services with 'pc-up' to generate logs."
        }
      else
        echo "No log files found yet."
        echo "Start services with 'pc-up' to generate logs."
      fi
    else
      # Show specific service log
      SERVICE="$1"
      LOG_FILE="$LOG_DIR/$SERVICE.log"
      if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
      else
        echo "Log file not found: $LOG_FILE"
        echo "Available logs:"
        ls -1 "$LOG_DIR"/*.log 2>/dev/null || echo "  (none)"
      fi
    fi
  '';

  # Restart services
  pc-restart = mkUtility "pc-restart" "Restart all services" ''
    echo "Restarting services..."

    if [ $# -eq 0 ]; then
      # Restart all
      ${processCompose}/bin/process-compose -f "$CONFIG" process restart all 2>/dev/null || {
        echo "Services are not running. Starting them..."
        exec ${pc-up}/bin/pc-up
      }
    else
      # Restart specific service
      SERVICE="$1"
      ${processCompose}/bin/process-compose -f "$CONFIG" process restart "$SERVICE"
    fi
  '';

  # Start a specific service
  pc-start = mkUtility "pc-start" "Start a specific service" ''
    if [ $# -eq 0 ]; then
      echo "Usage: pc-start <service-name>"
      exit 1
    fi

    SERVICE="$1"
    ${processCompose}/bin/process-compose -f "$CONFIG" process start "$SERVICE"
  '';

  # Stop a specific service
  pc-stop = mkUtility "pc-stop" "Stop a specific service" ''
    if [ $# -eq 0 ]; then
      echo "Usage: pc-stop <service-name>"
      exit 1
    fi

    SERVICE="$1"
    ${processCompose}/bin/process-compose -f "$CONFIG" process stop "$SERVICE"
  '';

  # Clean service data
  pc-clean = mkUtility "pc-clean" "Clean service data directories" ''
    echo "This will remove all service data in: $DATA_DIR"
    echo "Are you sure? (y/N)"
    read -r response
    case "$response" in
      [yY][eE][sS]|[yY])
        echo "Cleaning service data..."
        rm -rf "$DATA_DIR"
        mkdir -p "$DATA_DIR"
        echo "Done. Data directory cleaned."
        ;;
      *)
        echo "Cancelled."
        ;;
    esac
  '';

in
{
  inherit
    pc-up
    pc-down
    pc-status
    pc-logs
    pc-restart
    pc-start
    pc-stop
    pc-clean
    ;
}
