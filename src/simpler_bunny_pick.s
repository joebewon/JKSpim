################## ################## import PickBestBunny.s ################## ##################
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
    #   $f0 (float): best_bunny_dist | The number of distance in pixels from the spimbot's current location to the best bunny
    PickBestBunny:
        la      $t0, bunnies_info
        sw      $t0, SEARCH_BUNNIES($0)         # <$t0!> BunniesInfo* bunnies_info = *SEARCH_BUNNIES;
        lw      $t1, 0($t0)                     # <$t1!> int num_bunnies = bunnies_info->num_bunnies;

        add     $v0, $t0, 4                     # <$v0!> Bunny* best_bunny = &bunnies_info->info[0];
        mtc1    $zero, $f0                      # <$f0!> float best_bunny_dist = 0.0f;
        
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

            PBB_For_If:
                c.le.s  $f3, $f2                # FPCond = cycles_from_bot_to_bunny <= best_bunny_dist
                bc1t    PBB_For_Elif            # if cycles_from_bot_to_bunny <= best_bunny_dist, goto PBB_For_Elif

                move    $v0, $t3                # best_bunny = b;
                mov.s   $f0, $f3                # best_bunny_dist = cycles_from_bot_to_bunny;

            PBB_For_Inc:
                add     $t2, $t2, 1             # ++i;
                blt		$t2, $t1, PBB_For       # if i < bunnies_info->num_bunnies then goto PBB_For

            jr      $ra                         # return { best_bunny, best_bunny_dist };
