# ============================================================================
# Yosys Synthesis Script for Sky130
# ============================================================================
#
# Usage: yosys -c synth.tcl -D TOP=<module> -D VERILOG="<files>" -D OUT_DIR=<dir>
#
# Example:
#   yosys -c synth.tcl -D TOP=fortune_teller \
#         -D VERILOG="fortune_teller.v ../lib/debounce.v ../lib/uart_tx.v" \
#         -D OUT_DIR=build
#
# ============================================================================

# Check required variables
if {![info exists TOP]} {
    puts "ERROR: TOP not defined. Use -D TOP=<module_name>"
    exit 1
}

if {![info exists VERILOG]} {
    puts "ERROR: VERILOG not defined. Use -D VERILOG=\"<files>\""
    exit 1
}

if {![info exists OUT_DIR]} {
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
