# FPGA Tetris Project Instructions

This is a Vivado 2018.3 Verilog project for Nexys4 DDR / Artix-7.

The project implements a VGA Tetris interactive game using pure FPGA hardware logic. The main design direction is Verilog-based finite state machines and hardware datapaths. Do not introduce MicroBlaze, MIPS soft core, DDR framebuffer, SD card, or other large subsystems unless explicitly requested.

## Required Context Files

Before modifying code, read these files:

- docs/project_plan.md
- docs/interface_spec.md
- docs/work_division.md

If any of these files are missing, ask the user before making major code changes.

## Main Rules

- Use synthesizable Verilog-2001.
- Avoid SystemVerilog-only syntax unless explicitly requested.
- Use Vivado 2018.3 compatibility.
- Do not introduce MicroBlaze or MIPS soft CPU unless explicitly requested.
- Do not modify XDC pin constraints unless explicitly requested.
- Do not modify Vivado-generated files under vivado/, especially .runs, .cache, .sim, .gen, .srcs, or .Xil.
- Do not rewrite the whole project at once.
- Implement one small module at a time.
- Keep interfaces stable once documented in docs/interface_spec.md.
- Ask before changing top-level ports or shared definitions.

## Coding Style

- Sequential always blocks use nonblocking assignments.
- Combinational logic uses always @* blocks.
- Active-high reset is named rst.
- Main system clock is clk_100m.
- VGA pixel clock is pix_clk.
- Module names and file names use lowercase_with_underscores.
- Single-cycle action signals end with _pulse.
- Hold-level action signals end with _hold.

## Tetris Coordinate Convention

- Board size is 10 columns x 20 rows.
- row = 0 is the top row.
- row = 19 is the bottom row.
- col = 0 is the left column.
- col = 9 is the right column.
- The current piece position cur_piece_x / cur_piece_y is the top-left corner of a 4x4 local piece box.
- dx and dy are local block coordinates inside the 4x4 piece box.
- All input action pulses are one clk_100m cycle wide, except btn_soft_drop_hold.

## Project Structure

- rtl/common: shared constants.
- rtl/game: game core logic.
- rtl/video: VGA timing and rendering.
- rtl/io: buttons, keyboard, seven-segment display, LEDs.
- rtl/audio: PWM sound effects.
- sim: testbenches.
- constraints: XDC files.
- docs: design notes and report materials.
- vivado: Vivado project files and generated files.

## Development Workflow

1. Read AGENTS.md and docs before modifying code.
2. Implement one small module at a time.
3. Add or update a testbench for nontrivial logic.
4. Do not change shared interfaces without updating docs/interface_spec.md.
5. Do not modify files under vivado/ unless explicitly requested.
6. Do not modify constraints unless explicitly requested.
7. Prefer simple, reliable baseline functionality before enhanced features.