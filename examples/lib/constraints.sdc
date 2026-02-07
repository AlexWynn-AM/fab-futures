# ============================================================================
# Timing Constraints for Fab Futures Projects
# ============================================================================
#
# This file tells the synthesis and place & route tools about your design's
# timing requirements. The most important constraint is the clock period.
#
# SDC = Synopsys Design Constraints (industry standard format)
#
# ============================================================================

# ----------------------------------------------------------------------------
# Clock Definition
# ----------------------------------------------------------------------------
# Define a 50 MHz clock (20 ns period) on the 'clk' input
#
# create_clock arguments:
#   -name clk        : Name this clock "clk" for timing reports
#   -period 20       : Clock period in nanoseconds (50 MHz = 20 ns)
#   [get_ports clk]  : Apply to the port named "clk"

create_clock -name clk -period 20 [get_ports clk]

# ----------------------------------------------------------------------------
# Input Delays
# ----------------------------------------------------------------------------
# Tell the tools when input signals arrive relative to the clock.
# This accounts for delay from the board to the chip.
#
# For our simple designs with slow external signals (buttons, switches),
# we can use a conservative estimate: signals arrive 5 ns after clock edge.

set_input_delay -clock clk 5 [all_inputs]

# ----------------------------------------------------------------------------
# Output Delays
# ----------------------------------------------------------------------------
# Tell the tools when output signals must be valid relative to the clock.
# This accounts for setup time requirements of external devices.
#
# For our designs driving LEDs or slow peripherals, 5 ns is conservative.

set_output_delay -clock clk 5 [all_outputs]

# ----------------------------------------------------------------------------
# False Paths (Optional)
# ----------------------------------------------------------------------------
# Reset is asynchronous - don't try to meet timing on it
# (The reset synchronizer handles the clock domain crossing)

set_false_path -from [get_ports rst_n]

# ----------------------------------------------------------------------------
# Clock Uncertainty (Optional, for more accurate analysis)
# ----------------------------------------------------------------------------
# Account for clock jitter and skew. 0.5 ns is typical for simple designs.

set_clock_uncertainty 0.5 [get_clocks clk]

# ============================================================================
# That's it! For our educational designs, these basic constraints are enough.
#
# More complex designs might add:
#   - Multiple clock domains
#   - Clock-to-clock constraints (set_clock_groups)
#   - Multicycle paths (set_multicycle_path)
#   - Max transition/capacitance constraints
# ============================================================================
