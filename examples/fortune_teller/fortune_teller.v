// ============================================================================
// Fortune Teller - A Magic 8-Ball on a Chip
// ============================================================================
//
// HOW IT WORKS:
//   1. Press the button
//   2. Chip picks a random fortune from memory
//   3. Fortune appears on your computer's serial terminal
//
// WHAT YOU'LL LEARN:
//   - ROM (Read-Only Memory) - storing data in your chip
//   - LFSR (Linear Feedback Shift Register) - generating random numbers
//   - State machines - controlling the sequence of operations
//   - Using library modules - connecting pre-built components
//
// ============================================================================

module fortune_teller #(
    // ========================================================================
    // Parameters
    // ========================================================================
    parameter CLK_FREQ = 50_000_000,  // Your board's clock speed (Hz)
    parameter BAUD     = 115200       // Serial communication speed
)(
    // ========================================================================
    // Ports
    // ========================================================================
    input  wire clk,    // Clock input from your board
    input  wire rst_n,  // Reset button (active LOW)
    input  wire btn,    // The "ask a question" button
    output wire tx,     // Serial output (connect to USB-serial adapter)
    output wire led     // Shows when chip is "thinking"
);

    // ========================================================================
    // Button Debouncing
    // ========================================================================
    // We use the debounce module from the library to clean up the button
    // signal. btn_pressed will pulse HIGH for exactly one clock cycle
    // when a valid button press is detected.

    wire btn_pressed;  // Clean, debounced button signal

    debounce #(
        .CLK_FREQ(CLK_FREQ)  // Pass our clock frequency to the debouncer
    ) debounce_inst (
        .clk(clk),
        .rst_n(rst_n),
        .btn_raw(btn),           // Raw button input
        .btn_pressed(btn_pressed) // Clean output
    );

    // ========================================================================
    // Fortune ROM (Read-Only Memory)
    // ========================================================================
    // We store 8 different fortunes in memory. Each fortune can be up to
    // 20 characters long. Characters are stored as ASCII codes.
    //
    // ASCII codes: 'A'=0x41, 'a'=0x61, ' '=0x20, '.'=0x2E, '\n'=0x0A, etc.
    // 0x00 marks the end of a string (null terminator).
    //
    // Total memory: 8 fortunes x 20 bytes = 160 bytes

    reg [7:0] rom [0:159];  // 160 bytes of ROM

    // Initialize the ROM with our fortunes
    // (In a real chip, this would be hardcoded during manufacturing)
    initial begin
        // Fortune 0: "Yes definitely!\n"
        rom[0]  = 8'h59;  // 'Y'
        rom[1]  = 8'h65;  // 'e'
        rom[2]  = 8'h73;  // 's'
        rom[3]  = 8'h20;  // ' '
        rom[4]  = 8'h64;  // 'd'
        rom[5]  = 8'h65;  // 'e'
        rom[6]  = 8'h66;  // 'f'
        rom[7]  = 8'h69;  // 'i'
        rom[8]  = 8'h6E;  // 'n'
        rom[9]  = 8'h69;  // 'i'
        rom[10] = 8'h74;  // 't'
        rom[11] = 8'h65;  // 'e'
        rom[12] = 8'h6C;  // 'l'
        rom[13] = 8'h79;  // 'y'
        rom[14] = 8'h21;  // '!'
        rom[15] = 8'h0A;  // '\n' (newline)
        rom[16] = 8'h00;  // End of string
        rom[17] = 8'h00;
        rom[18] = 8'h00;
        rom[19] = 8'h00;

        // Fortune 1: "Ask again later.\n"
        rom[20] = 8'h41;  // 'A'
        rom[21] = 8'h73;  // 's'
        rom[22] = 8'h6B;  // 'k'
        rom[23] = 8'h20;  // ' '
        rom[24] = 8'h61;  // 'a'
        rom[25] = 8'h67;  // 'g'
        rom[26] = 8'h61;  // 'a'
        rom[27] = 8'h69;  // 'i'
        rom[28] = 8'h6E;  // 'n'
        rom[29] = 8'h20;  // ' '
        rom[30] = 8'h6C;  // 'l'
        rom[31] = 8'h61;  // 'a'
        rom[32] = 8'h74;  // 't'
        rom[33] = 8'h65;  // 'e'
        rom[34] = 8'h72;  // 'r'
        rom[35] = 8'h2E;  // '.'
        rom[36] = 8'h0A;  // '\n'
        rom[37] = 8'h00;
        rom[38] = 8'h00;
        rom[39] = 8'h00;

        // Fortune 2: "Outlook not good.\n"
        rom[40] = 8'h4F;  // 'O'
        rom[41] = 8'h75;  // 'u'
        rom[42] = 8'h74;  // 't'
        rom[43] = 8'h6C;  // 'l'
        rom[44] = 8'h6F;  // 'o'
        rom[45] = 8'h6F;  // 'o'
        rom[46] = 8'h6B;  // 'k'
        rom[47] = 8'h20;  // ' '
        rom[48] = 8'h6E;  // 'n'
        rom[49] = 8'h6F;  // 'o'
        rom[50] = 8'h74;  // 't'
        rom[51] = 8'h20;  // ' '
        rom[52] = 8'h67;  // 'g'
        rom[53] = 8'h6F;  // 'o'
        rom[54] = 8'h6F;  // 'o'
        rom[55] = 8'h64;  // 'd'
        rom[56] = 8'h2E;  // '.'
        rom[57] = 8'h0A;  // '\n'
        rom[58] = 8'h00;
        rom[59] = 8'h00;

        // Fortune 3: "Signs point to yes\n"
        rom[60] = 8'h53;  // 'S'
        rom[61] = 8'h69;  // 'i'
        rom[62] = 8'h67;  // 'g'
        rom[63] = 8'h6E;  // 'n'
        rom[64] = 8'h73;  // 's'
        rom[65] = 8'h20;  // ' '
        rom[66] = 8'h70;  // 'p'
        rom[67] = 8'h6F;  // 'o'
        rom[68] = 8'h69;  // 'i'
        rom[69] = 8'h6E;  // 'n'
        rom[70] = 8'h74;  // 't'
        rom[71] = 8'h20;  // ' '
        rom[72] = 8'h74;  // 't'
        rom[73] = 8'h6F;  // 'o'
        rom[74] = 8'h20;  // ' '
        rom[75] = 8'h79;  // 'y'
        rom[76] = 8'h65;  // 'e'
        rom[77] = 8'h73;  // 's'
        rom[78] = 8'h0A;  // '\n'
        rom[79] = 8'h00;

        // Fortune 4: "Very doubtful.\n"
        rom[80] = 8'h56;  // 'V'
        rom[81] = 8'h65;  // 'e'
        rom[82] = 8'h72;  // 'r'
        rom[83] = 8'h79;  // 'y'
        rom[84] = 8'h20;  // ' '
        rom[85] = 8'h64;  // 'd'
        rom[86] = 8'h6F;  // 'o'
        rom[87] = 8'h75;  // 'u'
        rom[88] = 8'h62;  // 'b'
        rom[89] = 8'h74;  // 't'
        rom[90] = 8'h66;  // 'f'
        rom[91] = 8'h75;  // 'u'
        rom[92] = 8'h6C;  // 'l'
        rom[93] = 8'h2E;  // '.'
        rom[94] = 8'h0A;  // '\n'
        rom[95] = 8'h00;
        rom[96] = 8'h00;
        rom[97] = 8'h00;
        rom[98] = 8'h00;
        rom[99] = 8'h00;

        // Fortune 5: "It is certain.\n"
        rom[100] = 8'h49;  // 'I'
        rom[101] = 8'h74;  // 't'
        rom[102] = 8'h20;  // ' '
        rom[103] = 8'h69;  // 'i'
        rom[104] = 8'h73;  // 's'
        rom[105] = 8'h20;  // ' '
        rom[106] = 8'h63;  // 'c'
        rom[107] = 8'h65;  // 'e'
        rom[108] = 8'h72;  // 'r'
        rom[109] = 8'h74;  // 't'
        rom[110] = 8'h61;  // 'a'
        rom[111] = 8'h69;  // 'i'
        rom[112] = 8'h6E;  // 'n'
        rom[113] = 8'h2E;  // '.'
        rom[114] = 8'h0A;  // '\n'
        rom[115] = 8'h00;
        rom[116] = 8'h00;
        rom[117] = 8'h00;
        rom[118] = 8'h00;
        rom[119] = 8'h00;

        // Fortune 6: "Reply hazy.\n"
        rom[120] = 8'h52;  // 'R'
        rom[121] = 8'h65;  // 'e'
        rom[122] = 8'h70;  // 'p'
        rom[123] = 8'h6C;  // 'l'
        rom[124] = 8'h79;  // 'y'
        rom[125] = 8'h20;  // ' '
        rom[126] = 8'h68;  // 'h'
        rom[127] = 8'h61;  // 'a'
        rom[128] = 8'h7A;  // 'z'
        rom[129] = 8'h79;  // 'y'
        rom[130] = 8'h2E;  // '.'
        rom[131] = 8'h0A;  // '\n'
        rom[132] = 8'h00;
        rom[133] = 8'h00;
        rom[134] = 8'h00;
        rom[135] = 8'h00;
        rom[136] = 8'h00;
        rom[137] = 8'h00;
        rom[138] = 8'h00;
        rom[139] = 8'h00;

        // Fortune 7: "Cannot predict.\n"
        rom[140] = 8'h43;  // 'C'
        rom[141] = 8'h61;  // 'a'
        rom[142] = 8'h6E;  // 'n'
        rom[143] = 8'h6E;  // 'n'
        rom[144] = 8'h6F;  // 'o'
        rom[145] = 8'h74;  // 't'
        rom[146] = 8'h20;  // ' '
        rom[147] = 8'h70;  // 'p'
        rom[148] = 8'h72;  // 'r'
        rom[149] = 8'h65;  // 'e'
        rom[150] = 8'h64;  // 'd'
        rom[151] = 8'h69;  // 'i'
        rom[152] = 8'h63;  // 'c'
        rom[153] = 8'h74;  // 't'
        rom[154] = 8'h2E;  // '.'
        rom[155] = 8'h0A;  // '\n'
        rom[156] = 8'h00;
        rom[157] = 8'h00;
        rom[158] = 8'h00;
        rom[159] = 8'h00;
    end

    // ========================================================================
    // LFSR - Random Number Generator
    // ========================================================================
    // An LFSR creates pseudo-random numbers using XOR feedback.
    // It cycles through all possible values (except 0) before repeating.
    //
    // The key insight: the LFSR runs CONTINUOUSLY on every clock cycle.
    // The exact moment you press the button determines which "random"
    // value you get. Since humans can't time button presses to the
    // nanosecond, this gives good randomness!
    //
    // The XOR taps [7,5,4,3] are chosen to create a maximal-length sequence.

    reg [7:0] lfsr;  // 8-bit shift register

    // Feedback bit is XOR of bits 7, 5, 4, and 3
    wire lfsr_feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= 8'hAC;  // Seed value (any non-zero value works)
        end
        else begin
            // Shift left and insert feedback bit at position 0
            lfsr <= {lfsr[6:0], lfsr_feedback};
        end
    end

    // ========================================================================
    // State Machine
    // ========================================================================
    // Controls the sequence: wait for button -> load char -> send char -> repeat

    // State definitions (2 bits = 4 possible states)
    localparam IDLE = 2'd0;  // Waiting for button press
    localparam LOAD = 2'd1;  // Loading a character from ROM
    localparam SEND = 2'd2;  // Sending character to UART
    localparam WAIT = 2'd3;  // Waiting for UART to finish

    // State machine registers
    reg [1:0] state;         // Current state
    reg [2:0] fortune_sel;   // Which fortune (0-7)
    reg [4:0] char_idx;      // Which character in the fortune (0-19)
    reg [7:0] current_char;  // The character we're currently sending
    reg       send_valid;    // Tell UART to send

    // Calculate ROM address: fortune_number * 20 + character_index
    wire [7:0] rom_addr = fortune_sel * 20 + char_idx;

    // UART ready signal (from the UART module)
    wire uart_ready;

    // ========================================================================
    // UART Transmitter Instance
    // ========================================================================
    // Connect to the UART module from the library

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(BAUD)
    ) uart_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data(current_char),   // Character to send
        .valid(send_valid),    // Start sending when HIGH
        .ready(uart_ready),    // UART tells us when it's ready
        .tx(tx)                // Serial output
    );

    // ========================================================================
    // LED Output
    // ========================================================================
    // LED is ON whenever we're not idle (i.e., while sending a fortune)

    assign led = (state != IDLE);

    // ========================================================================
    // Main State Machine Logic
    // ========================================================================

    always @(posedge clk or negedge rst_n) begin
        // --------------------------------------------------------------------
        // Reset
        // --------------------------------------------------------------------
        if (!rst_n) begin
            state        <= IDLE;
            fortune_sel  <= 0;
            char_idx     <= 0;
            send_valid   <= 0;
            current_char <= 0;
        end
        // --------------------------------------------------------------------
        // Normal Operation
        // --------------------------------------------------------------------
        else begin
            // Default: don't start a UART transmission
            send_valid <= 0;

            case (state)

                // ============================================================
                // IDLE: Wait for button press
                // ============================================================
                IDLE: begin
                    if (btn_pressed) begin
                        // Capture 3 bits from LFSR to pick fortune 0-7
                        fortune_sel <= lfsr[2:0];

                        // Start at first character
                        char_idx <= 0;

                        // Move to LOAD state
                        state <= LOAD;
                    end
                end

                // ============================================================
                // LOAD: Read character from ROM
                // ============================================================
                LOAD: begin
                    // Read the character at the current ROM address
                    current_char <= rom[rom_addr];

                    // Move to SEND state
                    state <= SEND;
                end

                // ============================================================
                // SEND: Send character to UART
                // ============================================================
                SEND: begin
                    // Check if we've reached the null terminator (end of string)
                    if (current_char == 0) begin
                        // Done! Go back to idle
                        state <= IDLE;
                    end
                    // Otherwise, wait for UART to be ready
                    else if (uart_ready) begin
                        // Start sending the character
                        send_valid <= 1;

                        // Move to WAIT state
                        state <= WAIT;
                    end
                end

                // ============================================================
                // WAIT: Wait for UART to start sending
                // ============================================================
                WAIT: begin
                    // When UART goes busy (ready drops), it has started
                    if (!uart_ready) begin
                        // Move to next character
                        char_idx <= char_idx + 1;

                        // Go load the next character
                        state <= LOAD;
                    end
                end

            endcase
        end
    end

endmodule
