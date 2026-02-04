# Fab Futures: Microelectronics

**Format:** 4 weeks, 2 sessions per week

---

## Course Project: Build Something You Want to Demo

You're going to design, simulate, and tape out a chip. Not a textbook exercise—something you'd actually want to show people.

Pick a project:

| Project | What it does | I/O |
|---------|--------------|-----|
| **Fortune Teller** | Magic 8-ball on silicon. Press button, get fortune. | Button, LED, serial |
| **Pocket Synth** | 4-note musical instrument. Press buttons, make tones. | 4 buttons, speaker, LEDs |
| **Dice Roller** | Hardware random dice with rolling animation. | Button, 7-segment, LED |
| **LED Messenger** | Scroll your name on NeoPixel LEDs. | Button, LED strip data |
| **Your Idea** | Pitch something that fits the constraints. | ~5-10 pins total |

All projects use the same RTL-to-GDS flow. The difference is what your chip *does*.

**Constraints:**
- ~200-500 gates (keeps P&R fast, fits educational tapeout)
- Single clock domain (50 MHz)
- 5-10 I/O pins
- Must simulate correctly before synthesis

**What we provide:**
- Working example designs with testbenches (see `examples/`)
- Shared library modules (UART, debounce, etc.)
- Complete toolchain in Docker container
- Reference documentation for each step

**What you build:**
- Customize an example *or* design your own
- Write/modify ~30-100 lines of Verilog
- Take it through the full flow: simulate → lint → synthesize → P&R → GDS
- Demo your chip at the end of week 4

---

## Week 1: Foundations

### Tuesday: Introduction & Development Pipeline

**Lecture:**
- Overview of semiconductor chips and systems: microcontrollers, CPUs, DACs/ADCs/DSP, sensors
- From transistor to IC to board to system: why this matters
- Resources for study, tools, and low-cost tapeout options for hobbyists and independent designers
- Development pipeline: code, test, synthesize, physical, verification, manufacture, packaging, eval board, test
- Overview of tools and ecosystem
- PDK setup and configuration (Sky130, GF180, IHP)
- Version control basics with git for hardware projects

**Project homework:**
- Install course toolchain (instructions provided) or set up VM/container
- Run hello world synthesis on a simple design
- Verify tools work end-to-end before Thursday

### Thursday: Analog Basics *(JV)*

**Lecture:**
- Wires: metal differences, tapeout considerations
- Passive components: inductance, capacitance, resistance
- Timing, noise, and signal fidelity implications
- Transistors as switches: comparators, flip-flops
- Transistors as amplifiers
- Device models and levels: complexity vs. simulation accuracy tradeoffs
- Power sources, grounding practices, and power grid basics
- Clock distribution fundamentals

**Project homework:**
- Simulate a PDK inverter in SPICE: measure delay from input to output
- Sweep the input slew rate - how does it affect delay and power?
- Look at the transistor-level schematic - identify PMOS and NMOS, understand sizing

---

## Week 2: Schematic Capture & Fabrication

### Tuesday: Schematic Design & Simulation *(JV)*

**Lecture:**
- Schematic capture process and workflow
- SPICE simulation (e.g., LTspice, ngspice)
- Libraries and PDKs: finding and configuring them
- Behavioral modeling and abstraction levels
- Layout process fundamentals
- Cell creation and common pitfalls

**Project homework:**
- Draw schematic for a 2-input NAND gate using PDK cells
- Simulate in SPICE: verify truth table, measure propagation delay
- Pick your project: Fortune Teller? Synth? Dice? LEDs? Something else?

### Thursday: Fabrication Basics *(AW)*

**Lecture:**
- Layout to manufacturing (GDS, KLayout)
- Design Rule Check (DRC)
- Layout vs. Schematic (LVS)
- Tapeout process and layout acceptance
- Fabrication process overview (including DIY microfab)
- Corner analysis and process variation

**Project homework:**
- Hand-draw layout for an inverter using PDK layers
- Run DRC - fix any errors
- Sketch block diagram for your project: what are the major components?

---

## Week 3: Digital Design

### Tuesday: RTL Design & Verification *(AO)*

**Lecture:**
- HDL languages: SystemVerilog, Verilog, VHDL, Chisel, Python-based flows
- Design methodology: coding style, synchronous design principles, common mistakes
- Core concepts: flip-flops, latches, reset, state machines, pipelines
- Reset synchronization and clock domain considerations
- IP reuse, library design, and memory integration (OpenRAM)
- Development environment: editors (VS Code, Emacs)
- Linting tools: Verilator, pyslang
- Testbench development: Icarus Verilog, cocotb
- Waveform viewing: GTKWave

**Project homework:**
- Write/modify Verilog for your project (start from an example or scratch)
- Create top-level wrapper, connect any library modules you need
- Simulate with testbench, view waveforms in GTKWave
- Run linter, fix any warnings

### Thursday: Synthesis & Physical Design *(AO)*

**Lecture:**
- Logic synthesis with Yosys
- Place and route basics with OpenROAD
- Clock tree synthesis
- Power planning and grid design
- Static timing analysis with OpenSTA
- Interpreting timing reports, fixing violations

**Project homework:**
- Synthesize your design - review gate count, check for unintended latches
- Run place and route flow
- Check timing reports - any violations? Fix if needed
- Generate GDS, view layout - find your flip-flops, trace the clock

---

## Week 4: Testing & System Integration

### Tuesday: Packaging & Board Design *(AW)*

**Lecture:**
- Package design and wirebonding diagrams (KiCad)
- Evaluation board design (KiCad)
- I/O planning and constraints
- Simple testing: embedded design, FPGA, microcontrollers
- Production testing: ATE, scan chains, fault coverage
- Design-for-debug and silicon debug techniques

**Project homework:**
- Run DRC/LVS on final design - fix any errors
- Document: what your chip does, pin assignments, how to test it
- Create test plan: how will you verify it works on real hardware?
- Prepare presentation/demo for Thursday

### Thursday: Presentations & Discussion

**Lecture:**
- Student project presentations
- Discussion and Q&A

**Project homework:**
- Demo your design: show it working (simulation or FPGA), explain what it does
- Present: block diagram, key waveforms, layout screenshot, gate count
- Reflect: what worked, what was hard, what you'd do differently