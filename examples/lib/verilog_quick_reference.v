// ============================================================================
// Verilog Quick Reference for Fab Futures
// ============================================================================
// This file is a runnable reference - you can compile it with:
//   iverilog -o ref verilog_quick_reference.v
//
// It won't do anything interesting, but it should compile without errors.
// ============================================================================

// ============================================================================
// MODULE STRUCTURE
// ============================================================================

module example_module #(
    // Parameters (can be overridden when instantiating)
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    // Inputs
    input  wire             clk,        // Clock
    input  wire             rst_n,      // Active-low reset
    input  wire [WIDTH-1:0] data_in,    // Parameterized width
    input  wire             enable,

    // Outputs
    output reg  [WIDTH-1:0] data_out,   // reg because assigned in always block
    output wire             valid       // wire because continuous assign
);

    // Derived parameters (cannot be overridden)
    localparam ADDR_BITS = $clog2(DEPTH);  // Calculate address width

    // Internal signals
    wire [WIDTH-1:0] intermediate;
    reg  [WIDTH-1:0] stored;
    reg  [ADDR_BITS-1:0] addr;

    // ... logic here ...

    assign valid = 1'b0;  // Placeholder
    assign intermediate = data_in;

endmodule


// ============================================================================
// NUMBER FORMATS
// ============================================================================

module number_formats;
    // Format: <bits>'<base><value>
    wire [7:0] binary_val  = 8'b1010_1010;  // Underscores for readability
    wire [7:0] hex_val     = 8'hAA;         // Hexadecimal
    wire [7:0] decimal_val = 8'd170;        // Decimal
    wire [7:0] octal_val   = 8'o252;        // Octal

    // Special values
    wire [3:0] unknown     = 4'bxxxx;       // Unknown (simulation only)
    wire [3:0] highz       = 4'bzzzz;       // High-impedance (tri-state)
    wire [3:0] mixed       = 4'b10xz;       // Can mix

    // Negative numbers (2's complement)
    wire signed [7:0] neg  = -8'd5;         // -5 in 8-bit signed
endmodule


// ============================================================================
// OPERATORS
// ============================================================================

module operators;
    reg [7:0] a, b, result;
    reg c;

    initial begin
        a = 8'd100;
        b = 8'd25;

        // Arithmetic
        result = a + b;       // Addition
        result = a - b;       // Subtraction
        result = a * b;       // Multiplication (careful with width!)
        result = a / b;       // Division (synthesizes to large circuit)
        result = a % b;       // Modulo

        // Bitwise
        result = a & b;       // AND
        result = a | b;       // OR
        result = a ^ b;       // XOR
        result = ~a;          // NOT (invert)
        result = a << 2;      // Left shift (multiply by 4)
        result = a >> 2;      // Right shift (divide by 4)

        // Logical (return 1-bit result)
        c = a && b;           // Logical AND
        c = a || b;           // Logical OR
        c = !a;               // Logical NOT

        // Comparison (return 1-bit result)
        c = (a == b);         // Equal
        c = (a != b);         // Not equal
        c = (a < b);          // Less than
        c = (a <= b);         // Less than or equal
        c = (a > b);          // Greater than
        c = (a >= b);         // Greater than or equal

        // Reduction (operate on all bits of operand)
        c = &a;               // AND all bits
        c = |a;               // OR all bits
        c = ^a;               // XOR all bits (parity)

        // Concatenation
        result = {a[3:0], b[3:0]};  // Combine nibbles

        // Replication
        result = {8{1'b1}};   // 8 copies of 1 = 8'hFF

        // Conditional (ternary)
        result = c ? a : b;   // If c then a else b
    end
endmodule


// ============================================================================
// COMBINATIONAL LOGIC
// ============================================================================

module combinational_examples (
    input  wire [3:0] a, b,
    input  wire [1:0] sel,
    output wire [3:0] and_out,
    output reg  [3:0] mux_out
);
    // Method 1: Continuous assignment (for simple logic)
    assign and_out = a & b;

    // Method 2: Always block with @(*)
    // @(*) = "whenever any input changes"
    always @(*) begin
        case (sel)
            2'b00: mux_out = a;
            2'b01: mux_out = b;
            2'b10: mux_out = a + b;
            2'b11: mux_out = a - b;
            default: mux_out = 4'b0;  // ALWAYS include default!
        endcase
    end

    // WARNING: Missing cases create LATCHES (usually a bug!)
    // This is BAD:
    // always @(*) begin
    //     if (sel == 2'b00) mux_out = a;
    //     // Missing else - latch inferred!
    // end

endmodule


// ============================================================================
// SEQUENTIAL LOGIC
// ============================================================================

module sequential_examples (
    input  wire       clk,
    input  wire       rst_n,    // Active-low reset
    input  wire [7:0] d,
    input  wire       load,
    output reg  [7:0] q,
    output reg  [7:0] counter
);
    // D Flip-Flop with async reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 8'b0;          // Reset value
        else
            q <= d;             // Normal operation
    end

    // Counter with enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= 8'b0;
        else if (load)
            counter <= d;       // Load new value
        else
            counter <= counter + 1;  // Count up
    end

    // CRITICAL: Use <= (non-blocking) in sequential blocks!
    // Using = (blocking) can cause simulation mismatches.
endmodule


// ============================================================================
// STATE MACHINES
// ============================================================================

module fsm_example (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire done,
    output reg  busy,
    output reg  complete
);
    // State encoding
    localparam IDLE    = 2'b00;
    localparam RUNNING = 2'b01;
    localparam FINISH  = 2'b10;

    reg [1:0] state;

    // Single always block FSM (recommended for simple FSMs)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 1'b0;
            complete <= 1'b0;
        end
        else begin
            // Default outputs
            complete <= 1'b0;

            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        state <= RUNNING;
                        busy <= 1'b1;
                    end
                end

                RUNNING: begin
                    busy <= 1'b1;
                    if (done) begin
                        state <= FINISH;
                    end
                end

                FINISH: begin
                    busy <= 1'b0;
                    complete <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;  // Safety catch
            endcase
        end
    end
endmodule


// ============================================================================
// GENERATE BLOCKS
// ============================================================================

module generate_example #(
    parameter NUM_CHANNELS = 4
)(
    input  wire [NUM_CHANNELS-1:0] in,
    output wire [NUM_CHANNELS-1:0] out
);
    // Generate multiple instances
    genvar i;
    generate
        for (i = 0; i < NUM_CHANNELS; i = i + 1) begin : channel
            // Each iteration creates a named block "channel[i]"
            assign out[i] = ~in[i];  // Invert each channel
        end
    endgenerate

    // Conditional generate
    generate
        if (NUM_CHANNELS > 8) begin : wide_mode
            // Include extra logic for wide configurations
        end
        else begin : narrow_mode
            // Simpler logic for narrow configurations
        end
    endgenerate
endmodule


// ============================================================================
// MODULE INSTANTIATION
// ============================================================================

module instantiation_example (
    input  wire clk,
    input  wire rst_n,
    input  wire [7:0] data,
    output wire [7:0] result
);
    // Internal wires to connect modules
    wire [7:0] stage1_out;

    // Instantiation with positional connection (NOT RECOMMENDED)
    // example_module u0 (clk, rst_n, data, 1'b1, stage1_out, );

    // Instantiation with named connection (RECOMMENDED)
    example_module #(
        .WIDTH(8),          // Override parameter
        .DEPTH(16)
    ) u1 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data),
        .enable(1'b1),
        .data_out(stage1_out),
        .valid()            // Leave unconnected (if unused)
    );

    // Another instance with different parameters
    example_module #(
        .WIDTH(8),
        .DEPTH(32)          // Different depth
    ) u2 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(stage1_out),
        .enable(1'b1),
        .data_out(result),
        .valid()
    );
endmodule


// ============================================================================
// TESTBENCH TEMPLATE
// ============================================================================

`timescale 1ns/1ps

module my_design_tb;
    // Inputs (driven by testbench, so they're reg)
    reg        clk;
    reg        rst_n;
    reg  [7:0] data_in;

    // Outputs (driven by DUT, so they're wire)
    wire [7:0] data_out;
    wire       valid;

    // Instantiate Device Under Test (DUT)
    example_module #(
        .WIDTH(8),
        .DEPTH(16)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .enable(1'b1),
        .data_out(data_out),
        .valid(valid)
    );

    // Clock generation: 50 MHz (20 ns period)
    always #10 clk = ~clk;

    // Test stimulus
    initial begin
        // Dump waveforms
        $dumpfile("waves.vcd");
        $dumpvars(0, my_design_tb);

        // Initialize
        clk = 0;
        rst_n = 0;
        data_in = 8'h00;

        // Apply reset
        #40;
        rst_n = 1;

        // Test case 1
        #20;
        data_in = 8'hAA;

        // Test case 2
        #20;
        data_in = 8'h55;

        // Add more test cases...

        // Finish simulation
        #200;
        $display("Test complete!");
        $finish;
    end

    // Monitor changes
    always @(posedge clk) begin
        if (valid)
            $display("Time=%0t: data_out=%h", $time, data_out);
    end
endmodule


// ============================================================================
// USEFUL SYSTEM FUNCTIONS
// ============================================================================

module system_functions;
    parameter MAX_COUNT = 1000;

    // $clog2: Calculate bits needed to represent a value
    // $clog2(1000) = 10 (because 2^10 = 1024 > 1000)
    localparam WIDTH = $clog2(MAX_COUNT + 1);

    reg [WIDTH-1:0] counter;  // Will be 10 bits

    // In simulation:
    // $display("msg", args)  - Print once
    // $monitor("msg", args)  - Print whenever args change
    // $time                  - Current simulation time
    // $finish                - End simulation
    // $dumpfile("f.vcd")     - Create VCD waveform file
    // $dumpvars(level, mod)  - Dump signals (0 = all levels)

    initial begin
        $display("WIDTH = %d", WIDTH);  // Prints: WIDTH = 10
    end
endmodule


// ============================================================================
// COMMON MISTAKES TO AVOID
// ============================================================================

// 1. LATCH INFERENCE (BAD!)
// Missing else or default case creates a latch:
//
// always @(*)
//     if (sel) y = a;      // BAD: What about sel=0?
//
// Fix: Always assign a value in all branches
// always @(*)
//     if (sel) y = a;
//     else     y = b;      // GOOD

// 2. BLOCKING VS NON-BLOCKING
// Use = for combinational, <= for sequential
//
// always @(posedge clk)
//     q = d;               // BAD: Should use <=
//
// always @(posedge clk)
//     q <= d;              // GOOD

// 3. INCOMPLETE SENSITIVITY LIST
// Use @(*) for combinational logic
//
// always @(a)              // BAD: Missing b
//     y = a & b;
//
// always @(*)              // GOOD: Automatic
//     y = a & b;

// 4. WIDTH MISMATCH
// wire [7:0] a;
// wire [3:0] b;
// assign b = a;            // BAD: Truncates upper bits silently
// assign b = a[3:0];       // GOOD: Explicit

// 5. RESET VALUE
// Make sure reset initializes ALL state:
// always @(posedge clk or negedge rst_n)
//     if (!rst_n)
//         state <= IDLE;   // GOOD: Initialize state
//     else ...

// ============================================================================
