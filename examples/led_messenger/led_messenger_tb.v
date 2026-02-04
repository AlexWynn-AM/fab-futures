// ============================================================================
// LED Messenger Testbench
// ============================================================================
//
// This testbench verifies the WS2812 LED driver by:
//   1. Capturing the serial data sent to the LED strip
//   2. Decoding the WS2812 protocol to extract color values
//   3. Printing the color of each LED
//
// WS2812 PROTOCOL RECAP:
//   - Each bit is encoded as a pulse:
//       '0' bit: ~0.4µs HIGH, ~0.8µs LOW
//       '1' bit: ~0.8µs HIGH, ~0.4µs LOW
//   - Each LED needs 24 bits (8 green, 8 red, 8 blue)
//   - After all LEDs, hold LOW for 50µs to latch
//
// HOW TO RUN:
//   $ iverilog -o sim.vvp -I../lib led_messenger.v led_messenger_tb.v ../lib/*.v
//   $ vvp sim.vvp
//
// ============================================================================

`timescale 1ns/1ps

module led_messenger_tb;

    // ========================================================================
    // Testbench Signals
    // ========================================================================

    reg  clk;        // Clock
    reg  rst_n;      // Reset
    reg  btn_color;  // Color change button
    wire led_data;   // WS2812 data output

    // ========================================================================
    // DUT Instantiation
    // ========================================================================
    //
    // We use a 1 MHz clock for faster simulation.
    //
    // WS2812 timing at 1 MHz (1 µs per clock):
    //   T0H = 1 MHz / 2,500,000 ≈ 0.4 cycles → rounds to ~1 cycle
    //   T0L = 1 MHz / 1,250,000 ≈ 0.8 cycles → rounds to ~1 cycle
    //   T1H = 1 MHz / 1,250,000 ≈ 0.8 cycles → rounds to ~1 cycle
    //   T1L = 1 MHz / 2,500,000 ≈ 0.4 cycles → rounds to ~1 cycle
    //
    // At 1 MHz, the timing is compressed, but the protocol still works
    // for simulation purposes. Real hardware would use a faster clock.

    led_messenger #(
        .CLK_FREQ(1_000_000),   // 1 MHz clock
        .NUM_LEDS(8),           // 8 LEDs in strip
        .MSG_LEN(8)             // 8 character message
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
    // This decoder measures the HIGH pulse width to determine if each bit
    // is a '0' or '1', then assembles the 24-bit color values.
    //
    // Decoding strategy:
    //   - On rising edge: record the time
    //   - On falling edge: calculate pulse width
    //   - If pulse width > 0.5 µs, it's a '1'; otherwise '0'
    //   - After 24 bits, we have one complete LED color

    time rise_time;       // When the pulse started
    time fall_time;       // When the pulse ended
    real high_time_us;    // Pulse width in microseconds

    reg [23:0] rx_data;   // Accumulated color data (24 bits)
    reg [4:0]  rx_bit;    // Which bit we're on (0-23)
    integer    led_count; // Which LED we're receiving (0-7)

    // Initialize the decoder state
    initial begin
        rx_bit    = 0;
        rx_data   = 0;
        led_count = 0;
        rise_time = 0;
    end

    // Record time on rising edge
    always @(posedge led_data) begin
        rise_time = $time;
    end

    // Decode on falling edge
    always @(negedge led_data) begin
        fall_time = $time;

        // Calculate pulse width in microseconds
        // $time is in nanoseconds (due to timescale), so divide by 1000
        high_time_us = (fall_time - rise_time) / 1000.0;

        // Decode the bit based on pulse width
        // With our compressed timing, threshold around 0.6 µs works
        if (high_time_us > 0.6) begin
            // Long pulse = '1' bit
            rx_data[23 - rx_bit] = 1;
        end
        else begin
            // Short pulse = '0' bit
            rx_data[23 - rx_bit] = 0;
        end

        // Move to next bit
        rx_bit = rx_bit + 1;

        // After 24 bits, we have a complete LED color
        if (rx_bit >= 24) begin
            // Print the color (GRB format)
            $display("LED %0d: G=0x%02h R=0x%02h B=0x%02h",
                     led_count,
                     rx_data[23:16],   // Green (first 8 bits)
                     rx_data[15:8],    // Red (middle 8 bits)
                     rx_data[7:0]);    // Blue (last 8 bits)

            // Reset for next LED
            rx_bit = 0;
            led_count = led_count + 1;

            // After all LEDs, reset counter for next frame
            if (led_count >= 8) begin
                led_count = 0;
                $display("--- End of frame ---");
                $display("");
            end
        end
    end

    // ========================================================================
    // Main Test Sequence
    // ========================================================================

    initial begin
        // --------------------------------------------------------------------
        // Setup
        // --------------------------------------------------------------------

        $dumpfile("led_messenger_tb.vcd");
        $dumpvars(0, led_messenger_tb);

        clk       = 0;
        rst_n     = 0;
        btn_color = 0;

        // Release reset
        #10000;
        rst_n = 1;

        // --------------------------------------------------------------------
        // Watch a Few Frames
        // --------------------------------------------------------------------
        //
        // Let the DUT run and output a few frames of LED data.
        // Each frame sends 8 LEDs × 24 bits = 192 bits.
        // At ~1.2 µs per bit + reset time, each frame takes ~0.3 ms.

        $display("Watching LED output (first color mode)...");
        $display("Colors are in GRB (Green-Red-Blue) format");
        $display("");

        // Let it run for a few frames
        #5000000;  // 5 ms = several frames

        // --------------------------------------------------------------------
        // Change Color
        // --------------------------------------------------------------------

        $display("Pressing color button...");
        $display("");

        btn_color = 1;
        #20000;         // Brief press
        btn_color = 0;

        // Wait for debounce and watch new color
        #15000000;      // 15 ms for debounce
        #5000000;       // 5 ms more to see output

        // --------------------------------------------------------------------
        // Done
        // --------------------------------------------------------------------

        $display("Test complete!");
        $finish;
    end

endmodule
