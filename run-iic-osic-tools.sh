#!/usr/bin/env bash
# Run IIC-OSIC-TOOLS VNC desktop for Fab Futures.
# Usage: ./run-iic-osic-tools.sh
# Then open http://localhost:8080 in your browser (default VNC password: abc123).
#
# Ensure Docker Desktop is running before executing.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESIGNS="${DESIGNS:-$SCRIPT_DIR/designs}"
EXAMPLES="$SCRIPT_DIR/examples"
WEBSERVER_PORT="${WEBSERVER_PORT:-8080}"

mkdir -p "$DESIGNS"
echo "=============================================="
echo "  Fab Futures - IIC-OSIC-TOOLS Environment"
echo "=============================================="
echo ""
echo "[INFO] Designs directory: $DESIGNS"
echo "       -> mounted at /foss/designs inside container"
echo ""
echo "[INFO] Examples directory: $EXAMPLES"
echo "       -> mounted at /foss/examples inside container"
echo ""
echo "[INFO] Web UI will be at http://localhost:$WEBSERVER_PORT"
echo "       Default VNC password: abc123"
echo ""
echo "Quick start once inside the container:"
echo "  cd /foss/examples"
echo "  make sim-fortune    # Run Fortune Teller simulation"
echo "  make sim-all        # Run all simulations"
echo ""

cd "$SCRIPT_DIR/IIC-OSIC-TOOLS"

# Mount examples directory (read-write so make can compile simulations)
export DOCKER_EXTRA_PARAMS="-v ${EXAMPLES}:/foss/examples"

DESIGNS="$DESIGNS" WEBSERVER_PORT="$WEBSERVER_PORT" ./start_vnc.sh
