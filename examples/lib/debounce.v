// ============================================================================
// Button Debouncer Module
// ============================================================================
//
// PROBLEM: Mechanical buttons don't make clean transitions. When you press
// a button, the metal contacts physically bounce, causing the signal to
// rapidly switch between 0 and 1 for a few milliseconds:
//
//   What we want:        What actually happens:
//
//   ────┐                ────┐ ┌┐ ┌┐ ┌─┐
//       │                    │ ││ ││ │ │
//       └────────            └─┘└─┘└─┘ └────────
//
// SOLUTION: Wait for the signal to be stable for some time (e.g., 10ms)
// before accepting it as a real button press.
//
// This module outputs a single-cycle pulse when a button press is detected.
//
// ============================================================================

`timescale 1ns/1ps

module debounce #(
    // ========================================================================
    // Parameters
    // ========================================================================
    parameter CLK_FREQ  = 50_000_000,  // Clock frequency in Hz
    parameter STABLE_MS = 10           // How long signal must be stable (ms)
)(
    // ========================================================================
    // Ports
    // ========================================================================
    input  wire clk,          // System clock
    input  wire rst_n,        // Active-low reset
    input  wire btn_raw,      // Raw button input (directly from pin)
    output reg  btn_pressed   // Single pulse when button press detected
);

    // ========================================================================
    // Calculate Counter Maximum
    // ========================================================================
    // How many clock cycles is STABLE_MS milliseconds?
    // Example: 50 MHz * 10ms = 50,000,000 * 0.010 = 500,000 cycles

    localparam COUNT_MAX = (CLK_FREQ / 1000) * STABLE_MS;

    // How many bits do we need to count to COUNT_MAX?
    localparam CTR_WIDTH = $clog2(COUNT_MAX + 1);

    // ========================================================================
    // Internal Registers
    // ========================================================================

    reg [CTR_WIDTH-1:0] counter;     // Counts how long input has been stable
    reg                 btn_sync;    // Synchronized button input (stage 1)
    reg                 btn_stable;  // Debounced stable value
    reg                 btn_prev;    // Previous stable value (for edge detect)

    // ========================================================================
    // Main Logic
    // ========================================================================

    always @(posedge clk or negedge rst_n) begin

        // --------------------------------------------------------------------
        // Reset: Initialize everything
        // --------------------------------------------------------------------
        if (!rst_n) begin
            btn_sync    <= 0;  // Assume button not pressed
            btn_stable  <= 0;  // Assume button not pressed
            btn_prev    <= 0;  // No previous value
            btn_pressed <= 0;  // No press detected
            counter     <= 0;  // Reset counter
        end

        // --------------------------------------------------------------------
        // Normal Operation
        // --------------------------------------------------------------------
        else begin

            // ================================================================
            // Step 1: Synchronize the raw input
            // ================================================================
            // External signals can change at any time, which can cause
            // "metastability" - the flip-flop output may briefly oscillate
            // or settle to an unpredictable value. This synchronizer register
            // gives the signal time to stabilize before we use it.
            btn_sync <= btn_raw;

            // ================================================================
            // Step 2: Debounce logic
            // ================================================================
            // If the synchronized input differs from the stable output,
            // start counting. If it stays different long enough, accept it.

            if (btn_sync != btn_stable) begin
                // Input is different from stable value - count up
                counter <= counter + 1;

                // Has it been stable long enough?
                if (counter >= COUNT_MAX) begin
                    btn_stable <= btn_sync;  // Accept the new value
                    counter    <= 0;         // Reset counter
                end
            end
            else begin
                // Input matches stable value - reset counter
                counter <= 0;
            end

            // ================================================================
            // Step 3: Edge detection
            // ================================================================
            // We want to output a single pulse when the button is pressed.
            // This is called "rising edge detection".

            btn_prev    <= btn_stable;                  // Remember previous value
            btn_pressed <= btn_stable && !btn_prev;    // HIGH only on 0->1 transition

            // Explanation of edge detection:
            //   btn_stable:  0 0 0 1 1 1 1 0 0
            //   btn_prev:    0 0 0 0 1 1 1 1 0   (delayed by one clock)
            //   btn_pressed: 0 0 0 1 0 0 0 0 0   (HIGH only when stable=1 and prev=0)

        end
    end

endmodule
