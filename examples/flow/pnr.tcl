# ============================================================================
# OpenROAD Place & Route Script for Sky130
# ============================================================================
#
# Usage: TOP=<module> OUT_DIR=<dir> openroad -exit pnr.tcl
#
# ============================================================================

# Get environment variables
set TOP $::env(TOP)
set OUT_DIR [expr {[info exists ::env(OUT_DIR)] ? $::env(OUT_DIR) : "build"}]
set PDK_ROOT $::env(PDK_ROOT)

set LIB_DIR "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd"
set TECH_DIR "$PDK_ROOT/sky130A/libs.tech/openlane/sky130_fd_sc_hd"

puts "============================================"
puts "Place & Route: $TOP"
puts "Build dir: $OUT_DIR"
puts "PDK: $PDK_ROOT"
puts "============================================"

# ----------------------------------------------------------------------------
# Read technology files
# ----------------------------------------------------------------------------
# Read tech LEF first (defines layers, sites, etc.)
read_lef $LIB_DIR/techlef/sky130_fd_sc_hd__nom.tlef

# Read standard cell LEFs
read_lef $LIB_DIR/lef/sky130_fd_sc_hd.lef
read_lef $LIB_DIR/lef/sky130_ef_sc_hd.lef

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
puts "Initializing floorplan..."

# Initialize with 40% utilization, square aspect ratio, 5um margin
initialize_floorplan \
    -utilization 40 \
    -aspect_ratio 1.0 \
    -core_space 5 \
    -site unithd

# Make tracks for routing
make_tracks

# ----------------------------------------------------------------------------
# I/O Placement
# ----------------------------------------------------------------------------
puts "Placing I/O pins..."
place_pins -hor_layers met3 -ver_layers met2

# ----------------------------------------------------------------------------
# Power Distribution Network
# ----------------------------------------------------------------------------
puts "Building power grid..."

# Add global connections for power
add_global_connection -net VDD -pin_pattern "^VPWR$" -power
add_global_connection -net VDD -pin_pattern "^VPB$"
add_global_connection -net VSS -pin_pattern "^VGND$" -ground
add_global_connection -net VSS -pin_pattern "^VNB$"

global_connect

# Simple power stripes
set_voltage_domain -power VDD -ground VSS

define_pdn_grid -name core_grid -pins {met4 met5}
add_pdn_stripe -grid core_grid -layer met1 -width 0.48 -followpins
add_pdn_stripe -grid core_grid -layer met4 -width 1.6 -pitch 50 -offset 2
add_pdn_stripe -grid core_grid -layer met5 -width 1.6 -pitch 50 -offset 2
add_pdn_connect -grid core_grid -layers {met1 met4}
add_pdn_connect -grid core_grid -layers {met4 met5}

pdngen

# ----------------------------------------------------------------------------
# Placement
# ----------------------------------------------------------------------------
puts "Running placement..."

# Global placement
global_placement -density 0.7 -pad_left 2 -pad_right 2

# Detailed placement
detailed_placement

# Check placement
if {[catch {check_placement -verbose} err]} {
    puts "Warning: Placement check: $err"
}

# ----------------------------------------------------------------------------
# Clock Tree Synthesis
# ----------------------------------------------------------------------------
puts "Running clock tree synthesis..."

# Repair design before CTS
repair_design

# Set wire RC for clock
set_wire_rc -clock -layer met3

# Run CTS
clock_tree_synthesis \
    -root_buf sky130_fd_sc_hd__clkbuf_16 \
    -buf_list {sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_16} \
    -sink_clustering_enable

# Repair clock nets
repair_clock_nets

# Legalize after CTS
detailed_placement

# ----------------------------------------------------------------------------
# Routing
# ----------------------------------------------------------------------------
puts "Running routing..."

# Set routing layers
set_routing_layers -signal met1-met4 -clock met1-met5

# Global route
global_route -guide_file $OUT_DIR/${TOP}_route.guide \
    -congestion_iterations 100 \
    -allow_congestion

# Detailed route
detailed_route -output_drc $OUT_DIR/${TOP}_drc.rpt

# ----------------------------------------------------------------------------
# Filler cells
# ----------------------------------------------------------------------------
puts "Adding filler cells..."

filler_placement {sky130_ef_sc_hd__decap_12 sky130_fd_sc_hd__fill_1 sky130_fd_sc_hd__fill_2}

# Final legalization
check_placement

# ----------------------------------------------------------------------------
# Final checks and reports
# ----------------------------------------------------------------------------
puts "Running final analysis..."

# Estimate parasitics for timing
estimate_parasitics -placement

# Timing analysis
report_checks -path_delay max -slack_max 0 -group_count 5 > $OUT_DIR/${TOP}_timing.rpt
report_wns > $OUT_DIR/${TOP}_wns.rpt
report_tns > $OUT_DIR/${TOP}_tns.rpt

# Power analysis
report_power > $OUT_DIR/${TOP}_power.rpt

# Area
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
