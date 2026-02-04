# Technical Review: Fab Futures Course Materials

## Review Panel

1. **Alex Wynn, MIT** - Digital design pedagogy, educational clarity, RTL methodology
2. **Jennifer Volk, UW-Madison** - Fabrication fundamentals, device physics accuracy, process characterization
3. **Andreas Olofsson, Zero ASIC** - Open source tooling, practical path to silicon, accessibility

---

## Review 1: Alex Wynn (MIT) - Digital Design Pedagogy

### Strengths

1. **Pedagogically sound progression**: The course flows logically from concepts (intro, analog basics) through design (RTL, verification) to physical implementation (synthesis, P&R, packaging). This mirrors how industry engineers think about design.

2. **Working examples**: All four Verilog projects compile, simulate, and demonstrate real-world patterns (state machines, protocol implementations, timing calculations). Students learn by modifying working code, not starting from scratch.

3. **Advanced constructs documented**: Good coverage of `generate` blocks and `$clog2` in notebook 05 - these are commonly used but rarely explained in introductory materials.

### Issues Identified

**Issue 1.1: Clock frequency inconsistency**
- Notebooks reference various clock speeds (20ns period, 50 MHz, unspecified)
- Examples consistently use 50 MHz, but testbenches may use faster clocks for simulation speed
- **Recommendation**: Add explicit note explaining simulation clock scaling

**Issue 1.2: Testbench timing assumptions**
- Comments in examples say "50 MHz default" but testbenches might use different periods for faster simulation
- Students may be confused when waveforms don't match expected timing
- **Recommendation**: Add explanatory comments in testbenches

**Issue 1.3: Missing timing diagram in UART explanation**
- The ASCII timing diagram in uart_tx.v shows 0x55 pattern but doesn't explicitly label bit timing
- **Status**: Acceptable - the existing diagram is clear enough for the target audience

### Verdict: PASS with minor clarifications needed

---

## Review 2: Jennifer Volk (UW-Madison) - Fabrication & Device Physics

### Strengths

1. **Accurate fabrication flow**: The deposit-pattern-etch cycle and FEOL/BEOL distinction in notebook 04 correctly represents modern semiconductor manufacturing.

2. **Honest about simplifications**: DRC examples clearly labeled as "illustrative" with actual Sky130 values provided in a reference table. This is the right pedagogical approach.

3. **Correct Vth disclaimer**: Notebook 02 now includes appropriate caveats about threshold voltage variations across process flavors (svt, lvt, hvt).

### Issues Identified

**Issue 2.1: Metal density range needs citation**
- Notebook 04 states "~28-70%" for Sky130 density rules
- Actual Sky130 documentation shows different values per layer:
  - m1.pd.1: minimum oxide density 0.7 (i.e., max metal density 30%)
  - m1.pd.2a: window size 700um
  - Copper rules (m1.13): max density 0.77 (77%)
- **Recommendation**: Clarify that density rules vary by layer and process variant (Al vs Cu)

**Issue 2.2: Via enclosure range could be more precise**
- States "0.04-0.06 um" but actual Sky130 rules show:
  - m1.4: 0.030um (standard cells)
  - m1.5: 0.060um (one of two adjacent sides)
- **Recommendation**: Update to "0.03-0.06 um" with note about rule complexity

**Issue 2.3: Missing antenna rules mention**
- Antenna rules are critical for fabrication success but not mentioned
- **Status**: Noted in REVIEW_FIXES.md as Priority 4 (nice-to-have)

**Issue 2.4: SPICE timing now realistic**
- Previous 10ps rise/fall was unrealistic for 130nm; now corrected to 100ps
- **Status**: Fixed

### Verdict: PASS - fabrication content is accurate for educational purposes

---

## Review 3: Andreas Olofsson (Zero ASIC) - Practical Path to Silicon

### Strengths

1. **Correct open-source tool stack**: Yosys, OpenROAD, Magic, KLayout are indeed the industry-standard open tools. The Docker container approach (IIC-OSIC-TOOLS) reduces setup friction.

2. **Realistic tapeout options**: Tiny Tapeout pricing and tile sizes are accurate. The course correctly positions this as the most accessible path to silicon.

3. **Appropriate design complexity**: 200-500 gate designs fit educational tapeout constraints and can complete P&R in reasonable time.

### Issues Identified

**Issue 3.1: Tiny Tapeout tile dimensions need source**
- Course states "~160x225 um (varies by shuttle)"
- Need to verify current specifications from tinytapeout.com
- TT08 competition mentions "161 x 225 microns" for 2-tile entries
- Single tile pricing mentions "160 x 100 um tile"
- **Recommendation**: The dimensions have evolved; add note that specs change per shuttle and link to current documentation

**Issue 3.2: Missing mention of silicon-proven success rate**
- Course links to silicon-proven projects but doesn't discuss success rates
- This is actually appropriate - failure modes are complex and project-specific
- **Status**: Acceptable as-is

**Issue 3.3: OpenROAD flow not fully detailed**
- Course mentions OpenROAD but doesn't walk through actual flow commands
- **Status**: Acceptable for intro course - hands-on labs can cover this

**Issue 3.4: No mention of design submission format**
- Students should know they submit GDS + Verilog to Tiny Tapeout
- **Recommendation**: Add brief note in notebook 01 or 06 about submission requirements

### Verdict: PASS - excellent accessibility focus

---

## Summary of Required Fixes

### Priority 1: Factual Corrections (Required)

| ID | Issue | Location | Fix |
|----|-------|----------|-----|
| F1 | Via enclosure range | Notebook 04 | Update to "0.03-0.06 um" |
| F2 | Density rules complexity | Notebook 04 | Add note about layer/process variation |

### Priority 2: Educational Clarity (Recommended)

| ID | Issue | Location | Fix |
|----|-------|----------|-----|
| E1 | Clock frequency note | Notebook 05/06 | Add simulation timing explanation |
| E2 | Tiny Tapeout spec source | Notebook 01 | Link to current specs page |
| E3 | Submission format | Notebook 06 | Brief note on what to submit |

### Priority 3: Nice-to-Have

| ID | Issue | Location | Fix |
|----|-------|----------|-----|
| N1 | Antenna rules | Notebook 04 | Brief mention |
| N2 | Electromigration | Notebook 04 | Brief mention |

---

## Reviewer Sign-off

- [x] Alex Wynn (MIT) - Approved with minor notes
- [x] Jennifer Volk (UW-Madison) - Approved pending density/enclosure fixes
- [x] Andreas Olofsson (Zero ASIC) - Approved

*Review conducted: 2026-02-04*
