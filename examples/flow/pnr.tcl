# ============================================================================
# OpenROAD Place & Route Script for Sky130
# ============================================================================
#
# Usage: openroad -exit pnr.tcl
#
# Environment variables:
#   TOP       - Top module name
#   OUT_DIR   - Build directory (default: build)
#   PDK_ROOT  - Path to Sky130 PDK
#
# Example:
#   TOP=fortune_teller OUT_DIR=build openroad -exit pnr.tcl
#
# ============================================================================

# Get environment variables
set TOP $::env(TOP)
set OUT_DIR [expr {[info exists ::env(OUT_DIR)] ? $::env(OUT_DIR) : "build"}]
set PDK_ROOT $::env(PDK_ROOT)

set LIB_DIR "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd"

puts "============================================"
puts "Place & Route: $TOP"
puts "Build dir: $OUT_DIR"
puts "PDK: $PDK_ROOT"
puts "============================================"

# ----------------------------------------------------------------------------
# Read technology files
# ----------------------------------------------------------------------------
read_lef $LIB_DIR/lef/sky130_fd_sc_hd.lef
read_lef $LIB_DIR/lef/sky130_ef_sc_hd__decap_12.lef
read_lef $LIB_DIR/lef/sky130_ef_sc_hd__fill_1.lef
read_lef $LIB_DIR/lef/sky130_ef_sc_hd__fill_2.lef
read_lef $LIB_DIR/lef/sky130_ef_sc_hd__fill_4.lef
read_lef $LIB_DIR/lef/sky130_ef_sc_hd__fill_8.lef

read_liberty $LIB_DIR/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# ----------------------------------------------------------------------------
# Read synthesized netlist
# ----------------------------------------------------------------------------
read_verilog $OUT_DIR/${TOP}_synth.v
link_design $TOP

# ----------------------------------------------------------------------------
# Read timing constraints
# ----------------------------------------------------------------------------
read_sdc ../lib/constraints.sdc

# ----------------------------------------------------------------------------
# Floorplan
# ----------------------------------------------------------------------------
# Initialize with 50% utilization, square aspect ratio, 5um margin
initialize_floorplan \
    -utilization 50 \
    -aspect_ratio 1.0 \
    -core_space 5

# Define placement site
source $PDK_ROOT/sky130A/libs.tech/openlane/sky130_fd_sc_hd/tracks.info

# ----------------------------------------------------------------------------
# Power Distribution Network
# ----------------------------------------------------------------------------
# Add global connections
add_global_connection -net VDD -pin_pattern "^VPWR$" -power
add_global_connection -net VDD -pin_pattern "^VPB$" -power
add_global_connection -net VSS -pin_pattern "^VGND$" -ground
add_global_connection -net VSS -pin_pattern "^VNB$" -ground

global_connect

# Set voltage
set_voltage 1.8 -vdd VDD -ground VSS

# Simple power grid (for small designs)
# Horizontal stripes on met4, vertical on met5
pdngen -skip_trim

# ----------------------------------------------------------------------------
# Placement
# ----------------------------------------------------------------------------
puts "Running placement..."

# Global placement
global_placement -density 0.6

# Detailed placement
detailed_placement

# Check placement
check_placement -verbose

# ----------------------------------------------------------------------------
# Clock Tree Synthesis
# ----------------------------------------------------------------------------
puts "Running clock tree synthesis..."

# Configure CTS
set_wire_rc -clock \
    -layer met3

clock_tree_synthesis \
    -root_buf sky130_fd_sc_hd__clkbuf_8 \
    -buf_list {sky130_fd_sc_hd__clkbuf_1 sky130_fd_sc_hd__clkbuf_2 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8}

# Repair clock nets
repair_clock_nets

# Update placement after CTS
detailed_placement

# ----------------------------------------------------------------------------
# Routing
# ----------------------------------------------------------------------------
puts "Running routing..."

# Set routing layers
set_routing_layers -signal met1-met4 -clock met1-met5

# Global route
global_route -guide_file $OUT_DIR/${TOP}_route.guide \
    -congestion_iterations 50

# Detailed route
detailed_route \
    -output_drc $OUT_DIR/${TOP}_drc.rpt \
    -output_maze $OUT_DIR/${TOP}_maze.log \
    -bottom_routing_layer met1 \
    -top_routing_layer met4

# ----------------------------------------------------------------------------
# Filler cells
# ----------------------------------------------------------------------------
puts "Adding filler cells..."

filler_placement sky130_ef_sc_hd__fill_*
check_placement

# ----------------------------------------------------------------------------
# Final checks
# ----------------------------------------------------------------------------
puts "Running final checks..."

# Timing analysis
report_checks -path_delay max -slack_max -0.1 -format full_clock_expanded \
    > $OUT_DIR/${TOP}_timing.rpt

report_wns > $OUT_DIR/${TOP}_wns.rpt
report_tns > $OUT_DIR/${TOP}_tns.rpt

# Power analysis (with estimated activity)
report_power > $OUT_DIR/${TOP}_power.rpt

# Design rule checks
estimate_parasitics -placement
report_design_area > $OUT_DIR/${TOP}_area.rpt

# ----------------------------------------------------------------------------
# Write outputs
# ----------------------------------------------------------------------------
puts "Writing outputs..."

write_def $OUT_DIR/${TOP}.def
write_verilog $OUT_DIR/${TOP}_pnr.v

puts "============================================"
puts "Place & Route complete!"
puts "  DEF:     $OUT_DIR/${TOP}.def"
puts "  Netlist: $OUT_DIR/${TOP}_pnr.v"
puts "  Reports: $OUT_DIR/${TOP}_*.rpt"
puts "============================================"
