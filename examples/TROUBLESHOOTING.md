# Troubleshooting Guide

Common issues and solutions for Fab Futures projects.

---

## Simulation Issues

### "Module not found" error

```
error: Unknown module type: debounce
```

**Cause**: Missing include or wrong file in compile command.

**Fix**: Include all required files:
```bash
iverilog -o sim.vvp -I../lib fortune_teller.v ../lib/debounce.v ../lib/uart_tx.v fortune_teller_tb.v
```

---

### Signals showing 'x' (unknown) in waveform

**Cause 1**: Uninitialized registers

**Fix**: Check that all registers get reset values:
```verilog
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        my_reg <= 8'b0;  // Initialize!
    else
        ...
```

**Cause 2**: Reset not applied in testbench

**Fix**: Make sure reset is asserted at start:
```verilog
initial begin
    rst_n = 0;      // Start in reset
    #40;
    rst_n = 1;      // Release reset
```

---

### Simulation runs forever

**Cause**: Missing `$finish` or infinite loop.

**Fix**: Add explicit end condition:
```verilog
initial begin
    ...
    #10000 $finish;  // End after 10us
end
```

---

### Output doesn't change when input changes

**Cause 1**: Combinational sensitivity list incomplete.

**Fix**: Use `@(*)`:
```verilog
always @(*)  // NOT always @(a)
    y = a & b;
```

**Cause 2**: Missing clock edge in sequential logic.

**Fix**: Verify clock is toggling in testbench:
```verilog
always #10 clk = ~clk;  // 50 MHz clock
```

---

## Synthesis Issues

### "inferred latch" warning

```
Warning: Latch inferred for signal 'my_signal'
```

**Cause**: Combinational always block doesn't assign output in all branches.

**Fix**: Add missing cases or default:
```verilog
// BAD
always @(*) begin
    if (sel) y = a;
    // Missing else!
end

// GOOD
always @(*) begin
    if (sel) y = a;
    else y = b;
end

// OR use default at start
always @(*) begin
    y = 0;  // Default
    if (sel) y = a;
end
```

---

### "signal has no driver"

**Cause**: Wire declared but never assigned.

**Fix**: Either remove the unused wire or connect it:
```verilog
wire my_signal;          // Declared
assign my_signal = ...;  // Must be driven
```

---

### "port size mismatch"

```
Warning: Port 'data' size mismatch (8 vs 16)
```

**Cause**: Module instantiation width doesn't match module definition.

**Fix**: Check parameter widths match:
```verilog
// Module has 8-bit port
module my_mod (
    input [7:0] data
);

// Instantiation must use 8 bits
my_mod u1 (
    .data(my_8bit_signal)  // Not 16-bit!
);
```

---

### Design too large / doesn't fit

**Cause**: Design exceeds tile capacity.

**Fixes**:
1. Reduce ROM size (use smaller messages)
2. Reduce counter widths (use `$clog2`)
3. Simplify logic
4. Request multiple tiles

---

## Timing Issues

### Negative slack (timing violation)

**Cause**: Logic path too long for clock period.

**Fixes**:
1. **Reduce clock frequency** (easiest)
2. **Add pipeline registers** to break long paths
3. **Simplify combinational logic**
4. **Use faster cell variants** (drive strength)

Example - adding pipeline:
```verilog
// BEFORE: Long combinational path
assign result = (a * b) + (c * d);

// AFTER: Pipelined
always @(posedge clk) begin
    stage1 <= a * b;
    stage2 <= c * d;
    result <= stage1 + stage2;  // 2-cycle latency
end
```

---

### Hold time violation

**Cause**: Data changes too fast after clock edge.

**Fixes**:
1. Add delay cells (tool usually fixes automatically)
2. Check for clock skew issues
3. Review clock domain crossings

---

## Hardware/Test Issues

### Chip draws no current

**Check**:
1. VDD and GND connected correctly?
2. Correct voltage (1.8V for core, 3.3V for I/O)?
3. Solder joints good?
4. Power LED on eval board lit?

---

### Chip draws too much current

**Cause 1**: Short circuit

**Check**: Inspect for solder bridges, especially on QFN pads.

**Cause 2**: Oscillation

**Check**: Ensure unused inputs are tied to VDD or GND, not floating.

**Cause 3**: Wrong voltage

**Check**: Don't apply 3.3V to 1.8V core!

---

### Output stuck at 0 or 1

**Check**:
1. Is reset working? (Active-low: rst_n should be HIGH during operation)
2. Is clock running? (Use oscilloscope)
3. Is input reaching the chip?
4. Check for level shifting issues (1.8V vs 3.3V)

---

### Outputs are noisy/glitchy

**Cause 1**: Power supply noise

**Fix**: Add decoupling capacitors (100nF + 10uF near VDD pins).

**Cause 2**: Ground bounce

**Fix**: Use ground plane on PCB, thick ground traces.

**Cause 3**: Clock integrity

**Fix**: Keep clock traces short, away from noisy signals.

---

### UART not working

**Check**:
1. Baud rate matches between chip and terminal (115200)?
2. TX and RX not swapped?
3. Level shifter if needed (1.8V to 3.3V)?
4. Ground connected between chip and USB adapter?
5. Terminal settings: 8N1 (8 data bits, no parity, 1 stop bit)?

---

### Button doesn't respond

**Check**:
1. Debounce working? (10ms is typical)
2. Button connected to correct pin?
3. Pull-up or pull-down configured correctly?
4. Polarity correct? (Active-low vs active-high)

---

## Tool Issues

### Yosys crashes or hangs

**Possible fixes**:
1. Check for combinational loops in design
2. Simplify large ROMs
3. Increase system memory
4. Update to latest Yosys version

---

### KLayout won't open GDS

**Possible causes**:
1. File corrupted (re-run P&R)
2. Wrong file format
3. KLayout version too old

**Fix**: Try `klayout -e design.gds` to open in edit mode.

---

### OpenROAD fails with DRC errors

**Check**:
1. Metal density too high/low?
2. Minimum spacing violations?
3. Via placement issues?

**Fixes**:
1. Increase die area (more room for routing)
2. Reduce utilization target
3. Let tool add fill cells

---

## Getting Help

1. **Check the error message carefully** - it usually tells you what's wrong
2. **Read the course notebooks** - most issues are covered
3. **Run the linter**: `verilator --lint-only -Wall your_design.v`
4. **Check example designs** - compare working code to your code
5. **Ask on the course Discord** - include:
   - Exact error message
   - What you tried
   - Relevant code snippet (use code blocks)

---

## Quick Reference: Common Error Messages

| Error | Likely Cause | Fix |
|-------|--------------|-----|
| `unknown module` | Missing file | Add to compile command |
| `inferred latch` | Missing else/default | Complete all branches |
| `no driver` | Unconnected wire | Assign or remove |
| `size mismatch` | Width error | Check bit widths |
| `negative slack` | Timing violation | Simplify or pipeline |
| `model not found` | PDK not loaded | Check .lib path |
| `singular matrix` | Floating node (SPICE) | Check connections |
