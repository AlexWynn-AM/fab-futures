// ============================================================================
// Fortune Teller Testbench
// ============================================================================
//
// WHAT IS A TESTBENCH?
//   A testbench is a Verilog module that tests another module (the "DUT" -
//   Device Under Test). It's like a test harness that:
//     1. Generates input signals (clock, reset, button presses)
//     2. Observes output signals (TX line, LED)
//     3. Checks that outputs match expectations
//
//   Testbenches are NOT synthesizable - they only run in simulation.
//   They can use special constructs like delays (#100), $display, and $finish.
//
// HOW TO RUN THIS TESTBENCH:
//   $ iverilog -o sim.vvp -I../lib fortune_teller.v fortune_teller_tb.v ../lib/*.v
//   $ vvp sim.vvp
//   $ gtkwave fortune_teller_tb.vcd   (optional: view waveforms)
//
// ============================================================================

// ----------------------------------------------------------------------------
// Timescale Directive
// ----------------------------------------------------------------------------
// `timescale <time_unit> / <time_precision>
//   - time_unit: what "1" means in delay statements (e.g., #1 = 1ns)
//   - time_precision: smallest time step the simulator uses
//
// With `timescale 1ns/1ps:
//   - #100 means 100 nanoseconds
//   - The simulator can resolve times down to 1 picosecond

`timescale 1ns/1ps

module fortune_teller_tb;

    // ========================================================================
    // Testbench Signals
    // ========================================================================
    //
    // These signals connect to the DUT. We use 'reg' for inputs (we drive them)
    // and 'wire' for outputs (the DUT drives them).

    reg  clk;      // Clock signal - we generate this
    reg  rst_n;    // Reset signal - we control this
    reg  btn;      // Button input - we simulate button presses
    wire tx;       // UART output - we observe this
    wire led;      // LED output - we observe this

    // ========================================================================
    // Device Under Test (DUT) Instantiation
    // ========================================================================
    //
    // We instantiate the fortune_teller module with test-friendly parameters:
    //   - CLK_FREQ = 1 MHz (instead of 50 MHz) - makes simulation faster
    //   - BAUD = 100,000 (instead of 115,200) - nice round number for testing
    //
    // At 1 MHz clock and 100 kbaud:
    //   - Each UART bit takes 10 clock cycles
    //   - Each UART bit takes 10 µs (since clock period = 1 µs)

    fortune_teller #(
        .CLK_FREQ(1_000_000),   // 1 MHz clock for fast simulation
        .BAUD(100_000)          // 100 kbaud for easy timing math
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .btn(btn),
        .tx(tx),
        .led(led)
    );

    // ========================================================================
    // Clock Generation
    // ========================================================================
    //
    // We need to generate a clock signal. At 1 MHz:
    //   - Period = 1 µs = 1000 ns
    //   - Half period = 500 ns
    //
    // The 'always' block with no sensitivity list runs forever.
    // Every 500 ns, we toggle the clock.

    always begin
        #500;           // Wait 500 ns
        clk = ~clk;     // Toggle clock (0->1 or 1->0)
    end

    // ========================================================================
    // UART Receiver (for monitoring output)
    // ========================================================================
    //
    // To see what the DUT is transmitting, we need to decode the UART signal.
    // This is a simple "bit-banging" receiver that samples the TX line.
    //
    // UART bit timing at 100 kbaud:
    //   - Bit period = 1 MHz / 100 kbaud = 10 clock cycles = 10 µs = 10,000 ns

    localparam BIT_TIME = 10000;  // 10 µs per bit in nanoseconds

    reg [7:0] rx_byte;  // The byte we're receiving
    integer i;          // Loop counter for receiving 8 bits

    // This 'always' block triggers on the falling edge of TX (start bit)
    always @(negedge tx) begin
        // Only receive if we're out of reset
        if (rst_n) begin
            // Wait until the middle of the start bit
            // (half a bit time from the falling edge)
            #(BIT_TIME / 2);

            // Skip the rest of the start bit
            #BIT_TIME;

            // Sample each of the 8 data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx_byte[i] = tx;  // Sample the current bit
                #BIT_TIME;        // Wait for next bit
            end

            // Now we're at the stop bit - print the character
            if (rx_byte >= 32 && rx_byte < 127) begin
                // Printable ASCII character
                $write("%c", rx_byte);
            end
            else if (rx_byte == 10) begin
                // Newline character
                $write("\n");
            end
            // (Other control characters are ignored)
        end
    end

    // ========================================================================
    // Main Test Sequence
    // ========================================================================
    //
    // The 'initial' block runs once at the start of simulation.
    // We use it to:
    //   1. Set up waveform dumping
    //   2. Initialize signals
    //   3. Apply reset
    //   4. Simulate button presses
    //   5. Wait for results
    //   6. End simulation

    initial begin
        // --------------------------------------------------------------------
        // Waveform Dumping
        // --------------------------------------------------------------------
        // These commands create a VCD (Value Change Dump) file that can be
        // viewed in GTKWave to see all signal transitions.

        $dumpfile("fortune_teller_tb.vcd");  // Output filename
        $dumpvars(0, fortune_teller_tb);     // Dump all signals in this module

        // --------------------------------------------------------------------
        // Initialize Signals
        // --------------------------------------------------------------------
        // At time 0, set initial values for all inputs

        clk   = 0;   // Clock starts low
        rst_n = 0;   // Start in reset (active low, so 0 = reset active)
        btn   = 0;   // Button not pressed

        // --------------------------------------------------------------------
        // Release Reset
        // --------------------------------------------------------------------
        // Hold reset for a bit, then release it

        #5000;        // Wait 5 µs
        rst_n = 1;    // Release reset (1 = not resetting)
        #50000;       // Wait 50 µs for things to stabilize

        // --------------------------------------------------------------------
        // First Button Press
        // --------------------------------------------------------------------
        // The debouncer requires the button to be held for 10 ms.
        // At 1 MHz, that's 10,000 clock cycles = 10,000 µs = 10,000,000 ns.
        // We hold for 15 ms to be safe.

        $display("Pressing button...");
        btn = 1;          // Press button
        #15000000;        // Hold for 15 ms (15,000,000 ns)
        btn = 0;          // Release button

        // Wait for the fortune to transmit
        // ~20 characters × 10 bits/char × 10 µs/bit = ~2 ms
        // We wait 3 ms to be safe
        #3000000;

        $display("");     // Print a blank line after the fortune

        // --------------------------------------------------------------------
        // Wait for Debouncer to Reset
        // --------------------------------------------------------------------
        // The debouncer also needs time to recognize the button release.
        // Wait another 15 ms before pressing again.

        #15000000;

        // --------------------------------------------------------------------
        // Second Button Press
        // --------------------------------------------------------------------
        // Press again to get a different fortune (LFSR has advanced)

        $display("Pressing button again...");
        btn = 1;
        #15000000;
        btn = 0;

        #3000000;

        $display("");

        // --------------------------------------------------------------------
        // End Simulation
        // --------------------------------------------------------------------

        $display("Test complete");
        $finish;  // Stop the simulation
    end

endmodule
