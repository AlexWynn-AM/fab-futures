// ============================================================================
// Pocket Synth Testbench
// ============================================================================
//
// This testbench verifies that the synthesizer generates the correct
// frequencies for each note. We:
//   1. Press each key one at a time
//   2. Measure the frequency of the audio output
//   3. Compare to the expected frequency
//
// HOW TO RUN:
//   $ iverilog -o sim.vvp -I../lib pocket_synth.v pocket_synth_tb.v ../lib/*.v
//   $ vvp sim.vvp
//
// ============================================================================

`timescale 1ns/1ps

module pocket_synth_tb;

    // ========================================================================
    // Testbench Signals
    // ========================================================================

    reg        clk;        // Clock input
    reg        rst_n;      // Reset (directly controlled, no debounce needed)
    reg  [3:0] keys;       // Four piano keys
    wire       audio_out;  // Audio output (square wave)
    wire [3:0] leds;       // LED indicators

    // ========================================================================
    // DUT Instantiation
    // ========================================================================
    //
    // We use a 1 MHz clock for faster simulation.
    // This means our frequencies will be generated with 1 µs resolution.
    //
    // Expected half-periods at 1 MHz:
    //   C4 (262 Hz): 1,000,000 / (2 × 262) ≈ 1908 cycles = 1908 µs
    //   E4 (330 Hz): 1,000,000 / (2 × 330) ≈ 1515 cycles = 1515 µs
    //   G4 (392 Hz): 1,000,000 / (2 × 392) ≈ 1276 cycles = 1276 µs
    //   B4 (494 Hz): 1,000,000 / (2 × 494) ≈ 1012 cycles = 1012 µs

    pocket_synth #(
        .CLK_FREQ(1_000_000)   // 1 MHz for fast simulation
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .keys(keys),
        .audio_out(audio_out),
        .leds(leds)
    );

    // ========================================================================
    // Clock Generation
    // ========================================================================
    //
    // 1 MHz clock = 1 µs period = 500 ns half-period

    always begin
        #500;
        clk = ~clk;
    end

    // ========================================================================
    // Frequency Measurement
    // ========================================================================
    //
    // To measure frequency, we time the interval between rising edges of
    // the audio output. The frequency is then 1 / period.
    //
    // We use Verilog's $time system function to get the current simulation time.

    time last_edge;       // Time of the previous rising edge
    time this_edge;       // Time of the current rising edge
    real measured_freq;   // Calculated frequency in Hz

    // Trigger on rising edge of audio output
    always @(posedge audio_out) begin
        this_edge = $time;  // Get current simulation time

        // Only calculate if we have a previous edge to compare to
        if (last_edge != 0) begin
            // Period = time between edges × 2 (since we measure half-periods)
            // Frequency = 1 / period
            // $time is in picoseconds with our timescale, so:
            //   period (in seconds) = (this_edge - last_edge) × 2 × 1e-12
            //   frequency = 1 / period = 1e12 / ((this_edge - last_edge) × 2)
            //
            // But with timescale 1ns/1ps, $time returns nanoseconds, so:
            //   frequency = 1e9 / ((this_edge - last_edge) × 2)

            measured_freq = 1.0e9 / (2.0 * (this_edge - last_edge));
        end

        last_edge = this_edge;  // Remember this edge for next time
    end

    // ========================================================================
    // Main Test Sequence
    // ========================================================================

    initial begin
        // --------------------------------------------------------------------
        // Setup
        // --------------------------------------------------------------------

        $dumpfile("pocket_synth_tb.vcd");
        $dumpvars(0, pocket_synth_tb);

        // Initialize signals
        clk   = 0;
        rst_n = 0;
        keys  = 4'b0000;   // No keys pressed
        last_edge = 0;

        // Release reset
        #10000;
        rst_n = 1;
        #10000;

        // --------------------------------------------------------------------
        // Test Each Note
        // --------------------------------------------------------------------
        //
        // For each key:
        //   1. Press the key
        //   2. Wait long enough for several oscillation cycles
        //   3. Print the measured frequency
        //   4. Release the key
        //
        // We need to wait long enough to get accurate measurements.
        // At ~262 Hz, one cycle takes ~4 ms. We wait ~4 ms per note.

        // Test C4 (262 Hz) - Key 0
        $display("Playing C...");
        keys = 4'b0001;         // Press key 0
        #4000000;               // Wait 4 ms (several cycles)
        $display("  Measured: %.1f Hz (expected ~262 Hz)", measured_freq);
        keys = 4'b0000;         // Release
        #1000000;               // Brief pause between notes

        // Test E4 (330 Hz) - Key 1
        $display("Playing E...");
        keys = 4'b0010;         // Press key 1
        #4000000;
        $display("  Measured: %.1f Hz (expected ~330 Hz)", measured_freq);
        keys = 4'b0000;
        #1000000;

        // Test G4 (392 Hz) - Key 2
        $display("Playing G...");
        keys = 4'b0100;         // Press key 2
        #4000000;
        $display("  Measured: %.1f Hz (expected ~392 Hz)", measured_freq);
        keys = 4'b0000;
        #1000000;

        // Test B4 (494 Hz) - Key 3
        $display("Playing B...");
        keys = 4'b1000;         // Press key 3
        #4000000;
        $display("  Measured: %.1f Hz (expected ~494 Hz)", measured_freq);
        keys = 4'b0000;
        #1000000;

        // --------------------------------------------------------------------
        // Test Priority (Multiple Keys)
        // --------------------------------------------------------------------
        //
        // When multiple keys are pressed, the lowest-numbered key should win.

        $display("Playing C+G (should hear C due to priority)...");
        keys = 4'b0101;         // Press keys 0 and 2
        #4000000;
        $display("  Measured: %.1f Hz (expected ~262 Hz)", measured_freq);
        keys = 4'b0000;

        // --------------------------------------------------------------------
        // Done
        // --------------------------------------------------------------------

        $display("Test complete!");
        $finish;
    end

endmodule
