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

.align 4
bunnies_info: .space 484                    # Space for the BunniesInfo Struct

playpen_x: .word 0                          # The x-cooridnate of our playpen
playpen_y: .word 0                          # The y-cooridnate of our playpen

.text

# @function
#
# Chooses the best bunny to pursue based on the largest weight/travel-time ratio.
# Ignores bunnies that cannot be reached before they jump. If two bunnies have
# the same ratio, chooses the heavier bunny. Also returns the distance/time from
# the bot to the chosen bunny.
#
# @UsedTemporaries:
# - Integers: $t0, $t1, $t2, $t3, $t4, $t5
# - Floating: $f2, $f3, $f4, $f5
#
# @Params: None
#
# @Returns:
#   $v0 (Bunny*): best_bunny | A pointer to the optimal bunny
#   $f0 (float): best_bunny_dist | The number of distance in cycles from the spimbot's current location to the best bunny
PickBestBunny:
    la      $t0, bunnies_info
    sw      $t0, SEARCH_BUNNIES($0)         # <$t0!> BunniesInfo* bunnies_info = *SEARCH_BUNNIES;
    lw      $t1, 0($t0)                     # <$t1!> int num_bunnies = bunnies_info->num_bunnies;

    add     $v0, $t0, 4                     # <$v0!> Bunny* best_bunny = &bunnies_info->info[0];
    mtc1    $zero, $f0                      # <$f0!> float best_bunny_dist = 0.0f;
    mtc1    $zero, $f2                      # <$f2!> float biggest_ratio = 0.0f;
    
    move    $t2, $0                         # <$t2!> int i = 0;
    PBB_For:
        mul     $t3, $t2, 16                # $t3 = i*16
        add     $t3, $t0, $t3               # $t3 = bunnies_info + i*16
        add     $t3, $t3, 4                 # <$t3!> Bunny* b = &bunnies_info->info[i];

        # <$f3!> float cycles_from_bot_to_bunny = sqrt((bot->x - b->x)**2 + (bot->y - b->y)**2);
        lw      $t4, 0($t3)                 # $t4 = b->x
        lw      $t5, BOT_X($0)              # $t5 = bot->x
        sub     $t4, $t5, $t4               # $t4 = bot->x - b->x
        mtc1    $t4, $f3                    # $f3 <-- bot->x - b->x
        cvt.s.w $f3, $f3                    # $f3 = static_cast<float>(bot->x - b->x)
        mul.s   $f3, $f3, $f3               # $f3 = static_cast<float>(bot->x - b->x)**2

        lw      $t4, 4($t3)                 # $t4 = b->y
        lw      $t5, BOT_Y($0)              # $t5 = bot->y
        sub     $t4, $t5, $t4               # $t4 = bot->y - b->y
        mtc1    $t4, $f4                    # $f4 <-- bot-y - b->y
        cvt.s.w $f4, $f4                    # $f4 = static_cast<float>(bot-y - b->y)
        mul.s   $f4, $f4, $f4               # $f4 = static_cast<float>(bot-y - b->y)**2

        add.s   $f3, $f4, $f3               # $f3 = static_cast<float>(bot->x - b->x)**2 + static_cast<float>(bot->y - b->y)**2
        sqrt.s  $f3, $f3                    # <$f3!> float cycles_from_bot_to_bunny = sqrt((bot->x - b->x)**2 + (bot->y - b->y)**2);

        lw      $t4, 12($t3)                # $t4 = b->remaining_cycles;
        mtc1    $t4, $f4                    # $f4 <-- $t4
        cvt.s.w $f4, $f4                    # $f4 = static_cast<float>(b->remaining_cycles)

        c.le.s  $f4, $f3                    # FPCond = b->remaining_cycles <= cycles_from_bot_to_bunny
        bc1t    PBB_For_Inc                 # if (b->remaining_cycles {$f4} <= cycles_from_bot_to_bunny {$f3}) continue;

        # <$f4> float cycles_from_bunny_to_playpen = sqrt((playpen_x - b->x)**2 + (playpen_y - b->y)**2);
        lw      $t4, 0($t3)                 # $t4 = b->x
        la      $t5, playpen_x              # $t5 = &playpen_x
        lw      $t5, 0($t5)                 # $t5 = playpen_x
        sub     $t4, $t5, $t4               # $t4 = playpen_x - b->x
        mtc1    $t4, $f4                    # $f4 <-- playpen_x - b->x
        cvt.s.w $f4, $f4                    # $f4 = static_cast<float>(playpen_x - b->x)
        mul.s   $f4, $f4, $f4               # $f4 = static_cast<float>(playpen_x - b->x)**2

        lw      $t4, 4($t3)                 # $t4 = b->y
        la      $t5, playpen_y              # $t5 = &playpen_y
        lw      $t5, 0($t5)                 # $t5 = playpen_y
        sub     $t4, $t5, $t4               # $t4 = playpen_y - b->y
        mtc1    $t4, $f5                    # $f5 <-- playpen_y - b->y
        cvt.s.w $f5, $f5                    # $f5 = static_cast<float>(playpen_y - b->y)
        mul.s   $f5, $f5, $f5               # $f5 = static_cast<float>(playpen_y - b->y)**2

        add.s   $f4, $f4, $f5               # $f3 = static_cast<float>(playpen_x - b->x)**2 + static_cast<float>(playpen_y - b->y)**2
        sqrt.s  $f4, $f4                    # # <$f4> float cycles_from_bunny_to_playpen = sqrt((playpen_x - b->x)**2 + (playpen_y - b->y)**2);

        add.s   $f4, $f3, $f4               # <$f4> float travel_time = cycles_from_bot_to_bunny + cycles_from_bunny_to_playpen;
        lw      $t4, 8($t3)                 # $t4! = b->weight
        mtc1    $t4, $f5                    # $f5 <-- $t4
        cvt.s.w $f5, $f5                    # $f5 = static_cast<float>(b->weight)
        div.s   $f5, $f5, $f4               # <$f5!> float ratio = static_cast<float>(b->weight) / travel_time;

        PBB_For_If:
            c.le.s  $f5, $f2                # FPCond = ratio <= biggest_ratio
            bc1t    PBB_For_Elif            # if ratio <= biggest_ratio, goto PBB_For_Elif

            mov.s   $f2, $f5                # biggest_ratio = ratio;
            move    $v0, $t3                # best_bunny = b;
            mov.s   $f0, $f3                # best_bunny_dist = cycles_from_bot_to_bunny;

            j       PBB_For_Inc
        PBB_For_Elif:
            c.eq.s  $f5, $f2                # FPCond = ratio == biggest_ratio
            bc1f    PBB_For_Inc             # if ratio != biggest_ratio, goto PBB_For_Inc
            lw      $t5, 8($v0)             # $t5 = best_bunny->weight
            ble     $t4, $t5, PBB_For_Inc   # if b->weight <= best_bunny->weight, goto PBB_For_Inc

            mov.s   $f2, $f5                # biggest_ratio = ratio;
            move    $v0, $t3                # best_bunny = b;
            mov.s   $f0, $f3                # best_bunny_dist = cycles_from_bot_to_bunny;


        PBB_For_Inc:
            add     $t2, $t2, 1             # ++i;
            blt		$t2, $t1, PBB_For       # if i < bunnies_info->num_bunnies then goto PBB_For

        jr      $ra                         # return { best_bunny, best_bunny_dist };

# PickBestBunny:
#     la      $t0, bunnies_info
#     sw      $t0, SEARCH_BUNNIES($0)         # $t0 = bunnies_info
#     lw      $t1, 0($t0)                     # $t1 = bunnies_info->num_bunnies
#     add     $v0, $t0, 4                     # Bunny* best_bunny = &bunnies_info->info[0];
#     li      $v1, 0                          # float best_bunny_dist = 0;
#     li      $t2, 0                          # float biggest_ratio = 0;

#     li      $t3, 0                          # int i = 0;
#     PBB_For:
#         pythag  $t4                         # $t4 = cycles_from_bot_to_bunny

#         mul     $t5, $t3, 16                # $t5 = i * 16
#         add     $t5, $t0, $t5               # $t5 = &bunnies_info[i]
#         add     $t5, $t5, 12                # $t5 = &bunnies_info[i]->remaining_cycles
#         lw      $t6, 0($t5)                 # $t5 = bunnies_info[i]->remaining_cycles
#         # Make $t5 floating somehow and also the bge floating somehow
#         bge     $t6, $t4, PBB_For_Inc       # if bunnies_info[i]->remaining_cycles >= cycles_from_bot_to_bunny, jump to PBB_For_Inc

#         pythag  $t6                         # $t6 = cycles_from_bunny_to_playpen
#         add.s   $t6, $t4, $t6               # float travel_time = cycles_from_bot_to_bunny + cycles_from_bunny_to_playpen
#         sub     $t5, $t5, 4                 # $t5 = &bunnies_info[i]->weight
#         lw      $t7, 0($t5)                 # $t7 = bunnies_info[i]->weight
#         div.s   $t6, $t7, $t6               # float ratio = bunnies_info[i]->weight / (cycles_from_bot_to_bunny + cycles_from_bunny_to_playpen);

#         PBB_For_If:
#             ble		$t6, $t2, PBB_For_Elif  # if ratio <= biggest_ratio then goto PBB_For_Elif
            
#             move    $t2, $t6                # biggest_ratio = ratio;
#             sub     $t5, $t5, 8             # $t5 = &bunnies_info[0]
#             move    $v0, $t5                # best_bunny = bunnies_info[0];
#             move    $v1, $t4                # best_bunny_dist = cycles_from_bot_to_bunny;

#             j       PBB_For_Inc
#         PBB_For_Elif:
#             bne     $t6, $t2, PBB_For_Inc   # if ratio != biggest_ratio then goto PBB_For_Inc
#             lw      $t8, 8($v0)             # $t8 = best_bunny->weight
#             ble     $t7, $t8, PBB_For_Inc   # if weight <= best_bunny->weight then goto PBB_For_Inc

#             move    $t2, $t6                # biggest_ratio = ratio;
#             sub     $t5, $t5, 8             # $t5 = &bunnies_info[0]
#             move    $v0, $t5                # best_bunny = bunnies_info[0];
#             move    $v1, $t4                # best_bunny_dist = cycles_from_bot_to_bunny;

#         PBB_For_Inc:
#             add     $t3, $t3, 1             # ++i;
#             blt		$t4, $t1, PBB_For     # if i < bunnies_info->num_bunnies then goto PBB_For