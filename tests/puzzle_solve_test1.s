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
    jal _solve                              # bool got_sol = solve(&puzzle, &solution, 0, 0);

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

# @function
#
# Attempts to solve a puzzle
#
# @UsedTemporaries: $t0, $t1, $t2
#
# @Params:
#   - $a0: LightsOuts* puzzle (word)
#   - $a1: unsigned char* solution (word)
#   - $a2: int row (word)
#   - $a3: int col (word)
#
# @Returns:
#   - $v0: Whether or not the puzzle is solved
_solve:
    lw $t0, 0($a0)                          # int num_rows = puzzle->num_rows;
    lw $t1, 4($a0)                          # int num_cols = puzzle->num_cols;
    lw $t2, 8($a0)                          # int num_colors = puzzle->num_colors;
    addi $t4, $a0, 12                       # $t4 = &(puzzle->board) | Preemptively load &(puzzle->board) in case we need it
    
    sub $t3, $t1, 1                         # $t3 = num_cols - 1 | Begin: int next_row = (col == num_cols-1) ? row + 1 : row;
    bne $a3, $t3, set_next_row_false_s        # Break iff ~(col == num_cols-1)
    
    add $t3, $a2, 1                         # int next_row = row + 1; | End: int next_row = (col == num_cols-1) ? row + 1 : row;
    
    j if_base_s
    
    set_next_row_false_s:
        move $t3, $a2                       # int next_row = row; | End: int next_row = (col == num_cols-1) ? row + 1 : row;
    
    if_base_s:
        bge $a2, $t0, fi_base_s               # Break if row >= num_rows
        bge $a3, $t1, fi_base_s               # Break if col >= num_cols
        
        if1_s:
            beq $a2, $0, fi1_s                # Break iff ~(row != 0)
            
            # int actions = (num_colors - puzzle->board[(row-1)*num_cols + col]) % num_colors;
            ## (row - 1)*num_cols + col --> Index
            sub $t5, $a2, 1                 # $t5 = (row - 1) | Begin: int actions = (num_colors - puzzle->board[(row-1)*num_cols + col]) % num_colors;
            mul $t5, $t5, $t1               # $t5 = (row - 1)*num_cols
            add $t5, $t5, $a3               # $t5 = (row - 1)*num_cols + col
            add $t5, $t5, $t4               # $t5 += &(puzzle->board) | Convert index to a char aligned Memory Address
            
            ## (num_colors - puzzle->board[(row-1)*num_cols + col]) % num_colors;
            lbu $t5, 0($t5)                 # $t5 = puzzle->board[(row-1)*num_cols + col]
            sub $t5, $t2, $t5               # $t5 = num_colors - puzzle->board[(row-1)*num_cols + col]
            rem $t5, $t5, $t2               # End: int actions = (num_colors - puzzle->board[(row-1)*num_cols + col]) % num_colors;
            
            # solution[row*num_cols + col] = actions;
            mul $t6, $a2, $t1               # $t6 = row*num_cols | Begin: solution[row*num_cols + col] = actions;
            add $t6, $t6, $a3               # $t6 = row*num_cols + col
            add $t6, $t6, $a1               # $t6 += solution | Convert index to a char aligned Memory Address
            sb  $t5, 0($t6)                 # End: solution[row*num_cols + col] = actions;
            
            sub $sp, $sp, 44
            sw $ra, 0($sp)
            sw $a0, 4($sp)
            sw $a1, 8($sp)
            sw $a2, 12($sp)
            sw $a3, 16($sp)
            sw $t0, 20($sp)
            sw $t1, 24($sp)
            sw $t2, 28($sp)
            sw $t3, 32($sp)
            sw $t4, 36($sp)
            sw $t5, 40($sp)

            # toggle_light(row, col, puzzle, actions);
            move $t9, $a0                   # $t9 = puzzle
            move $a0, $a2                   # $a0 = row
            move $a1, $a3                   # $a1 = col
            move $a2, $t9                   # $a2 = puzzle
            move $a3, $t5                   # $a3 = actions
            jal toggle_light                # toggle_light(row, col, puzzle, actions);
            
            lw $ra, 0($sp)
            lw $a0, 4($sp)
            lw $a1, 8($sp)
            lw $a2, 12($sp)
            lw $a3, 16($sp)
            lw $t0, 20($sp)
            lw $t1, 24($sp)
            lw $t2, 28($sp)
            lw $t3, 32($sp)
            lw $t4, 36($sp)
            lw $t5, 40($sp)
            
            if2_s:
                move $a0, $a0               # $a0 = puzzle
                move $a1, $a1               # $a1 = solution
                move $a2, $t3               # $a2 = next_row
                add  $a3, $a3, 1
                rem  $a3, $a3, $t1          # $a3 = (col + 1) % num_cols
                jal _solve                   # $v0 = _solve(puzzle,solution, next_row, (col + 1) % num_cols)
                
                beq $v0, $0, fi2_s            # Break iff ~(_solve(puzzle,solution, next_row, (col + 1) % num_cols));
                
                lw   $ra, 0($sp)
                add  $sp, $sp, 44
                
                li $v0, 1                   # $v0 = 1
                jr $ra                      # return true;
                
            fi2_s:
                lw $ra, 0($sp)
                lw $a0, 4($sp)
                lw $a1, 8($sp)
                lw $a2, 12($sp)
                lw $a3, 16($sp)
                lw $t0, 20($sp)
                lw $t1, 24($sp)
                lw $t2, 28($sp)
                lw $t3, 32($sp)
                lw $t4, 36($sp)
                lw $t5, 40($sp)
            
                # solution[row*num_cols + col] = 0;
                mul $t6, $a2, $t1           # $t6 = row*num_cols | Begin: solution[row*num_cols + col] = 0;
                add $t6, $t6, $a3           # $t6 = row*num_cols + col
                add $t6, $t6, $a1           # $t6 += solution | Convert index to a char aligned Memory Address
                sb  $0, 0($t6)              # End: solution[row*num_cols + col] = 0;
                
                # toggle_light(row, col, puzzle, num_colors - actions);
                move $t9, $a0               # $t9 = puzzle
                move $a0, $a2               # $a0 = row
                move $a1, $a3               # $a1 = col
                move $a2, $t9               # $a2 = puzzle
                sub  $a3, $t2, $t5          # $a3 = num_colors - actions
                jal toggle_light            # toggle_light(row, col, puzzle, num_colors - actions);
                
                lw   $ra, 0($sp)
                add  $sp, $sp, 44
                move $v0, $zero             # $v0 = 0
                jr   $ra                    # return false;
        fi1_s:
            move $t5, $0                    # int actions = 0;
            
            sub $sp, $sp, 44
            sw $ra, 0($sp)
            sw $a0, 4($sp)
            sw $a1, 8($sp)
            sw $a2, 12($sp)
            sw $a3, 16($sp)
            sw $t0, 20($sp)
            sw $t1, 24($sp)
            sw $t2, 28($sp)
            sw $t3, 32($sp)
            sw $t4, 36($sp)
                
            for_s:
                sw $t5, 40($sp)
                bge $t5, $t2, rof_s           # Break iff ~(actions < num_colors)
                
                lw $ra, 0($sp)
                lw $a0, 4($sp)
                lw $a1, 8($sp)
                lw $a2, 12($sp)
                lw $a3, 16($sp)
                lw $t0, 20($sp)
                lw $t1, 24($sp)
                lw $t2, 28($sp)
                lw $t3, 32($sp)
                lw $t4, 36($sp)
                lw $t5, 40($sp)
                
                # solution[row*num_cols + col] = actions;
                mul $t6, $a2, $t1               # $t6 = row*num_cols | Begin: solution[row*num_cols + col] = actions;
                add $t6, $t6, $a3               # $t6 = row*num_cols + col
                add $t6, $t6, $a1               # $t6 += solution | Convert index to a char aligned Memory Address
                sb  $t5, 0($t6)                 # End: solution[row*num_cols + col] = actions;
                
                sw $ra, 0($sp)
                sw $a0, 4($sp)
                sw $a1, 8($sp)
                sw $a2, 12($sp)
                sw $a3, 16($sp)
                sw $t0, 20($sp)
                sw $t1, 24($sp)
                sw $t2, 28($sp)
                sw $t3, 32($sp)
                sw $t4, 36($sp)
                sw $t5, 40($sp)
    
                # toggle_light(row, col, puzzle, actions);
                move $t9, $a0                   # $t9 = puzzle
                move $a0, $a2                   # $a0 = row
                move $a1, $a3                   # $a1 = col
                move $a2, $t9                   # $a2 = puzzle
                move $a3, $t5                   # $a3 = actions
                jal toggle_light                # toggle_light(row, col, puzzle, actions);
                
                lw $ra, 0($sp)
                lw $a0, 4($sp)
                lw $a1, 8($sp)
                lw $a2, 12($sp)
                lw $a3, 16($sp)
                lw $t0, 20($sp)
                lw $t1, 24($sp)
                lw $t2, 28($sp)
                lw $t3, 32($sp)
                lw $t4, 36($sp)
                lw $t5, 40($sp)

                if3_s:
                    sw $ra, 0($sp)
                    sw $a0, 4($sp)
                    sw $a1, 8($sp)
                    sw $a2, 12($sp)
                    sw $a3, 16($sp)
                    sw $t0, 20($sp)
                    sw $t1, 24($sp)
                    sw $t2, 28($sp)
                    sw $t3, 32($sp)
                    sw $t4, 36($sp)
                    sw $t5, 40($sp)
                
                    move $a0, $a0               # $a0 = puzzle
                    move $a1, $a1               # $a1 = solution
                    move $a2, $t3               # $a2 = next_row
                    add  $a3, $a3, 1
                    rem  $a3, $a3, $t1          # $a3 = (col + 1) % num_cols
                    jal _solve                   # $v0 = _solve(puzzle,solution, next_row, (col + 1) % num_cols)
                    
                    beq $v0, $0, fi3_s            # Break iff ~(_solve(puzzle,solution, next_row, (col + 1) % num_cols));
                    
                    lw   $ra, 0($sp)
                    add  $sp, $sp, 44
                    
                    li $v0, 1                   # $v0 = 1
                    jr $ra                      # return true;
                    
                fi3_s:
                    lw $ra, 0($sp)
                    lw $a0, 4($sp)
                    lw $a1, 8($sp)
                    lw $a2, 12($sp)
                    lw $a3, 16($sp)
                    lw $t0, 20($sp)
                    lw $t1, 24($sp)
                    lw $t2, 28($sp)
                    lw $t3, 32($sp)
                    lw $t4, 36($sp)
                    lw $t5, 40($sp)

                    sw $ra, 0($sp)
                    sw $a0, 4($sp)
                    sw $a1, 8($sp)
                    sw $a2, 12($sp)
                    sw $a3, 16($sp)
                    sw $t0, 20($sp)
                    sw $t1, 24($sp)
                    sw $t2, 28($sp)
                    sw $t3, 32($sp)
                    sw $t4, 36($sp)
                    sw $t5, 40($sp)
                
                    # toggle_light(row, col, puzzle, num_colors - actions);
                    move $t9, $a0                   # $t9 = puzzle
                    move $a0, $a2                   # $a0 = row
                    move $a1, $a3                   # $a1 = col
                    move $a2, $t9                   # $a2 = puzzle
                    sub  $a3, $t2, $t5      # $a3 = num_colors - actions
                    jal toggle_light        # toggle_light(row, col, puzzle, num_colors - actions);
                
                    lw $ra, 0($sp)
                    lw $a0, 4($sp)
                    lw $a1, 8($sp)
                    lw $a2, 12($sp)
                    lw $a3, 16($sp)
                    lw $t0, 20($sp)
                    lw $t1, 24($sp)
                    lw $t2, 28($sp)
                    lw $t3, 32($sp)
                    lw $t4, 36($sp)
                    lw $t5, 40($sp)
                
                    # solution[row*num_cols + col] = 0;
                    mul $t6, $a2, $t1       # $t6 = row*num_cols | Begin: solution[row*num_cols + col] = 0;
                    add $t6, $t6, $a3       # $t6 = row*num_cols + col
                    add $t6, $t6, $a1       # $t6 += solution | Convert index to a char aligned Memory Address
                    sb  $0, 0($t6)          # End: solution[row*num_cols + col] = 0;
                    
                    add $t5, $t5, 1         # actions++;
                    j for_s
            rof_s:
                lw   $ra, 0($sp)
                add  $sp, $sp, 44
                
                move $v0, $zero             # $v0 = 0
                jr   $ra                    # return false;
    fi_base_s:
        sub $sp, $sp, 4
        sw  $ra, 0($sp)
    
        # return board_done(num_rows, num_cols, puzzle->board);
        move $a0, $t0
        move $a1, $t1
        move $a2, $t4
        jal  board_done
        
        lw  $ra, 0($sp)
        add $sp, $sp, 4
        
        jr $ra                              # return board_done(num_rows, num_cols, puzzle->board);

# @function
#
# Zeros an entire board
#
# @UsedTemporaries: $t0, $t1, $t2
#
# @Params:
#   - $a0: int num_rows (word)
#   - $a1: int num_cols (word)
#   - $a2: unsigned char* solution (word)
#
# @Returns: void
zero_board:
    li $t0, 0 # int row = 0;
    for_outer_z:
        bge $t0, $a0, rof_outer_z
        li $t1, 0 # int col = 0;
        
        for_inner_z:
            bge $t1, $a1, rof_inner_z
        
            # (row)*num_cols + col
            mul $t2, $t0, $a1 # (row)*num_cols
            add $t2, $t2, $t1 # $t2 = (row)*num_cols + col
        
            # Index to Memory Address
            mul $t2, $t2, 1   # $t2 *= 1
            add $t2, $a2, $t2 # $t2 = ($t2 * 4) + solution
        
            # Store the zero
            sb $0, 0($t2)     # solution[(row)*num_cols + col] = 0;
        
            addi $t1, $t1, 1  # col++;
            j for_inner_z
        
        rof_inner_z:
            addi $t0, $t0, 1 # row++;
            j for_outer_z

    rof_outer_z:
        jr $ra

# @function
#
# Checks if the board is done
#
# @UsedTemporaries: $t0, $t1, $t2
#
# @Params:
#   - $a0: num_rows (word)
#   - $a1: num_columns (word)
#   - $a2: &solution (word)
#
# @Returns:
#   $v0: True if the board is done
board_done:
    li $t0, 0 # int row = 0;
    for_outer_b:
        bge $t0, $a0, rof_outer_b
        li $t1, 0 # int col = 0;
        
        for_inner_b:
            bge $t1, $a1, rof_inner_b
        
            # (row)*num_cols + col
            mul $t2, $t0, $a1 # (row)*num_cols
            add $t2, $t2, $t1 # $t2 = (row)*num_cols + col
        
            # Index to Memory Address
            mul $t2, $t2, 1   # $t2 *= 1
            add $t2, $a2, $t2 # $t2 = ($t2 * 4) + solution
        
            # Check if zero
            lb $t2, 0($t2)     # solution[(row)*num_cols + col] = 0;
            if_b:
                beq $t2, $0, fi_b
                
                move $v0, $0
                jr $ra
                
            fi_b:
                addi $t1, $t1, 1  # col++;
                j for_inner_b
        
        rof_inner_b:
            addi $t0, $t0, 1 # row++;
            j for_outer_b

    rof_outer_b:
        addi $t0, $0, 1
        move $v0, $t0
        jr $ra

# @function Toggles a light and its neighbors
#
# @UsedTemporaries: $t0, $t1, $t2, $t3, $t4, $t5
#
# @Params:
#   - $a0: int row (word)
#   - $a1: int col (word)
#   - $a2: LightsOuts* puzzle (word)
#   - $a4: int action_num (word)
#
# @Returns: void
toggle_light:
    preamble_t:
        ####### Stack Memory Management #######
        sub $sp, $sp, 40    # Allocate 10 words
        
        sw  $ra, 0($sp)     # Return Address
        
        # Save the arguments to the stack
        sw  $a0, 4($sp)     # int row
        sw  $a1, 8($sp)     # int col
        sw  $a2, 12($sp)    # LightsOuts* puzzle
        sw  $a3, 16($sp)    # int action_num
        
        # Compute local variables
        lw      $t0, 0($a2)     # int num_rows = puzzle->num_rows;
        lw      $t1, 4($a2)     # int num_cols = puzzle->num_cols;
        lw      $t2, 8($a2)     # int num_colors = puzzle->num_colors;
        addiu   $t3, $a2, 12    # unsigned char* board = puzzle->board;
        
        # Save locals to the stack
        sw  $t0, 20($sp)    # int            num_rows
        sw  $t1, 24($sp)    # int            num_cols
        sw  $t2, 28($sp)    # int            num_colors
        sw  $t3, 32($sp)    # unsigned char* board
        
        ####### First Toggle #######
        # Compute the pointer
        mul $t4, $a0, $t1   # $t4 = row*num_cols;
        add $t4, $t4, $a1   # $t4 = row*num_cols + col;
        add $t4, $t4, $t3   # $t4 += board;
        
        # Compute the toggle value
        sw   $t4, 36($sp)    # Save the pointer to the stack for later
        move $a0, $t4
        move $a1, $a3
        move $a2, $t2
        jal  getToggleValue  # Call the function that computer the toggle value
        lw   $t4, 36($sp)    # Restore the pointer
        sb   $v0, 0($t4)     # Save the returned toggle value to the array
        
    if0_t:
        ####### Second Toggle #######
        # Restore Arguments
        lw  $a0, 4($sp)     # int row
        lw  $a1, 8($sp)     # int col
        lw  $a3, 16($sp)    # int action_num
        
        # Restore Locals
        lw  $t1, 24($sp)    # int            num_cols
        lw  $t2, 28($sp)    # int            num_colors
        lw  $t3, 32($sp)    # unsigned char* board
        
        # Break Condition Check
        ble $a0, $0, if1_t
        
        # Compute the pointer @TODO
        sub $t4, $a0, 1     # $t4 = row - 1
        mul $t4, $t4, $t1   # $t4 = (row - 1)*num_cols;
        add $t4, $t4, $a1   # $t4 = (row - 1)*num_cols + col;
        add $t4, $t4, $t3   # $t4 += board;
        
        # # Compute the toggle value
        sw   $t4, 36($sp)    # Save the pointer to the stack for later
        move $a0, $t4
        move $a1, $a3
        move $a2, $t2
        jal  getToggleValue  # Call the function that computer the toggle value
        lw   $t4, 36($sp)    # Restore the pointer
        sb   $v0, 0($t4)
        
    if1_t:
        ####### Third Toggle #######
        # Restore Arguments
        lw  $a0, 4($sp)     # int row
        lw  $a1, 8($sp)     # int col
        lw  $a3, 16($sp)    # int action_num
        
        # Restore Locals
        lw  $t1, 24($sp)    # int            num_cols
        lw  $t2, 28($sp)    # int            num_colors
        lw  $t3, 32($sp)    # unsigned char* board
        
        # Break Condition Check
        ble $a1, $0, if2_t
        
        # Compute the pointer @TODO
        mul $t4, $a0, $t1   # $t4 = row*num_cols;
        add $t4, $t4, $a1   # $t4 = row*num_cols + col;
        sub $t4, $t4, 1     # $t4 = row*num_cols + col - 1;
        add $t4, $t4, $t3   # $t4 += board;
        
        # Compute the toggle value
        sw   $t4, 36($sp)    # Save the pointer to the stack for later
        move $a0, $t4
        move $a1, $a3
        move $a2, $t2
        jal  getToggleValue  # Call the function that computer the toggle value
        lw   $t4, 36($sp)    # Restore the pointer
        sb   $v0, 0($t4)
    
    if2_t:
        ####### Fourth Toggle #######
        # Restore Arguments
        lw  $a0, 4($sp)     # int row
        lw  $a1, 8($sp)     # int col
        lw  $a3, 16($sp)    # int action_num
        
        # Restore Locals
        lw  $t0, 20($sp)    # int            num_rows
        lw  $t1, 24($sp)    # int            num_cols
        lw  $t2, 28($sp)    # int            num_colors
        lw  $t3, 32($sp)    # unsigned char* board
        
        # Break Condition Check
        sub $t5, $t0, 1
        bge $a0, $t5, if3_t
        
        # Compute the pointer @TODO
        add $t4, $a0, 1     # $t4 = row + 1
        mul $t4, $t4, $t1   # $t4 = (row + 1)*num_cols;
        add $t4, $t4, $a1   # $t4 = (row + 1)*num_cols + col;
        add $t4, $t4, $t3   # $t4 += board;
        
        # Compute the toggle value
        sw   $t4, 36($sp)    # Save the pointer to the stack for later
        move $a0, $t4
        move $a1, $a3
        move $a2, $t2
        jal  getToggleValue  # Call the function that computer the toggle value
        lw   $t4, 36($sp)    # Restore the pointer
        sb   $v0, 0($t4)
    
    if3_t:
        ####### Fifth Toggle #######
        # Restore Arguments
        lw  $a0, 4($sp)     # int row
        lw  $a1, 8($sp)     # int col
        lw  $a3, 16($sp)    # int action_num
        
        # Restore Locals
        lw  $t0, 20($sp)    # int            num_rows
        lw  $t1, 24($sp)    # int            num_cols
        lw  $t2, 28($sp)    # int            num_colors
        lw  $t3, 32($sp)    # unsigned char* board
        
        # Break Condition Check
        sub $t5, $t1, 1
        bge $a1, $t5, postamble_t
        
        # Compute the pointer @TODO
        mul $t4, $a0, $t1   # $t4 = row*num_cols;
        add $t4, $t4, $a1   # $t4 = row*num_cols + col;
        add $t4, $t4, 1     # $t4 = row*num_cols + col + 1;
        add $t4, $t4, $t3   # $t4 += board;
        
        # Compute the toggle value
        sw   $t4, 36($sp)    # Save the pointer to the stack for later
        move $a0, $t4
        move $a1, $a3
        move $a2, $t2
        jal  getToggleValue  # Call the function that computer the toggle value
        lw   $t4, 36($sp)    # Restore the pointer
        sb   $v0, 0($t4)
    
    postamble_t:
        lw  $ra, 0($sp)     # Restore $ra
        add $sp, $sp, 40    # Dellocate 10 words
        jr  $ra
        
# @function
#
# Gets the toggle value for the light you need to toggle
#
# @UsedTemps: None
#
# @Params
#   $a0: ptr        - A pointer to the light we want to toggle
#   $a1: action_num - A value that defines how to toggle that light
#   $a2: num_colors - The numbers of valid values that light can take
#
# @Returns
#   $v0: The value to toggle the light to
getToggleValue:
    lbu  $v0, 0($a0)     # Dereference the pointer to the light
    add $v0, $v0, $a1   # $v0 += action_num
    rem $v0, $v0, $a2   # $v0 %= num_colors
    jr $ra
    
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