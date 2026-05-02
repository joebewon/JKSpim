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

# import Atan2Lookup.s