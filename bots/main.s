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
SUBMIT_SOLUTION         = 0xffff00d4
CURRENT_PUZZLE          = 0xffff00b8

BOT_X                   = 0xffff0020
BOT_Y                   = 0xffff0024
OTHER_X                 = 0xffff00a0
OTHER_Y                 = 0xffff00a4

NUM_CARROTS             = 0xffff0040
NUM_BUNNIES_CARRIED     = 0xffff0050

SEARCH_BUNNIES          = 0xffff0054
CATCH_BUNNY             = 0xffff0058
PUT_BUNNIES_IN_PLAYPEN  = 0xffff005c

PLAYPEN_LOCATION        = 0xffff0044
LOCK_PLAYPEN			= 0xffff0048
UNLOCK_PLAYPEN			= 0xffff004c
PLAYPEN_OTHER_LOCATION	= 0xffff00dc

SCORES_REQUEST          = 0xffff1018

TIMER                   = 0xffff001c

BONK_INT_MASK           = 0x1000      ## Bonk
BONK_ACK                = 0xffff0060  ## Bonk
TIMER_INT_MASK          = 0x8000      ## Timer
TIMER_ACK               = 0xffff006c  ## Timer
REQUEST_PUZZLE_INT_MASK = 0x800       ## Puzzle
REQUEST_PUZZLE_ACK		= 0xffff00e4  ## Puzzle
BUNNY_MOVE_INT_MASK     = 0x400       ## Bunny Move
BUNNY_MOVE_ACK          = 0xffff00e8  ## Bunny Move
EX_CARRY_LIMIT_INT_MASK = 0x4000      ## Exceeding Carry Limit
EX_CARRY_LIMIT_ACK      = 0xffff002c  ## Exceeding Carry Limit
PLAYPEN_UNLOCK_INT_MASK = 0x2000      ## Playpen Unlock
PLAYPEN_UNLOCK_ACK      = 0xffff0028  ## Playpen Unlock

MMIO_STATUS             = 0xffff204c

############################ Don't Link the above ############################

.data
.align 4
bunnies_info: .space 484                            # Space for the BunniesInfo Struct

puzzle: .space 268                                  # Space for the LightsOut Puzzle

solution: .space 256                                # Space for the solution to the LightsOut Puzzle

num_puzzles_requested: .word 0                      # The number of puzzles that have been requested

timestamp_can_unlock_enemy: .word 0                 # The timestamp, in cycles, of when we can next unlock the enemy's playpen

time_between_playpens: .word 0                      # The number of cycles it would take to travel between the two playpens

playpen_x: .word 0                                  # The x-cooridnate of our playpen
playpen_y: .word 0                                  # The y-cooridnate of our playpen
other_playpen_x: .word 0                            # The x-cooridnate of their playpen
other_playpen_y: .word 0                            # The y-cooridnate of their playpen

.align 1
has_bonked: .byte 0                                 # Bonk Interrupt

puzzle_received: .byte 0                            # Puzzle Received Interrupt

has_timer: .byte 0                                  # Whether or not we should actually respect the timer interrupt

fsm_state: .byte 0                                  # Current state of the FSM

.text
main:
        # enable interrupts
        li      $t4     1
        or      $t4     $t4     TIMER_INT_MASK
        or      $t4,    $t4,    BONK_INT_MASK             # enable bonk interrupt
        or      $t4,    $t4,    REQUEST_PUZZLE_INT_MASK   # enable puzzle interrupt
        or      $t4,    $t4,    1 # global enable
        mtc0    $t4     $12

        # li $t1, 0
        # sw $t1, ANGLE
        # li $t1, 1
        # sw $t1, ANGLE_CONTROL
        # li $t2, 0
        # sw $t2, VELOCITY

        # Save the playpen location to memory
        lw $t0, PLAYPEN_LOCATION
        and $t1, $t0, 0xFFFF0000
        srl $t1, $t1, 26    
        and $t2, $t0, 0x0000FFFF
        la $t3, playpen_x
        sw $t1, 0($t3)
        la $t4, playpen_y
        sw $t2, 0($t4)

        # Save the enemy playpen location to memory
        lw $t0, OTHER_PLAYPEN_LOCATION
        and $t5, $t0, 0xFFFF0000
        srl $t5, $t5, 26    
        and $t6, $t0, 0x0000FFFF
        la $t3, other_playpen_x
        sw $t5, 0($t3)
        la $t4, other_playpen_y
        sw $t6, 0($t4)

        # Calculate time_between_playpens
        sub     $t5, $t5, $t1
        sub     $t6, $t6, $t2
        mul     $t5, $t5, $t5
        mul     $t6, $t6, $t6
        add     $t5, $t6, $t5
        mtc1    $t5, $f2
        cvt.s.w $f2, $f2
        sqrt.s  $f2, $f2
        li      $t6, 1000
        mtc1    $t6, $f3
        cvt.s.w $f3, $f3
        mul.s   $f2, $f2, $f3
        cvt.w.s $f2, $f2
        mfc1    $t5, $f2
        la      $t0, time_between_playpens
        sw      $t5, 0($t0)

        jal     FSMTransitionFunction

# Once done, enter an infinite loop so that your bot can be graded by QtSpimbot once 10,000,000 cycles have elapsed
loop:
        jal     SolvePuzzle                                 # Infinitely Solve Puzzles. Bands on Bands on Bands.
        j       loop

# import kernel.s
# import FSMTransitionFunction.s
# import solve.s

.data
.align 4

# Lookup Table for arctan2.
# Set up as a 2d array s.t. the indices are deltaX and deltaY of the two points, where we use target - start
# e.g. start is at (236, 85)
#      target is at (27, 293)
#      deltaX = 27 - 236 = -209
#      deltaY = 293 - 85 = 208
#      then theta = arctan2(deltaY / deltaX) := arctan2_lookup[deltaX][deltaY]
# These numbers are directly represented as IEEE 754 Single Precision Floating Point Numbers 
arctan2_lookup: .word 0