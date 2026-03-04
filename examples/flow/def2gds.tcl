# ============================================================================
# Magic DEF to GDS Conversion Script
# ============================================================================
#
# Usage: magic -dnull -noconsole -rcfile $PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc def2gds.tcl
#
# Environment variables:
#   TOP       - Top module name
#   OUT_DIR   - Build directory (default: build)
#   PDK_ROOT  - Path to Sky130 PDK
#
# ============================================================================

# Get environment variables
set TOP $::env(TOP)
set OUT_DIR [expr {[info exists ::env(OUT_DIR)] ? $::env(OUT_DIR) : "build"}]

puts "============================================"
puts "DEF to GDS: $TOP"
puts "============================================"

# Read LEF files for standard cells
lef read $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef

# Read the DEF file
def read $OUT_DIR/${TOP}.def

# Load the design
load $TOP

# Select the entire design
select top cell
expand

# Write GDS
gds write $OUT_DIR/${TOP}.gds

puts "============================================"
puts "GDS written: $OUT_DIR/${TOP}.gds"
puts "============================================"

quit
