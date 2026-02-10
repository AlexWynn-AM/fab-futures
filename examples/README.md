# Example Projects

These examples are **starting points**, not finished assignments.

Your goal is to make something you'd actually want to demo. Use these as
reference implementations, then make them your own:

- **Modify** an example: change the fortunes, the notes, the colors, the message
- **Extend** it: add features, combine ideas, make it weird
- **Design your own**: pitch something that fits the constraints

Each project fits the same constraints (~200-500 gates, 50 MHz clock, a handful
of I/O pins) and uses the same RTL-to-GDS flow. The "Customize it" sections
below are the *minimum* expectation—the best projects go further.

---

## Silicon-Proven Inspiration

These aren't theoretical -- real people have taped out similar projects and
they work on actual silicon. Browse them for ideas and reference implementations:

**Gallery:** https://tinytapeout.com/chips/silicon-proven/

| Project | Description | Source |
|---------|-------------|--------|
| [Analog Monosynth](https://tinytapeout.com/chips/tt05/262) | Two oscillators + filter, similar to Pocket Synth | [GitHub](https://github.com/toivoh/tt05-synth) |
| [TTRPG Dice](https://tinytapeout.com/chips/tt06/105) | D4/D6/D8/D10/D12/D20 with 7-seg, similar to Dice Roller | [GitHub](https://github.com/sanojn/tt06_ttrpg_dice) |
| [Super Mario Tune](https://tinytapeout.com/chips/tt05/197) | Plays melody on piezo speaker | [GitHub](https://github.com/meriac/tt05-play-tune) |
| [Simon Says](https://tinytapeout.com/chips/tt06/899) | Memory game with LEDs and audio | [GitHub](https://github.com/urish/tt06-simon-game) |

---

## Fortune Teller

**What it does:** Press a button, get a fortune. It's a Magic 8-Ball on silicon.

**Demo moment:** Ask a question out loud, press the button, watch your laptop
terminal reveal the answer.

**I/O:**
- 1 button (ask)
- 1 LED (thinking...)
- TX pin (USB-serial to laptop)

**What you'll learn:** ROMs, random number generation (LFSR), state machines

**Customize it:**
- Write your own fortunes
- Add more responses (16? 32?)
- Make it sarcastic

```
examples/fortune_teller/
├── fortune_teller.v      # main design
└── fortune_teller_tb.v   # testbench
```

---

## Pocket Synth

**What it does:** Four buttons, four musical notes. Press a button, hear a tone.
Your chip is a musical instrument.

**Demo moment:** Play a simple melody. Hand it to someone. They play too.

**I/O:**
- 4 buttons (C, E, G, B notes)
- 1 audio output (connect to speaker/buzzer)
- 4 LEDs (show which note)

**What you'll learn:** Frequency generation, PWM, timing

**Customize it:**
- Change the notes (make it a minor chord? pentatonic scale?)
- Add polyphony (play multiple notes at once - see `pocket_synth_poly`)
- Add vibrato or tremolo

```
examples/pocket_synth/
├── pocket_synth.v        # main design (mono + poly versions)
└── pocket_synth_tb.v     # testbench
```

---

## Dice Roller

**What it does:** Press button, roll dice. Shows result on 7-segment display with
a satisfying "rolling" animation. Also logs rolls to serial for your D&D session.

**Demo moment:** "I attack the dragon." *press* *rolling animation* "Six! Critical hit!"

**I/O:**
- 1 button (roll)
- 7-segment display (result)
- 1 LED (rolling indicator)
- TX pin (optional logging)

**What you'll learn:** Display multiplexing, random numbers, animation timing

**Customize it:**
- Add a second die (2d6)
- Different dice (d4, d8, d20)
- Keep a running total

```
examples/dice_roller/
├── dice_roller.v         # main design
└── dice_roller_tb.v      # testbench
```

---

## Morse Beacon

**What it does:** Flashes your message in Morse code on a strip of NeoPixel LEDs.
All LEDs blink together—dots, dashes, and pauses. One wire output.

**Demo moment:** It's wearable. Put it on a hat, a bag, a jacket. Your chip, your message, your colors—in Morse code.

**I/O:**
- 1 button (cycle colors)
- 1 data pin (to WS2812 LED strip)

**What you'll learn:** Precise timing, serial protocols (WS2812), state machines, encoding (ASCII to Morse)

**Customize it:**
- Your name, your message
- Adjust Morse timing (faster or slower)
- More colors, color cycling

```
examples/morse_beacon/
├── morse_beacon.v       # main design
└── morse_beacon_tb.v    # testbench
```

---

## Your Own Idea

The best projects aren't on this list—they're yours.

**What makes a good custom project?**

- **Fits the constraints**: ~200-500 gates, 50 MHz clock, 5-10 I/O pins
- **Has a demo moment**: Something you can show someone in 30 seconds
- **You actually care about it**: You'll spend weeks on this; pick something fun

**Ideas that work well:**

- Games (reaction timer, pattern memory, simple puzzles)
- Art (LED patterns, sound generators, light-to-sound)
- Useful tools (frequency counter, PWM controller, serial decoder)
- Weird stuff (hardware RNG, cellular automata, prime number sieve)

**How to pitch it:**

1. One sentence: what does it do?
2. I/O list: what pins do you need?
3. Quick estimate: how complex? (compare to the examples)
4. Demo plan: how will you show it works?

Talk to the instructors early—we can help scope it.

---

## Shared Library

Common modules used by multiple projects:

```
examples/lib/
├── uart_tx.v             # serial transmitter (infrastructure, don't modify)
└── debounce.v            # button debouncer
```

---

## Running a Testbench

```bash
# From inside the container
cd /path/to/examples/fortune_teller

# Compile and run
iverilog -o sim.vvp -I../lib fortune_teller.v fortune_teller_tb.v ../lib/*.v
vvp sim.vvp

# View waveforms
gtkwave fortune_teller_tb.vcd
```

---

## What's Next?

Once your testbench works:

1. **Lint it** - `verilator --lint-only -I../lib your_design.v`
2. **Synthesize it** - Run through Yosys, check gate count
3. **Place & route** - LibreLane flow, check timing
4. **View layout** - Open GDS in KLayout, find your logic
5. **Tape out** - Your design is ready for fabrication!
