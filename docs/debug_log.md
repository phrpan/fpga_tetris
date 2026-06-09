# 调试日志

本文记录游戏核心相关模块从基础定义、单模块仿真、核心集成到上板调试的主要调试过程。记录内容仅覆盖当前已完成的游戏核心链路，不代表完整 VGA 俄罗斯方块游戏已经完成验证。

## 1. 公共常量定义：`game_defs.vh`

调试目标：

- 创建 `rtl/common/game_defs.vh`，统一定义棋盘尺寸、方块类型、棋盘 cell 编码和游戏状态编码。

遇到的问题：

- `game_defs.vh` 中使用的是 `localparam`，如果加入 include guard，同一个编译单元内多个 module 分别 `include` 时，后续 module 可能无法获得这些局部常量定义。

解决方法：

- 在 `game_defs.vh` 中定义 `BOARD_COLS=10`、`BOARD_ROWS=20`，以及 `PIECE_*`、`CELL_*`、`GS_*` 常量。
- 删除 include guard，使每个使用该文件的 module 都能在 module 内部独立展开一份 `localparam` 定义。

验证结果：

- 后续 `piece_rom`、`game_core_minimal`、`collision_check`、`line_clear`、`random_lfsr`、`score_level` 和 `game_core` 均可通过 module 内部 `include` 使用统一常量。

## 2. 方块形状 ROM：`piece_rom.v`

调试目标：

- 创建 `rtl/game/piece_rom.v` 和 `sim/tb_piece_rom.v`，提供七种俄罗斯方块在 4 种旋转状态下的 4 个 block 局部坐标。

遇到的问题：

- 需要保证所有输出坐标均位于 4x4 局部坐标系内，并且非法输入不能产生未知值或越界坐标。

解决方法：

- 使用 Verilog-2001 `case` 语句实现 I、O、T、S、Z、J、L 七种方块和 4 种 rotation 的坐标查表。
- 在 testbench 中遍历 7 种方块、4 种旋转、4 个 block，打印 `dx/dy` 并检查坐标不超过 3。

验证结果：

- `piece_rom.v` 和 `tb_piece_rom.v` 已通过 Vivado XSim 仿真，仿真结束输出 `PASS`。

## 3. 最小游戏核心：`game_core_minimal.v`

调试目标：

- 创建 `rtl/game/game_core_minimal.v` 和 `sim/tb_game_core_minimal.v`，验证最小状态机、开始按键、左右移动和旋转链路。

遇到的问题：

- 该阶段暂不引入棋盘、碰撞、锁定、消行和计分，需要先验证基础状态流和输入 pulse 行为。

解决方法：

- 复位后进入 `GS_TITLE`，固定当前方块为 `PIECE_T`，初始位置为 `x=3, y=0`。
- `btn_start_pulse` 后进入 `GS_PLAY`，在 `GS_PLAY` 下响应 left、right 和 rotate pulse，并限制水平边界。

验证结果：

- `game_core_minimal.v` 和 `tb_game_core_minimal.v` 已通过 Vivado XSim 仿真，基础状态机和按键响应正确。

## 4. 碰撞检测模块：`collision_check.v`

调试目标：

- 创建 `rtl/game/collision_check.v` 和 `sim/tb_collision_check.v`，为正式游戏核心提供边界和已有方块碰撞判断。

遇到的问题：

- 需要同时处理左边界、右边界、底部边界、棋盘已有 cell，以及 `block_y < 0` 的顶部生成区域。

解决方法：

- 通过 4 个 `piece_rom` 得到当前方块 4 个 block 的局部坐标。
- 对 `block_x < 0`、`block_x >= BOARD_COLS`、`block_y >= BOARD_ROWS` 判定碰撞。
- 对 `block_y < 0` 的 block 不查询棋盘且不判定碰撞。
- 对 `block_y >= 0` 的 block 查询棋盘 cell，非 `CELL_EMPTY` 时判定碰撞。

验证结果：

- `collision_check.v` 已通过 Vivado XSim 仿真，覆盖空棋盘、左右边界、底部边界、已有方块和顶部生成区域等用例。

## 5. 清行模块：`line_clear.v`

调试目标：

- 创建 `rtl/game/line_clear.v` 和 `sim/tb_line_clear.v`，验证扁平化棋盘格式下的满行检测和压缩逻辑。

遇到的问题：

- 需要确认 20 行 x 10 列 x 4 bit 的 800-bit 扁平化棋盘索引规则一致，并保证清行后上方行正确下移、顶部补空行。

解决方法：

- 使用 `cell_index = row * BOARD_COLS + col`，对应 bit 范围为 `cell_index*4 +: 4`。
- 对每行 10 个 cell 是否全非空进行判断，输出 `clear_line_mask` 和 `clear_count`，并生成压缩后的 `board_flat_out`。

验证结果：

- `line_clear.v` 已通过 Vivado XSim 仿真，覆盖空棋盘、底部单行、底部双行、中间行清除和非满行不清除等用例。

## 6. 随机方块模块：`random_lfsr.v`

调试目标：

- 创建 `rtl/game/random_lfsr.v` 和 `sim/tb_random_lfsr.v`，为正式游戏核心提供 `PIECE_I` 到 `PIECE_L` 范围内的下一个方块类型。

遇到的问题：

- LFSR 不能进入全 0 状态，输出也不能产生 `PIECE_NONE`。

解决方法：

- 使用 8-bit LFSR，复位后初始化为非零值 `8'hA5`。
- 在 `enable` 有效时更新 LFSR，并将 LFSR 值映射到 0 到 6 范围内。

验证结果：

- `random_lfsr.v` 已通过 Vivado XSim 仿真，连续 enable 多次时输出始终位于 0 到 6，并且不是一直不变。

## 7. 分数和等级模块：`score_level.v`

调试目标：

- 创建 `rtl/game/score_level.v` 和 `sim/tb_score_level.v`，实现分数、总消行数和等级更新逻辑。

遇到的问题：

- 需要按照更新后的总消行数计算等级，并限制等级最大值，同时处理非法 `clear_count`。

解决方法：

- 复位后设置 `score=0`、`lines=0`、`level=1`。
- `clear_event=1` 且 `clear_count` 为 1 到 4 时更新分数和总行数。
- 按 1/2/3/4 行分别加 `100/300/500/800 * level`，等级按 `lines / 10 + 1` 计算且最大不超过 15。

验证结果：

- `score_level.v` 已通过 Vivado XSim 仿真，覆盖复位、清 1 行、清 4 行、累计到 10 行升级、无事件不更新和 `clear_count=0` 不更新等用例。

## 8. 游戏核心初版：`game_core.v`

调试目标：

- 创建 `rtl/game/game_core.v` 和 `sim/tb_game_core.v`，集成 `piece_rom`、`collision_check`、`line_clear`、`random_lfsr` 和 `score_level`，形成可仿真的基础游戏核心。

遇到的问题：

- 初版需要同时实现状态机、棋盘、移动、旋转、重力下落、锁定、清行和计分，但暂不实现 hold、ghost、hard drop、pause、clear animation、audio pulse 和 wall kick。

解决方法：

- 实现 `GS_TITLE`、`GS_SPAWN`、`GS_PLAY`、`GS_LOCK`、`GS_CLEAR` 和 `GS_GAME_OVER` 基础状态流。
- 使用碰撞检测模块判断移动、旋转、下落和出生位置。
- 锁定方块时将 `PIECE_*` 映射为 `CELL_I` 到 `CELL_L` 后写入棋盘，避免直接写入 `piece_type`。

验证结果：

- `game_core.v` 初版已通过 Vivado XSim 仿真，testbench 能验证 reset、start、基础移动、旋转、软降、棋盘查询和无未知值输出。

## 9. LED 上板调试顶层：`top_minimal_debug.v`

调试目标：

- 创建 `rtl/top_minimal_debug.v`，在不依赖 VGA、正式输入模块和 audio 模块的情况下，用 Nexys4 DDR 板载按钮和 LED 验证 `game_core.v` 初版能在 FPGA 上运行。

遇到的问题：

- 上板早期阶段需要减少外设依赖，先确认 reset、button、game_core 和 LED 输出链路。

解决方法：

- 将 `CLK100MHZ` 作为 `clk_100m`，`CPU_RESETN` 取反作为高有效 `rst`。
- 对 `BTNC`、`BTNU`、`BTNL`、`BTNR` 做两级同步和上升沿检测，分别连接 start、rotate、left、right pulse。
- 对 `BTND` 做两级同步后作为 `btn_soft_drop_hold`。
- 使用 LED 显示 `game_state`、`cur_piece_rot`、`cur_piece_x`、`level` 和部分 `board_cell_value`。

验证结果：

- `top_minimal_debug.v` synthesis 通过，可作为不依赖 VGA 的游戏核心调试入口。

## 10. Nexys4 DDR 约束补充

调试目标：

- 补充 `constraints/Nexys4DDR.xdc` 中与 `top_minimal_debug` 相关的板级引脚约束。

遇到的问题：

- 上板调试需要明确约束 `CLK100MHZ`、`CPU_RESETN`、按钮和 `LED[15:0]`，否则无法完成综合实现和 bitstream 生成。

解决方法：

- 在 XDC 中补充 Nexys4 DDR 的 `CLK100MHZ`、`CPU_RESETN`、`BTNC`、`BTNU`、`BTND`、`BTNL`、`BTNR` 和 `LED[15:0]` 约束。

验证结果：

- 约束补充后，`top_minimal_debug` 可进入 Vivado synthesis 和 implementation 流程。

## 11. 第一次 implementation 资源超限

调试目标：

- 对 `top_minimal_debug` 进行 implementation，评估 `game_core.v` 初版上板资源占用。

遇到的问题：

- synthesis 通过，但 implementation 失败，原因是 LUT 资源超限。
- 优化前 hierarchical utilization 显示：
  - `top_minimal_debug Total LUTs = 113302`
  - `game_core_inst Total LUTs = 113204`
  - `game_core_inst` 自身内部逻辑约 `112781 LUT`
- `collision_check`、`random_lfsr`、`score_level` 等子模块资源较小，主要资源压力来自 `game_core.v` 内部组合逻辑。

解决方法：

- 分析初版 `game_core.v`，定位到并行计算 left/right/down/rotate 多套碰撞、多个 board 动态读取口、800-bit `board_flat` / `board_flat_out` 大组合网络，以及一拍内完成整板清行压缩等结构。

验证结果：

- 确认 LUT 超限主要不是独立子模块造成，而是游戏核心内部过宽的组合数据通路造成。

## 12. `game_core.v` 资源优化

调试目标：

- 在保持 `game_core.v` 顶层接口不变的前提下，显著降低 LUT 占用，使 `top_minimal_debug` 能通过 implementation。

遇到的问题：

- 初版 `game_core.v` 资源占用过高，不适合直接上板实现。

解决方法：

- 减少并行碰撞检查，不再同时计算 left/right/down/rotate 多套候选结果。
- 将按钮和重力动作转换为单个 candidate，并按 4 个 block 分多拍完成碰撞检查。
- 移除 `board_flat` / `board_flat_out` 大组合网络，不再在 `game_core.v` 内部生成 800-bit 清行组合通路。
- 将锁定方块改为多拍顺序写入，每拍写入一个 block。
- 将清行改为多拍顺序 FSM，逐行/逐格扫描、复制非满行、跳过满行、清空顶部剩余行，再触发一次 `score_level` 更新。

验证结果：

- 优化后资源显著下降：
  - `top_minimal_debug Total LUTs = 1290`
  - `game_core_inst Total LUTs = 1290`
- `tb_game_core` 已根据多拍行为调整，并通过 Vivado XSim 仿真。

## 13. implementation 和 bitstream

调试目标：

- 使用资源优化后的 `game_core.v` 重新执行 Vivado implementation 和 bitstream 生成。

遇到的问题：

- 优化前 LUT 超限导致 implementation 失败。

解决方法：

- 使用顺序化后的 `game_core.v` 重新综合、实现并生成 bitstream。

验证结果：

- implementation 成功，bitstream 生成成功。

## 14. LED 上板现象

调试目标：

- 将 bitstream 下载到 Nexys4 DDR，观察按钮和 LED 是否能反映游戏核心状态变化。

遇到的问题：

- 当前调试顶层未接入 VGA，因此只能通过 LED 观察核心状态、位置、旋转和等级等简化信号。

解决方法：

- 通过 `BTNC`、`BTNL`、`BTNR`、`BTNU`、`BTND` 操作 `game_core`，观察 `LED[15:0]` 显示变化。

验证结果：

- 按键后 LED 状态有响应，说明 reset、button、game_core、LED 链路基本打通。
- 该结果仅表示核心状态链路初步打通，不表示完整游戏显示和交互功能已经完成验证。

## 15. Game Over 后 Restart

调试目标：

- 在保持 `game_core.v` 顶层接口不变的前提下，实现 `GS_GAME_OVER` 状态下按 `btn_start_pulse` 重新开始游戏。

遇到的问题：

- `score_level.v` 只通过 `rst` 复位，不能修改该已验证子模块。
- Game Over 后重启需要清空棋盘，但不能重新引入 `board_flat` / `board_flat_out`，也不能使用一拍清空整板的结构。

解决方法：

- 在 `game_core.v` 内部新增 restart 顺序阶段。
- `GS_GAME_OVER` 下检测到 `btn_start_pulse` 后，使用 `scan_row` 和 `scan_col` 逐格清空 board，每个时钟周期只清一个 cell。
- 清空完成后，复位当前方块、下一个方块、位置、旋转、重力计数和内部检查寄存器。
- 在 `game_core.v` 内部给 `score_level` 的 `rst` 增加局部 restart 复位脉冲，使 `score`、`lines`、`level` 回到初始状态，同时不修改 `score_level.v`。

验证结果：

- `tb_game_core.v` 增加 Game Over 后按 start 重启测试：构造非空棋盘和非零分数，进入 `GS_GAME_OVER`，发送 start pulse 后等待重新进入 `GS_PLAY`。
- 测试检查重启后棋盘指定 cell 已清空，`score=0`、`lines=0`、`level=1`，当前方块位置和旋转回到初始值。
- 该验证说明 Game Over 后 restart 的核心状态链路已通过仿真覆盖，不代表完整游戏显示链路已完成验证。

## 16. 等级影响自动下落速度

调试目标：

- 在保持 `game_core.v` 顶层接口不变的前提下，使普通自动下落速度随 `level` 提高而加快。

遇到的问题：

- `score_level.v` 已经根据消行数计算 `level`，但原 `game_core.v` 中普通自动下落仍使用固定 `NORMAL_FALL_TICKS`。
- 仿真中直接等待 5,000,000 个 100MHz 时钟周期效率较低，不适合作为常规回归测试方式。

解决方法：

- 在 `game_core.v` 内部新增 `normal_fall_ticks_by_level`。
- 使用 Verilog-2001 `always @*` 和 `case(level)` 生成等级到普通下落周期的映射，不使用除法、乘法或复杂动态运算。
- `PH_PLAY` 中普通自动下落比较改为使用 `normal_fall_ticks_by_level`。
- `btn_soft_drop_hold` 仍继续使用固定 `SOFT_FALL_TICKS`。

验证结果：

- `tb_game_core.v` 增加等级加速测试。
- 测试将内部 gravity 计数器设置到 level 2 的阈值 `4,500,000` 附近，对比 level 1 和 level 2：level 1 不触发下落，level 2 触发下落。
- 该测试验证了等级会影响普通自动下落周期，同时没有改变 `game_core.v` 顶层接口。

## 17. Pause / Resume

调试目标：

- 在保持 `game_core.v` 顶层接口不变的前提下，复用 `btn_start_pulse` 实现暂停和继续。

遇到的问题：

- 当前 `game_core.v` 接口中没有单独的 pause 输入，不能新增顶层端口。
- 暂停期间需要停止自动下落和输入动作，同时保持 board、当前方块、分数、行数和等级不变。

解决方法：

- 在 `game_core.v` 内部新增 `PH_PAUSE` 阶段，对外输出使用已有 `GS_PAUSE` 状态编码。
- `GS_PLAY` 下检测到 `btn_start_pulse` 后进入 `GS_PAUSE`。
- `GS_PAUSE` 下再次检测到 `btn_start_pulse` 后返回 `GS_PLAY`。
- `GS_PAUSE` 内不推进 `gravity_counter`，不处理 left/right/rotate/soft_drop，也不修改 board 或计分状态。

验证结果：

- `tb_game_core.v` 增加 pause/resume 测试。
- 测试进入 `GS_PLAY` 后记录当前方块位置、旋转、分数、行数和等级；发送 start pulse 后确认进入 `GS_PAUSE`。
- 暂停期间施加 left/right/rotate/soft_drop 并等待若干周期，确认上述状态均保持不变。
- 再次发送 start pulse 后确认返回 `GS_PLAY`。

## 18. IO 按键输入模块集成

调试目标：

- 集成当前 `game_core.v` 实际使用的按键输入链路，只提供 start、left、right、rotate 和 soft drop 五个输入动作。

遇到的问题：

- develop 中的 `button_input.v` 同时包含 hard drop、pause、reset 等输出，与当前 `game_core` 接口范围不一致。
- 原 testbench 主要依赖波形观察，没有自动 PASS/FAIL 检查。
- 真实 10 ms 消抖时间不适合直接用于快速仿真回归。

解决方法：

- 将 `button_input.v` 收敛为五个输出：`btn_start_pulse`、`btn_left_pulse`、`btn_right_pulse`、`btn_rotate_pulse` 和 `btn_soft_drop_hold`。
- 保留 `debounce.v` 和 `one_pulse.v` 作为通用输入辅助模块。
- `button_input.v` 新增 `DEBOUNCE_TICKS` 参数，硬件默认约 10 ms，testbench 可覆盖为较小值。
- pause/resume 继续由 `game_core` 复用 `btn_start_pulse` 实现；hold、hard drop、独立 pause/reset 暂不接入。

验证结果：

- `tb_button_input.v` 增加自动检查，覆盖 start/left/right/rotate 单周期 pulse、按住不重复、短抖动过滤、soft drop 按住持续高、释放后变低和 reset 清零。
- `tb_debounce.v` 增加自动检查，覆盖复位、抖动过滤、稳定按下、稳定释放和多按键同时输入。
- `tb_one_pulse.v` 增加自动检查，覆盖单 bit 上升沿、多 bit 同时上升沿、按住不重复和释放不触发。
## 19. feature/vga-ui 上板问题最小修复

调试目标：

- 修复 VGA UI 增强分支上板时发现的三个现象：长按 BTND 后多个后续方块连续快速下落、BTNU 旋转时活动方块偶发隐藏、BTNC 暂停后活动方块不显示。

遇到的问题：

- `btn_soft_drop_hold` 是按住型输入，原逻辑在当前方块锁定并生成下一块后仍会继续使用 soft drop 周期，导致一次长按可能跨多个方块持续加速。
- `tetris_video.v` 的活动方块显示条件只覆盖 `GS_SPAWN`、`GS_PLAY` 和 `GS_LOCK`，没有覆盖 `GS_PAUSE`，暂停时 VGA 不画当前活动方块。
- 当前 `top_vga_debug.v` 仍保留早期临时按键边沿检测和自动 start pulse，不利于和正式 `button_input` 链路一致地上板验证。

解决方法：

- 在 `game_core.v` 内部增加 soft drop release guard：当某个方块因 soft drop 推进并最终锁定后，下一块在 BTND 未释放前只按普通 gravity 周期下落；检测到 `btn_soft_drop_hold == 0` 后，soft drop 才重新生效。
- 保持旋转逻辑为 candidate 先检查、碰撞通过后再提交到 `cur_piece_rot`；旋转失败时保持 `cur_piece_x`、`cur_piece_y` 和 `cur_piece_rot` 不变。
- 在 `tetris_video.v` 的活动方块显示条件中加入 `GS_PAUSE`，暂停时继续显示当前活动方块。
- 将 `top_vga_debug.v` 接回正式 `button_input`，移除自动 start 和临时按键边沿检测。

验证结果：

- `tb_game_core.v` 增加了 soft drop 长按保护、旋转成功/失败保持、pause 状态保持等自动检查，仿真结束仍应输出 `PASS`。
- 该修复不修改 `button_input.v`、`debounce.v`、`one_pulse.v`、`vga_timing.v`、`constraints/` 或 `vivado/`。
## 20. tb_game_core level-speed 预期同步

调试目标：

- 修复 `tb_game_core.v` 在 level-speed 回归测试中的误报，使测试预期与当前 `feature/vga-ui` 分支采用的慢速 gravity 表一致。

遇到的问题：

- XSim 输出 `FAIL: at its shorter gravity threshold`。
- 失败场景是 level 普通自动下落速度测试，不是 soft drop release guard、rotate 或 pause 测试。
- 当前 `game_core.v` 采用慢速表：level 1 为 `50,000,000` ticks，level 2 为 `45,000,000` ticks。
- `tb_game_core.v` 仍使用旧速度表中的 `4,500,000` ticks 作为 level 2 阈值，导致计数远未达到当前 RTL 的 level 2 下落阈值。

解决方法：

- 不修改 `game_core.v`，因为当前分支确认采用慢速 gravity 表。
- 将 `tb_game_core.v` 中 level-speed 测试使用的 level 2 阈值从 `26'd4500000` 同步为 `26'd45000000`。
- 同步更新 `docs/interface_spec.md` 中 level 到 gravity tick 的映射说明。

验证结果：

- level-speed 测试意图保持不变：level 1 在 level 2 阈值处不应下落，level 2 到达自己的较短阈值时应下落。
- 下一步需要重新运行 Vivado XSim 的 `tb_game_core`，确认仿真最终输出 `PASS`。

## 21. 七段数码管显示模块集成前修复

调试目标：

- 在不接入 `top_vga_debug.v` 的前提下，先修复七段数码管显示模块自身和 testbench，为后续 VGA + 七段 + LED 联合上板调试做准备。

遇到的问题：

- `display.v` 原扫描逻辑每个 100MHz 时钟切换一次位选，动态扫描频率过高，可能导致上板亮度和显示稳定性不理想。
- `tb_seven_seg_driver.v` 实例化端口名与 `seven_seg_driver.v` 不一致，使用 `.clk(clk)` 而不是 `.clk_100m(clk)`。
- `tb_seven_seg_driver.v` 使用了 `for (integer ...)` 等 SystemVerilog 风格写法，不符合 Verilog-2001 要求。
- `tb_display.v` 和 `tb_seven_seg_driver.v` 主要依赖波形观察，缺少自动 PASS/FAIL 检查。

解决方法：

- `display.v` 增加参数 `SCAN_DIV_TICKS`，硬件默认值为 `17'd100000`，即每 100000 个 `clk_100m` 周期切换一次扫描位；对外接口保持不变。
- `tb_seven_seg_driver.v` 修正实例化端口名为 `.clk_100m(clk)`，并改为 Verilog-2001 兼容写法。
- `tb_seven_seg_driver.v` 增加自检查，覆盖数字 0~9、字母 L/S、非法输入默认显示 0，以及 `an[7:0]` 低有效位选。
- `tb_display.v` 使用较小的 `SCAN_DIV_TICKS` 参数加速仿真，并自动检查 score 两位、level 两位、S/L 标签及位选轮转是否出现。

验证结果：

- 两个 testbench 均设计为无错误时输出 `PASS`，有错误时输出 `FAIL: ...`。
- 本轮未修改 `top_vga_debug.v`、`game_core.v`、IO 按键模块、VGA 时序模块、constraints 或 vivado 目录。

## 22. VGA + 七段数码管 + LED 状态顶层集成

调试目标：

- 在 `top_vga_debug.v` 中完成 VGA、正式按键输入、游戏核心、七段数码管和 LED 状态显示的联合顶层连接，为下一步上板综合和 bitstream 调试做准备。

遇到的问题：

- `top_vga_debug.v` 原本只有 VGA 和 LED 调试输出，没有七段数码管端口。
- 原 LED 输出由若干 `assign LED[...]` 显示 `game_state`、当前方块类型和坐标；如果直接再接入 `led_status.v` 会造成 LED 多驱动。
- 七段数码管约束文件使用端口名 `an[7:0]` 和 `ca_g[6:0]`，顶层端口必须与之保持一致。

解决方法：

- 在 `top_vga_debug.v` 顶层新增 `an[7:0]` 和 `ca_g[6:0]` 输出端口。
- 例化 `display.v`，将 `score[7:0]` 和 `{4'd0, level}` 接入七段显示模块；第一版显示 score 低两位、level 两位以及 S/L 标签，暂不显示 lines。
- 例化 `led_status.v`，使用 `game_state` 驱动 `LED[15:0]`。
- 移除原有 LED 调试 assign，避免 LED 总线多驱动。
- 未接入 `led_blink.v`，未使用 `constraints/led_ports.xdc`。

验证结果：

- 本轮未修改 `game_core.v`、按键输入模块、VGA 渲染模块、VGA 时序模块、`constraints/Nexys4DDR.xdc` 或 `vivado/`。
- 下一步需要在 Vivado 工程中加入 `display.v`、`seven_seg_driver.v`、`led_status.v`，并加入或启用 `constraints/seven_seg_ports.xdc` 后，对 `top_vga_debug` 运行 synthesis、implementation 和 bitstream。

## 23. led_blink 与 led_status 的 LED mux 集成

调试目标：

- 在 `top_vga_debug.v` 中接入 `led_blink.v`，使 Game Over 状态下 LED 使用闪烁提示；非 Game Over 状态下继续使用 `led_status.v` 状态灯。

遇到的问题：

- `led_status.v` 和 `led_blink.v` 都会产生 16-bit LED 输出，不能同时直接驱动顶层 `LED[15:0]`。
- `led_blink.v` 还包含 `beep` 输出，但当前顶层没有蜂鸣器端口，本轮不新增顶层端口。

解决方法：

- 在 `top_vga_debug.v` 中新增 `led_status_value`、`led_blink_value`、`blink_beep_unused` 和 `game_over` 内部 wire。
- 使用 `assign game_over = (game_state == 3'd6);` 判断 Game Over。
- 将 `led_status.v` 的输出改接到 `led_status_value`。
- 例化 `led_blink.v`，将 `failed` 接 `game_over`，将 `led` 接 `led_blink_value`，将 `beep` 接 `blink_beep_unused`。
- 使用单一 mux `assign LED = game_over ? led_blink_value : led_status_value;` 驱动顶层 LED，避免多驱动。

验证结果：

- 本轮未修改 `game_core.v`、按键输入模块、VGA 模块、`led_status.v`、`led_blink.v`、constraints 或 vivado 目录。
- 后续综合时需要确保 Vivado 工程中已经加入 `rtl/io/led_blink.v`。

## 24. feature/vga-ui 的 tetris_video UI/logo 手工融合

调试目标：

- 将 `origin/feature/vga-ui` 中的 VGA UI 布局优化和队标 logo 显示手工融合到当前稳定分支，同时保留当前分支已经修复的游戏显示 bug。

遇到的问题：

- 远程 `feature/vga-ui` 的 `tetris_video.v` 新增了 logo 显示和 UI 布局调整，但其活动方块显示条件漏掉了 `GS_PAUSE`。
- 远程版本删除了 VGA 上的 `LINES` 标签和 lines 数字显示，而当前融合目标要求继续保留 lines 显示。
- 不能直接覆盖当前 `tetris_video.v`，否则可能丢失 pause 显示修复和当前稳定接口约定。

解决方法：

- 手工移植 NEXT/INFO 区域布局调整，将信息区放到左侧，将 Next 预览移动到右侧。
- 新增 `LOGO_X0`、`LOGO_Y0`、`LOGO_W`、`LOGO_H`，以及 `in_logo_area`、logo 坐标映射、`logo_addr`、`logo_rgb` 和 `in_logo_area_d`。
- 在 `tetris_video.v` 中例化 `logo_rom.v`，从 `logo_128x128.mem` 读取 128x128 12-bit RGB logo 数据，并在 VGA 画面右上区域显示。
- 保留 `show_active_piece` 中的 `GS_PAUSE` 条件，暂停时活动方块继续显示。
- 保留 `LINES` 标签、lines BCD 转换和 lines 数字显示，仅调整其在左侧信息区内的位置。
- 保持 `tetris_video.v` 顶层端口、board query 单口读取方式和 game_core 接口不变。

验证结果：

- 本轮未修改 `game_core.v`、`top_vga_debug.v`、`rtl/io/`、constraints 或 vivado 目录。
- 后续 Vivado 工程需要包含 `rtl/video/logo_rom.v` 和 `rtl/video/logo_128x128.mem`。
