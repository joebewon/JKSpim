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

.text
main:
        #################### Enable Interrupts ####################
        li      $t4, 1
        or      $t4, $t4, TIMER_INT_MASK
        or      $t4, $t4, BONK_INT_MASK                         # enable bonk interrupt
        or      $t4, $t4, REQUEST_PUZZLE_INT_MASK               # enable puzzle interrupt
        or      $t4, $t4, 1                                     # global enable
        mtc0    $t4, $12

        #################### Preprocessing ####################
        # Save the playpen location to memory
        lw      $t0, PLAYPEN_LOCATION                           # $t0 = &PLAYPEN_LOCATION
        and     $t1, $t0, 0xFFFF0000                            # $t1 = $t0 & 0xFFFF0000
        srl     $t1, $t1, 16                                    # <$t6> int _playpen_x = $t1 >> 16;
        and     $t2, $t0, 0x0000FFFF                            # <$t2> int _playpen_y = $t0 & 0x0000FFFF;
        la      $t3, playpen_x                                  # $t3 = &playpen_x
        sw      $t1, 0($t3)                                     # playpen_x = _playpen_x;
        la      $t4, playpen_y                                  # $t4 = &playpen_y
        sw      $t2, 0($t4)                                     # playpen_y = _playpen_y;

        # Save the enemy playpen location to memory
        lw      $t0, PLAYPEN_OTHER_LOCATION                     # $t0 = &PLAYPEN_OTHER_LOCATION
        and     $t5, $t0, 0xFFFF0000                            # $t5 = $t0 & 0xFFFF0000
        srl     $t5, $t5, 16                                    # <$t5> int _other_playpen_x = $t1 >> 16;
        and     $t6, $t0, 0x0000FFFF                            # <$t6> int _other_playpen_y = $t0 & 0x0000FFFF;
        la      $t3, other_playpen_x                            # $t3 = &other_playpen_x
        sw      $t5, 0($t3)                                     # other_playpen_x = _other_playpen_x;
        la      $t4, other_playpen_y                            # $t4 = &other_playpen_y
        sw      $t6, 0($t4)                                     # other_playpen_y = _other_playpen_y;

        # Calculate time_between_playpens
        sub     $t5, $t5, $t1                                   # <$t5> int deltaX = _other_playpen_x - _playpen_x;
        sub     $t6, $t6, $t2                                   # <$t6> int deltaY = _other_playpen_Y - _playpen_Y;
        mul     $t5, $t5, $t5                                   # <$t5> int deltaX_2 = deltaX * deltaX;
        mul     $t6, $t6, $t6                                   # <$t6> int deltaY_2 = deltaY * deltaY;
        add     $t5, $t6, $t5                                   # <$t5> int squared_sum = deltaX_2 + deltaY_2;
        mtc1    $t5, $f2                                        # $f2 <-- squared_sum
        cvt.s.w $f2, $f2                                        # $f2 = static_cast<float>(squared_sum)
        sqrt.s  $f2, $f2                                        # $f2 = sqrt(squared_sum)
        li      $t6, 1000                                       # $t6 = 1000
        mtc1    $t6, $f3                                        # $f3 <-- 1000
        cvt.s.w $f3, $f3                                        # $f3 = static_cast<float>(1000)
        mul.s   $f2, $f2, $f3                                   # float _ftime_between_playpens = 1000.0 * sqrt((_other_playpen_x - _playpen_x)**2 + (_other_playpen_Y - _playpen_Y)**2)
        cvt.w.s $f2, $f2                                        # $f2 = static_cast<int>(_ftime_between_playpens)
        mfc1    $t5, $f2                                        # <$t5> int _time_between_playpens = static_cast<int>(_ftime_between_playpens);
        la      $t0, time_between_playpens                      # $t0 = &time_between_playpens
        sw      $t5, 0($t0)                                     # time_between_playpens = _time_between_playpens;

        #################### Start Schmoovin' ####################
        jal     FSMTransitionFunction                           # Lets get ts on the road!

#################### Tell 'em to bring out the whole ocean! ####################
loop:
        jal     SolvePuzzle                                     # Infinitely Solve Puzzles: Bands on Bands on Bands.
        j       loop                                            # MORE!!!!

# import Kernel.s
# import FSMTransitionFunction.s
# import Solve.s
# import DataSegment.s
.data
.align 4
bunnies_info: .space 484                                        # Space for the BunniesInfo Struct

puzzle: .space 268                                              # Space for the LightsOut Puzzle

solution: .space 256                                            # Space for the solution to the LightsOut Puzzle

num_puzzles_requested: .word 0                                  # The number of puzzles that have been requested

timestamp_can_unlock_enemy: .word 0                             # The timestamp, in cycles, of when we can next unlock the enemy's playpen

time_between_playpens: .word 0                                  # The number of cycles it would take to travel between the two playpens

playpen_x: .word 0                                              # The x-cooridnate of our playpen
playpen_y: .word 0                                              # The y-cooridnate of our playpen
other_playpen_x: .word 0                                        # The x-cooridnate of their playpen
other_playpen_y: .word 0                                        # The y-cooridnate of their playpen

.align 1
has_bonked: .byte 0                                             # Bonk Interrupt

puzzle_received: .byte 0                                        # Puzzle Received Interrupt

has_timer: .byte 0                                              # Whether or not we should actually respect the timer interrupt

fsm_state: .byte 0                                              # Current state of the FSM

# import Arctan2lookup.s