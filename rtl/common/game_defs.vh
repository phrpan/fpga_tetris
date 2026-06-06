localparam BOARD_COLS = 10;
localparam BOARD_ROWS = 20;

localparam PIECE_I    = 3'd0;
localparam PIECE_O    = 3'd1;
localparam PIECE_T    = 3'd2;
localparam PIECE_S    = 3'd3;
localparam PIECE_Z    = 3'd4;
localparam PIECE_J    = 3'd5;
localparam PIECE_L    = 3'd6;
localparam PIECE_NONE = 3'd7;

localparam CELL_EMPTY = 4'd0;
localparam CELL_I     = 4'd1;
localparam CELL_O     = 4'd2;
localparam CELL_T     = 4'd3;
localparam CELL_S     = 4'd4;
localparam CELL_Z     = 4'd5;
localparam CELL_J     = 4'd6;
localparam CELL_L     = 4'd7;
localparam CELL_GHOST = 4'd8;

localparam GS_TITLE     = 3'd0;
localparam GS_SPAWN     = 3'd1;
localparam GS_PLAY      = 3'd2;
localparam GS_LOCK      = 3'd3;
localparam GS_CLEAR     = 3'd4;
localparam GS_PAUSE     = 3'd5;
localparam GS_GAME_OVER = 3'd6;
