// ============================================================================
// Dice Roller - Hardware Random Dice
// ============================================================================
//
// HOW IT WORKS:
//   1. Press the roll button
//   2. Display shows a quick "rolling" animation (cycling 1-6)
//   3. Animation stops on a random number
//   4. Result is also sent to serial (for logging your D&D game!)
//
// WHAT YOU'LL LEARN:
//   - 7-segment display driving
//   - Animation timing
//   - Combining multiple modules (display + UART + random)
//
// ============================================================================

module dice_roller #(
    // ========================================================================
    // Parameters
    // ========================================================================
    parameter CLK_FREQ = 50_000_000,  // Clock speed in Hz
    parameter BAUD     = 115200       // Serial baud rate
)(
    // ========================================================================
    // Ports
    // ========================================================================
    input  wire       clk,         // Clock input
    input  wire       rst_n,       // Reset (active LOW)
    input  wire       btn_roll,    // Roll button
    output wire [6:0] seg,         // 7-segment display (active LOW)
    output wire       tx,          // Serial output
    output wire       rolling_led  // LED on while rolling
);

    // ========================================================================
    // Button Debouncing
    // ========================================================================

    wire roll_pressed;  // Clean button signal

    debounce #(
        .CLK_FREQ(CLK_FREQ)
    ) debounce_inst (
        .clk(clk),
        .rst_n(rst_n),
        .btn_raw(btn_roll),
        .btn_pressed(roll_pressed)
    );

    // ========================================================================
    // LFSR Random Number Generator
    // ========================================================================
    //
    // Same as the fortune teller - runs continuously, button timing picks value.
    // We use a 16-bit LFSR for longer sequences.

    reg [15:0] lfsr;

    // Feedback taps for maximal-length 16-bit sequence
    wire feedback = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr <= 16'hBEEF;  // Seed (any non-zero value)
        else
            lfsr <= {lfsr[14:0], feedback};
    end

    // ========================================================================
    // Convert LFSR to Dice Value (1-6)
    // ========================================================================
    //
    // The LFSR gives us values 0-7 (3 bits), but dice are 1-6.
    // We map: 0->1, 1->2, 2->3, 3->4, 4->5, 5->6, 6->1, 7->2
    //
    // Simple formula: ((value % 6) + 1) = valid dice roll

    wire [2:0] raw_roll = lfsr[2:0];  // Take 3 bits (0-7)

    // If 0-5, add 1 to get 1-6. If 6-7, subtract 5 to get 1-2.
    wire [2:0] dice_val = (raw_roll > 5) ? (raw_roll - 5) : (raw_roll + 1);

    // ========================================================================
    // Animation Timing
    // ========================================================================
    //
    // ROLL_CYCLES = how long the rolling animation lasts (0.5 seconds)
    // STEP_CYCLES = how fast the numbers cycle during animation (50ms per step)

    localparam ROLL_CYCLES = CLK_FREQ / 2;   // 0.5 seconds total
    localparam STEP_CYCLES = CLK_FREQ / 20;  // 50ms per animation frame

    // ========================================================================
    // State Machine
    // ========================================================================

    // States
    localparam IDLE    = 2'd0;  // Waiting for button
    localparam ROLLING = 2'd1;  // Showing animation
    localparam SHOW    = 2'd2;  // Displaying final result

    reg [1:0]  state;
    reg [25:0] roll_timer;   // Counts total rolling time
    reg [19:0] step_timer;   // Counts time per animation step
    reg [2:0]  display_val;  // What's shown on the display (1-6)
    reg [2:0]  anim_counter; // Cycles 1-6 during animation
    reg        send_result;  // Trigger to send result via UART

    // ========================================================================
    // Main State Machine
    // ========================================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset everything
            state        <= IDLE;
            roll_timer   <= 0;
            step_timer   <= 0;
            display_val  <= 1;
            anim_counter <= 1;
            send_result  <= 0;
        end
        else begin
            // Default: don't send result
            send_result <= 0;

            case (state)

                // ============================================================
                // IDLE: Wait for button press
                // ============================================================
                IDLE: begin
                    if (roll_pressed) begin
                        state      <= ROLLING;
                        roll_timer <= 0;
                        step_timer <= 0;
                    end
                end

                // ============================================================
                // ROLLING: Show animation, then capture result
                // ============================================================
                ROLLING: begin
                    // Increment timers
                    roll_timer <= roll_timer + 1;
                    step_timer <= step_timer + 1;

                    // Animation: cycle through 1-6 rapidly
                    if (step_timer >= STEP_CYCLES) begin
                        step_timer <= 0;

                        // Cycle: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 1 -> ...
                        if (anim_counter >= 6)
                            anim_counter <= 1;
                        else
                            anim_counter <= anim_counter + 1;

                        // Show the cycling number
                        display_val <= anim_counter;
                    end

                    // After ROLL_CYCLES, stop and capture the result
                    if (roll_timer >= ROLL_CYCLES) begin
                        display_val <= dice_val;  // Capture random value
                        send_result <= 1;         // Trigger UART send
                        state       <= SHOW;
                        roll_timer  <= 0;
                    end
                end

                // ============================================================
                // SHOW: Display result for 2 seconds
                // ============================================================
                SHOW: begin
                    roll_timer <= roll_timer + 1;

                    // After 2 seconds, go back to idle
                    if (roll_timer >= CLK_FREQ * 2) begin
                        state <= IDLE;
                    end

                    // Allow re-roll while displaying
                    if (roll_pressed) begin
                        state      <= ROLLING;
                        roll_timer <= 0;
                        step_timer <= 0;
                    end
                end

                // Default case (shouldn't happen)
                default: state <= IDLE;

            endcase
        end
    end

    // LED is on while rolling
    assign rolling_led = (state == ROLLING);

    // ========================================================================
    // 7-Segment Display Decoder
    // ========================================================================
    //
    // A 7-segment display has 7 LEDs arranged like this:
    //
    //      aaaa
    //     f    b
    //     f    b
    //      gggg
    //     e    c
    //     e    c
    //      dddd
    //
    // We output a 7-bit value: {g, f, e, d, c, b, a}
    // For active-LOW displays, 0 = LED on, 1 = LED off

    reg [6:0] seg_pattern;

    always @(*) begin
        case (display_val)
            //                   gfedcba
            3'd1: seg_pattern = 7'b1111001;  // 1: segments b, c on
            3'd2: seg_pattern = 7'b0100100;  // 2: a, b, g, e, d on
            3'd3: seg_pattern = 7'b0110000;  // 3: a, b, g, c, d on
            3'd4: seg_pattern = 7'b0011001;  // 4: f, g, b, c on
            3'd5: seg_pattern = 7'b0010010;  // 5: a, f, g, c, d on
            3'd6: seg_pattern = 7'b0000010;  // 6: a, f, g, e, c, d on
            default: seg_pattern = 7'b1111111;  // All off (blank)
        endcase
    end

    assign seg = seg_pattern;

    // ========================================================================
    // UART: Send "Rolled: N\n" when result is ready
    // ========================================================================

    // Message storage: "Rolled: X\n" = 10 characters
    reg [7:0] message [0:9];

    initial begin
        message[0] = 8'h52;  // 'R'
        message[1] = 8'h6F;  // 'o'
        message[2] = 8'h6C;  // 'l'
        message[3] = 8'h6C;  // 'l'
        message[4] = 8'h65;  // 'e'
        message[5] = 8'h64;  // 'd'
        message[6] = 8'h3A;  // ':'
        message[7] = 8'h20;  // ' '
        message[8] = 8'h3F;  // '?' (placeholder, replaced with digit)
        message[9] = 8'h0A;  // '\n'
    end

    // UART control signals
    reg [3:0] msg_idx;    // Which character we're sending (0-9)
    reg       sending;    // Are we in the middle of sending?
    reg [7:0] tx_data;    // Character to send
    reg       tx_valid;   // Start UART transmission
    wire      tx_ready;   // UART is ready for next character

    // State machine for sending the message
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sending  <= 0;
            msg_idx  <= 0;
            tx_valid <= 0;
            tx_data  <= 0;
        end
        else begin
            tx_valid <= 0;  // Default: don't start transmission

            // When a result is ready, start sending
            if (send_result) begin
                sending <= 1;
                msg_idx <= 0;
                // Update the digit in the message
                message[8] <= 8'h30 + display_val;  // 0x30 = '0', so '0'+3 = '3'
            end

            // Send characters one by one
            if (sending && tx_ready && !tx_valid) begin
                if (msg_idx < 10) begin
                    tx_data  <= message[msg_idx];
                    tx_valid <= 1;
                    msg_idx  <= msg_idx + 1;
                end
                else begin
                    // Done sending all characters
                    sending <= 0;
                end
            end
        end
    end

    // UART transmitter instance
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(BAUD)
    ) uart_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data(tx_data),
        .valid(tx_valid),
        .ready(tx_ready),
        .tx(tx)
    );

endmodule
