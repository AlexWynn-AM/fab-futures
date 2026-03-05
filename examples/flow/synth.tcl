# ============================================================================
# Yosys Synthesis Script for Sky130
# ============================================================================
#
# Usage: TOP=<module> VERILOG="<files>" OUT_DIR=<dir> yosys -c synth.tcl
#
# Example:
#   TOP=fortune_teller \
#   VERILOG="fortune_teller.v ../lib/debounce.v ../lib/uart_tx.v" \
#   OUT_DIR=build \
#   yosys -c synth.tcl
#
# ============================================================================

# Import Yosys commands into TCL namespace
yosys -import

# Get variables from environment
if {[info exists ::env(TOP)]} {
    set TOP $::env(TOP)
} else {
    puts "ERROR: TOP not defined. Set TOP=<module_name> environment variable"
    exit 1
}

if {[info exists ::env(VERILOG)]} {
    set VERILOG $::env(VERILOG)
} else {
    puts "ERROR: VERILOG not defined. Set VERILOG=\"<files>\" environment variable"
    exit 1
}

if {[info exists ::env(OUT_DIR)]} {
    set OUT_DIR $::env(OUT_DIR)
} else {
    set OUT_DIR "build"
}

# Create output directory
file mkdir $OUT_DIR

puts "============================================"
puts "Synthesizing: $TOP"
puts "Sources: $VERILOG"
puts "Output: $OUT_DIR"
puts "============================================"

# Read Verilog sources
foreach src $VERILOG {
    read_verilog -I../lib $src
}

# Elaborate hierarchy
hierarchy -check -top $TOP

# Synthesize to generic gates
synth -top $TOP

# Map flip-flops to Sky130 cells
dfflibmap -liberty $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Map combinational logic to Sky130 cells
abc -liberty $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Clean up
clean

# Replace constant drivers with tie cells
hilomap -hicell sky130_fd_sc_hd__conb_1 HI -locell sky130_fd_sc_hd__conb_1 LO

# Print statistics
stat -liberty $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Write outputs
write_verilog -noattr $OUT_DIR/${TOP}_synth.v
write_json $OUT_DIR/${TOP}_synth.json

puts "============================================"
puts "Synthesis complete!"
puts "  Netlist: $OUT_DIR/${TOP}_synth.v"
puts "  JSON:    $OUT_DIR/${TOP}_synth.json"
puts "============================================"
