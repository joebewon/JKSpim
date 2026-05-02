# import Constants.s
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

################## ################## import Main.s ################## ##################
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
        lw      $t0, OTHER_PLAYPEN_LOCATION                     # $t0 = &OTHER_PLAYPEN_LOCATION
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

################## ################## import FSMTransitionFunction.s ################## ##################
# @function
#
# Transition Function for the FSM. Changes the FSM state and also does the proper action tied with the state.
#
# @UsedTemporaries: $t0, $t1, $t2
#
# @Params: None
#
# @Returns: void
FSMTransitionFunction:
    sub     $sp, $sp, 4                             # Allocate 4 bytes on the stack
    sw      $ra, 0($sp)                             # Save $ra to the stack

    la      $t0, fsm_state                          # $t0 = &fsm_state
    lb		$t1, 0($t0)                             # Load the FSM State

    # Branch for each FSM State
    beq     $t1, 0, FSM_0                           # if fsm_state == 0, go to FSM_0
    beq     $t1, 1, FSM_1                           # if fsm_state == 1, go to FSM_1
    beq     $t1, 2, FSM_2                           # if fsm_state == 2, go to FSM_2
    beq     $t1, 3, FSM_3                           # if fsm_state == 3, go to FSM_3

    FSM_0:
        jal     PickBestBunny                       # (Bunny* best_bunny, float best_bunny_dist) = PickBestBunny()

        lw      $a0, 0($v0)                         # $a0 = best_bunny->x
        lw      $a1, 4($v0)                         # $a1 = best_bunny->y
        cvt.w.s $f0, $f0                            # $f0 = static_cast<int>(best_bunny_dist)
        mfc1    $a2, $f0                            # $a2 <-- $f0
        mul     $a2, $a2, 1000                      # $a2 = static_cast<int>(best_bunny_dist)*1000
        add     $a2, $a2, 10000                     # Add an arbitrary offset to take computation time into account
        jal     MoveWithTime                        # MoveWithTime(best_bunny->x, best_bunny->y, static_cast<int>(best_bunny_dist)*1000); | Asynchronous Move

        la      $t0, fsm_state                      # $t0 = &fsm_state
        li      $t1, 1                              # $t1 = 1
        sb      $t1, 0($t0)                         # fsm_state = 1;
        j       FSM_Return                          # return;
    FSM_1:
        sw      $0, CATCH_BUNNY
        lw      $t0, MMIO_STATUS

        beq     $t0, 0, FSM_1_Bunny_Picked          # if bunny was picked up, jump to FSM_1_Bunny_Picked
        la      $t0, fsm_state                      # $t0 = &fsm_state
        sb      $0, 0($t0)                          # fsm_state = 0;
        j       FSM_0                               # Pick a new bunny until you actually succesfully pick one up

        FSM_1_Bunny_Picked:
            la      $t0, playpen_x                  # $t0 = &playpen_x
            lw      $a0, 0($t0)                     # $a0 = playpen_x | Extract x coordinate
            lw      $a1, 4($t0)                     # $a0 = playpen_y | Extract shifted y coordinate
            jal     Move                            # Move(playpen_x, playpen_y); | Asynchronous Move
            
            la      $t0, fsm_state                  # $t0 = &fsm_state
            li      $t1, 2                          # $t1 = 2
            sb      $t1, 0($t0)                     # fsm_state = 2;
            j       FSM_Return                      # return;
    FSM_2:
        sw      $0, LOCK_PLAYPEN                    # Lock the playpen
        lw      $t0, NUM_BUNNIES_CARRIED            # $t0 = *NUM_BUNNIES_CARRIED
        sw      $t0, PUT_BUNNIES_IN_PLAYPEN         # Put all of the bunnies in our playpen

        # Since we can only unlock their playpen once every 100,000 cycles,
        #   we can save the timestamp of when we last unlocked their pen
        #   and only move to their playpen and state 3 iff the current timestamp is
        #   more than 100,000 cycles after the saved timestamp, then save the current timestamp to do the same later.

        la      $t0, timestamp_can_unlock_enemy     # $t0 = &timestamp_can_unlock_enemy
        lw      $t0, 0($t0)                         # $t0 = timestamp_can_unlock_enemy
        la      $t1, time_between_playpens          # $t1 = &time_between_playpens   
        lw      $t1, 0($t1)                         # $t1 = time_between_playpens
        lw      $t2, TIMER($0)                      # <$t2> int current_time = *timer

        add     $t2, $t2, $t1                       # $t2 = current_time + time_between_playpens | the timestamp when we would reach the enemy playpen
        bgt     $t2, $t0, FSM_2_Sabotage            # if current_time + time_between_playpens > timestamp_can_unlock_enemy, jump to FSM_2_Sabotage

        la      $t0, fsm_state                      # $t0 = &fsm_state
        sb      $0, 0($t0)                          # fsm_state = 0;
        j       FSM_0                               # Immediatly look for another bunny as we can't unlock their playpen anyway

        FSM_2_Sabotage:
            la      $t0, other_playpen_x            # $t0 = &other_playpen_x
            lw      $a0, 0($t0)                     # $a0 = other_playpen_x | Extract x coordinate
            lw      $a1, 4($t0)                     # $a1 = other_playpen_y | Extract shifted y coordinate
            jal     Move                            # Move(other_playpen_x, other_playpen_y); | Asynchronous Move
        
            la      $t0, fsm_state                  # $t0 = &fsm_state
            li      $t1, 3                          # $t1 = 3
            sb      $t1, 0($t0)                     # fsm_state = 3;
            j       FSM_Return                      # return;
    FSM_3:
        sw      $0, UNLOCK_PLAYPEN                  # Unlock Opponent's Playpen
        lw      $t1, TIMER($0)                      # $t1 = *timer
        lw      $t2, MMIO_STATUS                    # $t2 = *MMIO_STATUS

        beq     $t2, 1, FSM_3_Continue              # if the unlock failed, jump to FSM_3_Continue and don't update timestamp_can_unlock_enemy
        la      $t0, timestamp_can_unlock_enemy     # $t0 = &timestamp_can_unlock_enemy
        add     $t1, $t1, 100000                    # $t1 = *timer + 100000
        sw      $t1, 0($t0)                         # timestamp_can_unlock_enemy = *timer + 100000
        
        FSM_3_Continue:
            la      $t0, fsm_state                  # $t0 = &fsm_state
            sb      $0, 0($t0)                      # fsm_state = 0;
            j       FSM_0                           # Immediatly look for the next bunny

    FSM_Return:
        lw      $ra, 0($sp)                         # Load $ra from the stack
        add		$sp, $sp, 4                         # Deallocate 4 bytes
        jr      $ra                                 # return;
        
################## ################## import Move.s ################## ##################
# @async 
# @function
#
# Asynchronously moves the bot to a specified coordinate.
#
# @UsedTemporaries:
# - Integers: $t0, $t1, $t2, $t3
# - Floating: $f2, $f3
# 
# @Params:
# - $a0 (int target_x): The x coordinate of the target, [0,300]
# - $a1 (int target_y): The y coordinate of the target, [0,300]
#
# @Returns: void
Move:
    # Load our bots coordinates
    lw      $t0, BOT_X                      # <$t0> int bot_x = *BOT_X;
    lw      $t1, BOT_Y                      # <$t1> int bot_y = *BOT_Y;

    # Compute the angle
    sub     $t0, $a0, $t0                   # <$t0?> int deltaX = target_x - bot_x;
    sub     $t1, $a1, $t1                   # <$t1?> int deltaY = target_y - bot_y;

    mul     $t2, $t0, 601                   # $t2 = deltaX*601
    add     $t2, $t2, $t1                   # $t2 = deltaX*601 + deltaY
    sll     $t2, $t2, 1                     # $t2 = (deltaX*601 + deltaY)*2
    la      $t3, atan2lookup                # $t3 = &atan2lookup
    add     $t2, $t3, $t2                   # $t2 = &atan2lookup + (deltaX*601 + deltaY)*2
    lh      $t2, 0($t2)                     # <$t2> int theta = atan2lookup[deltaX][deltaY];

    # Turn
    sw      $t2, ANGLE                      # bot->set_angle = theta;
    li      $t3, 1                          # $t3 = 1
    sw      $t3, ANGLE_CONTROL              # bot->angle_control = 1; | Set the absolute orientation

    # Compute time to get there
    mul     $t0, $t0, $t0                   # <$t0> int deltaX_2 = deltaX * deltaX;
    mul     $t1, $t1, $t1                   # <$t1> int deltaY_2 = deltaY * deltaY;

    add     $t0, $t0, $t1                   # <$t0> int squared_sum = deltaX_2 + deltaY_2;
    mtc1    $t0, $f2                        # $f2 <-- squared_sum
    cvt.s.w $f2, $f2                        # $f2 = static_cast<float>(squared_sum)
    sqrt.s  $f2, $f2                        # $f2 = sqrt(squared_sum)

    li      $t1, 1000                       # $t1 = 1000
    mtc1    $t1, $f3                        # $f3 <-- 1000
    cvt.s.w $f3, $f3                        # $f3 = static_cast<float>(1000)
    
    mul.s   $f2, $f3, $f2                   # <$f2> float ftime_to_target = 1000.0 * sqrt(squared_sum);
    cvt.w.s $f2, $f2                        # $f2! = static_cast<int>(ftime_to_target)
    mfc1    $t2, $f2                        # <$t2!> int time_to_target = static_cast<int>(ftime_to_target);

    # Premeptively load the velocity
    li      $t3, 10                         # <$t3!> int velocity = 10; | Premeptively load the velocity
    
    # Request Timer Interrupt
    li      $t0, 1                          # $t0 = 1
    la      $t1, has_timer                  # $t1 = &has_timer
    sb      $t0, 0($t1)                     # has_timer = 1;
    
    lw      $t0, TIMER                      # $t0 = *TIMER
    add     $t0, $t0, $t2                   # <$t0> int timestamp = *TIMER + time_to_target;
    sw      $t0, TIMER                      # Request a timer interrupt for the time in `<t0> timestamp`
    
    # Move the spimbot
    sw      $t3, VELOCITY                   # *VELOCITY = velocity; i.e. *VELOCITY = 10;

    # Return
    jr      $ra                             # return;
    
# @async 
# @function
#
# Asynchronously moves the bot to a specified coordinate, without recomputing the time to get there.
#
# @UsedTemporaries:
# - Integers: $t0, $t1, $t2, $t3
# - Floating: None
#
# @Preconditions: $a2 is actually correct
#
# @Params:
# - $a0 (int target_x): The x coordinate of the target, [0,300]
# - $a1 (int target_y): The y coordinate of the target, [0,300]
# - $a2 (int time_to_target): The time in cycles it will take the spimbot to get to the target
#
# @Returns: void
MoveWithTime:
    # Load our bots coordinates
    lw      $t0, BOT_X                      # <$t0> int bot_x = *BOT_X;
    lw      $t1, BOT_Y                      # <$t1> int bot_y = *BOT_Y;

    # Compute the angle
    sub     $t0, $a0, $t0                   # <$t0?> int deltaX = target_x - bot_x;
    sub     $t1, $a1, $t1                   # <$t1?> int deltaY = target_y - bot_y;

    mul     $t2, $t0, 601                   # $t2 = deltaX*601
    add     $t2, $t2, $t1                   # $t2 = deltaX*601 + deltaY
    sll     $t2, $t2, 1                     # $t2 = (deltaX*601 + deltaY)*2
    la      $t3, atan2lookup                # $t3 = &atan2lookup
    add     $t2, $t3, $t2                   # $t2 = &atan2lookup + (deltaX*601 + deltaY)*2
    lh      $t2, 0($t2)                     # <$t2> int theta = atan2lookup[deltaX][deltaY];

    # Turn
    sw      $t2, ANGLE                      # bot->set_angle = theta;
    li      $t3, 1                          # $t3 = 1
    sw      $t3, ANGLE_CONTROL              # bot->angle_control = 1; | Set the absolute orientation

    # Premeptively load the velocity
    li      $t3, 10                         # <$t3!> int velocity = 10; | Premeptively load the velocity
    
    # Request Timer Interrupt
    li      $t0, 1                          # $t0 = 1
    la      $t1, has_timer                  # $t1 = &has_timer
    sb      $t0, 0($t1)                     # has_timer = 1;

    lw      $t0, TIMER                      # $t0 = *TIMER
    add     $t0, $t0, $a2                   # <$t0> int timestamp = *TIMER + time_to_target;
    sw      $t0, TIMER                      # Request a timer interrupt for the time in `<t0> timestamp`
    
    # Move the spimbot
    sw      $t3, VELOCITY                   # *VELOCITY = velocity; i.e. *VELOCITY = 10;

    # Return
    jr      $ra                             # return;

################## ################## import PickBestBunny.s ################## ##################
################## ################## import Solve.s ################## ##################

################## ################## import Kernel.s ################## ##################
# ======================== kernel code ================================
.kdata
chunkIH:    .space 44
non_intrpt_str:    .asciiz "Non-interrupt exception\n"
unhandled_str:    .asciiz "Unhandled interrupt type\n"
.ktext 0x80000180
interrupt_handler:
.set noat
    move    $k1, $at                    # Save $at
                                        # NOTE: Don't touch $k1 or else you destroy $at!
.set at
    la      $k0, chunkIH
    sw      $a0, 0($k0)                 # Get some free registers
    sw      $v0, 4($k0)                 # by storing them to a global variable
    sw      $t0, 8($k0)
    sw      $t1, 12($k0)
    sw      $t2, 16($k0)
    sw      $t3, 20($k0)
    sw      $t4, 24($k0)
    sw      $t5, 28($k0)
    sw      $ra, 40($k0)

    # Save coprocessor1 registers!
    # If you don't do this and you decide to use division or multiplication
    #   in your main code, and interrupt handler code, you get WEIRD bugs.
    mfhi    $t0
    sw      $t0, 32($k0)
    mflo    $t0
    sw      $t0, 36($k0)

    mfc0    $k0, $13                    # Get Cause register
    srl     $a0, $k0, 2
    and     $a0, $a0, 0xf               # ExcCode field
    bne     $a0, 0, non_intrpt


interrupt_dispatch:                     # Interrupt:
    mfc0    $k0, $13                    # Get Cause register, again
    beq     $k0, 0, done                # handled all outstanding interrupts

    and     $a0, $k0, BONK_INT_MASK     # is there a bonk interrupt?
    bne     $a0, 0, bonk_interrupt

    and     $a0, $k0, TIMER_INT_MASK    # is there a timer interrupt?
    bne     $a0, 0, timer_interrupt

    and     $a0 $k0 REQUEST_PUZZLE_INT_MASK
    bne     $a0 0 request_puzzle_interrupt

    li      $v0, PRINT_STRING           # Unhandled interrupt types
    la      $a0, unhandled_str
    syscall
    j       done

bonk_interrupt:
    sw      $0, BONK_ACK                # Acknwoledge the bonk
    sw      $0, VELOCITY                # Set the velocity to 0

    la      $t0, has_timer              # $t0 = &has_timer
    sb      $0, 0($t0)                  # has_timer = false; | Ignore the next timer interrupt to prevent double FSM transitioning

    jal     FSMTransitionFunction       # Call delta

    j       interrupt_dispatch          # see if other interrupts are waiting

timer_interrupt:
    sw      $0, TIMER_ACK               # Acknowledge the timer interrupt
    sw      $0, VELOCITY                # Set the velocity to 0

    la      $t0, has_timer              # $t0 = &has_timer
    lb		$t1, 0($t0)                 # $t1 = has_timer
    beq     $t1, 0, interrupt_dispatch  # Shortcircuit if we are supposed to ignore this interrupt

    sb      $0, 0($t0)                  # has_timer = 0;

    jal     FSMTransitionFunction       # Call delta

    j       interrupt_dispatch          # see if other interrupts are waiting

request_puzzle_interrupt:
    sw      $0, REQUEST_PUZZLE_ACK      # Acknowledge the puzzle request interrupt

    li	    $t0, 1
    sb	    $t0, puzzle_received        # Set the puzzle request interrupt flag to 1    
    
    j       interrupt_dispatch          # see if other interrupts are waiting

non_intrpt:                             # was some non-interrupt
    li      $v0, PRINT_STRING
    la      $a0, non_intrpt_str
    syscall                             # print out an error message
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

    lw      $a0, 0($k0)                 # Restore saved registers
    lw      $v0, 4($k0)
    lw      $t0, 8($k0)
    lw      $t1, 12($k0)
    lw      $t2, 16($k0)
    lw      $t3, 20($k0)
    lw      $t4, 24($k0)
    lw      $t5, 28($k0)
    lw      $ra, 40($k0)

.set noat
    move    $at, $k1                    # Restore $at
.set at
    eret

################## ################## import DataSegment.s ################## ##################
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