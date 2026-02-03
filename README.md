# Fab Futures

[IIC-OSIC-TOOLS](https://github.com/iic-jku/IIC-OSIC-TOOLS) — all-in-one Docker image for SKY130/GF180/IHP130-based analog and digital chip design.

## Prerequisites

- **Docker** ([Install](https://docs.docker.com/get-docker/))
- **Docker Desktop** must be **running** (on macOS/Windows)

## Quick start

1. **Start the container** (run in your system terminal, not from Cursor’s integrated terminal if you hit Docker issues):

   ```bash
   ./run-iic-osic-tools.sh
   ```

2. **Open in browser:** [http://localhost:8080](http://localhost:8080)  
   - noVNC password: `abc123`

3. Use the XFCE desktop in the browser to run **Magic**, **KLayout**, **Xschem**, **OpenROAD**, **Yosys**, and other tools.

## Options

- **Designs directory:** Stored in `./designs` (mounted as `/foss/designs` in the container). Override with `DESIGNS=/path/to/designs ./run-iic-osic-tools.sh`.
- **Port:** Default web port is `8080`. Use `WEBSERVER_PORT=80 ./run-iic-osic-tools.sh` if you prefer port 80 (may require `sudo` on some systems).

## Other modes

From `IIC-OSIC-TOOLS/`:

- **Shell only (no GUI):** `./start_shell.sh`
- **Jupyter:** `./start_jupyter.sh`
- **Local X11 (e.g. XQuartz on Mac):** `./start_x.sh`

See [IIC-OSIC-TOOLS README](IIC-OSIC-TOOLS/README.md) for details, PDK setup (`sak-pdk`), and more.
