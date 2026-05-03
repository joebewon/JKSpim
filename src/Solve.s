.data
.align 4
bunnies_info: .space 484                    # Space for the BunniesInfo Struct

puzzle: .space 268                          # Space for the LightsOut Puzzle

board_buff: .space 256                      # Space for the board buffer for solving the LightsOut Puzzle

solution: .space 256                        # Space for the solution to the LightsOut Puzzle

num_puzzles_requested: .word 0              # The number of puzzle that habve been requested

.align 1
has_bonked: .byte 0                         # Bonk Interrupt

puzzle_received: .byte 0                    # Puzzle Received Interrupt

# @function
#
# Requests and solves a puzzle efficiently
#
# @UsedTemporaries: $t0, $t1, $t2, $t4, $a0, $a1, $a2, $a3
#
# @Params: None
#
# @Returns:
# - $v0 (bool): Solved the Puzzle Correctly
SolvePuzzle:
    ################ ################ Allocate Stack ################ ################
    sub     $sp, $sp, 8
    sw      $ra, 0($sp)

    ################ ################ Request a Puzzle ################ ################
    la      $t0, puzzle_received
    sb      $0, 0($t0)                                  # puzzle_received = false;

    la      $t1, puzzle
    sw      $t1, REQUEST_PUZZLE($0)                     # Request a puzzle

    la      $t1, num_puzzles_requested
    lw      $t4, 0($t1)                                 # int puzzle_num = num_puzzles_requested;
    sw      $t4, 4($sp)                                 # Immediatly save puzzle_num to the stack
    add     $t2, $t9, 1                                 # num_puzzles_requested++;
    sw      $t2, 0($t1)                                 # store incremeneted num_puzzles_requested

    SP_WaitForPuzzle:
        lb      $t1, 0($t0)                             # $t0 = puzzle_received
        beq     $t1, 0, SP_WaitForPuzzle                # Loop iff (puzzle_received == 0)

    ################ ################ Request a Puzzle ################ ################
    la      $a0, puzzle
    lw      $t0, 8($a0)                                 # $t0 = puzzle->num_colors

    la      $a1, solution
    la      $a2, board_buff

    bne		$t0, 2, SP_Solve3                           # if $t0 != 2 then goto SP_Solve3
    jal     CTLSolve2                                   # bool got_sol = FRESolve2(&puzzle, &solution, &board_buff);
    j		SP_Submit                                   # jump to SP_Submit
    SP_Solve3:
        jal     CTLSolve3                               # bool got_sol = FRESolve3(&puzzle, &solution, &board_buff);
        beq     $v0, 0, SP_Return                       # Shortcircuit if unsolvable or skipped

    ################ ################ Submit the Solution ################ ################
    SP_Submit:
        lw      $t0, 4($sp)                             # Load puzzle_num from the stack
        sw      $t0, CURRENT_PUZZLE($0)                 # *CURRENT_PUZZLE = puzzle_num;

        la      $t0, solution
        sw      $t0, SUBMIT_SOLUTION($0)                # *SUBMIT_SOLUTION = &solution;

    ################ ################ Determine Solution Correctness ################ ################
    lw      $t0, MMIO_STATUS($0)                        # $t0 = *MMIO_STATUS;

    slt     $t0, $0, $t0                                # $t0 = 1 if 0 != *MMIO_STATUS else $t0 = 0
    li      $t1, 1
    sub     $t0, $t1, $t0                               # bool correct = *MMIO_STATUS == 0;

    and     $v0, $v0, $t0                               # $v0 = got_sol && correct

    SP_Return:
        lw      $ra, 0($sp)
        add     $sp, $sp, 8
        jr      $ra

# @function
#
# Solves a puzzle using a Chase The Lights Lookup Table for num_colors = 2
#
# @UsedTemporaries: $t0, $t0
#
# @Params:
# - $a0 (LightsOuts* puzzle): Pointer to the puzzle struct to solve
# - $a1 (unsigned char* solution): Pointer to the solution board
# - $a2 (unsigned char* board_buff): Pointer to a buffer board
# @Returns:
# - $v0 (bool): Solved the Puzzle Correctly
CTLSolve2:
    # Stack Allocation
    sub     $sp, $sp, 40
    sw      $ra, 0($sp)

    sw      $s0, 4($sp)
    sw      $s1, 8($sp)
    sw      $s2, 12($sp)
    sw      $s3, 16($sp)
    sw      $s4, 20($sp)
    sw      $s5, 24($sp)

    sw      $a0, 28($sp)
    sw      $a1, 32($sp)
    sw      $a2, 36($sp)

    # Preprocessing
    move    $s2, $a1                                        # $s2! = solution
    lw      $s3, 0($a0)                                     # <$s3!> const int num_rows = puzzle->num_rows;
    lw      $s4, 4($a0)                                     # <$s4!> const int num_cols = puzzle->num_cols;
    add     $s5, 12($a0)                                    # <$s5?> unsigned char* board_ptr = &puzzle->board;
    
    move    $a0, $a1                                        # $a0 = solution
    lw      $a1, 0($a0)                                     # $a1 = puzzle->num_rows
    lw      $a2, 4($a0)                                     # $a2 = puzzle->num_cols
    jal     ZeroBoard


    bgt     $t1, $t0, CS2T
    CS2N:
        # First Pass
        li      $s0, 1                                      # <$s0!> int i = 1;
        CS2N_1Pass_OFor:
            bge     $s0, $s3, CS2N_1Pass_ORof               # if i >= num_rows, goto CS2N_1Pass_ORof
            li      $s1, 0                                  # <$s1!> int j = 0;
            CS2N_1Pass_IFor:
                bge     $s1, $s4, CS2N_1Pass_IRof           # if i >= num_rows, goto CS2N_1Pass_IRof

                # $t0 = board_ptr[i - 1][j]
                sub     $t0, $s0, 1                         # $t0 = i - 1
                mul     $t0, $t0, $s4                       # $t0 = (i - 1)*num_cols
                add     $t0, $t0, $s1                       # $t0 = (i - 1)*num_cols + j
                add     $t0, $s5, $t0                       # $t0 = &board_ptr[i - 1][j]
                lbu     $t0, 0($t0)                         # $t0 = board_ptr[i - 1][j]
                bne     $t0, 1, CS2N_1Pass_IFor_Inc         # if board_ptr[i - 1][j] != 1, goto CS2N_1Pass_IFor_Inc

                # solution[i][j] = 1;
                mul     $t0, $s0, $s4                       # $t0 = i*num_cols
                add     $t0, $t0, $s1                       # $t0 = i*num_cols + j
                add     $t0, $s2, $t0                       # $t0 = &solution[i][j]
                li      $t1, 1                              # $t1 = 1
                sb      $t1, 0($t0)                         # solution[i][j] = 1;

                move    $a0, $s5                            # $a0 = board_ptr
                move    $a1, $s0                            # $a1 = i
                move    $a2, $s1                            # $a2 = j
                li      $a3, 1                              # $a3 = 1
                jal     ToggleLight                         # ToggleLight(board_ptr, i, j, 1);

                CS2N_1Pass_IFor_Inc:
                    add     $s1, $s1, 1
                    j       CS2N_1Pass_IFor
            CS2N_1Pass_IRof:
                # pass and directly increment i
                add     $s0, $s0, 1
                j       CS2N_1Pass_OFor
        CS2N_1Pass_ORof:

        # Done Check
        move    $a0, $s5                                    # $a0 = board_ptr
        jal     BoardDone
        beq     $v0, 1, CS2_Return                          # if (BoardDone(board_ptr)) return true;

        # const int last_row_residual = EncodeResidual2(board_ptr, num_rows, num_cols);
        li      $s1, 0                                      # int j = 0;
        li      $t2, 0                                      # <$t2> int last_row_residual = 0;
        sub     $t0, $s3, 1
        mul     $t0, $t0, $s4                               # $t0 = (num_rows - 1)*num_cols
        CS2N_Encode_Residual_For:
            bge     $s1, $s4, CS2N_Encode_Residual_Rof      # if j >= num_cols, goto CS2N_Encode_Residual_Rof
            add     $t1, $t0, $s1                           # $t1 = (num_rows - 1)*num_cols + j
            add     $t1, $s5, $t1                           # $t1 = &board_ptr[num_rows - 1][j]
            lbu     $t1, 0($t1)                             # $t1 = board_ptr[num_rows - 1][j]
            
            add     $t2, $t2, $t1                           # last_row_residual += board_ptr[num_rows - 1][j];
            sll     $t2, $t2, 1                             # last_row_residual <<= 1;

            add     $s1, $s1, 1
            j CS2N_Encode_Residual_For

        CS2N_Encode_Residual_Rof:
            # CLTLUT2 $t3, $s3, $s4 - Somehow @TODO - Assume $t3 has the correct address.
            mul     $t2, $t2, 2                             # $t2 = last_row_residual*2
            add     $t3, $t3, $t2                           # $t3 = &CLT_LUT_2[num_rows][num_cols][last_row_residual]
            lhu     $t3, 0($t3)                             # <$t3> int first_row_enumerate = CLT_LUT_2[num_rows][num_cols][last_row_residual];

            move    $v0, $0
            beq     $t3, $0, CS2_Return                     # if first_row_enumerate == 0, return false;

    CS2T:
        # First Pass
    CS2_Return:
        lw      $ra, 0($sp)
        add     $sp, $sp, 40
        jr      $ra

# @function
#
# Solves a puzzle using a Chase The Lights Lookup Table for num_colors = 3
#
# @UsedTemporaries: None
#
# @Params: None
#
# @Returns:
# - $v0 (bool): Solved the Puzzle Correctly
CTLSolve2:

# @function
#
# Copies and transposes a board to a board buffer
#
# @UsedTemporaries: None
#
# @Params: None
# - $a0 (unsigned char* board_ptr): ...
# - $a1 (unsigned char* board_buff): ...
# - $a2 (int num_rows): ...
# - $a3 (int num_cols): ...
#
# @Returns: Void
CopyT:

# @function
#
# Efficiently checks if a puzzle is solved
#
# @UsedTemporaries: $t0, $t1, $t2, $t3
#
# @Params:
# - $a1 (int num_rows): The number of rows
# - $a1 (int num_cols): The number of columns
# - $a2 (unsigned char* board): Pointer to the board matrix we want to check completion for
#
# @Returns:
# - $v0 (bool): Whether or not the puzzle is actually solved
BoardDone:
    sub     $t4, $a0,  1                                # $t4 = num_rows - 1
    mul     $t4, $t4, $a1                               # $t4 = (num_rows - 1)*num_cols
    add     $t4, $a2, $t4                               # $t4 = &board[num_rows - 1][0] equiv. $t4 = &board[(num_rows - 1)*num_cols + 0] equiv. $t4 = &board[(num_rows - 1)*num_cols]

    lwl     $t0, 0($t4)                                 # Load the first of the four bytes that make up the last row
    lwr     $t0, 3($t4)

    lwl     $t1, 4($t4)                                 # Load the second of the four bytes that make up the last row
    lwr     $t1, 7($t4)

    lwl     $t2, 8($t4)                                 # Load the third of the four bytes that make up the last row
    lwr     $t2, 11($t4)

    lwl     $t3, 12($t4)                                # Load the fourth of the four bytes that make up the last row
    lwr     $t3, 15($t4)

    or      $v0, $t0, $t1                               # $v0 = words[0] | words[1]
    or      $v0, $v0, $t2                               # $v0 = words[0] | words[1] | words[2]
    or      $v0, $v0, $t3                               # $v0 = words[0] | words[1] | words[2] | words[3]

    slt     $v0, $0, $v0                                # $v0 = 0 < words[0] | words[1] | words[2] | words[3] ? 1 : 0
    li      $t0, 1
    sub     $v0, $t0, $v0                               # $v0 = !(words[0] | words[1] | words[2] | words[3])
    j       $ra                                         # Return !(words[0] | words[1] | words[2] | words[3]);

# @function
#
# Zeros a board
#
# @UsedTemporaries: $t0, $t1, $t2, $t3
#
# @Params:
# - $a0 (unsigned char* board): Pointer to the board matrix we want to zero
#
# @Returns: void
ZeroBoard:
    li      $t0, 0              # row = 0

    row_loop:
        bge     $t0, $a0, zero_done      # if row >= num_rows, exit
        li      $t1, 0              # col = 0

    col_loop:
        bge     $t1, $a1, next_row_zero  # if col >= num_cols, next row

        # Calculate index: row * num_cols + col
        mul     $t2, $t0, $a1       # t2 = row * num_cols
        add     $t2, $t2, $t1       # t2 = row * num_cols + col
        add     $t3, $a2, $t2       # t3 = &solution[row * num_cols + col]
        sb      $zero, 0($t3)       # solution[index] = 0

        addi    $t1, $t1, 1         # col++
        j       col_loop

    next_row_zero:
        addi    $t0, $t0, 1         # row++
        j       row_loop

    zero_done:
        jr      $ra

# @function
#
# Toggles a light and its neighbors
#
# @UsedTemporaries: ...
#
# @Params: ...
#
# @Returns: void
ToggleLight:
        # t0=num_rows, t1=num_cols, t2=num_colors
        lw      $t0, 0($a2)
        lw      $t1, 4($a2)
        lw      $t2, 8($a2)

        # t3 = &board[0]
        addi    $t3, $a2, 12

        # addr = board_base + (row*num_cols + col)
        # val = (lbu(addr) + action_num) % num_colors
        # sb(val, addr)

        ######## center: (row, col)
        mul     $t4, $a0, $t1
        add     $t4, $t4, $a1
        add     $t5, $t3, $t4

        lbu     $t6, 0($t5)
        add     $t6, $t6, $a3
        rem     $t6, $t6, $t2
        sb      $t6, 0($t5)

        ######## if (row > 0) : up (row-1, col)
        slt     $t8, $zero, $a0          # t8 = (0 < row)
        beq     $t8, $zero, SKIP_UP

        addi    $t9, $a0, -1
        mul     $t4, $t9, $t1
        add     $t4, $t4, $a1
        add     $t5, $t3, $t4

        lbu     $t6, 0($t5)
        add     $t6, $t6, $a3
        rem     $t6, $t6, $t2
        sb      $t6, 0($t5)

    SKIP_UP:
        ######## if (col > 0) : left (row, col-1)
        slt     $t8, $zero, $a1          # t8 = (0 < col)
        beq     $t8, $zero, SKIP_LEFT

        addi    $t9, $a1, -1
        mul     $t4, $a0, $t1
        add     $t4, $t4, $t9
        add     $t5, $t3, $t4

        lbu     $t6, 0($t5)
        add     $t6, $t6, $a3
        rem     $t6, $t6, $t2
        sb      $t6, 0($t5)
    SKIP_LEFT:
        ######## if (row < num_rows - 1) : down (row+1, col)
        addi    $t9, $t0, -1             # t9 = num_rows - 1
        slt     $t8, $a0, $t9            # t8 = (row < num_rows-1)
        beq     $t8, $zero, SKIP_DOWN

        addi    $t9, $a0, 1
        mul     $t4, $t9, $t1
        add     $t4, $t4, $a1
        add     $t5, $t3, $t4

        lbu     $t6, 0($t5)
        add     $t6, $t6, $a3
        rem     $t6, $t6, $t2
        sb      $t6, 0($t5)
    SKIP_DOWN:
        ######## if (col < num_cols - 1) : right (row, col+1)
        addi    $t9, $t1, -1             # t9 = num_cols - 1
        slt     $t8, $a1, $t9            # t8 = (col < num_cols-1)
        beq     $t8, $zero, DONE

        addi    $t9, $a1, 1
        mul     $t4, $a0, $t1
        add     $t4, $t4, $t9
        add     $t5, $t3, $t4

        lbu     $t6, 0($t5)
        add     $t6, $t6, $a3
        rem     $t6, $t6, $t2
        sb      $t6, 0($t5)

    DONE:
        jr      $ra
################## ################## import CTLLookups.s ################## ##################