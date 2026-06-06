# Interface Specification

## 1. Global Rules

Tool and language:

- Tool: Vivado 2018.3
- Language: Verilog-2001
- Simulation: Vivado XSim
- Mainline design: pure Verilog hardware logic
- Soft CPU: not used as mainline

Clock and reset:

- Board input clock: `CLK100MHZ`
- Internal main clock: `clk_100m`
- VGA pixel clock: `pix_clk`
- Board reset input: `CPU_RESETN`
- Internal reset: `rst`, active high

Coordinate convention:

- Board size: 10 columns x 20 rows
- `row = 0`: top row
- `row = 19`: bottom row
- `col = 0`: left column
- `col = 9`: right column
- `cur_piece_x` and `cur_piece_y` represent the top-left corner of a 4x4 local piece box.
- `dx` and `dy` are local coordinates inside the 4x4 piece box.
- `block_x = cur_piece_x + dx`
- `block_y = cur_piece_y + dy`

Module responsibility:

- VGA module only reads game state and generates pixels.
- VGA module must not modify board state or game state.
- Input module only outputs action events.
- Input module must not directly modify `cur_piece_x`, `cur_piece_y`, `board`, `score`, or `game_state`.
- Game core decides whether movement, rotation, lock, line clear, or Game Over is legal.

## 2. Shared Definitions

Note: `game_defs.vh` contains localparam declarations and is intended to be included inside each module that uses these constants. Therefore, do not use an include guard in this file.

The following definitions must be placed in `rtl/common/game_defs.vh`.

### Board Size

```verilog
localparam BOARD_COLS = 10;
localparam BOARD_ROWS = 20;
```

### Piece Encoding

```verilog
localparam PIECE_I    = 3'd0;
localparam PIECE_O    = 3'd1;
localparam PIECE_T    = 3'd2;
localparam PIECE_S    = 3'd3;
localparam PIECE_Z    = 3'd4;
localparam PIECE_J    = 3'd5;
localparam PIECE_L    = 3'd6;
localparam PIECE_NONE = 3'd7;
```

### Cell Encoding

```verilog
localparam CELL_EMPTY = 4'd0;
localparam CELL_I     = 4'd1;
localparam CELL_O     = 4'd2;
localparam CELL_T     = 4'd3;
localparam CELL_S     = 4'd4;
localparam CELL_Z     = 4'd5;
localparam CELL_J     = 4'd6;
localparam CELL_L     = 4'd7;
localparam CELL_GHOST = 4'd8;
```

Important note:

- `PIECE_I` is 0, but `CELL_EMPTY` is also 0.
- Do not directly use `piece_type` as board cell value.
- Convert piece type to cell value before writing to board.

### Game State Encoding

```verilog
localparam GS_TITLE     = 3'd0;
localparam GS_SPAWN     = 3'd1;
localparam GS_PLAY      = 3'd2;
localparam GS_LOCK      = 3'd3;
localparam GS_CLEAR     = 3'd4;
localparam GS_PAUSE     = 3'd5;
localparam GS_GAME_OVER = 3'd6;
```

| State | Meaning |
|---|---|
| `GS_TITLE` | Title screen, waiting for start |
| `GS_SPAWN` | Spawn new piece |
| `GS_PLAY` | Normal playing |
| `GS_LOCK` | Lock current piece into board |
| `GS_CLEAR` | Check and clear full lines |
| `GS_PAUSE` | Pause |
| `GS_GAME_OVER` | Game over |

## 3. Input Module to Game Core

The input module must output game actions, not raw buttons or raw keyboard scan codes.

All `_pulse` signals are one `clk_100m` cycle wide.

```verilog
btn_left_pulse
btn_right_pulse
btn_rotate_pulse
btn_soft_drop_hold
btn_hard_drop_pulse
btn_hold_pulse
btn_pause_pulse
btn_start_pulse
btn_reset_pulse
```

| Signal | Type | Meaning |
|---|---|---|
| `btn_left_pulse` | pulse | Move left once |
| `btn_right_pulse` | pulse | Move right once |
| `btn_rotate_pulse` | pulse | Rotate clockwise once |
| `btn_soft_drop_hold` | hold | Speed up falling while held |
| `btn_hard_drop_pulse` | pulse | Hard drop |
| `btn_hold_pulse` | pulse | Hold current piece |
| `btn_pause_pulse` | pulse | Pause or resume |
| `btn_start_pulse` | pulse | Start game from title |
| `btn_reset_pulse` | pulse | Restart game |

First-version button mapping:

| Board input | Game action |
|---|---|
| `BTNL` | Left |
| `BTNR` | Right |
| `BTNU` | Rotate |
| `BTND` | Soft drop |
| `BTNC` | Start or hard drop |
| `SW0` | Pause |
| `SW1` | Hold |
| `CPU_RESETN` | Global reset |

Recommended left/right repeat behavior:

- Immediate movement when first pressed.
- After about 300 ms hold delay, repeat every about 80 ms.
- Stop repeat after release.

## 4. Game Core to VGA

The VGA module queries board cell content by row and col.

```verilog
input  wire [4:0] board_query_row;
input  wire [3:0] board_query_col;
output wire [3:0] board_cell_value;

output wire [2:0] cur_piece_type;
output wire [1:0] cur_piece_rot;
output wire signed [4:0] cur_piece_x;
output wire signed [5:0] cur_piece_y;

output wire [2:0] next_piece_type;
output wire [2:0] hold_piece_type;
output wire       hold_valid;

output wire [15:0] score;
output wire [7:0]  lines;
output wire [3:0]  level;

output wire [2:0]  game_state;
output wire [19:0] clear_line_mask;
output wire        clear_anim_active;
```

Rules:

- `board_query_row` range: 0 to 19.
- `board_query_col` range: 0 to 9.
- `board_cell_value` returns the corresponding `CELL_*` value.
- If query coordinate is invalid, return `CELL_EMPTY`.
- VGA must not access the internal board array directly.
- VGA may call `piece_rom` to render active piece, Next, Hold, and Ghost.

## 5. Game Core to IO and Audio

```verilog
output wire [15:0] score;
output wire [3:0]  level;
output wire [7:0]  lines;
output wire [2:0]  game_state;

output wire sfx_move;
output wire sfx_rotate;
output wire sfx_drop;
output wire sfx_clear;
output wire sfx_game_over;
```

Rules:

- `sfx_*` signals are one `clk_100m` cycle wide.
- Trigger `sfx_move` only when movement is successful.
- Trigger `sfx_rotate` only when rotation is successful.
- Trigger `sfx_drop` on hard drop or piece lock.
- Trigger `sfx_clear` when one or more lines are cleared.
- Trigger `sfx_game_over` only once when entering Game Over.

## 6. VGA Layout

Recommended display mode:

- 640 x 480

Recommended board layout:

```verilog
localparam CELL_SIZE = 20;
localparam BOARD_X0  = 220;
localparam BOARD_Y0  = 40;
```

Board pixel size:

```text
width  = 10 * 20 = 200 pixels
height = 20 * 20 = 400 pixels
```

Rendering priority:

1. Title, Pause, or Game Over overlay
2. Clear-line animation
3. Current active piece
4. Locked board cells
5. Ghost piece
6. Board grid
7. Background

## 7. Key Module Interfaces

### `piece_rom.v`

```verilog
module piece_rom (
    input  wire [2:0] piece_type,
    input  wire [1:0] rotation,
    input  wire [1:0] block_idx,
    output reg  [1:0] dx,
    output reg  [1:0] dy
);
```

Function:

Given piece type, rotation state, and block index, output the local 4x4 coordinate of that block.

Users:

- Game core uses it for collision detection.
- VGA uses it for rendering current piece, Next, Hold, and Ghost.

### `vga_timing.v`

```verilog
module vga_timing (
    input  wire       pix_clk,
    input  wire       rst,
    output reg        hsync,
    output reg        vsync,
    output wire       video_on,
    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y
);
```

Function:

Generate VGA timing and current pixel coordinate.

### `button_input.v`

```verilog
module button_input (
    input  wire       clk_100m,
    input  wire       rst,
    input  wire       btnc,
    input  wire       btnu,
    input  wire       btnd,
    input  wire       btnl,
    input  wire       btnr,
    input  wire [1:0] sw,

    output wire       btn_left_pulse,
    output wire       btn_right_pulse,
    output wire       btn_rotate_pulse,
    output wire       btn_soft_drop_hold,
    output wire       btn_hard_drop_pulse,
    output wire       btn_hold_pulse,
    output wire       btn_pause_pulse,
    output wire       btn_start_pulse,
    output wire       btn_reset_pulse
);
```

Function:

Convert board buttons and switches into unified game action signals.

### `game_core_minimal.v`

```verilog
module game_core_minimal (
    input  wire              clk_100m,
    input  wire              rst,

    input  wire              btn_left_pulse,
    input  wire              btn_right_pulse,
    input  wire              btn_rotate_pulse,
    input  wire              btn_start_pulse,

    output reg  [2:0]        cur_piece_type,
    output reg  [1:0]        cur_piece_rot,
    output reg signed [4:0]  cur_piece_x,
    output reg signed [5:0]  cur_piece_y,
    output reg  [2:0]        game_state
);
```

Function:

Early integration module. It only needs to implement title start, fixed T piece, left/right movement, and rotation.

## 8. Internal Game Module Interfaces

This section documents helper modules used inside `game_core`. These are internal game-core datapath interfaces, not VGA or IO external interfaces.

### `collision_check.v`

Function:

Check whether a candidate piece placement collides with the board boundary or with existing locked board cells. The module expands the 4 blocks of the piece by instantiating four `piece_rom` modules, then produces up to four board query addresses and a combinational `collision` result.

Interface:

```verilog
module collision_check (
    input  wire signed [4:0] test_x,
    input  wire signed [5:0] test_y,
    input  wire [2:0]        piece_type,
    input  wire [1:0]        rotation,

    output reg  [4:0]        q_row0,
    output reg  [3:0]        q_col0,
    input  wire [3:0]        q_cell0,

    output reg  [4:0]        q_row1,
    output reg  [3:0]        q_col1,
    input  wire [3:0]        q_cell1,

    output reg  [4:0]        q_row2,
    output reg  [3:0]        q_col2,
    input  wire [3:0]        q_cell2,

    output reg  [4:0]        q_row3,
    output reg  [3:0]        q_col3,
    input  wire [3:0]        q_cell3,

    output reg               collision
);
```

Coordinate rules:

- `test_x` and `test_y` are the top-left corner of the 4x4 local piece box being tested.
- For each local block, `block_x = test_x + dx` and `block_y = test_y + dy`.
- The module queries board cells only for blocks with `block_y >= 0`.
- For blocks with `block_y < 0`, the corresponding `q_row` and `q_col` may be `0`, and the block does not collide merely because it is above the board.

Collision rules:

- `block_x < 0` causes collision.
- `block_x >= BOARD_COLS` causes collision.
- `block_y >= BOARD_ROWS` causes collision.
- `block_y < 0` does not cause collision and does not require a board-cell query.
- When `block_y >= 0`, any corresponding queried `q_cell` not equal to `CELL_EMPTY` causes collision.
- If no block violates these rules, `collision = 0`.

### `line_clear.v`

Function:

Check a full board image for completed lines and produce the compressed board after line removal. This is a combinational helper module for `game_core` internal board update logic. It is not a VGA or IO external interface.

Interface:

```verilog
module line_clear (
    input  wire [799:0] board_flat_in,
    output reg  [799:0] board_flat_out,
    output reg  [19:0]  clear_line_mask,
    output reg  [2:0]   clear_count
);
```

Flattened board rules:

- The board is flattened as 20 rows x 10 columns x 4 bits per cell, for 800 bits total.
- `cell_index = row * BOARD_COLS + col`.
- The corresponding bit range is `cell_index*4 +: 4`.
- `row = 0` is the top row and `row = 19` is the bottom row.
- `col = 0` is the left column and `col = 9` is the right column.

Line-clear rules:

- A row is full when all 10 cells are not `CELL_EMPTY`.
- `clear_line_mask[row] = 1` marks a row that is removed.
- `clear_count` is the number of removed rows.
- `board_flat_out` keeps all non-full rows, removes full rows, shifts rows above cleared lines downward, and fills the top rows with `CELL_EMPTY`.
- The module is pure combinational logic and has no `clk` or `rst`.

### `random_lfsr.v`

Function:

Generate the next piece type for `game_core` using a simple 8-bit LFSR. This is an internal game-core helper module, not a VGA or IO external interface.

Interface:

```verilog
module random_lfsr (
    input  wire       clk_100m,
    input  wire       rst,
    input  wire       enable,
    output reg  [2:0] piece_type
);
```

Rules:

- The module runs in the `clk_100m` clock domain and uses active-high `rst`.
- On reset, the internal 8-bit LFSR is initialized to a nonzero seed.
- When `enable = 1`, the LFSR advances and `piece_type` is updated.
- `piece_type` must always be in the range `PIECE_I` through `PIECE_L`, encoded as 0 through 6.
- The module must not output `PIECE_NONE`.
- The mapping from LFSR state to piece type does not need to be perfectly uniform for the first playable version.
