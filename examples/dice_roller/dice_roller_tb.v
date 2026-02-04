// ============================================================================
// Dice Roller Testbench
// ============================================================================
//
// This testbench verifies the dice roller by:
//   1. Pressing the roll button multiple times
//   2. Checking that the 7-segment display shows valid dice values (1-6)
//   3. Monitoring the UART output for "Rolled: X" messages
//
// NOTE: The rolling animation takes 0.5 seconds at the DUT's clock frequency.
//       We use a 1 MHz clock, so the animation still takes 0.5 real seconds
//       of simulation time. This testbench may take a while to run!
//
// HOW TO RUN:
//   $ iverilog -o sim.vvp -I../lib dice_roller.v dice_roller_tb.v ../lib/*.v
//   $ vvp sim.vvp
//
// ============================================================================

`timescale 1ns/1ps

module dice_roller_tb;

    // ========================================================================
    // Testbench Signals
    // ========================================================================

    reg        clk;          // Clock
    reg        rst_n;        // Reset
    reg        btn_roll;     // Roll button
    wire [6:0] seg;          // 7-segment display output
    wire       tx;           // UART output
    wire       rolling_led;  // Rolling indicator LED

    // ========================================================================
    // DUT Instantiation
    // ========================================================================
    //
    // At 1 MHz clock:
    //   - Rolling animation lasts CLK_FREQ/2 = 500,000 cycles = 0.5 seconds
    //   - UART at 100 kbaud: 10 cycles per bit = 10 µs per bit

    dice_roller #(
        .CLK_FREQ(1_000_000),
        .BAUD(100_000)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .btn_roll(btn_roll),
        .seg(seg),
        .tx(tx),
        .rolling_led(rolling_led)
    );

    // ========================================================================
    // Clock Generation
    // ========================================================================

    always begin
        #500;           // 500 ns half-period = 1 MHz
        clk = ~clk;
    end

    // ========================================================================
    // 7-Segment Decoder (for verification)
    // ========================================================================
    //
    // This function converts the 7-segment pattern back to a number.
    // We use it to check what value is being displayed.
    //
    // 7-segment layout:
    //       aaa
    //      f   b
    //       ggg
    //      e   c
    //       ddd
    //
    // seg = {g, f, e, d, c, b, a}  (active LOW)

    function [3:0] decode_seg;
        input [6:0] s;
        begin
            case (s)
                7'b1111001: decode_seg = 1;  // Only b, c lit
                7'b0100100: decode_seg = 2;  // a, b, g, e, d lit
                7'b0110000: decode_seg = 3;  // a, b, g, c, d lit
                7'b0011001: decode_seg = 4;  // f, g, b, c lit
                7'b0010010: decode_seg = 5;  // a, f, g, c, d lit
                7'b0000010: decode_seg = 6;  // a, f, g, e, c, d lit
                default:    decode_seg = 0;  // Unknown pattern
            endcase
        end
    endfunction

    // ========================================================================
    // Roll Completion Monitor
    // ========================================================================
    //
    // We watch for the rolling_led to turn off, which indicates the roll
    // is complete and the final value is displayed.

    reg [3:0] last_result;

    always @(negedge rolling_led) begin
        if (rst_n) begin
            // Decode what's on the display
            last_result = decode_seg(seg);
            $display("  Rolled: %0d", last_result);
        end
    end

    // ========================================================================
    // UART Receiver (for monitoring)
    // ========================================================================
    //
    // Same as fortune_teller testbench - receives and prints UART data.

    localparam BIT_TIME = 10000;  // 10 µs per bit at 100 kbaud

    reg [7:0] rx_byte;
    integer i;

    always @(negedge tx) begin
        if (rst_n) begin
            #(BIT_TIME / 2);   // Wait to middle of start bit
            #BIT_TIME;         // Skip start bit

            // Sample 8 data bits
            for (i = 0; i < 8; i = i + 1) begin
                rx_byte[i] = tx;
                #BIT_TIME;
            end

            // Print received character
            if (rx_byte >= 32 && rx_byte < 127)
                $write("%c", rx_byte);
            else if (rx_byte == 10)
                $write("\n");
        end
    end

    // ========================================================================
    // Main Test Sequence
    // ========================================================================

    integer roll_count;

    initial begin
        // --------------------------------------------------------------------
        // Setup
        // --------------------------------------------------------------------

        $dumpfile("dice_roller_tb.vcd");
        $dumpvars(0, dice_roller_tb);

        clk      = 0;
        rst_n    = 0;
        btn_roll = 0;

        // Release reset
        #10000;
        rst_n = 1;
        #50000;

        // --------------------------------------------------------------------
        // Roll the Dice Multiple Times
        // --------------------------------------------------------------------
        //
        // We roll 5 times to see different results. Each roll involves:
        //   1. Press button for 15 ms (to pass debouncer)
        //   2. Wait 550 ms for animation to complete (500 ms + margin)
        //
        // Total time per roll: ~565 ms
        // Total test time: ~3 seconds

        $display("Rolling dice 5 times...");
        $display("(Each roll takes ~0.5 seconds for the animation)");
        $display("");

        for (roll_count = 1; roll_count <= 5; roll_count = roll_count + 1) begin
            $display("Roll #%0d:", roll_count);

            // Press button (must hold > 10 ms for debounce)
            btn_roll = 1;
            #15000000;          // Hold for 15 ms
            btn_roll = 0;

            // Wait for rolling animation to complete
            // Animation is CLK_FREQ/2 = 500,000 cycles = 500 ms
            // Add some margin
            #550000000;         // Wait 550 ms

            $display("");       // Blank line between rolls
        end

        // --------------------------------------------------------------------
        // Done
        // --------------------------------------------------------------------

        $display("Test complete!");
        $finish;
    end

endmodule
