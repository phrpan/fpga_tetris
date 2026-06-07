module game_core (
    input  wire              clk_100m,
    input  wire              rst,

    input  wire              btn_left_pulse,
    input  wire              btn_right_pulse,
    input  wire              btn_rotate_pulse,
    input  wire              btn_soft_drop_hold,
    input  wire              btn_start_pulse,

    input  wire [4:0]        board_query_row,
    input  wire [3:0]        board_query_col,
    output reg  [3:0]        board_cell_value,

    output reg  [2:0]        cur_piece_type,
    output reg  [1:0]        cur_piece_rot,
    output reg signed [4:0]  cur_piece_x,
    output reg signed [5:0]  cur_piece_y,

    output reg  [2:0]        next_piece_type,
    output wire [15:0]       score,
    output wire [7:0]        lines,
    output wire [3:0]        level,
    output reg  [2:0]        game_state
);
    `include "../common/game_defs.vh"

    localparam [25:0] NORMAL_FALL_TICKS = 26'd5000000;
    localparam [25:0] SOFT_FALL_TICKS   = 26'd5;

    localparam [3:0] PH_TITLE       = 4'd0;
    localparam [3:0] PH_SPAWN_LOAD  = 4'd1;
    localparam [3:0] PH_SPAWN_CHECK = 4'd2;
    localparam [3:0] PH_PLAY        = 4'd3;
    localparam [3:0] PH_CHECK       = 4'd4;
    localparam [3:0] PH_LOCK        = 4'd5;
    localparam [3:0] PH_CLEAR_SCAN  = 4'd6;
    localparam [3:0] PH_CLEAR_COPY  = 4'd7;
    localparam [3:0] PH_CLEAR_TOP   = 4'd8;
    localparam [3:0] PH_SCORE       = 4'd9;
    localparam [3:0] PH_GAME_OVER   = 4'd10;
    localparam [3:0] PH_RESTART_CLEAR = 4'd11;
    localparam [3:0] PH_RESTART_RESET = 4'd12;
    localparam [3:0] PH_PAUSE       = 4'd13;

    localparam [2:0] ACT_NONE   = 3'd0;
    localparam [2:0] ACT_MOVE   = 3'd1;
    localparam [2:0] ACT_ROTATE = 3'd2;
    localparam [2:0] ACT_DOWN   = 3'd3;
    localparam [2:0] ACT_SPAWN  = 3'd4;

    reg [3:0] board [0:19][0:9];

    reg [3:0] core_phase;
    reg [25:0] gravity_counter;
    reg [25:0] normal_fall_ticks_by_level;

    reg signed [4:0] candidate_x;
    reg signed [5:0] candidate_y;
    reg [1:0] candidate_rot;
    reg [2:0] candidate_action;

    reg [1:0] check_idx;
    reg check_collision;

    reg [1:0] lock_idx;

    reg [4:0] scan_row;
    reg [3:0] scan_col;
    reg [4:0] write_row;
    reg [3:0] copy_col;
    reg row_full;
    reg [2:0] clear_count_reg;

    reg score_clear_event;
    reg score_restart_rst;
    wire score_rst;
    wire [2:0] random_piece_type;
    wire random_enable;

    wire [1:0] piece_dx;
    wire [1:0] piece_dy;

    integer row;
    integer col;

    assign random_enable = (core_phase == PH_SPAWN_LOAD);
    assign score_rst = rst | score_restart_rst;

    random_lfsr random_piece_gen (
        .clk_100m(clk_100m),
        .rst(rst),
        .enable(random_enable),
        .piece_type(random_piece_type)
    );

    score_level score_level_inst (
        .clk_100m(clk_100m),
        .rst(score_rst),
        .clear_event(score_clear_event),
        .clear_count(clear_count_reg),
        .score(score),
        .lines(lines),
        .level(level)
    );

    piece_rom active_piece_rom (
        .piece_type(cur_piece_type),
        .rotation(candidate_rot),
        .block_idx((core_phase == PH_LOCK) ? lock_idx : check_idx),
        .dx(piece_dx),
        .dy(piece_dy)
    );

    function [3:0] piece_to_cell;
        input [2:0] piece;
        begin
            case (piece)
                PIECE_I: piece_to_cell = CELL_I;
                PIECE_O: piece_to_cell = CELL_O;
                PIECE_T: piece_to_cell = CELL_T;
                PIECE_S: piece_to_cell = CELL_S;
                PIECE_Z: piece_to_cell = CELL_Z;
                PIECE_J: piece_to_cell = CELL_J;
                PIECE_L: piece_to_cell = CELL_L;
                default: piece_to_cell = CELL_EMPTY;
            endcase
        end
    endfunction

    function [3:0] board_cell;
        input [4:0] q_row;
        input [3:0] q_col;
        begin
            if ((q_row < BOARD_ROWS) && (q_col < BOARD_COLS)) begin
                board_cell = board[q_row][q_col];
            end else begin
                board_cell = CELL_EMPTY;
            end
        end
    endfunction

    wire signed [5:0] piece_dx_signed;
    wire signed [6:0] piece_dy_signed;
    wire signed [5:0] candidate_x_ext;
    wire signed [6:0] candidate_y_ext;
    wire signed [5:0] cur_piece_x_ext;
    wire signed [6:0] cur_piece_y_ext;
    wire signed [5:0] block_x_signed;
    wire signed [6:0] block_y_signed;
    wire signed [5:0] lock_x_signed;
    wire signed [6:0] lock_y_signed;
    wire [4:0] block_row;
    wire [3:0] block_col;
    wire [4:0] lock_row;
    wire [3:0] lock_col;

    assign piece_dx_signed = {4'b0000, piece_dx};
    assign piece_dy_signed = {5'b00000, piece_dy};
    assign candidate_x_ext = candidate_x;
    assign candidate_y_ext = candidate_y;
    assign cur_piece_x_ext = cur_piece_x;
    assign cur_piece_y_ext = cur_piece_y;
    assign block_x_signed = candidate_x_ext + piece_dx_signed;
    assign block_y_signed = candidate_y_ext + piece_dy_signed;
    assign lock_x_signed = cur_piece_x_ext + piece_dx_signed;
    assign lock_y_signed = cur_piece_y_ext + piece_dy_signed;
    assign block_row = block_y_signed[4:0];
    assign block_col = block_x_signed[3:0];
    assign lock_row = lock_y_signed[4:0];
    assign lock_col = lock_x_signed[3:0];

    always @* begin
        case (level)
            4'd1: normal_fall_ticks_by_level = 26'd5000000;
            4'd2: normal_fall_ticks_by_level = 26'd4500000;
            4'd3: normal_fall_ticks_by_level = 26'd4000000;
            4'd4: normal_fall_ticks_by_level = 26'd3500000;
            4'd5: normal_fall_ticks_by_level = 26'd3000000;
            4'd6: normal_fall_ticks_by_level = 26'd2500000;
            4'd7: normal_fall_ticks_by_level = 26'd2000000;
            4'd8: normal_fall_ticks_by_level = 26'd1500000;
            default: normal_fall_ticks_by_level = 26'd1000000;
        endcase
    end

    always @* begin
        board_cell_value = board_cell(board_query_row, board_query_col);
    end

    always @(posedge clk_100m) begin
        if (rst) begin
            for (row = 0; row < BOARD_ROWS; row = row + 1) begin
                for (col = 0; col < BOARD_COLS; col = col + 1) begin
                    board[row][col] <= CELL_EMPTY;
                end
            end

            core_phase <= PH_TITLE;
            game_state <= GS_TITLE;
            cur_piece_type <= PIECE_T;
            cur_piece_rot <= 2'd0;
            cur_piece_x <= 5'sd3;
            cur_piece_y <= 6'sd0;
            next_piece_type <= PIECE_T;
            gravity_counter <= 26'd0;

            candidate_x <= 5'sd3;
            candidate_y <= 6'sd0;
            candidate_rot <= 2'd0;
            candidate_action <= ACT_NONE;
            check_idx <= 2'd0;
            check_collision <= 1'b0;
            lock_idx <= 2'd0;

            scan_row <= 5'd19;
            scan_col <= 4'd0;
            write_row <= 5'd19;
            copy_col <= 4'd0;
            row_full <= 1'b1;
            clear_count_reg <= 3'd0;
            score_clear_event <= 1'b0;
            score_restart_rst <= 1'b0;
        end else begin
            score_clear_event <= 1'b0;
            score_restart_rst <= 1'b0;

            case (core_phase)
                PH_TITLE: begin
                    game_state <= GS_TITLE;
                    gravity_counter <= 26'd0;
                    if (btn_start_pulse) begin
                        for (row = 0; row < BOARD_ROWS; row = row + 1) begin
                            for (col = 0; col < BOARD_COLS; col = col + 1) begin
                                board[row][col] <= CELL_EMPTY;
                            end
                        end
                        core_phase <= PH_SPAWN_LOAD;
                        game_state <= GS_SPAWN;
                    end
                end

                PH_SPAWN_LOAD: begin
                    game_state <= GS_SPAWN;
                    cur_piece_type <= next_piece_type;
                    next_piece_type <= random_piece_type;
                    cur_piece_rot <= 2'd0;
                    cur_piece_x <= 5'sd3;
                    cur_piece_y <= 6'sd0;
                    candidate_x <= 5'sd3;
                    candidate_y <= 6'sd0;
                    candidate_rot <= 2'd0;
                    candidate_action <= ACT_SPAWN;
                    check_idx <= 2'd0;
                    check_collision <= 1'b0;
                    gravity_counter <= 26'd0;
                    core_phase <= PH_SPAWN_CHECK;
                end

                PH_SPAWN_CHECK: begin
                    game_state <= GS_SPAWN;
                    if ((block_x_signed < 0) ||
                        (block_x_signed >= BOARD_COLS) ||
                        (block_y_signed >= BOARD_ROWS) ||
                        ((block_y_signed >= 0) && (board_cell(block_row, block_col) != CELL_EMPTY))) begin
                        check_collision <= 1'b1;
                    end

                    if (check_idx == 2'd3) begin
                        if (check_collision ||
                            (block_x_signed < 0) ||
                            (block_x_signed >= BOARD_COLS) ||
                            (block_y_signed >= BOARD_ROWS) ||
                            ((block_y_signed >= 0) && (board_cell(block_row, block_col) != CELL_EMPTY))) begin
                            core_phase <= PH_GAME_OVER;
                            game_state <= GS_GAME_OVER;
                        end else begin
                            core_phase <= PH_PLAY;
                            game_state <= GS_PLAY;
                        end
                    end else begin
                        check_idx <= check_idx + 1'b1;
                    end
                end

                PH_PLAY: begin
                    game_state <= GS_PLAY;

                    if (btn_start_pulse) begin
                        core_phase <= PH_PAUSE;
                        game_state <= GS_PAUSE;
                    end else if (btn_left_pulse) begin
                        candidate_x <= cur_piece_x - 1'b1;
                        candidate_y <= cur_piece_y;
                        candidate_rot <= cur_piece_rot;
                        candidate_action <= ACT_MOVE;
                        check_idx <= 2'd0;
                        check_collision <= 1'b0;
                        core_phase <= PH_CHECK;
                    end else if (btn_right_pulse) begin
                        candidate_x <= cur_piece_x + 1'b1;
                        candidate_y <= cur_piece_y;
                        candidate_rot <= cur_piece_rot;
                        candidate_action <= ACT_MOVE;
                        check_idx <= 2'd0;
                        check_collision <= 1'b0;
                        core_phase <= PH_CHECK;
                    end else if (btn_rotate_pulse) begin
                        candidate_x <= cur_piece_x;
                        candidate_y <= cur_piece_y;
                        candidate_rot <= cur_piece_rot + 1'b1;
                        candidate_action <= ACT_ROTATE;
                        check_idx <= 2'd0;
                        check_collision <= 1'b0;
                        core_phase <= PH_CHECK;
                    end else if (gravity_counter >= (btn_soft_drop_hold ? SOFT_FALL_TICKS : normal_fall_ticks_by_level)) begin
                        candidate_x <= cur_piece_x;
                        candidate_y <= cur_piece_y + 1'b1;
                        candidate_rot <= cur_piece_rot;
                        candidate_action <= ACT_DOWN;
                        check_idx <= 2'd0;
                        check_collision <= 1'b0;
                        gravity_counter <= 26'd0;
                        core_phase <= PH_CHECK;
                    end else begin
                        gravity_counter <= gravity_counter + 1'b1;
                    end
                end

                PH_PAUSE: begin
                    game_state <= GS_PAUSE;
                    if (btn_start_pulse) begin
                        core_phase <= PH_PLAY;
                        game_state <= GS_PLAY;
                    end
                end

                PH_CHECK: begin
                    game_state <= GS_PLAY;
                    if ((block_x_signed < 0) ||
                        (block_x_signed >= BOARD_COLS) ||
                        (block_y_signed >= BOARD_ROWS) ||
                        ((block_y_signed >= 0) && (board_cell(block_row, block_col) != CELL_EMPTY))) begin
                        check_collision <= 1'b1;
                    end

                    if (check_idx == 2'd3) begin
                        if (check_collision ||
                            (block_x_signed < 0) ||
                            (block_x_signed >= BOARD_COLS) ||
                            (block_y_signed >= BOARD_ROWS) ||
                            ((block_y_signed >= 0) && (board_cell(block_row, block_col) != CELL_EMPTY))) begin
                            if (candidate_action == ACT_DOWN) begin
                                lock_idx <= 2'd0;
                                candidate_rot <= cur_piece_rot;
                                core_phase <= PH_LOCK;
                                game_state <= GS_LOCK;
                            end else begin
                                core_phase <= PH_PLAY;
                            end
                        end else begin
                            cur_piece_x <= candidate_x;
                            cur_piece_y <= candidate_y;
                            cur_piece_rot <= candidate_rot;
                            core_phase <= PH_PLAY;
                        end
                    end else begin
                        check_idx <= check_idx + 1'b1;
                    end
                end

                PH_LOCK: begin
                    game_state <= GS_LOCK;
                    candidate_x <= cur_piece_x;
                    candidate_y <= cur_piece_y;
                    candidate_rot <= cur_piece_rot;

                    if ((lock_y_signed >= 0) &&
                        (lock_y_signed < BOARD_ROWS) &&
                        (lock_x_signed >= 0) &&
                        (lock_x_signed < BOARD_COLS)) begin
                        board[lock_row][lock_col] <= piece_to_cell(cur_piece_type);
                    end

                    if (lock_idx == 2'd3) begin
                        scan_row <= 5'd19;
                        scan_col <= 4'd0;
                        write_row <= 5'd19;
                        copy_col <= 4'd0;
                        row_full <= 1'b1;
                        clear_count_reg <= 3'd0;
                        core_phase <= PH_CLEAR_SCAN;
                        game_state <= GS_CLEAR;
                    end else begin
                        lock_idx <= lock_idx + 1'b1;
                    end
                end

                PH_CLEAR_SCAN: begin
                    game_state <= GS_CLEAR;

                    if (board[scan_row][scan_col] == CELL_EMPTY) begin
                        row_full <= 1'b0;
                    end

                    if (scan_col == (BOARD_COLS - 1)) begin
                        copy_col <= 4'd0;
                        if (row_full && (board[scan_row][scan_col] != CELL_EMPTY)) begin
                            clear_count_reg <= clear_count_reg + 1'b1;
                            if (scan_row == 5'd0) begin
                                copy_col <= 4'd0;
                                core_phase <= PH_CLEAR_TOP;
                            end else begin
                                scan_row <= scan_row - 1'b1;
                                scan_col <= 4'd0;
                                row_full <= 1'b1;
                            end
                        end else begin
                            core_phase <= PH_CLEAR_COPY;
                        end
                    end else begin
                        scan_col <= scan_col + 1'b1;
                    end
                end

                PH_CLEAR_COPY: begin
                    game_state <= GS_CLEAR;
                    board[write_row][copy_col] <= board[scan_row][copy_col];

                    if (copy_col == (BOARD_COLS - 1)) begin
                        if (write_row != 5'd0) begin
                            write_row <= write_row - 1'b1;
                        end

                        if (scan_row == 5'd0) begin
                            copy_col <= 4'd0;
                            if (write_row == 5'd0) begin
                                core_phase <= PH_SCORE;
                            end else begin
                                write_row <= write_row - 1'b1;
                                core_phase <= PH_CLEAR_TOP;
                            end
                        end else begin
                            scan_row <= scan_row - 1'b1;
                            scan_col <= 4'd0;
                            copy_col <= 4'd0;
                            row_full <= 1'b1;
                            core_phase <= PH_CLEAR_SCAN;
                        end
                    end else begin
                        copy_col <= copy_col + 1'b1;
                    end
                end

                PH_CLEAR_TOP: begin
                    game_state <= GS_CLEAR;
                    board[write_row][copy_col] <= CELL_EMPTY;

                    if (copy_col == (BOARD_COLS - 1)) begin
                        if (write_row == 5'd0) begin
                            core_phase <= PH_SCORE;
                        end else begin
                            write_row <= write_row - 1'b1;
                            copy_col <= 4'd0;
                        end
                    end else begin
                        copy_col <= copy_col + 1'b1;
                    end
                end

                PH_SCORE: begin
                    game_state <= GS_CLEAR;
                    if (clear_count_reg != 3'd0) begin
                        score_clear_event <= 1'b1;
                    end
                    core_phase <= PH_SPAWN_LOAD;
                    game_state <= GS_SPAWN;
                end

                PH_GAME_OVER: begin
                    game_state <= GS_GAME_OVER;
                    if (btn_start_pulse) begin
                        scan_row <= 5'd0;
                        scan_col <= 4'd0;
                        core_phase <= PH_RESTART_CLEAR;
                    end
                end

                PH_RESTART_CLEAR: begin
                    game_state <= GS_GAME_OVER;
                    board[scan_row][scan_col] <= CELL_EMPTY;

                    if ((scan_row == (BOARD_ROWS - 1)) && (scan_col == (BOARD_COLS - 1))) begin
                        core_phase <= PH_RESTART_RESET;
                    end else if (scan_col == (BOARD_COLS - 1)) begin
                        scan_row <= scan_row + 1'b1;
                        scan_col <= 4'd0;
                    end else begin
                        scan_col <= scan_col + 1'b1;
                    end
                end

                PH_RESTART_RESET: begin
                    game_state <= GS_GAME_OVER;
                    score_restart_rst <= 1'b1;
                    cur_piece_type <= PIECE_T;
                    cur_piece_rot <= 2'd0;
                    cur_piece_x <= 5'sd3;
                    cur_piece_y <= 6'sd0;
                    next_piece_type <= PIECE_T;
                    gravity_counter <= 26'd0;
                    candidate_x <= 5'sd3;
                    candidate_y <= 6'sd0;
                    candidate_rot <= 2'd0;
                    candidate_action <= ACT_NONE;
                    check_idx <= 2'd0;
                    check_collision <= 1'b0;
                    lock_idx <= 2'd0;
                    clear_count_reg <= 3'd0;
                    core_phase <= PH_SPAWN_LOAD;
                    game_state <= GS_SPAWN;
                end

                default: begin
                    core_phase <= PH_TITLE;
                    game_state <= GS_TITLE;
                end
            endcase
        end
    end
endmodule
