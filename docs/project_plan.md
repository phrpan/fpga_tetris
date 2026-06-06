# 基于 FPGA 的 VGA 俄罗斯方块项目协作推进文档

> 项目名称：基于 Nexys4 DDR FPGA 的 VGA 俄罗斯方块交互游戏设计与实现  
> 开发工具：Vivado 2018.3  
> 开发方式：三人协作，纯 Verilog/硬件状态机主线，不使用软核作为主线  
> 计划周期：4 天完成可演示版本  
> 当前状态：Vivado 环境、bitstream 生成、Hardware Manager 连接、LED0 闪烁、CPU_RESETN 复位均已验证通过

---

## 0. 项目目标与优先级

本项目目标是在 Nexys4 DDR 开发板上实现一个完整可玩的 VGA 俄罗斯方块游戏，使用 FPGA 纯硬件逻辑完成游戏状态更新、碰撞检测、VGA 显示、按键输入、数码管显示、LED 状态显示和可选音效。

### 0.1 必须完成的基础验收功能

这些功能必须优先保证，不允许被增强功能拖慢。

1. VGA 640×480 显示稳定；
2. 屏幕上显示 10×20 游戏棋盘；
3. 七种俄罗斯方块 I/O/T/S/Z/J/L；
4. 方块自动下落；
5. 左移、右移、旋转、软降、硬降；
6. 边界检测和已有方块碰撞检测；
7. 方块触底后锁定到棋盘；
8. 满行检测、消行、棋盘下移；
9. 分数、等级或消行数显示；
10. 游戏开始、暂停、Game Over、重新开始；
11. 七段数码管或 LED 至少显示部分状态信息。

### 0.2 建议完成的出彩功能

这些功能按优先级推进，必须在基础版稳定后再加入。

1. Next 方块预览；
2. Hold 方块；
3. Ghost 影子方块；
4. 消行动画；
5. 标题页、暂停页、Game Over 页；
6. PWM 音效；
7. USB 键盘控制；
8. UI 美化和演示视频优化。

### 0.3 暂不作为主线的内容

以下内容不在 4 天内作为主线，除非基础版已稳定完成。

1. MicroBlaze 软核；
2. 自研 MIPS 软核；
3. DDR2 完整帧缓冲；
4. SD 卡存储；
5. 复杂排行榜；
6. 加速度计体感控制。

---

## 1. 三人角色

### 1.1 成员 1：游戏核心与系统集成负责人。

职责定位：负责 FPGA 俄罗斯方块系统的核心控制单元、游戏数据通路、状态机调度和顶层集成，是整个系统的逻辑控制中心。

主要任务：

1. 制定公共接口协议和编码规范；
2. 编写 `game_defs.vh`；
3. 实现 `piece_rom.v`；
4. 实现最小版 `game_core_minimal.v`；
5. 实现正式 `game_core.v`；
6. 实现棋盘存储、碰撞检测、锁定、消行、计分、等级、Game Over；
7. 负责 `top.v` 顶层集成；
8. 负责处理三方接口不一致、端口命名不一致、位宽不一致等问题；
9. 负责关键 testbench：方块 ROM、碰撞检测、消行逻辑、游戏状态机。

关键交付文件：

```text
rtl/common/game_defs.vh
rtl/game/piece_rom.v
rtl/game/game_core_minimal.v
rtl/game/game_core.v
rtl/game/collision_check.v
rtl/game/line_clear.v
rtl/game/score_level.v
rtl/game/random_lfsr.v
rtl/top.v
sim/tb_piece_rom.v
sim/tb_collision_check.v
sim/tb_line_clear.v
sim/tb_game_core.v
```

必须优先完成：

1. `game_defs.vh`；
2. `piece_rom.v`；
3. `game_core_minimal.v`；
4. 和 VGA、输入模块打通第一个联调版本。

---

### 1.2 成员 2：VGA 显示与 UI 负责人

职责定位：负责 VGA 视频时序、像素级实时渲染、游戏画面合成和交互式 UI 显示，是系统中最直接体现 FPGA 实时并行显示能力的模块负责人。

主要任务：

1. 实现 VGA 时序模块；
2. 完成 VGA 彩条测试；
3. 绘制 10×20 棋盘网格；
4. 使用假数据渲染静态棋盘；
5. 接入游戏核心的棋盘查询接口；
6. 渲染已锁定方块；
7. 渲染当前活动方块；
8. 渲染 Next、Hold、Ghost；
9. 实现标题页、暂停页、Game Over 页；
10. 实现消行动画和 UI 美化；
11. 保存 VGA 相关调试截图、仿真截图和显示器照片。

关键交付文件：

```text
rtl/video/vga_timing.v
rtl/video/vga_colorbar.v
rtl/video/board_renderer.v
rtl/video/piece_renderer.v
rtl/video/ui_renderer.v
rtl/video/color_palette.v
rtl/video/font_rom.v        # 可选
rtl/video/clear_animation.v # 可选
sim/tb_vga_timing.v
```

第一优先级：

1. VGA 彩条显示成功；
2. 棋盘网格显示成功；
3. 假棋盘数据显示成功；
4. 能显示游戏核心输出的真实棋盘和当前方块。

---

### 1.3 成员 3：输入外设、音效、数码管、报告视频负责人

职责定位：负责人机交互输入系统、外设反馈系统、调试辅助与工程文档，是系统可玩性、演示完整度和答辩材料质量的主要负责人。

主要任务：

1. 板载按键消抖；
2. 单周期输入脉冲生成；
3. 左右长按重复控制；
4. 统一游戏输入动作输出；
5. 七段数码管显示分数、等级、行数；
6. LED 显示游戏状态；
7. PWM 音效；
8. USB 键盘控制，可作为后期增强；
9. 整理调试日志、截图、分工、报告素材、演示视频脚本。

关键交付文件：

```text
rtl/io/debounce.v
rtl/io/one_pulse.v
rtl/io/button_input.v
rtl/io/repeat_pulse.v
rtl/io/seven_seg_driver.v
rtl/io/score_bcd.v
rtl/io/led_status.v
rtl/io/ps2_receiver.v       # 可选增强
rtl/io/keyboard_decoder.v   # 可选增强
rtl/audio/tone_gen.v        # 可选增强
rtl/audio/pwm_audio.v       # 可选增强
rtl/audio/sfx_controller.v  # 可选增强
sim/tb_debounce.v
sim/tb_button_input.v
sim/tb_ps2_receiver.v       # 可选
```

第一优先级：

1. 板载按键消抖；
2. 输出统一游戏动作信号；
3. 七段数码管和 LED；
4. 报告素材同步整理。

---

## 2. 全员必须共同约定的内容

这些约定一旦确定，不允许个人随意修改。若必须修改，应先在群里说明，并同步更新本文档和代码中的公共定义文件。

---

### 2.1 工具与语言约定

1. 使用 Vivado 2018.3；
2. 主线使用 Verilog-2001，不主动使用 SystemVerilog 特性；
3. 不使用软核作为主线；
4. 不使用 ISE；
5. 仿真优先使用 Vivado 自带 XSim；
6. 顶层约束使用 Nexys4 DDR 对应 XDC，不要误用 Nexys A7、Basys3 或其他开发板的约束；
7. 每次修改顶层端口后必须检查 XDC 中对应端口名。

---

### 2.2 代码目录约定

统一使用如下结构：

```text
fpga_tetris/
├── rtl/
│   ├── common/
│   │   └── game_defs.vh
│   ├── game/
│   ├── video/
│   ├── io/
│   ├── audio/
│   └── top.v
├── sim/
├── constraints/
├── docs/
│   ├── interface_spec.md
│   ├── debug_log.md
│   ├── work_division.md
│   ├── demo_script.md
│   └── images/
└── vivado/
```

命名规范：

1. 文件名小写加下划线，例如 `game_core.v`；
2. 模块名与文件名尽量一致；
3. 时钟信号统一命名为 `clk_100m`、`pix_clk`；
4. 复位信号统一在模块内部使用高有效 `rst`；
5. 单周期脉冲以 `_pulse` 结尾；
6. 按住型电平以 `_hold` 结尾；
7. VGA 像素坐标统一为 `pixel_x`、`pixel_y`。

---

### 2.3 时钟与复位约定

全局输入：

```verilog
input wire CLK100MHZ;
input wire CPU_RESETN;
```

顶层统一转换：

```verilog
wire clk_100m = CLK100MHZ;
wire rst_raw  = ~CPU_RESETN;
```

建议在顶层做复位同步，之后所有子模块使用：

```verilog
wire rst;
```

约定：

1. `rst` 为高有效复位；
2. 游戏核心、输入、数码管、音效优先运行在 `clk_100m`；
3. VGA 时序运行在 `pix_clk`；
4. VGA 模块只读取游戏状态，不修改游戏状态；
5. 跨时钟域的信号要谨慎处理，第一版尽量使用稳定寄存器状态供 VGA 读取；
6. 单周期输入 pulse 均在 `clk_100m` 域产生。

---

### 2.4 棋盘坐标约定

棋盘大小：

```text
10 列 × 20 行
```

坐标方向：

```text
row = 0  表示最上方一行
row = 19 表示最下方一行
col = 0  表示最左侧一列
col = 9  表示最右侧一列
```

当前方块位置：

```text
cur_piece_x / cur_piece_y 表示当前方块 4×4 局部包围盒左上角在棋盘中的位置。
```

局部坐标：

```text
dx, dy 范围为 0~3
实际棋盘坐标：
block_x = cur_piece_x + dx
block_y = cur_piece_y + dy
```

注意事项：

1. `cur_piece_x` 必须使用 signed 类型，因为旋转或 wall kick 时可能临时测试负坐标；
2. `cur_piece_y` 也建议使用 signed 类型，因为新方块刚生成时可以有部分在棋盘上方；
3. 碰撞检测中，`block_y < 0` 时不查询棋盘，视为未进入棋盘；
4. `block_x < 0`、`block_x >= 10`、`block_y >= 20` 均视为碰撞。

---

### 2.5 方块编号约定

统一在 `rtl/common/game_defs.vh` 中定义：

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

对应棋盘格颜色/类型编码：

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

注意：

1. `PIECE_*` 用于游戏逻辑中的方块类型；
2. `CELL_*` 用于棋盘格子存储和 VGA 颜色显示；
3. 不要把 `PIECE_I = 0` 直接当成棋盘格值，因为 `CELL_EMPTY` 也是 0。

---

### 2.6 游戏状态编码约定

统一在 `game_defs.vh` 中定义：

```verilog
localparam GS_TITLE     = 3'd0;
localparam GS_SPAWN     = 3'd1;
localparam GS_PLAY      = 3'd2;
localparam GS_LOCK      = 3'd3;
localparam GS_CLEAR     = 3'd4;
localparam GS_PAUSE     = 3'd5;
localparam GS_GAME_OVER = 3'd6;
```

状态含义：

| 状态 | 含义 |
|---|---|
| `GS_TITLE` | 标题页，等待开始 |
| `GS_SPAWN` | 生成新方块 |
| `GS_PLAY` | 正常游戏运行 |
| `GS_LOCK` | 当前方块锁定到棋盘 |
| `GS_CLEAR` | 检查消行、执行消行动画或棋盘压缩 |
| `GS_PAUSE` | 暂停 |
| `GS_GAME_OVER` | 游戏结束 |

注意：VGA、LED、数码管均根据同一份 `game_state` 显示状态。

---

### 2.7 输入动作接口约定

输入模块最终只输出游戏动作，不把原始按键或扫描码直接交给游戏核心。

统一接口如下：

```verilog
input wire btn_left_pulse;
input wire btn_right_pulse;
input wire btn_rotate_pulse;
input wire btn_soft_drop_hold;
input wire btn_hard_drop_pulse;
input wire btn_hold_pulse;
input wire btn_pause_pulse;
input wire btn_start_pulse;
input wire btn_reset_pulse;
```

语义约定：

| 信号 | 类型 | 说明 |
|---|---|---|
| `btn_left_pulse` | 单周期脉冲 | 左移一次 |
| `btn_right_pulse` | 单周期脉冲 | 右移一次 |
| `btn_rotate_pulse` | 单周期脉冲 | 顺时针旋转一次 |
| `btn_soft_drop_hold` | 按住电平 | 按住时加速下落 |
| `btn_hard_drop_pulse` | 单周期脉冲 | 硬降到底 |
| `btn_hold_pulse` | 单周期脉冲 | Hold 当前方块 |
| `btn_pause_pulse` | 单周期脉冲 | 暂停/继续 |
| `btn_start_pulse` | 单周期脉冲 | 标题页开始 |
| `btn_reset_pulse` | 单周期脉冲 | 重新开始 |

脉冲宽度约定：

```text
所有 `_pulse` 信号均为 clk_100m 时钟域下 1 个周期宽度。
```

第一版板载按键映射：

| 输入 | 功能 |
|---|---|
| BTNL | 左移 |
| BTNR | 右移 |
| BTNU | 旋转 |
| BTND | 软降 |
| BTNC | 开始/硬降，可由状态区分 |
| SW0 | 暂停，可选 |
| SW1 | Hold，可选 |
| CPU_RESETN | 全局复位 |

长按重复建议：

```text
左/右刚按下：立即移动一次
持续按住约 300 ms 后：每约 80 ms 重复移动一次
松开：停止重复
```

---

### 2.8 游戏核心输出给 VGA 的接口约定

VGA 模块通过查询坐标读取棋盘格内容。

推荐接口：

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

约定：

1. `board_query_row` 范围 0~19；
2. `board_query_col` 范围 0~9；
3. `board_cell_value` 返回对应棋盘格编码；
4. VGA 负责人不要直接访问游戏核心内部棋盘数组；
5. 如果坐标越界，游戏核心返回 `CELL_EMPTY`。

---

### 2.9 游戏核心输出给外设的接口约定

外设模块读取游戏核心状态显示数码管、LED 和音效。

推荐接口：

```verilog
output wire [15:0] score;
output wire [3:0]  level;
output wire [7:0]  lines;
output wire [2:0]  game_state;

output wire        sfx_move;
output wire        sfx_rotate;
output wire        sfx_drop;
output wire        sfx_clear;
output wire        sfx_game_over;
```

约定：

1. `sfx_*` 为 `clk_100m` 域下单周期脉冲；
2. 成功移动才触发 `sfx_move`，撞墙不能触发；
3. 成功旋转才触发 `sfx_rotate`；
4. 硬降或锁定可触发 `sfx_drop`；
5. 消除至少一行触发 `sfx_clear`；
6. 第一次进入 Game Over 触发 `sfx_game_over`。

---

### 2.10 VGA 显示参数约定

建议使用 640×480 显示模式。

棋盘显示布局建议：

```verilog
localparam CELL_SIZE = 20;
localparam BOARD_X0  = 220;
localparam BOARD_Y0  = 40;
```

棋盘像素大小：

```text
宽度：10 × 20 = 200 像素
高度：20 × 20 = 400 像素
```

显示优先级建议：

```text
标题/暂停/Game Over 覆盖层
> 消行动画高亮
> 当前活动方块
> 已锁定棋盘方块
> Ghost 影子方块
> 棋盘网格
> 背景
```

注意：

1. VGA 模块不能修改游戏状态；
2. VGA 模块可以调用 `piece_rom` 判断当前方块/预览方块形状；
3. VGA 模块应先支持假数据，不能等待游戏核心完全完成。

---

## 3. 关键模块接口草案

### 3.1 `piece_rom.v`

```verilog
module piece_rom (
    input  wire [2:0] piece_type,
    input  wire [1:0] rotation,
    input  wire [1:0] block_idx,
    output reg  [1:0] dx,
    output reg  [1:0] dy
);
```

功能：根据方块类型、旋转状态和第几个小方块，输出该小方块在 4×4 局部坐标中的位置。

使用者：

1. 游戏核心用于碰撞检测；
2. VGA 模块用于渲染当前方块、Next、Hold、Ghost。

---

### 3.2 `vga_timing.v`

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

功能：产生 VGA 扫描时序和当前像素坐标。

---

### 3.3 `button_input.v`

```verilog
module button_input (
    input  wire clk_100m,
    input  wire rst,
    input  wire btnc,
    input  wire btnu,
    input  wire btnd,
    input  wire btnl,
    input  wire btnr,
    input  wire [1:0] sw,

    output wire btn_left_pulse,
    output wire btn_right_pulse,
    output wire btn_rotate_pulse,
    output wire btn_soft_drop_hold,
    output wire btn_hard_drop_pulse,
    output wire btn_hold_pulse,
    output wire btn_pause_pulse,
    output wire btn_start_pulse,
    output wire btn_reset_pulse
);
```

功能：将板载按键和开关转换为统一游戏动作接口。

---

### 3.4 `game_core_minimal.v`

```verilog
module game_core_minimal (
    input  wire clk_100m,
    input  wire rst,

    input  wire btn_left_pulse,
    input  wire btn_right_pulse,
    input  wire btn_rotate_pulse,
    input  wire btn_start_pulse,

    output reg  [2:0] cur_piece_type,
    output reg  [1:0] cur_piece_rot,
    output reg signed [4:0] cur_piece_x,
    output reg signed [5:0] cur_piece_y,
    output reg  [2:0] game_state
);
```

功能：早期联调用，只需实现标题页开始、固定 T 方块左右移动和旋转。

---

### 3.5 正式 `game_core.v`

正式版接口后续可以在最小版基础上扩展，但必须保持对 VGA 和输入模块的接口稳定。

核心功能：

1. 方块生成；
2. 自动下落；
3. 左右移动；
4. 旋转；
5. 软降；
6. 硬降；
7. 碰撞检测；
8. 锁定；
9. 消行；
10. 分数等级；
11. Next；
12. Hold；
13. Ghost；
14. Game Over。

---

## 4. 四天推进计划

4 天时间较紧，必须采用“先闭环、后增强”的策略。每天都要有可运行成果。

---

### Day 1：接口冻结 + 三条线并行启动

目标：晚上前完成三个独立链路的最小成果。

#### 成员 1：游戏核心与集成

必须完成：

1. 创建项目目录结构；
2. 创建 `game_defs.vh`；
3. 创建 `docs/interface_spec.md`；
4. 完成 `piece_rom.v`；
5. 完成 `tb_piece_rom.v` 并仿真；
6. 完成 `game_core_minimal.v` 初版。

验收标准：

1. `piece_rom` 仿真通过；
2. `game_core_minimal` 能在仿真中从 TITLE 进入 PLAY；
3. 按 left/right/rotate 后，当前方块状态变化正确。

#### 成员 2：VGA/UI

必须完成：

1. `vga_timing.v`；
2. VGA 彩条显示；
3. 棋盘网格的参数设计。

验收标准：

1. 显示器有稳定图像；
2. 彩条不滚动、不闪烁；
3. `tb_vga_timing` 中水平、垂直计数范围正确。

#### 成员 3：输入/外设/报告

必须完成：

1. `debounce.v`；
2. `one_pulse.v`；
3. `button_input.v` 初版；
4. 创建 `docs/debug_log.md`、`docs/work_division.md`。

验收标准：

1. 板载按键能产生单周期 pulse；
2. LED 可临时显示按键状态；
3. 记录第一天调试过程和截图。

#### Day 1 晚上集成目标

完成一个最小联调：

```text
按键输入 pulse → game_core_minimal 修改当前方块位置/旋转 → VGA 显示当前方块变化
```

如果 Day 1 晚上无法完成完整联调，至少要保证三方接口已经确定，第二天上午立即联调。

---

### Day 2：完成基础可玩闭环前半部分

目标：实现方块自动下落、边界限制、简单碰撞、锁定雏形。

#### 成员 1：游戏核心与集成

必须完成：

1. 自动下落 tick；
2. 当前方块左右移动边界检查；
3. 当前方块旋转；
4. 棋盘数组或棋盘寄存器；
5. 碰撞检测初版；
6. 方块到底部后锁定。

建议 tick：

```text
普通下落：约 500 ms 一格
软降：约 50 ms 一格
```

验收标准：

1. 方块能自动下落；
2. 方块不会穿过左右边界；
3. 方块到底后能锁定到棋盘；
4. 生成下一个固定方块或随机方块。

#### 成员 2：VGA/UI

必须完成：

1. 10×20 棋盘网格；
2. 假棋盘数据显示；
3. 接入真实 `board_cell_value`；
4. 渲染当前活动方块。

验收标准：

1. 已锁定棋盘方块能显示；
2. 当前方块和已锁定方块颜色不同或显示清楚；
3. 画面布局基本固定。

#### 成员 3：输入/外设/报告

必须完成：

1. 左右长按重复；
2. 软降 hold；
3. 暂停/开始/重开输入；
4. LED 显示 `game_state`；
5. 七段数码管驱动初版。

验收标准：

1. 左右长按手感基本可用；
2. LED 能显示不同状态；
3. 数码管能显示固定测试数字或当前分数。

#### Day 2 晚上集成目标

完成一个半可玩版本：

```text
能开始游戏；
方块能下落；
能左右移动和旋转；
能锁定；
能继续生成新方块；
VGA 能显示棋盘和当前方块。
```

---

### Day 3：完成基础可玩版本 + 部分增强

目标：当天必须做出“可演示基础版”。

#### 成员 1：游戏核心与集成

必须完成：

1. 满行检测；
2. 消行和棋盘下移；
3. 分数、等级、行数；
4. Game Over 判断；
5. 重新开始；
6. 随机方块初版，建议先用 LFSR。

验收标准：

1. 能完整玩一局；
2. 满行能消除；
3. 分数能变化；
4. Game Over 能触发；
5. Restart 后棋盘清空。

#### 成员 2：VGA/UI

必须完成：

1. 分数、等级、行数显示区域；
2. Next 预览；
3. Game Over 页面或覆盖层；
4. 暂停页面或提示；
5. 基础配色美化。

验收标准：

1. 画面看起来像完整游戏；
2. 分数等级信息可见；
3. Game Over 状态可见。

#### 成员 3：输入/外设/报告

必须完成：

1. 七段数码管显示真实分数/等级/行数；
2. LED 状态显示稳定；
3. PWM 音效初版，至少移动/旋转/消行/Game Over 中完成 2 种；
4. 整理前三天截图、问题和解决方法。

验收标准：

1. 数码管显示与游戏状态有关；
2. 至少一种音效或 LED 反馈可展示；
3. 文档中已有调试过程记录。

#### Day 3 晚上必须冻结基础版

将当前能玩的版本备份或打标签：

```text
baseline_playable
```

冻结标准：

1. 能显示；
2. 能控制；
3. 能自动下落；
4. 能碰撞；
5. 能锁定；
6. 能消行；
7. 能计分；
8. 能 Game Over；
9. 能重新开始。

冻结后，任何增强功能都必须以不破坏该版本为前提。

---

### Day 4：增强、调试、报告、视频

目标：做出最终演示版本并整理答辩材料。

#### 成员 1：游戏核心与集成

优先任务：

1. 修复基础版 bug；
2. Hold 功能；
3. Ghost 位置计算；
4. 速度随等级提升；
5. 代码清理和注释；
6. 配合全员最终集成。

如果时间不足，优先级如下：

```text
修 bug > 速度等级 > Ghost > Hold > 7-bag
```

#### 成员 2：VGA/UI

优先任务：

1. Ghost 显示；
2. Hold 显示；
3. 消行动画；
4. 标题页美化；
5. Game Over 页面美化；
6. 截图和视频画面优化。

如果时间不足，优先级如下：

```text
Game Over 页面 > Next > Ghost > Hold > 消行动画 > 字体美化
```

#### 成员 3：输入/外设/报告

优先任务：

1. 完善音效；
2. 尝试 USB 键盘，若不顺利立即放弃，保留板载按键；
3. 完善数码管显示；
4. 整理报告大纲；
5. 录制演示视频；
6. 整理分工、创新点、调试截图、问题解决过程。

如果时间不足，优先级如下：

```text
报告视频 > 数码管 > 音效 > USB 键盘
```

#### Day 4 最终验收清单

1. bitstream 可稳定生成；
2. 开发板下载后能立即演示；
3. VGA 显示稳定；
4. 游戏可玩；
5. 基础功能齐全；
6. 至少有 2 个出彩功能；
7. 有演示视频；
8. 有调试截图；
9. 有模块框图；
10. 有分工说明；
11. 有创新点总结；
12. 有后续展望。

---

## 5. 并行开发方式

三个人可以同时开展，但必须采用“接口先行、假数据联调、逐步替换”的方式。

### 5.1 第一阶段：完全并行

成员 1 写游戏核心骨架和假状态输出；成员 2 写 VGA 并使用假棋盘；成员 3 写输入并用 LED 验证。

互相不等待。

### 5.2 第二阶段：第一次联调

目标只有一个：

```text
按键 pulse → 当前方块坐标改变 → VGA 上方块移动
```

此时不需要消行、不需要随机、不需要 Game Over。

### 5.3 第三阶段：逐步替换假数据

1. VGA 假棋盘替换为游戏核心真实棋盘；
2. 游戏核心假输入替换为输入模块真实 pulse；
3. 数码管假分数替换为游戏核心真实分数；
4. 音效测试 pulse 替换为游戏核心真实 `sfx_*`。

### 5.4 第四阶段：基础版冻结

当基础版可玩时立即备份，不允许直接在唯一版本上冒险加入复杂功能。

---

## 6. 关键注意事项

### 6.1 不要让增强功能破坏主线

4 天时间很紧，必须先实现可玩版本。USB 键盘、音效、动画、字体美化都不能优先于核心游戏闭环。

推荐优先级：

```text
VGA 稳定 > 输入可用 > 方块可玩 > 碰撞消行 > 计分结束 > UI 美化 > 音效键盘
```

---

### 6.2 不要在 VGA 扫描过程中修改游戏状态

VGA 负责显示，游戏核心负责状态更新。VGA 模块只读取状态，不写入棋盘、不触发游戏逻辑。

错误做法：

```text
在 pixel_x/pixel_y 扫描到某个位置时修改棋盘。
```

正确做法：

```text
游戏核心在 clk_100m 域按 tick 更新棋盘；
VGA 在 pix_clk 域读取当前状态并生成颜色。
```

---

### 6.3 不要让输入模块直接控制棋盘

输入模块只输出动作事件。游戏规则只能由游戏核心决定。

错误做法：

```text
button_input 里直接修改 cur_piece_x。
```

正确做法：

```text
button_input 输出 btn_left_pulse；
game_core 判断是否能左移，若能则修改 cur_piece_x。
```

---

### 6.4 注意单周期脉冲和按住电平的区别

左移、右移、旋转、硬降、Hold、暂停、开始都建议用 pulse。软降建议用 hold。

否则容易出现：

1. 按一下旋转很多次；
2. 按一下暂停后马上又取消暂停；
3. 左右移动过快；
4. 硬降重复触发。

---

### 6.5 注意 signed 坐标

当前方块坐标建议：

```verilog
reg signed [4:0] cur_piece_x;
reg signed [5:0] cur_piece_y;
```

不要全部用 unsigned，否则 `cur_piece_x - 1` 可能下溢，导致边界判断错误。

---

### 6.6 注意棋盘数组综合问题

可以使用寄存器数组：

```verilog
reg [3:0] board [0:19][0:9];
```

但要注意：

1. Vivado 2018.3 对二维数组端口支持有限，不建议把整个二维数组作为端口传出去；
2. 对外使用查询接口更稳；
3. 在 `always` 中清空棋盘时要使用 for 循环；
4. 多处 always 同时写同一个 board 会出错，棋盘最好只在 game_core 一个时序 always 或少数明确流程中写。

---

### 6.7 注意消行逻辑

消行最容易出现错位。建议先写 testbench，再上板。

推荐流程：

1. 扫描每一行是否满；
2. 生成 `clear_line_mask[19:0]`；
3. 统计消除行数；
4. 从底向上压缩棋盘；
5. 顶部补空行；
6. 更新分数和行数。

不要在还没验证的情况下直接加入复杂消行动画。

---

### 6.8 注意旋转规则先简单后复杂

第一版旋转只需要：

```text
测试 rotation + 1 后是否碰撞；
不碰撞则旋转；
碰撞则保持原状态。
```

暂不实现复杂 wall kick。若后续时间充裕，再加入简单 wall kick：

```text
原地旋转失败后，尝试 x-1、x+1、x-2、x+2。
```

---

### 6.9 注意随机数先简单后高级

第一版使用 LFSR 随机即可。

后续若有时间再做 7-bag。不要因为追求现代俄罗斯方块随机算法影响基础版进度。

---

### 6.10 注意每晚都要保存可运行版本

建议每天结束时备份：

```text
day1_vga_input_minimal
day2_falling_locking
day3_baseline_playable
day4_final_demo
```

如果使用 Git，建议每天至少 commit 三次：

```text
morning_start
midday_working
night_verified
```

---

## 7. 调试与验收清单

### 7.1 VGA 调试清单

1. 彩条是否稳定；
2. `hsync/vsync` 是否有输出；
3. `pixel_x` 是否 0~639 有效；
4. `pixel_y` 是否 0~479 有效；
5. 棋盘坐标是否和屏幕显示一致；
6. 当前方块是否和棋盘格对齐；
7. Game Over 页面是否覆盖正确。

### 7.2 输入调试清单

1. 按一下是否只产生一次 pulse；
2. 长按左右是否先立即移动，再间隔重复；
3. 软降是否为 hold 电平；
4. 暂停是否不会连续翻转；
5. 复位是否能清空状态。

### 7.3 游戏核心调试清单

1. 方块生成位置正确；
2. 左右边界不越界；
3. 旋转不会穿墙；
4. 触底后能锁定；
5. 新方块能继续生成；
6. 已有方块能阻挡当前方块；
7. 满行能消除；
8. 消行后棋盘下移正确；
9. 分数和行数更新正确；
10. 顶部堆满后 Game Over。

### 7.4 外设调试清单

1. LED 能显示状态；
2. 数码管能显示分数或等级；
3. 音效不会持续乱响；
4. 音效事件和游戏动作对应；
5. USB 键盘若加入，板载按键仍保留作为备用。

---

## 8. 报告与演示材料同步要求

报告不能最后一天才写。成员 3 负责收集，但三个人都要提供材料。

### 8.1 每个成员每天必须提交的材料

1. 完成的模块名称；
2. 模块输入输出说明；
3. 一张仿真截图或上板截图；
4. 遇到的问题；
5. 解决方法；
6. 第二天计划。

### 8.2 最终报告建议结构

1. 项目名称；
2. 团队构成与分工；
3. 项目背景与目标；
4. 总体功能描述；
5. 硬件平台说明；
6. 系统总体框图；
7. 模块划分；
8. VGA 显示设计；
9. 游戏核心设计；
10. 输入外设设计；
11. 数码管、LED、音效设计；
12. 关键状态机流程图；
13. 关键参数设计；
14. 仿真与调试过程；
15. 实验结果截图；
16. 遇到的问题与解决方法；
17. 创新点；
18. 总结与展望。

### 8.3 演示视频建议脚本

1. 展示开发板、VGA 显示器、按键或键盘；
2. 标题页开始游戏；
3. 演示左右移动、旋转、软降、硬降；
4. 演示方块锁定和生成新方块；
5. 演示消行和分数变化；
6. 演示暂停和继续；
7. 演示 Game Over 和重新开始；
8. 展示数码管、LED、音效；
9. 若有增强功能，展示 Next、Hold、Ghost、消行动画。

---

## 9. 创新点包装建议

最终答辩时不要只说“做了俄罗斯方块”，要说成“基于 FPGA 的实时图形交互系统”。

可以强调：

1. 硬件实时 VGA 扫描显示；
2. 游戏核心由 FPGA 状态机直接实现；
3. 棋盘 RAM、方块 ROM、碰撞检测形成清晰数据通路；
4. 输入、VGA、数码管、LED、音效多外设协同；
5. 支持现代俄罗斯方块特性，例如 Next、Hold、Ghost；
6. 具有可视化 UI、状态提示和演示视频；
7. 模块化设计，便于仿真和扩展。

---

## 10. 最终最低交付标准

如果时间极限不足，最低也必须交付：

1. VGA 棋盘显示；
2. 当前方块显示；
3. 按键控制；
4. 自动下落；
5. 碰撞和锁定；
6. 消行；
7. 分数或行数显示；
8. Game Over；
9. 至少一个板载外设反馈，例如 LED 或数码管；
10. 报告中有模块框图、流程图、调试截图、分工和创新点。

若基础版已经稳定，推荐最终展示版本包括：

```text
VGA 彩色 UI + 板载按键控制 + 自动下落 + 旋转 + 硬降 + 消行 + 分数等级 + Next + Ghost + 数码管 + LED + 简单音效
```

---

## 11. 今日立即执行清单

### 成员 1 立即做

1. 建立目录结构；
2. 创建 `game_defs.vh`；
3. 将本文档同步给两位成员；
4. 创建 `piece_rom.v`；
5. 创建 `game_core_minimal.v`；
6. 准备和 VGA、输入做第一次联调。

### 成员 2 立即做

1. 写 `vga_timing.v`；
2. 做彩条显示；
3. 画 10×20 棋盘网格；
4. 用假数据画几个静态方块。

### 成员 3 立即做

1. 写 `debounce.v`；
2. 写 `one_pulse.v`；
3. 写 `button_input.v`；
4. 用 LED 验证按键 pulse；
5. 建立调试日志和报告材料文档。

---

## 12. 一句话原则

```text
先打通 输入 → 游戏核心 → VGA 的最小闭环；
再完成 下落 → 碰撞 → 锁定 → 消行 的基础玩法；
最后加入 UI → 数码管 → 音效 → 键盘 的增强效果。
```