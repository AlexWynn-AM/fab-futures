// ============================================================================
// LED Messenger - Your Name in Lights
// ============================================================================
//
// HOW IT WORKS:
//   1. Chip drives a strip of WS2812 (NeoPixel) LEDs
//   2. Your message scrolls across the LEDs
//   3. Press button to change colors
//
// WHAT YOU'LL LEARN:
//   - Precise timing for serial protocols
//   - Bit-banging (generating protocols in software/hardware)
//   - Simple graphics with a font
//
// ABOUT WS2812 LEDs:
//   These "smart" LEDs have a built-in chip. You send color data one bit
//   at a time using precise pulse widths:
//
//   Sending a '0' bit:        Sending a '1' bit:
//   ┌──┐                      ┌────────┐
//   │  │                      │        │
//   └──┴──────────            └────────┴────
//   0.4µs HIGH, 0.8µs LOW     0.8µs HIGH, 0.4µs LOW
//
//   Each LED needs 24 bits: 8 green, 8 red, 8 blue (yes, GRB order!)
//   After sending all LED data, hold LOW for 50µs to latch.
//
// ============================================================================

module led_messenger #(
    // ========================================================================
    // Parameters
    // ========================================================================
    parameter CLK_FREQ = 50_000_000,  // Clock speed in Hz
    parameter NUM_LEDS = 8,           // How many LEDs in your strip
    parameter MSG_LEN  = 8            // Characters in your message
)(
    // ========================================================================
    // Ports
    // ========================================================================
    input  wire clk,         // Clock input
    input  wire rst_n,       // Reset (active LOW)
    input  wire btn_color,   // Button to cycle colors
    output wire led_data     // Data output to WS2812 strip (just 1 wire!)
);

    // ========================================================================
    // YOUR MESSAGE - EDIT THIS!
    // ========================================================================

    reg [7:0] message [0:MSG_LEN-1];

    initial begin
        message[0] = "H";
        message[1] = "E";
        message[2] = "L";
        message[3] = "L";
        message[4] = "O";
        message[5] = " ";
        message[6] = " ";
        message[7] = " ";
    end

    // ========================================================================
    // Simple 5x3 Font
    // ========================================================================
    //
    // Each character is stored as a 15-bit pattern (5 rows × 3 columns).
    // A '1' means the pixel is lit, '0' means off.
    //
    // Example: Letter 'H'
    //   Row 0:  # . #  = 101
    //   Row 1:  # . #  = 101
    //   Row 2:  # # #  = 111
    //   Row 3:  # . #  = 101
    //   Row 4:  # . #  = 101
    //
    // Packed as: 101_101_111_101_101 = 15'b101101111101101

    reg [14:0] font [0:127];  // ASCII lookup table

    initial begin
        // Initialize common characters
        font["H"] = 15'b101_101_111_101_101;
        font["E"] = 15'b111_100_111_100_111;
        font["L"] = 15'b100_100_100_100_111;
        font["O"] = 15'b111_101_101_101_111;
        font[" "] = 15'b000_000_000_000_000;
        font["I"] = 15'b111_010_010_010_111;
        font["W"] = 15'b101_101_101_111_101;
        font["R"] = 15'b111_101_111_110_101;
        font["D"] = 15'b110_101_101_101_110;
        font["A"] = 15'b010_101_111_101_101;
        font["B"] = 15'b110_101_110_101_110;
        font["C"] = 15'b011_100_100_100_011;
        font["N"] = 15'b101_111_111_111_101;
        font["S"] = 15'b011_100_010_001_110;
        font["T"] = 15'b111_010_010_010_010;
        font["U"] = 15'b101_101_101_101_111;
        font["Y"] = 15'b101_101_010_010_010;
    end

    // ========================================================================
    // Color Palette
    // ========================================================================

    wire btn_pressed;

    debounce #(
        .CLK_FREQ(CLK_FREQ)
    ) debounce_inst (
        .clk(clk),
        .rst_n(rst_n),
        .btn_raw(btn_color),
        .btn_pressed(btn_pressed)
    );

    // Cycle through 4 color modes
    reg [1:0] color_mode;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            color_mode <= 0;
        else if (btn_pressed)
            color_mode <= color_mode + 1;
    end

    // Define foreground and background colors (GRB format for WS2812)
    reg [23:0] fg_color;  // Foreground (text) color
    reg [23:0] bg_color;  // Background color

    always @(*) begin
        case (color_mode)
            2'd0: begin  // Green on black
                fg_color = 24'hFF0000;  // GRB: G=FF, R=00, B=00
                bg_color = 24'h000000;
            end
            2'd1: begin  // Red on black
                fg_color = 24'h00FF00;  // GRB: G=00, R=FF, B=00
                bg_color = 24'h000000;
            end
            2'd2: begin  // Blue on black
                fg_color = 24'h0000FF;  // GRB: G=00, R=00, B=FF
                bg_color = 24'h000000;
            end
            2'd3: begin  // White on dim blue
                fg_color = 24'hFFFFFF;
                bg_color = 24'h000005;
            end
        endcase
    end

    // ========================================================================
    // Scrolling Animation
    // ========================================================================
    //
    // We scroll the message by shifting which "column" we start displaying from.
    // Each character is 3 columns wide + 1 column gap = 4 columns per character.

    localparam SCROLL_RATE = CLK_FREQ / 8;  // Scroll speed: 8 columns per second

    reg [25:0] scroll_timer;
    reg [7:0]  scroll_pos;  // Current scroll position (column offset)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scroll_timer <= 0;
            scroll_pos   <= 0;
        end
        else begin
            scroll_timer <= scroll_timer + 1;

            if (scroll_timer >= SCROLL_RATE) begin
                scroll_timer <= 0;

                // Wrap around when we've scrolled past the whole message
                if (scroll_pos >= (MSG_LEN * 4) - 1)
                    scroll_pos <= 0;
                else
                    scroll_pos <= scroll_pos + 1;
            end
        end
    end

    // ========================================================================
    // Pixel Color Calculation
    // ========================================================================
    //
    // For each LED, determine if it should show foreground or background color.
    // We arrange LEDs vertically (LED 0 at top, LED 7 at bottom).
    // The middle 5 LEDs (1-5) show the font; LEDs 0 and 7 are blank padding.

    function get_pixel_on;
        input [2:0] led_idx;   // Which LED (0-7, top to bottom)
        input [7:0] scroll;    // Current scroll position

        reg [7:0]  char_idx;   // Which character in the message
        reg [1:0]  col;        // Which column within the character (0-2, or 3=gap)
        reg [2:0]  row;        // Which row of the font (0-4)
        reg [14:0] pattern;    // The character's font pattern
    begin
        // LEDs 0 and 6-7 are padding (always off)
        if (led_idx < 1 || led_idx > 5) begin
            get_pixel_on = 0;
        end
        else begin
            // Map LED index to font row (LED 1 = row 0, LED 5 = row 4)
            row = led_idx - 1;

            // Calculate which character and column we're displaying
            char_idx = scroll / 4;       // Each char takes 4 columns
            col = scroll % 4;            // Position within the 4-column group

            // Column 3 is the gap between characters
            if (col == 3 || char_idx >= MSG_LEN) begin
                get_pixel_on = 0;
            end
            else begin
                // Look up the font pattern for this character
                pattern = font[message[char_idx]];

                // Extract the bit for this (row, col) position
                // Font is packed: row 0 is bits [14:12], row 1 is [11:9], etc.
                // Within each row, col 0 is the MSB, col 2 is the LSB
                get_pixel_on = pattern[(4 - row) * 3 + (2 - col)];
            end
        end
    end
    endfunction

    // ========================================================================
    // WS2812 Timing Parameters
    // ========================================================================
    //
    // At 50 MHz clock (20ns per cycle):
    //   T0H (0 bit high time) = 0.4µs = 20 cycles
    //   T0L (0 bit low time)  = 0.8µs = 40 cycles
    //   T1H (1 bit high time) = 0.8µs = 40 cycles
    //   T1L (1 bit low time)  = 0.4µs = 20 cycles
    //   TRESET (latch time)   = 50µs  = 2500 cycles

    localparam T0H    = CLK_FREQ / 2_500_000;   // 0.4µs
    localparam T0L    = CLK_FREQ / 1_250_000;   // 0.8µs
    localparam T1H    = CLK_FREQ / 1_250_000;   // 0.8µs
    localparam T1L    = CLK_FREQ / 2_500_000;   // 0.4µs
    localparam TRESET = CLK_FREQ / 20_000;      // 50µs

    // ========================================================================
    // WS2812 Driver State Machine
    // ========================================================================

    // States
    localparam WS_RESET = 2'd0;  // Sending reset (50µs LOW)
    localparam WS_LOAD  = 2'd1;  // Loading pixel color
    localparam WS_HIGH  = 2'd2;  // Sending HIGH portion of bit
    localparam WS_LOW   = 2'd3;  // Sending LOW portion of bit

    reg [1:0]  ws_state;
    reg [2:0]  led_idx;      // Which LED we're sending (0 to NUM_LEDS-1)
    reg [4:0]  bit_idx;      // Which bit of the 24-bit color (23 down to 0)
    reg [23:0] pixel_data;   // Current LED's color (GRB)
    reg [15:0] timer;        // General purpose timer
    reg        data_out;     // The actual output bit

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ws_state   <= WS_RESET;
            led_idx    <= 0;
            bit_idx    <= 0;
            pixel_data <= 0;
            timer      <= 0;
            data_out   <= 0;
        end
        else begin
            case (ws_state)

                // ============================================================
                // RESET: Hold line LOW for 50µs to latch data
                // ============================================================
                WS_RESET: begin
                    data_out <= 0;
                    timer    <= timer + 1;

                    if (timer >= TRESET) begin
                        timer   <= 0;
                        led_idx <= 0;
                        ws_state <= WS_LOAD;
                    end
                end

                // ============================================================
                // LOAD: Get the color for the current LED
                // ============================================================
                WS_LOAD: begin
                    // Determine if this pixel should be lit or not
                    if (get_pixel_on(led_idx, scroll_pos))
                        pixel_data <= fg_color;
                    else
                        pixel_data <= bg_color;

                    bit_idx  <= 23;      // Start with MSB (bit 23)
                    ws_state <= WS_HIGH;
                    timer    <= 0;
                end

                // ============================================================
                // HIGH: Output HIGH for appropriate duration
                // ============================================================
                WS_HIGH: begin
                    data_out <= 1;
                    timer    <= timer + 1;

                    // High time depends on whether we're sending 0 or 1
                    if (pixel_data[bit_idx]) begin
                        // Sending a '1': stay HIGH for T1H cycles
                        if (timer >= T1H - 1) begin
                            timer    <= 0;
                            ws_state <= WS_LOW;
                        end
                    end
                    else begin
                        // Sending a '0': stay HIGH for T0H cycles
                        if (timer >= T0H - 1) begin
                            timer    <= 0;
                            ws_state <= WS_LOW;
                        end
                    end
                end

                // ============================================================
                // LOW: Output LOW for appropriate duration
                // ============================================================
                WS_LOW: begin
                    data_out <= 0;
                    timer    <= timer + 1;

                    // Low time depends on whether we're sending 0 or 1
                    if (pixel_data[bit_idx]) begin
                        // Sending a '1': stay LOW for T1L cycles
                        if (timer >= T1L - 1) begin
                            timer <= 0;

                            // Move to next bit or next LED
                            if (bit_idx == 0) begin
                                // Done with this LED
                                if (led_idx >= NUM_LEDS - 1) begin
                                    // Done with all LEDs, send reset
                                    ws_state <= WS_RESET;
                                end
                                else begin
                                    // Move to next LED
                                    led_idx  <= led_idx + 1;
                                    ws_state <= WS_LOAD;
                                end
                            end
                            else begin
                                // Move to next bit
                                bit_idx  <= bit_idx - 1;
                                ws_state <= WS_HIGH;
                            end
                        end
                    end
                    else begin
                        // Sending a '0': stay LOW for T0L cycles
                        if (timer >= T0L - 1) begin
                            timer <= 0;

                            // Move to next bit or next LED (same logic as above)
                            if (bit_idx == 0) begin
                                if (led_idx >= NUM_LEDS - 1) begin
                                    ws_state <= WS_RESET;
                                end
                                else begin
                                    led_idx  <= led_idx + 1;
                                    ws_state <= WS_LOAD;
                                end
                            end
                            else begin
                                bit_idx  <= bit_idx - 1;
                                ws_state <= WS_HIGH;
                            end
                        end
                    end
                end

            endcase
        end
    end

    // Connect state machine output to the actual pin
    assign led_data = data_out;

endmodule
