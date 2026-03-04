# =============================================================================
# Fab Futures Examples - Build Automation
# =============================================================================
#
# Simulation:
#   make sim-fortune     - Simulate Fortune Teller
#   make sim-synth       - Simulate Pocket Synth
#   make sim-dice        - Simulate Dice Roller
#   make sim-led         - Simulate Morse Beacon
#   make sim-all         - Simulate all projects
#
# ASIC Flow (requires IIC-OSIC-TOOLS or similar environment):
#   make build-fortune   - Full flow: synth + PnR + GDS
#   make build-synth     - Full flow for Pocket Synth
#   make build-dice      - Full flow for Dice Roller
#   make build-led       - Full flow for Morse Beacon
#   make build-all       - Build all projects
#
#   make view-fortune    - View layout in KLayout
#
# Individual steps:
#   make sky130-fortune  - Synthesize to Sky130 cells
#   make pnr-fortune     - Place and route
#   make gds-fortune     - Generate GDS
#
# =============================================================================

# Default shell
SHELL := /bin/bash

# Tools
IVERILOG := iverilog
VVP := vvp
VERILATOR := verilator
YOSYS := yosys
OPENROAD := openroad
MAGIC := magic
KLAYOUT := klayout

# Common options
IVERILOG_FLAGS := -Wall -g2012
VERILATOR_FLAGS := --lint-only -Wall

# Library and flow paths
LIB := lib
FLOW := flow

# Check for PDK
PDK_ROOT ?= $(error PDK_ROOT is not set. Source the IIC-OSIC-TOOLS environment first)

# =============================================================================
# Project definitions
# =============================================================================

# Fortune Teller
FORTUNE_TOP := fortune_teller
FORTUNE_DIR := fortune_teller
FORTUNE_SRC := $(FORTUNE_DIR)/fortune_teller.v $(LIB)/debounce.v $(LIB)/uart_tx.v
FORTUNE_BUILD := $(FORTUNE_DIR)/build

# Pocket Synth
SYNTH_TOP := pocket_synth
SYNTH_DIR := pocket_synth
SYNTH_SRC := $(SYNTH_DIR)/pocket_synth.v $(LIB)/debounce.v
SYNTH_BUILD := $(SYNTH_DIR)/build

# Dice Roller
DICE_TOP := dice_roller
DICE_DIR := dice_roller
DICE_SRC := $(DICE_DIR)/dice_roller.v $(LIB)/debounce.v $(LIB)/uart_tx.v
DICE_BUILD := $(DICE_DIR)/build

# Morse Beacon
LED_TOP := morse_beacon
LED_DIR := morse_beacon
LED_SRC := $(LED_DIR)/morse_beacon.v $(LIB)/debounce.v
LED_BUILD := $(LED_DIR)/build

# =============================================================================
# Simulation targets
# =============================================================================

.PHONY: sim-fortune sim-synth sim-dice sim-led sim-all

sim-fortune: $(FORTUNE_DIR)/fortune_teller.vvp
	$(VVP) $<

sim-synth: $(SYNTH_DIR)/pocket_synth.vvp
	$(VVP) $<

sim-dice: $(DICE_DIR)/dice_roller.vvp
	$(VVP) $<

sim-led: $(LED_DIR)/morse_beacon.vvp
	$(VVP) $<

sim-all: sim-fortune sim-synth sim-dice sim-led
	@echo "All simulations complete."

# Simulation compilation
$(FORTUNE_DIR)/fortune_teller.vvp: $(FORTUNE_DIR)/fortune_teller.v $(FORTUNE_DIR)/fortune_teller_tb.v $(LIB)/debounce.v $(LIB)/uart_tx.v
	$(IVERILOG) $(IVERILOG_FLAGS) -I$(LIB) -o $@ $^

$(SYNTH_DIR)/pocket_synth.vvp: $(SYNTH_DIR)/pocket_synth.v $(SYNTH_DIR)/pocket_synth_tb.v $(LIB)/debounce.v
	$(IVERILOG) $(IVERILOG_FLAGS) -I$(LIB) -o $@ $^

$(DICE_DIR)/dice_roller.vvp: $(DICE_DIR)/dice_roller.v $(DICE_DIR)/dice_roller_tb.v $(LIB)/debounce.v $(LIB)/uart_tx.v
	$(IVERILOG) $(IVERILOG_FLAGS) -I$(LIB) -o $@ $^

$(LED_DIR)/morse_beacon.vvp: $(LED_DIR)/morse_beacon.v $(LED_DIR)/morse_beacon_tb.v $(LIB)/debounce.v
	$(IVERILOG) $(IVERILOG_FLAGS) -I$(LIB) -o $@ $^

# =============================================================================
# Lint targets
# =============================================================================

.PHONY: lint-fortune lint-synth lint-dice lint-led lint-all

lint-fortune:
	$(VERILATOR) $(VERILATOR_FLAGS) -I$(LIB) $(FORTUNE_SRC)

lint-synth:
	$(VERILATOR) $(VERILATOR_FLAGS) -I$(LIB) $(SYNTH_SRC)

lint-dice:
	$(VERILATOR) $(VERILATOR_FLAGS) -I$(LIB) $(DICE_SRC)

lint-led:
	$(VERILATOR) $(VERILATOR_FLAGS) -I$(LIB) $(LED_SRC)

lint-all: lint-fortune lint-synth lint-dice lint-led
	@echo "All lint checks passed."

# =============================================================================
# Quick synthesis (gate count only, no PDK required)
# =============================================================================

.PHONY: synth-fortune synth-synth synth-dice synth-led

synth-fortune:
	$(YOSYS) -p "read_verilog -I$(LIB) $(FORTUNE_SRC); synth -top $(FORTUNE_TOP); stat"

synth-synth:
	$(YOSYS) -p "read_verilog -I$(LIB) $(SYNTH_SRC); synth -top $(SYNTH_TOP); stat"

synth-dice:
	$(YOSYS) -p "read_verilog -I$(LIB) $(DICE_SRC); synth -top $(DICE_TOP); stat"

synth-led:
	$(YOSYS) -p "read_verilog -I$(LIB) $(LED_SRC); synth -top $(LED_TOP); stat"

# =============================================================================
# ASIC Flow: Sky130 Synthesis
# =============================================================================

.PHONY: sky130-fortune sky130-synth sky130-dice sky130-led sky130-all

sky130-fortune: $(FORTUNE_BUILD)/$(FORTUNE_TOP)_synth.v
sky130-synth: $(SYNTH_BUILD)/$(SYNTH_TOP)_synth.v
sky130-dice: $(DICE_BUILD)/$(DICE_TOP)_synth.v
sky130-led: $(LED_BUILD)/$(LED_TOP)_synth.v
sky130-all: sky130-fortune sky130-synth sky130-dice sky130-led

$(FORTUNE_BUILD)/$(FORTUNE_TOP)_synth.v: $(FORTUNE_SRC)
	@mkdir -p $(FORTUNE_BUILD)
	cd $(FORTUNE_DIR) && $(YOSYS) -c ../$(FLOW)/synth.tcl \
		-D TOP=$(FORTUNE_TOP) \
		-D 'VERILOG=fortune_teller.v ../lib/debounce.v ../lib/uart_tx.v' \
		-D OUT_DIR=build

$(SYNTH_BUILD)/$(SYNTH_TOP)_synth.v: $(SYNTH_SRC)
	@mkdir -p $(SYNTH_BUILD)
	cd $(SYNTH_DIR) && $(YOSYS) -c ../$(FLOW)/synth.tcl \
		-D TOP=$(SYNTH_TOP) \
		-D 'VERILOG=pocket_synth.v ../lib/debounce.v' \
		-D OUT_DIR=build

$(DICE_BUILD)/$(DICE_TOP)_synth.v: $(DICE_SRC)
	@mkdir -p $(DICE_BUILD)
	cd $(DICE_DIR) && $(YOSYS) -c ../$(FLOW)/synth.tcl \
		-D TOP=$(DICE_TOP) \
		-D 'VERILOG=dice_roller.v ../lib/debounce.v ../lib/uart_tx.v' \
		-D OUT_DIR=build

$(LED_BUILD)/$(LED_TOP)_synth.v: $(LED_SRC)
	@mkdir -p $(LED_BUILD)
	cd $(LED_DIR) && $(YOSYS) -c ../$(FLOW)/synth.tcl \
		-D TOP=$(LED_TOP) \
		-D 'VERILOG=morse_beacon.v ../lib/debounce.v' \
		-D OUT_DIR=build

# =============================================================================
# ASIC Flow: Place & Route
# =============================================================================

.PHONY: pnr-fortune pnr-synth pnr-dice pnr-led pnr-all

pnr-fortune: $(FORTUNE_BUILD)/$(FORTUNE_TOP).def
pnr-synth: $(SYNTH_BUILD)/$(SYNTH_TOP).def
pnr-dice: $(DICE_BUILD)/$(DICE_TOP).def
pnr-led: $(LED_BUILD)/$(LED_TOP).def
pnr-all: pnr-fortune pnr-synth pnr-dice pnr-led

$(FORTUNE_BUILD)/$(FORTUNE_TOP).def: $(FORTUNE_BUILD)/$(FORTUNE_TOP)_synth.v
	cd $(FORTUNE_DIR) && TOP=$(FORTUNE_TOP) OUT_DIR=build $(OPENROAD) -exit ../$(FLOW)/pnr.tcl

$(SYNTH_BUILD)/$(SYNTH_TOP).def: $(SYNTH_BUILD)/$(SYNTH_TOP)_synth.v
	cd $(SYNTH_DIR) && TOP=$(SYNTH_TOP) OUT_DIR=build $(OPENROAD) -exit ../$(FLOW)/pnr.tcl

$(DICE_BUILD)/$(DICE_TOP).def: $(DICE_BUILD)/$(DICE_TOP)_synth.v
	cd $(DICE_DIR) && TOP=$(DICE_TOP) OUT_DIR=build $(OPENROAD) -exit ../$(FLOW)/pnr.tcl

$(LED_BUILD)/$(LED_TOP).def: $(LED_BUILD)/$(LED_TOP)_synth.v
	cd $(LED_DIR) && TOP=$(LED_TOP) OUT_DIR=build $(OPENROAD) -exit ../$(FLOW)/pnr.tcl

# =============================================================================
# ASIC Flow: GDS Generation
# =============================================================================

.PHONY: gds-fortune gds-synth gds-dice gds-led gds-all

gds-fortune: $(FORTUNE_BUILD)/$(FORTUNE_TOP).gds
gds-synth: $(SYNTH_BUILD)/$(SYNTH_TOP).gds
gds-dice: $(DICE_BUILD)/$(DICE_TOP).gds
gds-led: $(LED_BUILD)/$(LED_TOP).gds
gds-all: gds-fortune gds-synth gds-dice gds-led

$(FORTUNE_BUILD)/$(FORTUNE_TOP).gds: $(FORTUNE_BUILD)/$(FORTUNE_TOP).def
	cd $(FORTUNE_DIR) && TOP=$(FORTUNE_TOP) OUT_DIR=build \
		$(MAGIC) -dnull -noconsole \
		-rcfile $(PDK_ROOT)/sky130A/libs.tech/magic/sky130A.magicrc \
		../$(FLOW)/def2gds.tcl

$(SYNTH_BUILD)/$(SYNTH_TOP).gds: $(SYNTH_BUILD)/$(SYNTH_TOP).def
	cd $(SYNTH_DIR) && TOP=$(SYNTH_TOP) OUT_DIR=build \
		$(MAGIC) -dnull -noconsole \
		-rcfile $(PDK_ROOT)/sky130A/libs.tech/magic/sky130A.magicrc \
		../$(FLOW)/def2gds.tcl

$(DICE_BUILD)/$(DICE_TOP).gds: $(DICE_BUILD)/$(DICE_TOP).def
	cd $(DICE_DIR) && TOP=$(DICE_TOP) OUT_DIR=build \
		$(MAGIC) -dnull -noconsole \
		-rcfile $(PDK_ROOT)/sky130A/libs.tech/magic/sky130A.magicrc \
		../$(FLOW)/def2gds.tcl

$(LED_BUILD)/$(LED_TOP).gds: $(LED_BUILD)/$(LED_TOP).def
	cd $(LED_DIR) && TOP=$(LED_TOP) OUT_DIR=build \
		$(MAGIC) -dnull -noconsole \
		-rcfile $(PDK_ROOT)/sky130A/libs.tech/magic/sky130A.magicrc \
		../$(FLOW)/def2gds.tcl

# =============================================================================
# Full build targets
# =============================================================================

.PHONY: build-fortune build-synth build-dice build-led build-all

build-fortune: gds-fortune
	@echo "Fortune Teller build complete: $(FORTUNE_BUILD)/$(FORTUNE_TOP).gds"

build-synth: gds-synth
	@echo "Pocket Synth build complete: $(SYNTH_BUILD)/$(SYNTH_TOP).gds"

build-dice: gds-dice
	@echo "Dice Roller build complete: $(DICE_BUILD)/$(DICE_TOP).gds"

build-led: gds-led
	@echo "Morse Beacon build complete: $(LED_BUILD)/$(LED_TOP).gds"

build-all: build-fortune build-synth build-dice build-led
	@echo "All builds complete."

# =============================================================================
# View layouts in KLayout
# =============================================================================

.PHONY: view-fortune view-synth view-dice view-led

view-fortune: $(FORTUNE_BUILD)/$(FORTUNE_TOP).gds
	$(KLAYOUT) -l $(PDK_ROOT)/sky130A/libs.tech/klayout/tech/sky130A.lyp $<

view-synth: $(SYNTH_BUILD)/$(SYNTH_TOP).gds
	$(KLAYOUT) -l $(PDK_ROOT)/sky130A/libs.tech/klayout/tech/sky130A.lyp $<

view-dice: $(DICE_BUILD)/$(DICE_TOP).gds
	$(KLAYOUT) -l $(PDK_ROOT)/sky130A/libs.tech/klayout/tech/sky130A.lyp $<

view-led: $(LED_BUILD)/$(LED_TOP).gds
	$(KLAYOUT) -l $(PDK_ROOT)/sky130A/libs.tech/klayout/tech/sky130A.lyp $<

# =============================================================================
# Reports
# =============================================================================

.PHONY: report-fortune report-synth report-dice report-led

report-fortune:
	@echo "=== Fortune Teller Reports ==="
	@cat $(FORTUNE_BUILD)/$(FORTUNE_TOP)_timing.rpt 2>/dev/null || echo "Run 'make pnr-fortune' first"
	@cat $(FORTUNE_BUILD)/$(FORTUNE_TOP)_area.rpt 2>/dev/null || true

report-synth:
	@echo "=== Pocket Synth Reports ==="
	@cat $(SYNTH_BUILD)/$(SYNTH_TOP)_timing.rpt 2>/dev/null || echo "Run 'make pnr-synth' first"

report-dice:
	@echo "=== Dice Roller Reports ==="
	@cat $(DICE_BUILD)/$(DICE_TOP)_timing.rpt 2>/dev/null || echo "Run 'make pnr-dice' first"

report-led:
	@echo "=== Morse Beacon Reports ==="
	@cat $(LED_BUILD)/$(LED_TOP)_timing.rpt 2>/dev/null || echo "Run 'make pnr-led' first"

# =============================================================================
# Clean
# =============================================================================

.PHONY: clean clean-sim clean-build

clean-sim:
	rm -f */*.vvp */*.vcd
	@echo "Cleaned simulation files."

clean-build:
	rm -rf */build
	@echo "Cleaned build directories."

clean: clean-sim clean-build
	@echo "All cleaned."

# =============================================================================
# Help
# =============================================================================

.PHONY: help

help:
	@echo "Fab Futures Examples Makefile"
	@echo ""
	@echo "Simulation (no PDK required):"
	@echo "  make sim-fortune   - Run Fortune Teller simulation"
	@echo "  make sim-synth     - Run Pocket Synth simulation"
	@echo "  make sim-dice      - Run Dice Roller simulation"
	@echo "  make sim-led       - Run Morse Beacon simulation"
	@echo "  make sim-all       - Run all simulations"
	@echo ""
	@echo "Linting (no PDK required):"
	@echo "  make lint-all      - Lint all projects with Verilator"
	@echo ""
	@echo "Quick Synthesis (no PDK required):"
	@echo "  make synth-fortune - Synthesize and show gate count"
	@echo ""
	@echo "ASIC Flow (requires PDK_ROOT environment variable):"
	@echo "  make build-fortune - Full flow: synth -> P&R -> GDS"
	@echo "  make build-all     - Build all projects"
	@echo ""
	@echo "Individual ASIC steps:"
	@echo "  make sky130-fortune - Synthesize to Sky130 cells"
	@echo "  make pnr-fortune    - Place and route"
	@echo "  make gds-fortune    - Generate GDS"
	@echo ""
	@echo "View & Reports:"
	@echo "  make view-fortune   - Open layout in KLayout"
	@echo "  make report-fortune - Show timing/area reports"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean         - Remove all generated files"
	@echo "  make clean-sim     - Remove simulation files only"
	@echo "  make clean-build   - Remove build directories only"
