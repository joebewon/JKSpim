# @function
#
# Requests and solves a puzzle
#
# @UsedTemporaries: None
#
# @Params: None
#
# @Returns: void
SolvePuzzle:
    jal  requestPuzzle

    move $a0, $v0
    jal  solvePuzzle

    jr $ra

########################################

# @function
#
# Requests a puzzle
#
# Ovewrites: $t0, $t1, $t2
# Returns:
#   - $v0: The id of the requested puzzle
requestPuzzle:
    la  $t0, puzzle_received
    sb  $0, 0($t0)                                  # puzzle_received = false;

    la  $t1, puzzle
    sw  $t1, REQUEST_PUZZLE($0)                     # Request a puzzle

    la  $t1, num_puzzles_requested
    lw  $v0, 0($t1)                                 # int puzzle_num = num_puzzles_requested;
    add $t2, $v0, 1                                 # num_puzzles_requested++;
    sw  $t2, 0($t1)                                 # store incremeneted num_puzzles_requested

    waitForPuzzle:
        lb  $t1, 0($t0)                             # $t0 = puzzle_received
        bne $t1, 0, receivedPuzzle                  # Break iff ~(puzzle_received == 0)
        j   waitForPuzzle                           # Wait for the puzzle
    receivedPuzzle:
        jr  $ra                                     # return puzzle_num;

solvePuzzle:
    sub $sp, $sp, 8
    sw  $ra, 0($sp)
    sw  $a0, 4($sp)

    # Zero the board
    la  $t0, puzzle
    lw  $a0, 0($t0)
    lw  $a1, 4($t0)
    la  $a2, solution
    jal zero_board                          # zero_board(puzzle.num_rows, puzzle.num_cols, &solution);

    la  $a0, puzzle
    la  $a1, solution
    li  $a2, 0
    li  $a3, 0
    jal solve                              # bool got_sol = solve(&puzzle, &solution, 0, 0);

    lw  $t0, 4($sp)
    sw  $t0, CURRENT_PUZZLE($0)             # *CURRENT_PUZZLE = puzzle_num;

    la  $t0, solution
    sw  $t0, SUBMIT_SOLUTION($0)            # *SUBMIT_SOLUTION = &solution;

    lw  $t0, MMIO_STATUS($0)                # $t0 = *MMIO_STATUS;

    slt $t0, $0, $t0                        # $t0 = 1 if 0 != *MMIO_STATUS else $t0 = 0
    li  $t1, 1
    sub $t0, $t1, $t0                       # bool correct = *MMIO_STATUS == 0;

    and $v0, $v0, $t0                       # $v0 = got_sol && correct

    lw  $ra, 0($sp)
    add $sp, $sp, 8
    jr  $ra                                 # return got_sol && correct;

#########################################
zero_board:
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
#########################################
board_done_given:
    li      $t0, 0

row_loop_board_done_given:
    bge     $t0, $a0, all_zero_given
    li      $t1, 0

col_loop_board_done_given:
    bge     $t1, $a1, next_row_given

    mul     $t2, $t0, $a1
    add     $t2, $t2, $t1
    add     $t3, $a2, $t2

    lbu     $t4, 0($t3)
    bne     $t4, $0, found_nonzero_given

    addi    $t1, $t1, 1
    j       col_loop_board_done_given

next_row_given:
    addi    $t0, $t0, 1
    j       row_loop_board_done_given

found_nonzero_given:
    li      $v0, 0
    jr      $ra

all_zero_given:
    li      $v0, 1
    jr      $ra

#########################################

toggle_light:
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

#########################################

linearize:
    bne $a0 $0 not_base
    li $v0 0
    jr $ra

not_base:
    sub $sp $sp 4
    sw $ra 0($sp)
    li $t0 0

for:
    bge $t0 4 after_for
    mul $t3 $t0 4 # 4*i
    add $t3 $t3 4 # 4*i +4
    add $t2 $a0 $t3 #&node->data[i]
    lw $t4 0($t2)  # node->data[i]
    sw $t4 0($a1)  # *array = node->data[i];
    addi $a1 $a1 4 # array ++
    addi $t0 $t0 1 # i++

	j for

after_for:
    lw $a0 0($a0)
	jal linearize
	lw $ra 0($sp)
	add $sp $sp 4
	jr $ra

#########################################

solve:
# solve(LightsOuts* puzzle, unsigned char* solution, int row, int col)
# $a0 = puzzle, $a1 = solution, $a2 = row, $a3 = col
# Returns: $v0 = bool (0 or 1)

    # Save callee-saved registers
    sub     $sp, $sp, 36
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    sw      $s1, 8($sp)
    sw      $s2, 12($sp)
    sw      $s3, 16($sp)
    sw      $s4, 20($sp)
    sw      $s5, 24($sp)
    sw      $s6, 28($sp)
    sw      $s7, 32($sp)

    # Save arguments to $s registers
    move    $s0, $a0        # $s0 = puzzle
    move    $s1, $a1        # $s1 = solution
    move    $s2, $a2        # $s2 = row
    move    $s3, $a3        # $s3 = col

    # Load struct fields
    lw      $s4, 0($s0)     # $s4 = num_rows = puzzle->num_rows
    lw      $s5, 4($s0)     # $s5 = num_cols = puzzle->num_cols
    lw      $s6, 8($s0)     # $s6 = num_colors = puzzle->num_colors

    # Calculate next_row = ((col == num_cols-1) ? row + 1 : row)
    sub     $t0, $s5, 1     # $t0 = num_cols - 1
    bne     $s3, $t0, solve_same_row
    add     $s7, $s2, 1     # next_row = row + 1
    j       solve_check_bounds
solve_same_row:
    move    $s7, $s2        # next_row = row

solve_check_bounds:
    # if (row >= num_rows || col >= num_cols)
    bge     $s2, $s4, solve_call_board_done
    bge     $s3, $s5, solve_call_board_done
    j       solve_check_row

solve_call_board_done:
    # return board_done(num_rows, num_cols, puzzle->board)
    move    $a0, $s4        # num_rows
    move    $a1, $s5        # num_cols
    add     $a2, $s0, 12    # puzzle->board (offset 12)
    jal     board_done_given
    j       solve_return

solve_check_row:
    # if (row != 0)
    beq     $s2, $0, solve_first_row

    # Row != 0 case
    # int actions = (num_colors - puzzle->board[(row-1)*num_cols + col]) % num_colors
    sub     $t0, $s2, 1     # row - 1
    mul     $t0, $t0, $s5   # (row-1) * num_cols
    add     $t0, $t0, $s3   # (row-1)*num_cols + col
    add     $t1, $s0, 12    # puzzle->board
    add     $t1, $t1, $t0   # &puzzle->board[(row-1)*num_cols + col]
    lbu     $t2, 0($t1)     # puzzle->board[(row-1)*num_cols + col]
    sub     $t3, $s6, $t2   # num_colors - board[...]
    rem     $t3, $t3, $s6   # actions = ... % num_colors

    # Store actions in stack for later use
    sub     $sp, $sp, 4
    sw      $t3, 0($sp)     # save actions

    # solution[row*num_cols + col] = actions
    mul     $t0, $s2, $s5   # row * num_cols
    add     $t0, $t0, $s3   # row*num_cols + col
    add     $t1, $s1, $t0   # &solution[row*num_cols + col]
    sb      $t3, 0($t1)

    # toggle_light(row, col, puzzle, actions)
    move    $a0, $s2
    move    $a1, $s3
    move    $a2, $s0
    move    $a3, $t3
    jal     toggle_light

    # Prepare recursive call: solve(puzzle, solution, next_row, (col+1) % num_cols)
    add     $t0, $s3, 1     # col + 1
    rem     $t0, $t0, $s5   # (col + 1) % num_cols
    move    $a0, $s0
    move    $a1, $s1
    move    $a2, $s7
    move    $a3, $t0
    jal     solve

    # if (solve(...)) return true
    bne     $v0, $0, solve_row_return_true

    # solution[row*num_cols + col] = 0
    mul     $t0, $s2, $s5
    add     $t0, $t0, $s3
    add     $t1, $s1, $t0
    sb      $0, 0($t1)

    # Restore actions from stack
    lw      $t3, 0($sp)

    # toggle_light(row, col, puzzle, num_colors - actions)
    sub     $t4, $s6, $t3   # num_colors - actions
    move    $a0, $s2
    move    $a1, $s3
    move    $a2, $s0
    move    $a3, $t4
    jal     toggle_light

    # Clean up stack and return false
    add     $sp, $sp, 4
    li      $v0, 0
    j       solve_return

solve_row_return_true:
    add     $sp, $sp, 4     # clean up actions from stack
    li      $v0, 1
    j       solve_return

solve_first_row:
    # for(char actions = 0; actions < num_colors; actions++)
    li      $t6, 0          # actions = 0

    # Save actions counter in stack
    sub     $sp, $sp, 4

solve_loop:
    bge     $t6, $s6, solve_loop_end

    # Save actions to stack
    sw      $t6, 0($sp)

    # solution[row*num_cols + col] = actions
    mul     $t0, $s2, $s5   # row * num_cols
    add     $t0, $t0, $s3   # row*num_cols + col
    add     $t1, $s1, $t0   # &solution[row*num_cols + col]
    sb      $t6, 0($t1)

    # toggle_light(row, col, puzzle, actions)
    move    $a0, $s2
    move    $a1, $s3
    move    $a2, $s0
    move    $a3, $t6
    jal     toggle_light

    # Prepare recursive call: solve(puzzle, solution, next_row, (col+1) % num_cols)
    add     $t0, $s3, 1     # col + 1
    rem     $t0, $t0, $s5   # (col + 1) % num_cols
    move    $a0, $s0
    move    $a1, $s1
    move    $a2, $s7
    move    $a3, $t0
    jal     solve

    # if (solve(...)) return true
    bne     $v0, $0, solve_loop_return_true

    # Restore actions from stack
    lw      $t6, 0($sp)

    # toggle_light(row, col, puzzle, num_colors - actions)
    sub     $t4, $s6, $t6   # num_colors - actions
    move    $a0, $s2
    move    $a1, $s3
    move    $a2, $s0
    move    $a3, $t4
    jal     toggle_light

    # solution[row*num_cols + col] = 0
    mul     $t0, $s2, $s5
    add     $t0, $t0, $s3
    add     $t1, $s1, $t0
    sb      $0, 0($t1)

    # Restore actions and increment
    lw      $t6, 0($sp)
    add     $t6, $t6, 1
    j       solve_loop

solve_loop_return_true:
    add     $sp, $sp, 4     # clean up actions from stack
    li      $v0, 1
    j       solve_return

solve_loop_end:
    add     $sp, $sp, 4     # clean up actions from stack
    li      $v0, 0

solve_return:
    # Restore callee-saved registers
    lw      $ra, 0($sp)
    lw      $s0, 4($sp)
    lw      $s1, 8($sp)
    lw      $s2, 12($sp)
    lw      $s3, 16($sp)
    lw      $s4, 20($sp)
    lw      $s5, 24($sp)
    lw      $s6, 28($sp)
    lw      $s7, 32($sp)
    add     $sp, $sp, 36
    jr      $ra
