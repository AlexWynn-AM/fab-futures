# Review Fixes Plan

## Priority 1: Incorrect Numbers (Fix Immediately)

### Notebook 01
- [x] Fix Tiny Tapeout tile size: 160x100 -> ~161x225 µm (or say "varies by shuttle")

### Notebook 03
- [x] Fix SPICE PULSE timing: 10ps -> 100ps rise/fall (realistic for 130nm)

### Notebook 04
- [x] Add disclaimer that DRC numbers are "simplified examples"
- [x] Add actual Sky130 values in a reference table:
  - M1 min width: 0.14 µm
  - M1 min space: 0.14 µm
  - Via enclosure: 0.06 µm (varies)
- [x] Fix density rules or mark as illustrative

## Priority 2: Missing Educational Content

### Notebook 05
- [x] Add section on `generate` blocks with example
- [x] Add section on `$clog2` and other system functions
- [x] Reference where these are used in example projects

### Notebook 06
- [x] Add explanation for negative setup time in timing reports
- [ ] Add real synthesis results for one of the example projects

## Priority 3: Consistency Issues

### All Notebooks
- [ ] Standardize on 50 MHz as reference clock (matches examples)
- [ ] Add note explaining testbench clock scaling for simulation speed

### Notebook 02
- [x] Add note that Vth=0.4V is illustrative, actual PDK values differ
- [x] Mention short-channel effects exist but are beyond scope

## Priority 4: Nice-to-Have Improvements

### Notebook 04
- [ ] Add brief mention of antenna rules
- [ ] Add brief mention of electromigration

### Notebook 07
- [ ] Improve wirebond description with loop height mention
