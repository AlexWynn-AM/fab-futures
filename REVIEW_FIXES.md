# Review Fixes Plan

## Priority 1: Incorrect Numbers (Fix Immediately)

### Notebook 01
- [x] Fix Tiny Tapeout tile size: 160x100 -> ~161x225 um (or say "varies by shuttle")
- [x] Add link to current Tiny Tapeout specs page

### Notebook 03
- [x] Fix SPICE PULSE timing: 10ps -> 100ps rise/fall (realistic for 130nm)

### Notebook 04
- [x] Add disclaimer that DRC numbers are "simplified examples"
- [x] Add actual Sky130 values in a reference table:
  - M1 min width: 0.14 um
  - M1 min space: 0.14 um
  - Via enclosure: 0.03-0.06 um (updated with correct range)
- [x] Fix density rules - clarified as "varies by layer" with documentation link

## Priority 2: Missing Educational Content

### Notebook 05
- [x] Add section on `generate` blocks with example
- [x] Add section on `$clog2` and other system functions
- [x] Reference where these are used in example projects
- [x] Add note about simulation clock timing vs target hardware

### Notebook 06
- [x] Add explanation for negative setup time in timing reports
- [x] Add note about Tiny Tapeout submission format
- [x] Add real synthesis results for one of the example projects (fortune_teller)

## Priority 3: Consistency Issues

### All Notebooks
- [x] Add note explaining testbench clock scaling for simulation speed
- [ ] Standardize on 50 MHz as reference clock (matches examples)

### Notebook 02
- [x] Add note that Vth=0.4V is illustrative, actual PDK values differ
- [x] Mention short-channel effects exist but are beyond scope

## Priority 4: Nice-to-Have Improvements

### Notebook 04
- [ ] Add brief mention of antenna rules
- [ ] Add brief mention of electromigration

### Notebook 07
- [ ] Improve wirebond description with loop height mention

---

## Technical Review Completed

See `TECHNICAL_REVIEW.md` for the full three-perspective review from:
- Alex Wynn (MIT) - Digital design pedagogy
- Jennifer Volk (UW-Madison) - Fabrication and device physics
- Andreas Olofsson (Zero ASIC) - Open source tooling and accessibility

See `WORKS_CITED.md` (git-ignored) for source citations and justifications for all technical claims.

*Last updated: 2026-02-04*
