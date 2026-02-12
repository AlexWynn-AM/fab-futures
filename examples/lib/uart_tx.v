// ============================================================================
// UART Transmitter Module
// ============================================================================
//
// UART (Universal Asynchronous Receiver/Transmitter) is a simple serial
// protocol used to send data one bit at a time over a single wire.
//
// This module sends bytes in "8N1" format:
//   - 1 start bit (always 0)
//   - 8 data bits (LSB first)
//   - 1 stop bit (always 1)
//
// Example: sending the byte 0x55 (binary 01010101):
//
//   Idle ──┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐
//          │   │   │   │   │   │   │   │   │
//          └───┘   └───┘   └───┘   └───┘   └───────
//          START  D0  D1  D2  D3  D4  D5  D6  D7  STOP
//            0    1   0   1   0   1   0   1   0    1
//
// The "baud rate" is how many bits per second we send.
// Common rates: 9600, 115200
//
// ============================================================================

`timescale 1ns/1ps

module uart_tx #(
    // ========================================================================
    // Parameters - these can be changed when instantiating the module
    // ========================================================================
    parameter CLK_FREQ = 50_000_000,  // Clock frequency in Hz (50 MHz default)
    parameter BAUD     = 115200       // Bits per second to transmit
)(
    // ========================================================================
    // Ports - the wires that connect this module to the outside world
    // ========================================================================
    input  wire       clk,    // System clock (active on rising edge)
    input  wire       rst_n,  // Reset signal (active LOW - the 'n' means negated)
    input  wire [7:0] data,   // The byte we want to send (8 bits)
    input  wire       valid,  // Pulse this HIGH for one clock to start sending
    output reg        ready,  // HIGH when we can accept new data
    output reg        tx      // The actual serial output line
);

    // ========================================================================
    // Local Parameters - calculated from the input parameters
    // ========================================================================

    // How many clock cycles per bit?
    // Example: 50 MHz clock / 115200 baud = 434 clocks per bit
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;

    // How many bits do we need to count up to CLKS_PER_BIT?
    // $clog2 is "ceiling of log base 2" - gives us the bit width needed
    // Example: $clog2(434) = 9 bits (since 2^9 = 512 > 434)
    localparam CTR_WIDTH = $clog2(CLKS_PER_BIT);

    // ========================================================================
    // State Machine States
    // ========================================================================
    // We use a simple state machine with 4 states:
    //   IDLE  - waiting for data to send
    //   START - sending the start bit (0)
    //   DATA  - sending the 8 data bits
    //   STOP  - sending the stop bit (1)

    localparam IDLE  = 2'b00;  // State 0: waiting
    localparam START = 2'b01;  // State 1: sending start bit
    localparam DATA  = 2'b10;  // State 2: sending data bits
    localparam STOP  = 2'b11;  // State 3: sending stop bit

    // ========================================================================
    // Internal Registers
    // ========================================================================

    reg [1:0]           state;      // Current state (2 bits for 4 states)
    reg [CTR_WIDTH-1:0] clk_ctr;    // Counts clocks within each bit
    reg [2:0]           bit_idx;    // Which data bit we're sending (0-7)
    reg [7:0]           shift_reg;  // Holds the byte we're sending

    // ========================================================================
    // Combinational Logic
    // ========================================================================

    // "tick" goes HIGH for one clock when we've counted a full bit time
    wire tick = (clk_ctr == CLKS_PER_BIT - 1);

    // ========================================================================
    // Main State Machine (Sequential Logic)
    // ========================================================================
    // This always block runs on every rising edge of the clock.
    // The "or negedge rst_n" means it also runs when reset goes LOW.

    always @(posedge clk or negedge rst_n) begin

        // --------------------------------------------------------------------
        // Reset Condition
        // --------------------------------------------------------------------
        // When rst_n is LOW, reset everything to initial values
        if (!rst_n) begin
            state     <= IDLE;   // Go to idle state
            clk_ctr   <= 0;      // Clear the clock counter
            bit_idx   <= 0;      // Clear the bit index
            shift_reg <= 0;      // Clear the shift register
            ready     <= 1;      // We're ready to accept data
            tx        <= 1;      // Idle state of UART line is HIGH
        end

        // --------------------------------------------------------------------
        // Normal Operation
        // --------------------------------------------------------------------
        else begin
            // Use a case statement to handle each state
            case (state)

                // ============================================================
                // IDLE State: Wait for data
                // ============================================================
                IDLE: begin
                    tx    <= 1;      // Keep line HIGH (idle)
                    ready <= 1;      // Signal that we can accept data

                    // When valid goes HIGH, capture the data and start sending
                    if (valid) begin
                        shift_reg <= data;   // Capture the byte to send
                        state     <= START;  // Move to START state
                        ready     <= 0;      // No longer ready for new data
                        clk_ctr   <= 0;      // Reset the clock counter
                    end
                end

                // ============================================================
                // START State: Send start bit (0)
                // ============================================================
                START: begin
                    tx <= 0;  // Start bit is always 0

                    // Count clocks until one bit time has passed
                    if (tick) begin
                        clk_ctr <= 0;        // Reset counter for next bit
                        bit_idx <= 0;        // Start with bit 0
                        state   <= DATA;     // Move to DATA state
                    end
                    else begin
                        clk_ctr <= clk_ctr + 1;  // Keep counting
                    end
                end

                // ============================================================
                // DATA State: Send 8 data bits (LSB first)
                // ============================================================
                DATA: begin
                    // Output the current bit from the shift register
                    tx <= shift_reg[bit_idx];

                    // Count clocks until one bit time has passed
                    if (tick) begin
                        clk_ctr <= 0;  // Reset counter for next bit

                        // Check if we've sent all 8 bits
                        if (bit_idx == 7) begin
                            state <= STOP;  // Move to STOP state
                        end
                        else begin
                            bit_idx <= bit_idx + 1;  // Move to next bit
                        end
                    end
                    else begin
                        clk_ctr <= clk_ctr + 1;  // Keep counting
                    end
                end

                // ============================================================
                // STOP State: Send stop bit (1)
                // ============================================================
                STOP: begin
                    tx <= 1;  // Stop bit is always 1

                    // Count clocks until one bit time has passed
                    if (tick) begin
                        state <= IDLE;  // Go back to idle, ready for next byte
                    end
                    else begin
                        clk_ctr <= clk_ctr + 1;  // Keep counting
                    end
                end

            endcase
        end
    end

endmodule
