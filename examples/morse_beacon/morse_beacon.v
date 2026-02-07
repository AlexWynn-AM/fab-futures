// ============================================================================
// LED Morse Beacon - Your Message in Morse Code
// ============================================================================
//
// HOW IT WORKS:
//   1. Chip drives a strip of WS2812 (NeoPixel) LEDs
//   2. All LEDs flash together to send Morse code
//   3. Press button to change colors
//
// WHAT YOU'LL LEARN:
//   - Precise timing for serial protocols (WS2812)
//   - State machines for sequencing
//   - Encoding data (ASCII to Morse)
//
// MORSE CODE TIMING:
//   - Dot  = 1 unit
//   - Dash = 3 units
//   - Gap between dots/dashes = 1 unit
//   - Gap between letters = 3 units
//   - Gap between words = 7 units
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
//
// OTHER USES FOR THIS CODE:
//   - VU meter / level display (map input to number of lit LEDs)
//   - Battery gauge
//   - Progress bar
//   - Temperature indicator
//   - Binary counter display
//
// ============================================================================

module led_level_meter #(
    parameter CLK_FREQ = 50_000_000,  // Clock speed in Hz
    parameter NUM_LEDS = 8            // How many LEDs in your strip
)(
    input  wire clk,
    input  wire rst_n,
    input  wire btn_color,   // Button to cycle colors
    output wire led_data     // Data output to WS2812 strip
);

    // ========================================================================
    // YOUR MESSAGE - EDIT THIS!
    // ========================================================================
    // Each character will be converted to Morse code and flashed.

    localparam MSG_LEN = 5;
    reg [7:0] message [0:MSG_LEN-1];

    initial begin
        message[0] = "H";  // ....
        message[1] = "E";  // .
        message[2] = "L";  // .-..
        message[3] = "L";  // .-..
        message[4] = "O";  // ---
    end

    // ========================================================================
    // Morse Code Lookup Table
    // ========================================================================
    // Each entry: {length[3:0], pattern[7:0]}
    // Pattern is sent LSB first. 0=dot, 1=dash.
    // Example: 'A' = .- = 2 symbols, pattern = 01 (dot first, then dash)

    function [11:0] get_morse;
        input [7:0] char;
        begin
            case (char)
                "A": get_morse = {4'd2, 8'b00000010};  // .-
                "B": get_morse = {4'd4, 8'b00000001};  // -...
                "C": get_morse = {4'd4, 8'b00000101};  // -.-.
                "D": get_morse = {4'd3, 8'b00000001};  // -..
                "E": get_morse = {4'd1, 8'b00000000};  // .
                "F": get_morse = {4'd4, 8'b00000100};  // ..-.
                "G": get_morse = {4'd3, 8'b00000011};  // --.
                "H": get_morse = {4'd4, 8'b00000000};  // ....
                "I": get_morse = {4'd2, 8'b00000000};  // ..
                "J": get_morse = {4'd4, 8'b00001110};  // .---
                "K": get_morse = {4'd3, 8'b00000101};  // -.-
                "L": get_morse = {4'd4, 8'b00000010};  // .-..
                "M": get_morse = {4'd2, 8'b00000011};  // --
                "N": get_morse = {4'd2, 8'b00000001};  // -.
                "O": get_morse = {4'd3, 8'b00000111};  // ---
                "P": get_morse = {4'd4, 8'b00000110};  // .--.
                "Q": get_morse = {4'd4, 8'b00001011};  // --.-
                "R": get_morse = {4'd3, 8'b00000010};  // .-.
                "S": get_morse = {4'd3, 8'b00000000};  // ...
                "T": get_morse = {4'd1, 8'b00000001};  // -
                "U": get_morse = {4'd3, 8'b00000100};  // ..-
                "V": get_morse = {4'd4, 8'b00001000};  // ...-
                "W": get_morse = {4'd3, 8'b00000110};  // .--
                "X": get_morse = {4'd4, 8'b00001001};  // -..-
                "Y": get_morse = {4'd4, 8'b00001101};  // -.--
                "Z": get_morse = {4'd4, 8'b00000011};  // --..
                " ": get_morse = {4'd0, 8'b00000000};  // Word gap (special)
                default: get_morse = {4'd0, 8'b00000000};
            endcase
        end
    endfunction

    // ========================================================================
    // Timing Parameters
    // ========================================================================
    // Morse timing: 1 unit = 100ms at standard speed (adjustable)

    localparam UNIT_TIME = CLK_FREQ / 10;  // 100ms per unit
    localparam DOT_TIME  = UNIT_TIME;      // 1 unit
    localparam DASH_TIME = UNIT_TIME * 3;  // 3 units
    localparam SYM_GAP   = UNIT_TIME;      // 1 unit between symbols
    localparam CHAR_GAP  = UNIT_TIME * 3;  // 3 units between characters
    localparam WORD_GAP  = UNIT_TIME * 7;  // 7 units between words

    // ========================================================================
    // Color Selection
    // ========================================================================

    wire btn_pressed;

    debounce #(.CLK_FREQ(CLK_FREQ)) debounce_inst (
        .clk(clk),
        .rst_n(rst_n),
        .btn_raw(btn_color),
        .btn_pressed(btn_pressed)
    );

    reg [1:0] color_mode;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            color_mode <= 0;
        else if (btn_pressed)
            color_mode <= color_mode + 1;
    end

    reg [23:0] on_color;   // Color when LED is "on" (GRB format)
    reg [23:0] off_color;  // Color when LED is "off"

    always @(*) begin
        case (color_mode)
            2'd0: begin on_color = 24'h00FF00; off_color = 24'h000000; end  // Red
            2'd1: begin on_color = 24'hFF0000; off_color = 24'h000000; end  // Green
            2'd2: begin on_color = 24'h0000FF; off_color = 24'h000000; end  // Blue
            2'd3: begin on_color = 24'hFFFFFF; off_color = 24'h050500; end  // White on dim
        endcase
    end

    // ========================================================================
    // Morse Code State Machine
    // ========================================================================

    localparam MS_IDLE     = 3'd0;  // Starting / between messages
    localparam MS_LOAD     = 3'd1;  // Load next character
    localparam MS_SYMBOL   = 3'd2;  // Sending dot or dash (LEDs on)
    localparam MS_SYM_GAP  = 3'd3;  // Gap between symbols
    localparam MS_CHAR_GAP = 3'd4;  // Gap between characters
    localparam MS_WORD_GAP = 3'd5;  // Gap between words

    reg [2:0]  morse_state;
    reg [3:0]  char_idx;       // Which character in message
    reg [11:0] morse_data;     // Current character's morse {len, pattern}
    reg [2:0]  symbol_idx;     // Which symbol within character
    reg [31:0] morse_timer;    // Timing counter
    reg        leds_on;        // Should LEDs be lit?

    wire [3:0] morse_len = morse_data[11:8];
    wire       is_dash   = morse_data[symbol_idx];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            morse_state <= MS_IDLE;
            char_idx    <= 0;
            morse_data  <= 0;
            symbol_idx  <= 0;
            morse_timer <= 0;
            leds_on     <= 0;
        end
        else begin
            case (morse_state)

                MS_IDLE: begin
                    leds_on <= 0;
                    morse_timer <= morse_timer + 1;
                    // Brief pause before starting message
                    if (morse_timer >= WORD_GAP) begin
                        morse_timer <= 0;
                        char_idx <= 0;
                        morse_state <= MS_LOAD;
                    end
                end

                MS_LOAD: begin
                    leds_on <= 0;
                    morse_data <= get_morse(message[char_idx]);
                    symbol_idx <= 0;
                    morse_timer <= 0;

                    // Check for space (word gap) or regular character
                    if (message[char_idx] == " " || get_morse(message[char_idx])[11:8] == 0)
                        morse_state <= MS_WORD_GAP;
                    else
                        morse_state <= MS_SYMBOL;
                end

                MS_SYMBOL: begin
                    leds_on <= 1;  // LEDs on during dot/dash
                    morse_timer <= morse_timer + 1;

                    // Dot = 1 unit, Dash = 3 units
                    if ((is_dash && morse_timer >= DASH_TIME) ||
                        (!is_dash && morse_timer >= DOT_TIME)) begin
                        morse_timer <= 0;
                        leds_on <= 0;
                        symbol_idx <= symbol_idx + 1;

                        // More symbols in this character?
                        if (symbol_idx + 1 >= morse_len)
                            morse_state <= MS_CHAR_GAP;
                        else
                            morse_state <= MS_SYM_GAP;
                    end
                end

                MS_SYM_GAP: begin
                    leds_on <= 0;
                    morse_timer <= morse_timer + 1;
                    if (morse_timer >= SYM_GAP) begin
                        morse_timer <= 0;
                        morse_state <= MS_SYMBOL;
                    end
                end

                MS_CHAR_GAP: begin
                    leds_on <= 0;
                    morse_timer <= morse_timer + 1;
                    if (morse_timer >= CHAR_GAP) begin
                        morse_timer <= 0;
                        char_idx <= char_idx + 1;

                        // More characters?
                        if (char_idx + 1 >= MSG_LEN)
                            morse_state <= MS_IDLE;  // Restart message
                        else
                            morse_state <= MS_LOAD;
                    end
                end

                MS_WORD_GAP: begin
                    leds_on <= 0;
                    morse_timer <= morse_timer + 1;
                    if (morse_timer >= WORD_GAP) begin
                        morse_timer <= 0;
                        char_idx <= char_idx + 1;

                        if (char_idx + 1 >= MSG_LEN)
                            morse_state <= MS_IDLE;
                        else
                            morse_state <= MS_LOAD;
                    end
                end

            endcase
        end
    end

    // ========================================================================
    // WS2812 Driver
    // ========================================================================
    // Generates the precise timing needed to control WS2812 LEDs.

    localparam T0H    = CLK_FREQ / 2_500_000;   // 0.4µs
    localparam T0L    = CLK_FREQ / 1_250_000;   // 0.8µs
    localparam T1H    = CLK_FREQ / 1_250_000;   // 0.8µs
    localparam T1L    = CLK_FREQ / 2_500_000;   // 0.4µs
    localparam TRESET = CLK_FREQ / 20_000;      // 50µs

    localparam WS_RESET = 2'd0;
    localparam WS_LOAD  = 2'd1;
    localparam WS_HIGH  = 2'd2;
    localparam WS_LOW   = 2'd3;

    reg [1:0]  ws_state;
    reg [2:0]  led_idx;
    reg [4:0]  bit_idx;
    reg [23:0] pixel_data;
    reg [15:0] timer;
    reg        data_out;

    // All LEDs show the same color based on morse state
    wire [23:0] current_color = leds_on ? on_color : off_color;

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

                WS_RESET: begin
                    data_out <= 0;
                    timer <= timer + 1;
                    if (timer >= TRESET) begin
                        timer <= 0;
                        led_idx <= 0;
                        ws_state <= WS_LOAD;
                    end
                end

                WS_LOAD: begin
                    pixel_data <= current_color;
                    bit_idx <= 23;
                    ws_state <= WS_HIGH;
                    timer <= 0;
                end

                WS_HIGH: begin
                    data_out <= 1;
                    timer <= timer + 1;

                    if (pixel_data[bit_idx]) begin
                        if (timer >= T1H - 1) begin
                            timer <= 0;
                            ws_state <= WS_LOW;
                        end
                    end
                    else begin
                        if (timer >= T0H - 1) begin
                            timer <= 0;
                            ws_state <= WS_LOW;
                        end
                    end
                end

                WS_LOW: begin
                    data_out <= 0;
                    timer <= timer + 1;

                    if (pixel_data[bit_idx]) begin
                        if (timer >= T1L - 1) begin
                            timer <= 0;
                            if (bit_idx == 0) begin
                                if (led_idx >= NUM_LEDS - 1)
                                    ws_state <= WS_RESET;
                                else begin
                                    led_idx <= led_idx + 1;
                                    ws_state <= WS_LOAD;
                                end
                            end
                            else begin
                                bit_idx <= bit_idx - 1;
                                ws_state <= WS_HIGH;
                            end
                        end
                    end
                    else begin
                        if (timer >= T0L - 1) begin
                            timer <= 0;
                            if (bit_idx == 0) begin
                                if (led_idx >= NUM_LEDS - 1)
                                    ws_state <= WS_RESET;
                                else begin
                                    led_idx <= led_idx + 1;
                                    ws_state <= WS_LOAD;
                                end
                            end
                            else begin
                                bit_idx <= bit_idx - 1;
                                ws_state <= WS_HIGH;
                            end
                        end
                    end
                end

            endcase
        end
    end

    assign led_data = data_out;

endmodule
