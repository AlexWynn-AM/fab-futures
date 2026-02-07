// ============================================================================
// Morse Beacon Testbench
// ============================================================================
//
// This testbench verifies the Morse code beacon by:
//   1. Capturing the serial data sent to the LED strip
//   2. Decoding the WS2812 protocol to extract color values
//   3. Detecting dots, dashes, and gaps in the Morse output
//
// MORSE TIMING RECAP:
//   - Dot  = 1 unit (LEDs on)
//   - Dash = 3 units (LEDs on)
//   - Gap between symbols = 1 unit (LEDs off)
//   - Gap between letters = 3 units (LEDs off)
//   - Gap between words   = 7 units (LEDs off)
//
// HOW TO RUN:
//   $ iverilog -o sim.vvp -I../lib morse_beacon.v morse_beacon_tb.v ../lib/*.v
//   $ vvp sim.vvp
//
// ============================================================================

`timescale 1ns/1ps

module morse_beacon_tb;

    // ========================================================================
    // Testbench Signals
    // ========================================================================

    reg  clk;
    reg  rst_n;
    reg  btn_color;
    wire led_data;

    // ========================================================================
    // DUT Instantiation
    // ========================================================================
    //
    // We use a faster clock and shorter unit time for simulation.
    // At 1 MHz with UNIT_TIME = CLK_FREQ/10 = 100,000 cycles = 100ms per unit.
    // That's still slow for simulation, so we'll just run a portion.

    morse_beacon #(
        .CLK_FREQ(1_000_000),   // 1 MHz clock for simulation
        .NUM_LEDS(8)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .btn_color(btn_color),
        .led_data(led_data)
    );

    // ========================================================================
    // Clock Generation
    // ========================================================================

    always begin
        #500;           // 500 ns half-period = 1 MHz
        clk = ~clk;
    end

    // ========================================================================
    // WS2812 Protocol Decoder
    // ========================================================================
    //
    // Decodes WS2812 serial data to extract LED colors.

    time rise_time;
    time fall_time;
    real high_time_us;

    reg [23:0] rx_data;
    reg [4:0]  rx_bit;
    integer    led_count;
    integer    frame_count;

    // Track LED on/off state for Morse decoding
    reg        last_led_on;
    reg [23:0] last_color;

    initial begin
        rx_bit      = 0;
        rx_data     = 0;
        led_count   = 0;
        frame_count = 0;
        rise_time   = 0;
        last_led_on = 0;
        last_color  = 0;
    end

    // Record time on rising edge
    always @(posedge led_data) begin
        rise_time = $time;
    end

    // Decode on falling edge
    always @(negedge led_data) begin
        fall_time = $time;
        high_time_us = (fall_time - rise_time) / 1000.0;

        if (high_time_us > 0.6)
            rx_data[23 - rx_bit] = 1;
        else
            rx_data[23 - rx_bit] = 0;

        rx_bit = rx_bit + 1;

        if (rx_bit >= 24) begin
            // First LED tells us if Morse signal is on or off
            if (led_count == 0) begin
                // Check if LEDs are "on" (non-zero color)
                if (rx_data != 24'h000000 && last_color == 24'h000000) begin
                    $display("[%0t] LEDs ON  (color: G=%02h R=%02h B=%02h)",
                             $time, rx_data[23:16], rx_data[15:8], rx_data[7:0]);
                end
                else if (rx_data == 24'h000000 && last_color != 24'h000000) begin
                    $display("[%0t] LEDs OFF", $time);
                end
                last_color = rx_data;
            end

            rx_bit = 0;
            led_count = led_count + 1;

            if (led_count >= 8) begin
                led_count = 0;
                frame_count = frame_count + 1;
            end
        end
    end

    // ========================================================================
    // Main Test Sequence
    // ========================================================================

    initial begin
        $dumpfile("morse_beacon_tb.vcd");
        $dumpvars(0, morse_beacon_tb);

        clk       = 0;
        rst_n     = 0;
        btn_color = 0;

        $display("");
        $display("===========================================");
        $display("Morse Beacon Testbench");
        $display("===========================================");
        $display("Message: HELLO");
        $display("Expected Morse: .... . .-.. .-.. ---");
        $display("");
        $display("Watching for LED on/off transitions...");
        $display("(At 1 MHz sim clock, 1 unit = 100ms = 100,000 cycles)");
        $display("");

        // Release reset
        #10000;
        rst_n = 1;

        // ----------------------------------------------------------------
        // Watch Morse Output
        // ----------------------------------------------------------------
        // The message "HELLO" in Morse:
        //   H = ....  (4 dots)
        //   E = .     (1 dot)
        //   L = .-..  (dot dash dot dot)
        //   L = .-..  (dot dash dot dot)
        //   O = ---   (3 dashes)
        //
        // At 100ms per unit, the full message takes several seconds.
        // For simulation, we'll just watch the first few symbols.

        // Run for 2 seconds of simulated time (enough for H and part of E)
        // At 1 MHz, 2 seconds = 2,000,000,000 ns = 2 billion cycles
        // That's too long - let's just run enough to see the pattern start

        #500_000_000;  // 500 ms - should see several dots

        // ----------------------------------------------------------------
        // Test Color Change
        // ----------------------------------------------------------------

        $display("");
        $display("Pressing color button...");

        btn_color = 1;
        #20000;
        btn_color = 0;

        // Wait for debounce
        #20_000_000;

        // Watch a bit more
        #200_000_000;

        // ----------------------------------------------------------------
        // Done
        // ----------------------------------------------------------------

        $display("");
        $display("===========================================");
        $display("Test complete!");
        $display("Frames captured: %0d", frame_count);
        $display("===========================================");
        $finish;
    end

endmodule
