### syscall constants
PRINT_STRING            = 4
PRINT_CHAR              = 11
PRINT_INT               = 1

### MMIO addrs
ANGLE                   = 0xffff0014
ANGLE_CONTROL           = 0xffff0018
VELOCITY                = 0xffff0010

REQUEST_PUZZLE          = 0xffff00d0
AVAIL_PUZZLES           = 0xffff00b4
CURRENT_PUZZLE          = 0xffff00b8
PUZZLE_FEEDBACK         = 0xffff00e0
SUBMIT_SOLUTION         = 0xffff00d4

BOT_X                   = 0xffff0020
BOT_Y                   = 0xffff0024

NUM_CARROTS             = 0xffff0040
NUM_BUNNIES_CARRIED     = 0xffff0050

SEARCH_BUNNIES          = 0xffff0054
CATCH_BUNNY             = 0xffff0058
PUT_BUNNIES_IN_PLAYPEN  = 0xffff005c

PLAYPEN_LOCATION        = 0xffff0044

SCORES_REQUEST          = 0xffff1018

TIMER                   = 0xffff001c

BONK_INT_MASK           = 0x1000        ## Bonk
BONK_ACK                = 0xffff0060    ## Bonk
TIMER_INT_MASK          = 0x8000        ## Timer
TIMER_ACK               = 0xffff006c    ## Timer
BUNNY_MOVE_INT_MASK     = 0x400         ## Bunny Move
BUNNY_MOVE_ACK          = 0xffff00e8    ## Bunny Move
EX_CARRY_LIMIT_INT_MASK = 0x4000        ## Exceeding Carry Limit
EX_CARRY_LIMIT_ACK      = 0xffff002c    ## Exceeding Carry Limit
REQUEST_PUZZLE_INT_MASK = 0x0800        ## Request Puzzle
REQUEST_PUZZLE_ACK      = 0xffff00e4    ## Request Puzzle

MMIO_STATUS             = 0xffff204c

BOT_SPEED               = 10
BUNNIES_TO_CATCH        = 10
THRESHOLD				= 400000

.data
.align 4
bunnies_info: .space 484                    # Space for the BunniesInfo Struct

puzzle: .space 268                          # Space for the LightsOut Puzzle

solution: .space 256                        # Space for the solution to the LightsOut Puzzle

num_puzzles_requested: .word 0              # The number of puzzle that habve been requested

.align 1
has_bonked: .byte 0                         # Bonk Interrupt

puzzle_received: .byte 0                    # Puzzle Received Interrupt

.text
main:
    # enable interrupts
    li      $t4     1
    or      $t4     $t4     TIMER_INT_MASK
    or      $t4,    $t4,    BONK_INT_MASK               # enable bonk interrupt
    or      $t4,    $t4,    REQUEST_PUZZLE_INT_MASK     # enable request puzzle interrupt
    or      $t4,    $t4,    1                           # global enable
    mtc0    $t4     $12

    li $t1, 0
    sw $t1, ANGLE
    li $t1, 1
    sw $t1, ANGLE_CONTROL
    li $t2, 0
    sw $t2, VELOCITY

    # allocate_stack:
    #     sub $sp, $sp, 4                     # Allocate 4 bytes
    #     sw  $ra, 0($sp)

    #     add $t8, $0, $0

    # pickUpBunnies1:
    #     bge $t8, 5, depositeBunnies1

	# 	selectABunny1:
    #     	jal getNextBunny				# Get the next bunny

	# 		bne $v0, -1 catchTheBunny1		# Break when suitable bunny is found

	# 		j	selectABunny1				# Try again if not

	# 	catchTheBunny1:
	# 		move $t6, $v0
	# 		move $t7, $v1
	# 		move $a0, $t8
	# 		move $a1, $v0
	# 		move $a2, $v1
	# 		jal print_xy

	# 		move $a0, $t6					# $a0 = bunnies_info->info[0]->x
	# 		move $a1, $t7					# $a1 = bunnies_info->info[0]->y
	# 		jal  moveTo						# Move to (bunnies_info->info[0]->x, bunnies_info->info[0]->x)

	# 		li $t9, CATCH_BUNNY
	# 		sw $0, 0($t9)					# Catch the bunny

	# 		add $t8, $t8, 1

	# 		j pickUpBunnies1				# Pick up another bunny

    # depositeBunnies1:
    #     li  $t9, PLAYPEN_LOCATION
    #     lw  $t0, 0($t9)                     # Get the playpen location
    #     and $a0, $t0, 0xFFFF0000            # $a0 = the playpen's x coordinate
    #     srl $a1, $a0, 16
    #     and $a2, $t0, 0x0000FFFF            # $a1 = the playpen's y coordinate
    #     jal print_xy

    #     li  $t9, PLAYPEN_LOCATION
    #     lw  $t0, 0($t9)                     # Get the playpen location
    #     and $a0, $t0, 0xFFFF0000            # $a0 = the playpen's x coordinate
    #     srl $a0, $a0, 16
    #     and $a1, $t0, 0x0000FFFF            # $a1 = the playpen's y coordinate
    #     jal moveTo                          # Move to the playpen

    #     li  $t0, NUM_BUNNIES_CARRIED
    #     lw  $t0, 0($t0)
    #     li  $t9, PUT_BUNNIES_IN_PLAYPEN
    #     sw  $t0, 0($t9)  # Put 10 bunnies in the playpen

    #     add $t8, $0, $0
    
	# pickUpBunnies2:
    #     bge $t8, 5, depositeBunnies2

	# 	selectABunny2:
    #     	jal getNextBunny				# Get the next bunny

	# 		bne $v0, -1 catchTheBunny2		# Break when suitable bunny is found

	# 		j	selectABunny2				# Try again if not

	# 	catchTheBunny2:
	# 		move $t6, $v0
	# 		move $t7, $v1
	# 		move $a0, $t8
	# 		move $a1, $v0
	# 		move $a2, $v1
	# 		jal print_xy

	# 		move $a0, $t6					# $a0 = bunnies_info->info[0]->x
	# 		move $a1, $t7					# $a1 = bunnies_info->info[0]->y
	# 		jal  moveTo						# Move to (bunnies_info->info[0]->x, bunnies_info->info[0]->x)

	# 		li $t9, CATCH_BUNNY
	# 		sw $0, 0($t9)                   # Catch the bunny

	# 		add $t8, $t8, 1

	# 		j pickUpBunnies2

    # depositeBunnies2:
    #     li  $t9, PLAYPEN_LOCATION
    #     lw  $t0, 0($t9)                     # Get the playpen location
    #     and $a0, $t0, 0xFFFF0000            # $a0 = the playpen's x coordinate
    #     srl $a1, $a0, 16
    #     and $a2, $t0, 0x0000FFFF            # $a1 = the playpen's y coordinate
    #     jal print_xy

    #     li  $t9, PLAYPEN_LOCATION
    #     lw  $t0, 0($t9)                     # Get the playpen location
    #     and $a0, $t0, 0xFFFF0000            # $a0 = the playpen's x coordinate
    #     srl $a0, $a0, 16
    #     and $a1, $t0, 0x0000FFFF            # $a1 = the playpen's y coordinate
    #     jal moveTo                          # Move to the playpen

    #     lw  $t0, NUM_BUNNIES_CARRIED($0)
    #     sw  $t0, PUT_BUNNIES_IN_PLAYPEN($0) # Put the bunnies in the playpen

    # solvePuzzles:
    #     jal  requestPuzzle

    #     move $a0, $v0
    #     jal  solvePuzzle

    #     beq  $t0, 1, deallocate

    #     j    solvePuzzles

    # deallocate:
    #     lw  $ra, 0($sp)
    #     add $sp, $sp, 4                     # Deallocate 4 bytes

    ######################################
    jal  requestPuzzle
    move $a0, $v0
    jal  solvePuzzle

# Once done, enter an infinite loop so that your bot can be graded by QtSpimbot once 10,000,000 cycles have elapsed
loop:
    jal  requestPuzzle
    move $a0, $v0
    jal  solvePuzzle
    j       loop

# function
#
# Overwrites: $t0, $t1, $t2, $t3, $t4, $t5, $t9
# Params:     None
# Returns:
#	- $v0: x-coordinate of the bunny (-1 if none are suitable)
#	- $v1: y-coordinate of the bunny (-1 if none are suitable)
getNextBunny:
    la 	$t0, bunnies_info            		# $t0 = &bunnies_info
    li 	$t9, SEARCH_BUNNIES
    sw 	$t0, 0($t9)							# Retrieve the BunniesInfo Struct
	lw  $t9, 0($t0)							# *$t9 = bunnies_info->num_bunnies
	add $t0, $t0, 4							# Point the pointer to the array of bunnies

	move $t1, $0							# int i = 0;
	selectBunny:
		bge $t1, $t9, noneSelected			# Break when no bunnies are suitable

		mul $t2, $t1, 16					# $t2 = $t1 * 16
		add $t2, $t2, $t0					# Bunny b = bunnies_info->info[i];
		lw  $t3, 12($t2)					# remaining_cycles = b->remaining_cycles;

        lw  $t4, BOT_X($0)                  # $t4 = *BOT_X
        lw  $t5, BOT_Y($0)                  # $t5 = *BOT_Y
		lw  $v0, 0($t2)						# $v0 = b->x (returned if selected)
		lw  $v1, 4($t2)						# $v1 = b->y (returned if selected)

        sub $t4, $t4, $v0                   # $t4 = *BOT_X - b->x
        sub $t5, $t5, $v1                   # $t5 = *BOT_Y - b->y
        abs $t4, $t4                        # $t4 = | *BOT_X - b->x |
        abs $t5, $t5                        # $t5 = | *BOT_Y - b->y |
        add $t4, $t4, $t5                   # $t4 = | *BOT_X - b->x | + | *BOT_Y - b->y |
        mul $t4, $t4, 1000                  # $t4 = number of cycles to get to this bunny at speed 10
        add $t4, $t4, 10000

		blt $t4, $t3, selectedBunny         # Break if (number of cycles to get there < number of cycles before the jumop)

		add $t1, $t1, 1
		j selectBunny

	selectedBunny:
		jr $ra                          	# return (b->x, b->y)

	noneSelected:
		li $v0, -1							# $v0 = -1 
		li $v1, -1							# $v1 = -1 
		jr $ra								# return (-1, -1)

# function
#
# Overwrites: $t0, $t1, $t2, $t9
# Params:
#   - $a0 (word): target_x
#   - $a1 (word): target_y
# Returns:        void
moveTo:
    ##### Allocate Stack #####
    sub $sp, $sp, 4                     # Allocate 1 word
    sw  $ra, 0($sp)

    ##### Horizontal Move #####
    ifOnTargetX:
        li  $t9, BOT_X
        lw  $t0, 0($t9)
        bne $t0, $a0, ifTargetRight     # Break iff target_x != BOT_X

        j   ifOnTargetY

    ifTargetRight:
        blt $a0, $t0, elseTargetLeft    # Break iff target_x < BOT_X

        li  $t1, 0
        li  $t9, ANGLE
        sw  $t1, 0($t9)                 # Set Angle to 0deg
        li  $t1, 1
        li  $t9, ANGLE_CONTROL
        sw  $t1, 0($t9)                 # Set Angle Absolute

        jal moveRight                   # Move to the right

        j   ifOnTargetY

    elseTargetLeft:
        li  $t1, 180
        li  $t9, ANGLE
        sw  $t1, 0($t9)                 # Set Angle to 180deg
        li  $t1, 1
        li  $t9, ANGLE_CONTROL
        sw  $t1, 0($t9)                 # Set Angle Absolute

        jal moveLeft                    # Move to the left

    ##### Vertical Move #####
    ifOnTargetY:
        li  $t9, BOT_Y
        lw  $t0, 0($t9)
        bne $t0, $a1, ifTargetAbove     # Break iff target_y != BOT_Y

        j   endMoveTo                   # FLAAAAAAAAG

    ifTargetAbove:
        bgt $a1 $t0, elseTargetBelow   # Break iff target_y > BOT_Y

        li  $t1, -90
        li  $t9, ANGLE
        sw  $t1, 0($t9)                 # Set Angle to -90deg
        li  $t1, 1
        li  $t9, ANGLE_CONTROL
        sw  $t1, 0($t9)                 # Set Angle Absolute

        jal moveUp                      # Move up
    
        j   endMoveTo

    elseTargetBelow:
        li  $t1, 90
        li  $t9, ANGLE
        sw  $t1, 0($t9)                 # Set Angle to 90deg
        li  $t1, 1
        li  $t9, ANGLE_CONTROL
        sw  $t1, 0($t9)                 # Set Angle Absolute

        jal moveDown                    # Move to the Down
        lw  $ra, 0($sp)

    endMoveTo:
        lw  $ra, 0($sp)
        add $sp, $sp, 4                 # Deallocate 1 word
        jr $ra

# function Moves the bot right until it reaches a target x-coordinate 
#
# Overwrites: $t0, $t1, $t2
# Params:
#   - $a0 (word): target_x
#   - $a1 (word): target_y
# Returns:        void
moveRight:
    lw  $t0, BOT_X($0)                          # Load the x-coordinate

	############ Move Until Bonk or Reach ############
	la   $t1, has_bonked
	lb   $t1, 0($t1)                            # Get if we have bonked
    beq  $t1, 1, mRightAckBonk                  # Break if we did
    beq  $t0, $a0, mRightEnd                    # Shortcircuit if landed perfectly

    move $t1, $zero                             # int cycle = 0;
    li   $t2, BOT_SPEED                         # Load velocity
    sw   $t2, VELOCITY($0)                      # Set the velocity
    mRightWait:
        bge $t1, 250, mRightJump                # Break iff ~(cycles < 2500)
        add $t1, $t1, 1                         # cycle++;
        j mRightWait                            # Wait 1000 Cycles

    mRightJump:
        sw  $0, VELOCITY($0)
        j   moveRight

    mRightAckBonk:
        la   $t1, has_bonked
        sb   $t1, 0($t1)                        # Reset if we have bonked

    mRightEnd:
        jr $ra

# function Moves the bot left until it reaches a target x-coordinate 
#
# Overwrites: $t0, $t1, $t2
# Params:
#   - $a0 (word): target_x
#   - $a1 (word): target_y
# Returns:        void
moveLeft:
    lw  $t0, BOT_X($0)                          # Load the x-coordinate

	############ Move Until Bonk or Reach ############
	la   $t1, has_bonked
	lb   $t1, 0($t1)                            # Get if we have bonked
    beq  $t1, 1, mLeftAckBonk                   # Break if we did
    beq  $t0, $a0, mLeftEnd                     # Shortcircuit if landed perfectly

    move $t1, $zero                             # int cycle = 0;
    li   $t2, BOT_SPEED                         # Load velocity
    sw   $t2, VELOCITY($0)                      # Set the velocity
    mLeftWait:
        bge $t1, 250, mLeftJump                 # Break iff ~(cycles < 2500)
        add $t1, $t1, 1                         # cycle++;
        j mLeftWait                             # Wait 1000 Cycles

    mLeftJump:
        sw  $0, VELOCITY($0)
        j   moveLeft

    mLeftAckBonk:
        la   $t1, has_bonked
        sb   $t1, 0($t1)                        # Reset if we have bonked

    mLeftEnd:
        jr $ra

# function Moves the bot up until it reaches a target y-coordinate 
#
# Overwrites: $t0, $t1, $t2
# Params:
#   - $a0 (word): target_x
#   - $a1 (word): target_y
# Returns:        void
moveUp:
    lw  $t0, BOT_Y($0)                          # Load the y-coordinate

	############ Move Until Bonk or Reach ############
	la   $t1, has_bonked
	lb   $t1, 0($t1)                            # Get if we have bonked
    beq  $t1, 1, mUpAckBonk                     # Break if we did
    beq  $t0, $a1, mUpEnd                       # Shortcircuit if landed perfectly

    move $t1, $zero                             # int cycle = 0;
    li   $t2, BOT_SPEED                         # Load velocity
    sw   $t2, VELOCITY($0)                      # Set the velocity
    mUpWait:
        bge $t1, 250, mUpJump                   # Break iff ~(cycles < 2500)
        add $t1, $t1, 1                         # cycle++;
        j   mUpWait                             # Wait 1000 Cycles

    mUpJump:
        sw  $0, VELOCITY($0)
        j   moveUp

    mUpAckBonk:
        la  $t1, has_bonked
        sb  $0, 0($t1)                           # Reset if we have bonked

    mUpEnd:
        jr $ra

# function Moves the bot down until it reaches a target y-coordinate 
#
# Overwrites: $t0, $t1, $t2
# Params:
#   - $a0 (word): target_x
#   - $a1 (word): target_y
# Returns:        void
moveDown:
    lw  $t0, BOT_Y($0)                          # Load the y-coordinate

	############ Move Until Bonk or Reach ############
	la   $t1, has_bonked
	lb   $t1, 0($t1)                            # Get if we have bonked
    beq  $t1, 1, mDownAckBonk                   # Break if we did
    beq  $t0, $a1, mDownEnd                     # Shortcircuit if landed perfectly

    move $t1, $zero                             # int cycle = 0;
    li   $t2, BOT_SPEED                         # Load velocity
    sw   $t2, VELOCITY($0)                      # Set the velocity
    mDownWait:
        bge $t1, 250, mDownJump                 # Break iff ~(cycles < 2500)
        add $t1, $t1, 1                         # cycle++;
        j mDownWait                             # Wait 1000 Cycles

    mDownJump:
        sw  $0, VELOCITY($0)
        j   moveDown

    mDownAckBonk:
	    la   $t1, has_bonked
	    sb   $t1, 0($t1)                        # Reset if we have bonked

    mDownEnd:
        jr $ra

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
    
print_xy:
  # this syscall takes $a0 as an argument of what INT to print
  li	$v0, PRINT_INT              # Print idx
        syscall

  li	$a0, 32		                # Print space
  li	$v0, PRINT_CHAR
        syscall

  move	$a0, $a1                    # Print x
  li	$v0, PRINT_INT
        syscall

  li	$a0, 32		                # Print space
  li	$v0, PRINT_CHAR
        syscall

  move	$a0, $a2                    # Print y
  li	$v0, PRINT_INT
        syscall
  
  li	$a0, 13		                # Print return
  li	$v0, PRINT_CHAR
        syscall
  
  jr	$ra

# ======================== kernel code ================================
.kdata
chunkIH:    .space 40
non_intrpt_str:    .asciiz "Non-interrupt exception\n"
unhandled_str:    .asciiz "Unhandled interrupt type\n"
.ktext 0x80000180
interrupt_handler:
.set noat
    move    $k1, $at        # Save $at
                            # NOTE: Don't touch $k1 or else you destroy $at!
.set at
    la      $k0, chunkIH
    sw      $a0, 0($k0)        # Get some free registers
    sw      $v0, 4($k0)        # by storing them to a global variable
    sw      $t0, 8($k0)
    sw      $t1, 12($k0)
    sw      $t2, 16($k0)
    sw      $t3, 20($k0)
    sw      $t4, 24($k0)
    sw      $t5, 28($k0)

    # Save coprocessor1 registers!
    # If you don't do this and you decide to use division or multiplication
    #   in your main code, and interrupt handler code, you get WEIRD bugs.
    mfhi    $t0
    sw      $t0, 32($k0)
    mflo    $t0
    sw      $t0, 36($k0)

    mfc0    $k0, $13                # Get Cause register
    srl     $a0, $k0, 2
    and     $a0, $a0, 0xf           # ExcCode field
    bne     $a0, 0, non_intrpt


interrupt_dispatch:                             # Interrupt:
    mfc0    $k0, $13                            # Get Cause register, again
    beq     $k0, 0, done                        # handled all outstanding interrupts

    and     $a0, $k0, BONK_INT_MASK             # is there a bonk interrupt?
    bne     $a0, 0, bonk_interrupt

    # and     $a0, $k0, TIMER_INT_MASK            # is there a timer interrupt?
    # bne     $a0, 0, timer_interrupt

    and     $a0, $k0, REQUEST_PUZZLE_INT_MASK   # is there a puzzle request interrupt?
    bne     $a0, 0, request_puzzle_interupt

    li      $v0, PRINT_STRING                   # Unhandled interrupt types
    la      $a0, unhandled_str
    syscall
    j       done

bonk_interrupt:
    sw      $0, BONK_ACK                        # Acknowledge the bonk interrupt

    li      $t1, 1
    sb      $t1, has_bonked                     # Set the bonk interrupt flag to 1

    sw      $0, VELOCITY($0)                    # Set the velocity to 0

    j       interrupt_dispatch                  # see if other interrupts are waiting

# timer_interrupt:
#     sw      $0, TIMER_ACK                       # Acknowledge the timer interrupt

#     li	    $t0, 1
#     sb	    $t0, has_timer                      # Set the timer interrupt flag to 1

#     j       interrupt_dispatch                  # see if other interrupts are waiting

request_puzzle_interupt:
    sw      $0, REQUEST_PUZZLE_ACK              # Acknowledge the puzzle request interrupt

    li	    $t0, 1
    sb	    $t0, puzzle_received                # Set the puzzle request interrupt flag to 1

    j       interrupt_dispatch                  # see if other interrupts are waiting


non_intrpt:                                     # was some non-interrupt
    li      $v0, PRINT_STRING
    la      $a0, non_intrpt_str
    syscall                                     # print out an error message
    # fall through to done

done:
    la      $k0, chunkIH

    # Restore coprocessor1 registers!
    # If you don't do this and you decide to use division or multiplication
    #   in your main code, and interrupt handler code, you get WEIRD bugs.
    lw      $t0, 32($k0)
    mthi    $t0
    lw      $t0, 36($k0)
    mtlo    $t0

    lw      $a0, 0($k0)             # Restore saved registers
    lw      $v0, 4($k0)
    lw      $t0, 8($k0)
    lw      $t1, 12($k0)
    lw      $t2, 16($k0)
    lw      $t3, 20($k0)
    lw      $t4, 24($k0)
    lw      $t5, 28($k0)

.set noat
    move    $at, $k1        # Restore $at
.set at
    eret