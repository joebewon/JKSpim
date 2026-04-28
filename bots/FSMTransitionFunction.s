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
timestamp_can_unlock_enemy: .word 0               # The timestamp, in cycles, of when we can next unlock the enemy's playpen

time_between_playpens: .word 0                      # The number of cycles it would take to travel between the two playpens

.align 1
fsm_state: .byte 0                                  # Current state of the FSM

.text

# @function
#
# Transition Function for the FSM. Changes the FSM state and also does the proper action tied with the state.
#
# @UsedTemporaries: $t0, $t1
#
# @Params: None
#
# @Returns: void
FSMTransitionFunction:
    sub     $sp, $sp, 4                             # Allocate 4 bytes on the stack
    sw      $ra, 0($ra)                             # Save $ra to the stack

    la      $t0, fsm_state                          # $t0 = &fsm_state
    lw		$t1, 0($t0)                             # Load the FSM State

    # Branch for each FSM State
    beq     $t1, 0, FSM_0                           # if fsm_state == 0, go to FSM_0
    beq     $t1, 1, FSM_1                           # if fsm_state == 1, go to FSM_1
    beq     $t1, 2, FSM_2                           # if fsm_state == 2, go to FSM_2
    beq     $t1, 3, FSM_3                           # if fsm_state == 3, go to FSM_3

    FSM_0:
        jal     ChooseBunny                         # (bunny_x, bunny_y) = ChooseBunny() ### Possibly (bunny_coord, cycles_to_bunny) = ChooseBunny()

        #### Split coord if we go down that route ####
        # and     $a0, $v0, 0x0000FFFF                # $a0 = bunny_x | Extract x coordinate
        # and     $a1, $v0, 0xFFFF0000                # Extract shifted y coordinate
        # srl     $a1, $a1, 16                        # $a1 = bunny_y | Unshift the y coordinate
        # move    $a2, $v1                            # $a2 = cycles_to_bunny

        move    $a0, $v0                            # $a0 = bunny_x
        move    $a1, $v1                            # $a1 = bunny_y
        jal     Move                                # Move(); | Asynchronous Move

        la      $t0, fsm_state                      # $t0 = &fsm_state
        li      $t1, 1                              # $t1 = 1
        sw      $t1, 0($t0)                         # fsm_state = 1;
        j       FSM_Return                          # return;
    FSM_1:
        sw      $0, CATCH_BUNNY($0)
        lw      $t0, MMIO_STATUS($0)

        beq     $t0, 0, FSM_1_Bunny_Picked          # if bunny was picked up, jump to FSM_1_Bunny_Picked
        la      $t0, fsm_state                      # $t0 = &fsm_state
        sw      $0, 0($t0)                          # fsm_state = 0;
        j       FSM_0                               # Pick a new bunny until you actually succesfully pick one up

        FSM_1_Bunny_Picked:
            lw      $t0, PLAYPEN_LOCATION($0)       # $t0 = *playpen_location
            and     $a0, $v0, 0x0000FFFF            # $a0 = playpen_x | Extract x coordinate
            and     $a1, $v0, 0xFFFF0000            # Extract shifted y coordinate
            srl     $a1, $a1, 16                    # $a1 = playpen_y | Unshift the y coordinate
            jal     Move                            # Move(); | Asynchronous Move
            
            li      $t1, 2                          # $t1 = 2
            sw      $t1, 0($t0)                     # fsm_state = 2;
            j       FSM_Return                      # return;
    FSM_2:
        sw      $0, LOCK_PLAYPEN($0)                # Lock the playpen
        lw      $t0, NUM_BUNNIES_CARRIED($0)        # $t0 = *NUM_BUNNIES_CARRIED
        sw      $t0, PUT_BUNNIES_IN_PLAYPEN($0)     # Put all of the bunnies in our playpen

        # Since we can only unlock their playpen once every 100,000 cycles,
        #   we can save the timestamp of when we last unlocked their pen
        #   and only move to their playpen and state 3 iff the current timestamp is
        #   more than 100,000 cycles after the saved timestamp, then save the current timestamp to do the same later.

        la      $t0, timestamp_unlocked_enemy       # $t0 = &timestamp_can_unlock_enemy
        lw      $t0, 0($t0)                         # $t0 = timestamp_can_unlock_enemy
        la      $t1, time_between_playpens          # $t1 = &time_between_playpens   
        lw      $t1, 0($t1)                         # $t1 = time_between_playpens
        lw      $t2, TIMER($0)                      # $t2 = *timer

        add     $t2, $t2, $t1                       # $t2 = current_time + time_between_playpens | the timestamp when we would reach the enemy playpen
        bgt     $t2, $t0, FSM_2_Sabotage            # if current_time + time_between_playpens > timestamp_can_unlock_enemy, jump to FSM_2_Sabotage

        la      $t0, fsm_state                      # $t0 = &fsm_state
        sw      $0, 0($t0)                          # fsm_state = 0;
        j       FSM_0                               # Immediatly look for another bunny as we can't unlock their playpen anyway

        FSM_2_Sabotage:
            lw      $t0, PLAYPEN_OTHER_LOCATION($0) # $t0 = *playpen_location
            and     $a0, $v0, 0x0000FFFF            # $a0 = playpen_x | Extract x coordinate
            and     $a1, $v0, 0xFFFF0000            # Extract shifted y coordinate
            srl     $a1, $a1, 16                    # $a1 = playpen_y | Unshift the y coordinate
            jal     Move                            # Move(); | Asynchronous Move

            li      $t1, 3                          # $t1 = 3
            sw      $t1, 0($t0)                     # fsm_state = 3;
            j       FSM_Return                      # return;
    FSM_3:
        lw      $t0, UNLOCK_PLAYPEN($0)             # Unlock Opponent's Playpen
        lw      $t1, TIMER($0)                      # $t1 = *timer
        lw      $t2, MMIO_STATUS                    # $t1 = *MMIO_STATUS

        beq     $t2, 1, FSM_3_Continue              # if the unlock failed, jump to FSM_3_Continue and don't update timestamp_can_unlock_enemy
        la      $t0, timestamp_can_unlock_enemy     # $t0 = &timestamp_can_unlock_enemy
        add     $t1, $t1, 100000                    # $t1 = *timer + 100000
        sw      $t1, 0($t0)                         # timestamp_can_unlock_enemy = *timer + 100000
        
        FSM_3_Continue:
            la      $t0, fsm_state                  # $t0 = &fsm_state
            sw      $0, 0($t0)                      # fsm_state = 0;
            j       FSM_0                           # Immediatly look for the next bunny

    FSM_Return:
        lw      $ra, 0($sp)                         # Load $ra from the stack
        add		$sp, $sp, 4                         # Deallocate 4 bytes
        jr      $ra                                 # return;
        
# import Move.s;
# import PickBestBunny.s;