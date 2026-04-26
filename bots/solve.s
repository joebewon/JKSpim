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
# Efficiently checks if a puzzle is solved
#
# @UsedTemporaries: $t0, $t1, $t2, $t3
#
# @Params:
# - $a0 (unsigned char* board): Pointer to the board matrix we want to check completion for
#
# @Returns:
# - $v0 (bool): Whether or not the puzzle is actually soved
board_done_opt:
    li      $t4, 240                                    # $t4 = 240 (15*16, the index of the first element of the last row.
    add     $t4, $a0, $t4                               # $t4 = &board[15*16][0] equiv. $t4 = &board[15*16 + 0] equiv. $t4 = &board[15*16]

    lwl     $t0, 0($t4)                                 # Load the first of the four words that make up the last row
    lwr     $t0, 3($t4)

    lwl     $t1, 4($t4)                                 # Load the second of the four words that make up the last row
    lwr     $t1, 7($t4)

    lwl     $t2, 8($t4)                                 # Load the third of the four words that make up the last row
    lwr     $t2, 11($t4)

    lwl     $t3, 12($t4)                                # Load the fourth of the four words that make up the last row
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
    jal     FRESolve2                                   # bool got_sol = FRESolve2(&puzzle, &solution, &board_buff);
    j		SP_Submit                                   # jump to SP_Submit
    SP_Solve3:
        jal     FRESolve3                               # bool got_sol = FRESolve3(&puzzle, &solution, &board_buff);

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

    lw      $ra, 0($sp)
    add     $sp, $sp, 8
    jr      $ra

FRESolve2:
    ################ ################ Allocate Stack ################ ################
    sub		$sp, $sp, 44                                # Allocate 44 bytes on the stack
    sw      $ra, 0($sp)                                 # Save $ra to the stack
    sw      $a0, 4($sp)                                 # Save puzzle to the stack
    sw      $a1, 8($sp)                                 # Save solution to the stack
    sw      $a2, 12($sp)                                # Save board_buff to the stack

    ################ ################ Preamble ################ ################
    lw      $t0, $a0(0)                                 # const int num_rows = puzzle->num_rows;
    lw      $t1, $a0(4)                                 # const int num_cols = puzzle->num_cols;
    addi    $t2, $a0, 12                                # unsigned char* board_ptr = &puzzle->board;

    bgt		$t1, $t0, FS2_Transpose                     # if num_cols > num_rows then goto FS2_Transpose
    
    ################ ################ Normal Solve ################ ################
    FS2_Normal:
        addi    $t3, $0, 1
        sllv    $t3, $t3, $t1                           # const uint32_t permutations = 2**num_cols;

        sw      $t0, 16($sp)                            # Save num_rows to the stack
        sw      $t1, 20($sp)                            # Save num_cols to the stack
        sw      $t2, 24($sp)                            # Save board_ptr to the stack
        sw      $t3, 28($sp)                            # Save permutations to the stack

        addi    $t4, $0, $0                             # uint16_t mask = 0;
        move    $a0, $t2                                # $a0 = board_ptr | Premptively move for the copy call
        move    $a1, $a2                                # $a1 = board_buff | Premptively move for the copy call
        move    $a2, $t0                                # $a2 = num_rows | Premptively move for the copy call
        move    $a3, $t1                                # $a3 = num_cols | Premptively move for the copy call
        FS2_N_Main_For:
            bge		$t4, $t3, FS2_N_Main_Rof            # if mask >= permutations then goto FS2_N_Main_Rof

            sw      $t4, 32($sp)                        # Save mask to the stack

            jal     Copy                                # copy(board_ptr, board_buff, num_rows, num_cols);

            lw      $a0, 4($sp)                         # $a0 = &solution (directly from the stack)
            lw      $a1, 16($sp)                        # $a0 = num_rows (directly from the stack)
            lw      $a3, 20($sp)                        # $a0 = num_cols (directly from the stack)
            jal     zero_board                          # zero_board(solution, num_rows, num_cols);

            lw      $t1, 20($sp)                        # Load num_cols from the stack
            lw      $t4, 32($sp)                        # Load mask from the stack
            # lw      $a2, 12($sp)                        # Load board_buff from the stack
            # lw      $a1, 8($sp)                         # Load solution from the stack
            addi    $t5, $0, $0                         # int j = 0;
            FS2_N_Enum_For:
                sllv    $t6, $t4, $t5                   # $t6 = mask >> j
                andi    $t6, $t6, 1                     # $t6 = (mask >> j) & 1
                bne		$t6, 1, FS2_N_Enum_For_Inc      # Continue iff !((mask >> j) & 1 == 1)
                
                sw      $t5, 36($sp)                    # Save j to the stack

                lw      $a0, 12($sp)                    # Load board buff directly into $a0
                add     $a1, $0, $0                     # $a1 = 0
                add     $a2, $t5, $0                    # $a2 = j
                addi    $a3, $0, 1                      # $a4 = 0
                jal     toggle_light

                lw      $a1, 8($sp)                     # Load solution from the stack
                add     $a1, $a1, $t5                   # $a1 = &solution[0][j]; equiv. $a1 = &solution + j;
                ori     $t6, $0, 1                      # $t6 = 1
                sw      $t6, 0($a1)                     # solution[0][j] = 1; equiv. solution[0*num_cols + j] = 1; solution[j] = 1;

                lw      $t4, 32($sp)                    # Load mask from the stack
                lw      $t1, 20($sp)                    # Load num_cols from the stack
                lw      $t5, 36($sp)                    # Load j from the stack
                FS2_N_Enum_For_Inc:
                    addi    $t5, $t5, 1                 # ++j;
                    blt		$t5, $t1, FS2_N_Enum_For    # if j < num_cols then goto FS2_N_Enum_For
                
            FS2_N_Enum_Rof:
                lw      $t3, 28($sp)                    # Load permutations from the stack
                # mask ($t4) already loaded
                lw $a0, 24($sp)                         # $a0 = board_ptr | Premptively move for the copy call
                lw $a1, 12($sp)                         # $a1 = board_buff | Premptively move for the copy call
                lw $a2, 16($sp)                         # $a2 = num_rows | Premptively move for the copy call
                move $a3, $t1                           # $a3 = num_cols | Already loaded, Premptively move for the copy call
                add		$t4, $t4, 1                     # ++mask;
            
            FS2_N_Iter_For_O:
                FS2_N_Iter_For_I:
                    # if (board_buff[i - 1][j] == 1)
                    # toggle_light(board_buff, i, j, 1);
                    # solution[j][i] = 1; // Remember to reverse the indexing
                FS2_N_Iter_Rof_I:
            FS2_N_Iter_Rof_O:
                # $a0 = board_buff
                # $a1 = num_cols
                # $a2 = num_rows
                jal     board_done                      # $v0 = board_done(board_buff, num_cols, num_rows)
                # Reload all of the things we need
                bne		$v0, 1, FS2_N_Main_For          # Try next permutation iff !board_done(board_buff, num_cols, num_rows)
                lw      $ra, 0($sp)                     # Otherwise, load $ra from the stack
                add     $sp, $sp, 44                    # Deallocate 44 bytes from the stack
                jr      $ra

        FS2N_Main_Rof:
            lw      $ra, 0($sp)
            add     $sp, $sp, 44                        # Deallocate 44 bytes from the stack
            move    $v0, $0
            jr      $ra                                 # return false;
    
    ################ ################ Transposed Solve ################ ################
    FS2_Transpose:


FRESolve2: