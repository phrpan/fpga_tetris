# Work Division

## Member 1: Game Core Logic and System Integration, 40%

Responsible for the game controller, datapath, board state management, collision detection, line clearing, score/level control, and top-level integration.

Main files:

- rtl/common/game_defs.vh
- rtl/game/piece_rom.v
- rtl/game/game_core_minimal.v
- rtl/game/game_core.v
- rtl/game/collision_check.v
- rtl/game/line_clear.v
- rtl/game/score_level.v
- rtl/game/random_lfsr.v
- rtl/top.v
- sim/tb_piece_rom.v
- sim/tb_collision_check.v
- sim/tb_line_clear.v
- sim/tb_game_core.v

First priorities:

1. game_defs.vh
2. piece_rom.v
3. tb_piece_rom.v
4. game_core_minimal.v
5. First integration with input and VGA

## Member 2: VGA Graphics Display and Real-Time Rendering, 35%

Responsible for VGA timing, pixel-coordinate mapping, real-time rendering, game screen composition, and UI display.

Main files:

- rtl/video/vga_timing.v
- rtl/video/vga_colorbar.v
- rtl/video/board_renderer.v
- rtl/video/piece_renderer.v
- rtl/video/ui_renderer.v
- rtl/video/color_palette.v
- rtl/video/font_rom.v
- rtl/video/clear_animation.v
- sim/tb_vga_timing.v

First priorities:

1. vga_timing.v
2. VGA color-bar display
3. 10x20 board grid
4. Fake board rendering
5. Current piece rendering
6. Real board rendering from game core

## Member 3: Human Interaction, Peripheral Feedback, Audio, and Documentation, 25%

Responsible for button debouncing, one-pulse event generation, keyboard input, seven-segment display, LEDs, PWM audio, debug logs, report materials, and demo video preparation.

Main files:

- rtl/io/debounce.v
- rtl/io/one_pulse.v
- rtl/io/button_input.v
- rtl/io/repeat_pulse.v
- rtl/io/seven_seg_driver.v
- rtl/io/score_bcd.v
- rtl/io/led_status.v
- rtl/io/ps2_receiver.v
- rtl/io/keyboard_decoder.v
- rtl/audio/tone_gen.v
- rtl/audio/pwm_audio.v
- rtl/audio/sfx_controller.v
- sim/tb_debounce.v
- sim/tb_button_input.v
- docs/debug_log.md
- docs/demo_script.md

First priorities:

1. debounce.v
2. one_pulse.v
3. button_input.v
4. LED verification for button events
5. repeat_pulse.v
6. seven_seg_driver.v
7. debug log and report material collection