# Fab Futures: Microelectronics

**Format:** 4 weeks, 2 sessions per week

---

## Course Project: Build a Chip That Transmits Some Data!

Students build a chip that transmits data over serial (UART). A reference UART TX module is provided (~50 lines of Verilog). Students implement the data source (~10-30 lines), then take the complete design through the RTL-to-GDS flow.

**Base design:**
- UART TX module (provided): baud generator, shift register, FSM
- Data source (student-designed): generates bytes to transmit
- Top-level wrapper connecting data source to UART TX

**Extension options:**
- Message ROM: transmit your name or a phrase on startup
- Counter: transmit incrementing numbers on a timer
- LFSR: transmit pseudo-random bytes
- Button interface: transmit characters based on input pins
- Pattern generator: transmit a repeating sequence (morse code, musical notes, etc.)
- Timer: transmit elapsed time periodically
- UART RX: make it bidirectional (advanced)

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
- Brainstorm: What do you want your chip to transmit? A message? Counter? Random numbers?

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
- Sketch block diagram for your UART project: data source + UART TX

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
- Write Verilog for your data source module (10-30 lines)
- Connect to provided UART TX module, create top-level wrapper
- Simulate with testbench, view waveforms
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
- Document: what your chip transmits, pin assignments, baud rate
- Create test plan: how to verify output works
- Prepare presentation for Thursday

### Thursday: Presentations & Discussion

**Lecture:**
- Student project presentations
- Discussion and Q&A

**Project homework:**
- Present your design: what it transmits, block diagram, waveforms, layout screenshot
- Reflect on the process: what worked, what was difficult, ideas for future work