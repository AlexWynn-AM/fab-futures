# Fab Futures: Microelectronics

A 4-week hands-on course where you design, simulate, and tape out your own chip.

## What You'll Build

Pick a project and take it from Verilog to GDS:

| Project | Description |
|---------|-------------|
| **Fortune Teller** | Magic 8-ball — press a button, get a fortune |
| **Pocket Synth** | 4-button musical instrument |
| **Dice Roller** | Hardware random dice with 7-segment display |
| **LED Messenger** | Scroll your name on NeoPixel LEDs |

All projects use the same RTL-to-GDS flow. You'll learn digital design, synthesis, place & route, and verification — with a chip you actually want to demo.

## Repository Structure

```
fab-futures/
├── examples/           # Starter projects with full source & testbenches
│   ├── fortune_teller/
│   ├── pocket_synth/
│   ├── dice_roller/
│   ├── led_messenger/
│   └── lib/            # Shared modules (UART, debounce)
├── designs/            # Your work goes here
├── class-overview.md   # Full 4-week curriculum
└── IIC-OSIC-TOOLS/     # Docker-based EDA toolchain
```

## Quick Start

### 1. Install Docker

- [Get Docker](https://docs.docker.com/get-docker/)
- Make sure Docker Desktop is **running**

### 2. Start the Environment

```bash
./run-iic-osic-tools.sh
```

### 3. Open in Browser

Go to [http://localhost:8080](http://localhost:8080) (password: `abc123`)

You'll get a full Linux desktop with all the EDA tools pre-installed:
- **Xschem** — schematic capture
- **ngspice** — SPICE simulation
- **Yosys** — synthesis
- **OpenROAD** — place & route
- **Magic / KLayout** — layout viewing
- **Icarus Verilog** — simulation
- **GTKWave** — waveform viewer

### 4. Run Your First Simulation

Inside the container:

```bash
cd /foss/designs
cp -r /path/to/examples/fortune_teller .
cd fortune_teller
iverilog -o sim.vvp -I../lib fortune_teller.v fortune_teller_tb.v ../lib/*.v
vvp sim.vvp
```

## Course Overview

| Week | Topics |
|------|--------|
| **1** | Foundations — semiconductors, dev pipeline, PDK setup, analog basics |
| **2** | Schematic & Fabrication — SPICE, layout, DRC/LVS |
| **3** | Digital Design — RTL, synthesis, place & route, timing |
| **4** | Testing & Integration — packaging, verification, presentations |

See [`class-overview.md`](class-overview.md) for the full curriculum with homework assignments.

## Example Projects

Each example includes:
- Heavily commented Verilog (designed for beginners)
- Working testbench with simulation instructions
- Concepts explained inline (state machines, timing, protocols)

See [`examples/README.md`](examples/README.md) for project details and customization ideas.

## Tools & PDKs

This course uses [IIC-OSIC-TOOLS](https://github.com/iic-jku/IIC-OSIC-TOOLS), an all-in-one Docker container with open-source EDA tools.

Supported PDKs:
- **SkyWater 130nm** (sky130A) — primary
- **GlobalFoundries 180nm** (gf180mcuD)
- **IHP 130nm** (ihp-sg13g2)

## Alternative Modes

From the `IIC-OSIC-TOOLS/` directory:

```bash
./start_shell.sh    # Terminal only (no GUI)
./start_jupyter.sh  # Jupyter notebooks
./start_x.sh        # Local X11 (XQuartz on Mac)
```

## Resources

- [Fab Futures Program](https://futures.academany.org/classes/microelectronics/) — official Academany microelectronics course
- [IIC-OSIC-TOOLS Documentation](https://github.com/iic-jku/IIC-OSIC-TOOLS)
- [SkyWater PDK Documentation](https://skywater-pdk.readthedocs.io/)
- [OpenROAD Documentation](https://openroad.readthedocs.io/)
- [Zero to ASIC Course](https://zerotoasiccourse.com/) — Matt Venn's course on chip design
