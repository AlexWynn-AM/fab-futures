# Example Projects

Pick a project. Build a chip. Show it off.

Each project is a complete, working design you can tape out. They all fit the
same constraints (~200-500 gates, 50 MHz clock, a handful of I/O pins) and use
the same RTL-to-GDS flow. The difference is what your chip *does*.

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

## LED Messenger

**What it does:** Scrolls your name (or any message) on a strip of NeoPixel LEDs.
One wire output. Pure magic.

**Demo moment:** It's wearable. Put it on a hat, a bag, a jacket. Your chip, your name, your colors.

**I/O:**
- 1 button (cycle colors)
- 1 data pin (to WS2812 LED strip)

**What you'll learn:** Precise timing, serial protocols, finite state machines

**Customize it:**
- Your name, your message
- More colors, gradients, rainbow mode
- Different fonts, bigger letters

```
examples/led_messenger/
├── led_messenger.v       # main design
└── led_messenger_tb.v    # testbench
```

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
5. **Tape out** - You made a chip!
