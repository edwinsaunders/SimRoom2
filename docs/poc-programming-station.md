# Physical VM Programming Station

This document describes the proof-of-concept programming machine in the prototype annex as if it were a tiny assembly-like platform.

The goal is not to model a real CPU in detail. The goal is to establish the design language for "a 3D world as a physical abstraction layer over a tiny programming model."

## Overview

The prototype annex contains a wall-mounted 16:9 screen and a physical command station.

You program the station by walking up to the buttons and pressing `E` on them in sequence.

The machine stores a short instruction list, then executes it on the screen when you press `RUN`.

The current machine controls a single on-screen object:

- it can move left
- it can move right
- it can wait in place
- it can change color

## Machine Model

The current proof-of-concept machine can be treated as a tiny visual virtual machine with one visible actor and one program queue.

State tracked by the machine:

- object horizontal position
- object color
- current instruction pointer
- current queued program

Execution model:

- the machine executes one instruction at a time
- instructions advance at a fixed step interval
- the screen shows the current queue and execution progress
- `RUN` restarts execution from a clean initial state
- `RESET` clears the queued program and restores the initial screen state

## Physical Interface

The station is programmed through six physical buttons:

- `MOVE LEFT`
- `WAIT`
- `SET COLOR`
- `MOVE RIGHT`
- `RUN`
- `RESET`

Interaction rules:

- stand near the station
- look at the desired button
- press `E`

Command buttons add instructions to the queue.

Control buttons operate on the queue:

- `RUN` executes the current queued program
- `RESET` clears the queue and resets the display

## Program Capacity

The current machine supports a maximum program length of 8 instructions.

If you try to add more than 8 instructions, the station reports:

```text
PROGRAM FULL
```

## Instruction Set Reference

### `MOVE_LEFT`

Mnemonic:

```text
MOVE_LEFT
```

Effect:

- moves the on-screen object one step to the left
- movement is clamped so the object cannot leave the playfield

Use when:

- you want the object to travel toward the left side of the screen

### `MOVE_RIGHT`

Mnemonic:

```text
MOVE_RIGHT
```

Effect:

- moves the on-screen object one step to the right
- movement is clamped so the object cannot leave the playfield

Use when:

- you want the object to travel toward the right side of the screen

### `WAIT`

Mnemonic:

```text
WAIT
```

Effect:

- consumes one execution step
- leaves position and color unchanged

Use when:

- you want visible timing between operations
- you want to space out movement or color changes

### `SET_COLOR`

Mnemonic:

```text
SET_COLOR
```

Effect:

- advances the on-screen object to the next color in the machine palette

Current palette cycle:

1. cyan
2. yellow
3. red
4. green

Use when:

- you want visible state change without changing position
- you want to combine movement and state change into a short visual program

## Control Operations

### `RUN`

`RUN` does not append to the program. It executes the current queued program.

Execution behavior:

- the machine resets the object to its initial state
- execution starts from instruction 1
- one instruction is executed per step interval
- when the last instruction finishes, the machine reports completion

Important consequence:

- `RUN` always starts from a clean initial state, not from the last partially executed state

### `RESET`

`RESET` clears the queued program and restores the initial machine state.

Effect:

- queue becomes empty
- instruction pointer resets
- object position returns to center
- object color returns to the initial color
- screen status returns to reset/idle state

## Screen Readout

The wall screen shows the machine state in a compact debug-style format.

Visible elements:

- machine title
- status field
- current queued program
- current step readout
- 2D playfield with the object

Typical status messages:

- `STATUS: RESET`
- `STATUS: READY`
- `STATUS: RUNNING`
- `STATUS: DONE`
- `STATUS: EMPTY`

Queue display format:

- before execution, entries are numbered
- during execution, the current instruction is marked with `>`

Example:

```text
PROGRAM: 1:MOVE_RIGHT  |  2:SET_COLOR  |  3:WAIT
```

During execution:

```text
PROGRAM: 1:MOVE_RIGHT  |  >:SET_COLOR  |  3:WAIT
```

## Programming Workflow

The intended workflow is:

1. Walk to the prototype annex.
2. Approach the station.
3. Press `E` on command buttons to build a sequence.
4. Check the queue on the wall screen.
5. Press `E` on `RUN`.
6. Observe the object execute the queued instructions.
7. Press `E` on `RESET` when you want to clear the machine.

## Example Programs

### Example 1: Move Right Once

Input sequence:

```text
MOVE_RIGHT
RUN
```

Expected result:

- the object moves one step to the right

### Example 2: Move Right, Pause, Move Right Again

Input sequence:

```text
MOVE_RIGHT
WAIT
MOVE_RIGHT
RUN
```

Expected result:

- the object moves right
- pauses for one step
- moves right again

### Example 3: Change Color While Moving

Input sequence:

```text
MOVE_LEFT
SET_COLOR
WAIT
MOVE_RIGHT
RUN
```

Expected result:

- the object shifts left
- changes to the next palette color
- pauses
- shifts right

## Recommended Mental Model

Think of the machine as a very small queued instruction processor:

- the buttons are your instruction entry mechanism
- the queue is your program memory
- the screen is your debugger and output device
- `RUN` is equivalent to starting program execution
- `RESET` is equivalent to clearing memory and returning the machine to its boot state

## Current Limits

This is intentionally a first proof of concept. Current constraints are part of the design.

Current limits:

- only one visible object is simulated
- only horizontal movement is supported
- there is no branching
- there are no labels
- there are no registers exposed to the player
- there is no editable text program entry
- programs are entered physically by pressing buttons
- maximum program length is 8 instructions

## Future Expansion Path

This prototype is already structured so it can grow in an assembly-like direction later.

Natural future additions:

- more motion instructions
- explicit registers or counters
- conditional branches
- loops
- multiple on-screen entities
- physical instruction cartridges or blocks instead of buttons
- memory cells or rails in the room that represent program state

## Where It Lives In The Project

Primary scene and script files:

- [prototype_annex.tscn](/home/edwin/Documents/SimRoom2/poc/scenes/prototype_annex.tscn)
- [poc_station.tscn](/home/edwin/Documents/SimRoom2/poc/scenes/poc_station.tscn)
- [poc_button.tscn](/home/edwin/Documents/SimRoom2/poc/scenes/poc_button.tscn)
- [poc_screen.tscn](/home/edwin/Documents/SimRoom2/poc/scenes/poc_screen.tscn)
- [poc_station.gd](/home/edwin/Documents/SimRoom2/poc/scripts/poc_station.gd)
- [poc_button.gd](/home/edwin/Documents/SimRoom2/poc/scripts/poc_button.gd)
- [poc_screen.gd](/home/edwin/Documents/SimRoom2/poc/scripts/poc_screen.gd)

Integration point into the existing world:

- [main.tscn](/home/edwin/Documents/SimRoom2/scenes/main.tscn)
