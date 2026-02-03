#!/usr/bin/env bash
# Run IIC-OSIC-TOOLS VNC desktop.
# Usage: ./run-iic-osic-tools.sh
# Then open http://localhost:8080 in your browser (default VNC password: abc123).
#
# Ensure Docker Desktop is running before executing.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESIGNS="${DESIGNS:-$SCRIPT_DIR/designs}"
WEBSERVER_PORT="${WEBSERVER_PORT:-8080}"

mkdir -p "$DESIGNS"
echo "[INFO] Designs directory: $DESIGNS"
echo "[INFO] Web UI will be at http://localhost:$WEBSERVER_PORT (noVNC)"
echo ""

cd "$SCRIPT_DIR/IIC-OSIC-TOOLS"
DESIGNS="$DESIGNS" WEBSERVER_PORT="$WEBSERVER_PORT" ./start_vnc.sh
