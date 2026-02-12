// ============================================================================
// Pocket Synth - A Musical Instrument on a Chip
// ============================================================================
//
// HOW IT WORKS:
//   1. Press a button
//   2. Speaker plays a musical note
//   3. Release button, sound stops
//
// WHAT YOU'LL LEARN:
//   - Generating square waves for audio
//   - Calculating timing from frequency
//   - Simple combinational logic for note selection
//
// HOW SOUND WORKS:
//   Sound is vibration. A speaker vibrates when we toggle its input
//   between HIGH and LOW. The faster we toggle, the higher the pitch.
//
//   Musical note C4 (middle C) = 262 Hz = 262 toggles per second
//   Musical note A4 (concert A) = 440 Hz = 440 toggles per second
//
// ============================================================================

`timescale 1ns/1ps

module pocket_synth #(
    // ========================================================================
    // Parameters
    // ========================================================================
    parameter CLK_FREQ = 50_000_000  // Your board's clock speed (Hz)
)(
    // ========================================================================
    // Ports
    // ========================================================================
    input  wire       clk,        // Clock input
    input  wire       rst_n,      // Reset (active LOW)
    input  wire [3:0] keys,       // 4 piano key buttons
    output wire       audio_out,  // Connect to speaker or buzzer
    output wire [3:0] leds        // Show which key is pressed
);

    // ========================================================================
    // Note Frequency Calculations
    // ========================================================================
    //
    // To generate a tone, we need to toggle the output at the right speed.
    //
    // For a 262 Hz tone (middle C):
    //   - Full wave period = 1/262 seconds ≈ 3.8 ms
    //   - Half period = 1.9 ms (time between toggles)
    //   - In clock cycles: 50,000,000 / (2 × 262) ≈ 95,420 cycles
    //
    // We count clock cycles, and toggle the output when we reach half_period.

    // Half-period values for our 4 notes (C, E, G, B - a C major 7th chord)
    localparam [23:0] HALF_C4 = CLK_FREQ / (2 * 262);  // C4 = 262 Hz
    localparam [23:0] HALF_E4 = CLK_FREQ / (2 * 330);  // E4 = 330 Hz
    localparam [23:0] HALF_G4 = CLK_FREQ / (2 * 392);  // G4 = 392 Hz
    localparam [23:0] HALF_B4 = CLK_FREQ / (2 * 494);  // B4 = 494 Hz

    // ========================================================================
    // Input Synchronization
    // ========================================================================
    //
    // External signals (like buttons) can change at any time. We need to
    // synchronize them to our clock to avoid metastability issues.
    //
    // A 2-stage synchronizer passes the signal through two flip-flops.

    reg [1:0] key_sync [0:3];   // 2-bit shift register for each key
    wire [3:0] keys_clean;      // Synchronized key values

    // Generate synchronizers for all 4 keys
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : sync_gen
            // On each clock, shift in the new value
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    key_sync[i] <= 2'b00;
                else
                    key_sync[i] <= {key_sync[i][0], keys[i]};
            end

            // Use the second stage as our clean output
            assign keys_clean[i] = key_sync[i][1];
        end
    endgenerate

    // ========================================================================
    // Note Selection (Combinational Logic)
    // ========================================================================
    //
    // This logic decides which note to play based on which key is pressed.
    // If multiple keys are pressed, the lowest-numbered key wins (priority).

    reg [23:0] half_period;  // How many cycles between toggles
    reg        active;       // Is any key pressed?

    always @(*) begin
        // Default: no sound
        half_period = 0;
        active = 0;

        // Check keys in priority order
        if (keys_clean[0]) begin
            half_period = HALF_C4;  // Key 0 = C
            active = 1;
        end
        else if (keys_clean[1]) begin
            half_period = HALF_E4;  // Key 1 = E
            active = 1;
        end
        else if (keys_clean[2]) begin
            half_period = HALF_G4;  // Key 2 = G
            active = 1;
        end
        else if (keys_clean[3]) begin
            half_period = HALF_B4;  // Key 3 = B
            active = 1;
        end
    end

    // ========================================================================
    // Tone Generator (Sequential Logic)
    // ========================================================================
    //
    // This counter generates the square wave:
    //   1. Count up on each clock cycle
    //   2. When counter reaches half_period, toggle output and reset counter
    //   3. If no key pressed, output stays LOW

    reg [23:0] counter;  // Counts clock cycles
    reg        tone;     // The square wave output (0 or 1)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset: clear counter and output
            counter <= 0;
            tone    <= 0;
        end
        else if (!active) begin
            // No key pressed: silence
            counter <= 0;
            tone    <= 0;
        end
        else begin
            // Key pressed: generate tone
            if (counter >= half_period - 1) begin
                // Reached half period: toggle output and reset counter
                counter <= 0;
                tone    <= ~tone;  // Toggle: 0->1 or 1->0
            end
            else begin
                // Keep counting
                counter <= counter + 1;
            end
        end
    end

    // ========================================================================
    // Output Assignments
    // ========================================================================

    assign audio_out = tone;       // Square wave to speaker
    assign leds = keys_clean;      // Show which keys are pressed

endmodule


// ############################################################################
//
// BONUS: POLYPHONIC VERSION
//
// The basic version above can only play one note at a time.
// This version has 4 independent oscillators that can all play together!
//
// ############################################################################

module pocket_synth_poly #(
    parameter CLK_FREQ = 50_000_000
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] keys,
    output wire       audio_out,
    output wire [3:0] leds
);

    // Half-period values (same as basic version)
    localparam [23:0] HALF_C4 = CLK_FREQ / (2 * 262);
    localparam [23:0] HALF_E4 = CLK_FREQ / (2 * 330);
    localparam [23:0] HALF_G4 = CLK_FREQ / (2 * 392);
    localparam [23:0] HALF_B4 = CLK_FREQ / (2 * 494);

    // ========================================================================
    // Input Synchronization
    // ========================================================================

    reg [1:0] key_sync [0:3];
    wire [3:0] keys_clean;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : sync_gen
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    key_sync[i] <= 2'b00;
                else
                    key_sync[i] <= {key_sync[i][0], keys[i]};
            end
            assign keys_clean[i] = key_sync[i][1];
        end
    endgenerate

    // ========================================================================
    // Four Independent Oscillators
    // ========================================================================
    // Each oscillator runs independently, controlled by its own key.

    reg [23:0] ctr0, ctr1, ctr2, ctr3;  // Counters for each oscillator
    reg        tone0, tone1, tone2, tone3;  // Outputs for each oscillator

    // Oscillator 0: C note
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctr0  <= 0;
            tone0 <= 0;
        end
        else if (!keys_clean[0]) begin
            ctr0  <= 0;
            tone0 <= 0;
        end
        else if (ctr0 >= HALF_C4 - 1) begin
            ctr0  <= 0;
            tone0 <= ~tone0;
        end
        else begin
            ctr0 <= ctr0 + 1;
        end
    end

    // Oscillator 1: E note
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctr1  <= 0;
            tone1 <= 0;
        end
        else if (!keys_clean[1]) begin
            ctr1  <= 0;
            tone1 <= 0;
        end
        else if (ctr1 >= HALF_E4 - 1) begin
            ctr1  <= 0;
            tone1 <= ~tone1;
        end
        else begin
            ctr1 <= ctr1 + 1;
        end
    end

    // Oscillator 2: G note
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctr2  <= 0;
            tone2 <= 0;
        end
        else if (!keys_clean[2]) begin
            ctr2  <= 0;
            tone2 <= 0;
        end
        else if (ctr2 >= HALF_G4 - 1) begin
            ctr2  <= 0;
            tone2 <= ~tone2;
        end
        else begin
            ctr2 <= ctr2 + 1;
        end
    end

    // Oscillator 3: B note
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctr3  <= 0;
            tone3 <= 0;
        end
        else if (!keys_clean[3]) begin
            ctr3  <= 0;
            tone3 <= 0;
        end
        else if (ctr3 >= HALF_B4 - 1) begin
            ctr3  <= 0;
            tone3 <= ~tone3;
        end
        else begin
            ctr3 <= ctr3 + 1;
        end
    end

    // ========================================================================
    // Mixing the Oscillators
    // ========================================================================
    //
    // Real audio mixing would require a DAC (digital-to-analog converter).
    // With just digital outputs, we use XOR to combine the waves.
    //
    // XOR mixing creates interesting harmonic content - not "correct" audio
    // mixing, but it sounds cool and is very simple!

    assign audio_out = tone0 ^ tone1 ^ tone2 ^ tone3;
    assign leds = keys_clean;

endmodule
