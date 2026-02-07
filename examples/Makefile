# =============================================================================
# Fab Futures Examples - Build Automation
# =============================================================================
#
# Usage:
#   make sim-fortune    - Simulate Fortune Teller
#   make sim-synth      - Simulate Pocket Synth
#   make sim-dice       - Simulate Dice Roller
#   make sim-led        - Simulate LED Messenger
#   make sim-all        - Simulate all projects
#   make lint-all       - Lint all projects
#   make clean          - Remove generated files
#
# =============================================================================

# Default shell
SHELL := /bin/bash

# Tools
IVERILOG := iverilog
VVP := vvp
VERILATOR := verilator
YOSYS := yosys

# Common options
IVERILOG_FLAGS := -Wall -g2012
VERILATOR_FLAGS := --lint-only -Wall

# Library path
LIB := lib

# =============================================================================
# Simulation targets
# =============================================================================

.PHONY: sim-fortune sim-synth sim-dice sim-led sim-all

sim-fortune: fortune_teller/fortune_teller.vvp
	$(VVP) $<

sim-synth: pocket_synth/pocket_synth.vvp
	$(VVP) $<

sim-dice: dice_roller/dice_roller.vvp
	$(VVP) $<

sim-led: led_messenger/led_messenger.vvp
	$(VVP) $<

sim-all: sim-fortune sim-synth sim-dice sim-led
	@echo "All simulations complete."

# =============================================================================
# Compilation targets
# =============================================================================

fortune_teller/fortune_teller.vvp: fortune_teller/fortune_teller.v fortune_teller/fortune_teller_tb.v $(LIB)/debounce.v $(LIB)/uart_tx.v
	$(IVERILOG) $(IVERILOG_FLAGS) -I$(LIB) -o $@ $^

pocket_synth/pocket_synth.vvp: pocket_synth/pocket_synth.v pocket_synth/pocket_synth_tb.v $(LIB)/debounce.v
	$(IVERILOG) $(IVERILOG_FLAGS) -I$(LIB) -o $@ $^

dice_roller/dice_roller.vvp: dice_roller/dice_roller.v dice_roller/dice_roller_tb.v $(LIB)/debounce.v
	$(IVERILOG) $(IVERILOG_FLAGS) -I$(LIB) -o $@ $^

led_messenger/led_messenger.vvp: led_messenger/led_messenger.v led_messenger/led_messenger_tb.v
	$(IVERILOG) $(IVERILOG_FLAGS) -I$(LIB) -o $@ $^

# =============================================================================
# Lint targets
# =============================================================================

.PHONY: lint-fortune lint-synth lint-dice lint-led lint-all

lint-fortune:
	$(VERILATOR) $(VERILATOR_FLAGS) -I$(LIB) fortune_teller/fortune_teller.v $(LIB)/debounce.v $(LIB)/uart_tx.v

lint-synth:
	$(VERILATOR) $(VERILATOR_FLAGS) -I$(LIB) pocket_synth/pocket_synth.v $(LIB)/debounce.v

lint-dice:
	$(VERILATOR) $(VERILATOR_FLAGS) -I$(LIB) dice_roller/dice_roller.v $(LIB)/debounce.v

lint-led:
	$(VERILATOR) $(VERILATOR_FLAGS) -I$(LIB) led_messenger/led_messenger.v

lint-all: lint-fortune lint-synth lint-dice lint-led
	@echo "All lint checks passed."

# =============================================================================
# Synthesis (Yosys) - produces gate count estimate
# =============================================================================

.PHONY: synth-fortune synth-synth synth-dice synth-led

synth-fortune:
	$(YOSYS) -p " \
		read_verilog -I$(LIB) fortune_teller/fortune_teller.v $(LIB)/debounce.v $(LIB)/uart_tx.v; \
		synth -top fortune_teller; \
		stat"

synth-synth:
	$(YOSYS) -p " \
		read_verilog -I$(LIB) pocket_synth/pocket_synth.v $(LIB)/debounce.v; \
		synth -top pocket_synth; \
		stat"

synth-dice:
	$(YOSYS) -p " \
		read_verilog -I$(LIB) dice_roller/dice_roller.v $(LIB)/debounce.v; \
		synth -top dice_roller; \
		stat"

synth-led:
	$(YOSYS) -p " \
		read_verilog -I$(LIB) led_messenger/led_messenger.v; \
		synth -top led_messenger; \
		stat"

# =============================================================================
# Clean
# =============================================================================

.PHONY: clean

clean:
	rm -f */*.vvp */*.vcd
	@echo "Cleaned generated files."

# =============================================================================
# Help
# =============================================================================

.PHONY: help

help:
	@echo "Fab Futures Examples Makefile"
	@echo ""
	@echo "Simulation:"
	@echo "  make sim-fortune  - Run Fortune Teller simulation"
	@echo "  make sim-synth    - Run Pocket Synth simulation"
	@echo "  make sim-dice     - Run Dice Roller simulation"
	@echo "  make sim-led      - Run LED Messenger simulation"
	@echo "  make sim-all      - Run all simulations"
	@echo ""
	@echo "Linting:"
	@echo "  make lint-all     - Lint all projects with Verilator"
	@echo ""
	@echo "Synthesis:"
	@echo "  make synth-fortune - Synthesize and show gate count"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean        - Remove generated files"
