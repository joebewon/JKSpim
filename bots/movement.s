.data
puzzle_received: .word 0
timer_received: .word 0
bunnies: .space 484 # allocate
.align 2 # to make sure that the next item starts at address div by 4 (may want to add this in other places)
puzzle_data: .space 300
.align 2
puzzle_sol: .space 256
puzzle_num: .word 0

# If you want, you can use the following to detect if a bonk has happened.
has_bonked: .byte 0
.align 2 # to make sure that the next item starts at address div by 4 (may want to add this in other places)

.text
main:

        la $t0, puzzle_data
        sw $t0, REQUEST_PUZZLE  # request immediately after starting


        # enable interrupts
        li      $t4     1
        or      $t4     $t4     TIMER_INT_MASK
        or      $t4,    $t4,    BONK_INT_MASK             # enable bonk interrupt
        or      $t4,    $t4,    REQUEST_PUZZLE_INT_MASK   # enable puzzle interrupt
        or      $t4,    $t4,    1 # global enable
        mtc0    $t4     $12

        li $t1, 0
        sw $t1, ANGLE
        li $t1, 1
        sw $t1, ANGLE_CONTROL
        li $t2, 0
        sw $t2, VELOCITY

        # YOUR CODE GOES HERE!!!!!!

 first_loop:
     lw $t0, puzzle_received
     beq $t0, $0, bunny_loop  # no puzzle -> go to finding bunnies
     lw $a0, puzzle_num  # get puzzle_num

     jal solve_puzzle

     # after solving
     lw $t1, puzzle_num # so we can match with which puzzle, this is why it wasn't solving but now fixed
     add $t1, $t1, 1
     sw $t1, puzzle_num # store after incrementing

     sw $0, puzzle_received  # after solving, clear and request new immediately
     la $t0, puzzle_data
     sw $t0, REQUEST_PUZZLE
     j bunny_loop

bunny_loop:
    la $s4, bunnies        
    sw $s4, SEARCH_BUNNIES   

wait_for_bunnies:
    lw $s5, 0($s4)  # how many bunnies
    beq $s5, $0, bunny_loop
    li $t4, 0  # start at 0

find_bunny: # make sure bunny won't hop in next 100,000 cycles
    li $t0, 16
    mul $t0, $t4, $t0  # index * 16

    add $t0, $s4, $t0  # add base address
    add $t0, $t0, 4  # find address of bunny

    # get current time and bunny's next hop time
    lw $t5, TIMER
    lw $t6, 12($t0) 

    sub $t6, $t6, $t5 # subtract current time from next hop time, how much time / cycles we have left
    li $t7, 100000 # 100,000 cycles
    bge $t6, $t7, found_bunny # make sure 100k+ remaining cycles

    add $t4, $t4, 1   # index increment
    blt $t4, $s5, find_bunny  # loop to find next bunny and check
    addi $t0, $s4, 4   # use bunnies[0] if no bunny valid
    j found_bunny

found_bunny:
    lw $a0, 0($t0)
    lw $a1, 4($t0)

    jal move_to_xy

    li $t1, 1
    sw $t1, CATCH_BUNNY # catch bunny after reaching

deliver_to_playpen:

    lw $t0, PLAYPEN_LOCATION
    srl $a0, $t0, 16 # for playpen X (upper 16 bits)
    sll $a1, $t0, 16  # remove upper bits
    srl $a1, $a1, 16  # for playpen Y (lower 16 bits)

    # now move diagonally to playpen since we can move in both x and y at the same time
    jal move_to_xy

    lw $t1, NUM_BUNNIES_CARRIED
    sw $t1, PUT_BUNNIES_IN_PLAYPEN 

    j first_loop 


# New Movement Subroutine Starts Here

move_to_xy:
# input (x,y) --> $a0, $a1
# output: bot moves to (x,y) using atan2 lookup table
# handle relative to target
# absolute angle move
# TO-DO

move_xy_loop:
    lw $t0, BOT_X
    lw $t1, BOT_Y

    sub $t2, $a0, $t0 # deltaX = targetX - botX
    sub $t3, $a1, $t1 # deltaY = targetY - botY

    move $t4, $t2 # for atan2 lookup
    slt $t6, $t4, $0
    beq $t6, $0, deltax_nonneg 
    sub $t4, $0, $t4 # abs(deltaX)

deltax_nonneg:
   move $t5, $t3 # for atan2 lookup
   slt $t6, $t5, $0
   beq $t6, $0, deltay_nonneg
   sub $t5, $0, $t5 # abs(deltaY)

deltay_nonneg:
   li $t6, 4
   bgt $t4, $t6, keep_moving 
   bgt $t5, $t6, keep_moving
   jr $ra # if both deltaX and deltaY are within threshold, we are done


keep_moving:
    # calculate angle to target using atan2 lookup table
    # set angle and velocity to move bot
    # loop until we reach target (within some threshold)
    li $t6, 601

    mul $t9, $t2, $t6 # deltaX * 601
    add $t9, $t9, $t3 # (deltaX * 601) + (deltaY)
    sll $t9, $t9, 2 

    la $t6, atan2lookup # base address of atan2 lookup table
    add $t6, $t6, $t9 # address of angle
    lw $t7, 0($t6) # angle

    sw $t7, ANGLE # set angle
    li $t8, 1
    sw $t8, ANGLE_CONTROL # move
    li $t8, 10 
    sw $t8, VELOCITY

    j move_xy_loop


solve_puzzle:
    sub $sp, $sp, 8  # allocate
    sw $ra, 0($sp)
    sw $s0, 4($sp)  # puzzle_num
    move $s0, $a0

    # zero out
    la $t0, puzzle_data
    lw $a0, 0($t0)  # num_rows
    lw $a1, 4($t0) # num_cols
    la $a2, puzzle_sol
    jal zero_board

    # solve 
    la $a0, puzzle_data
    la $a1, puzzle_sol
    li $a2, 0
    li $a3, 0
    jal solve

    sw $s0, CURRENT_PUZZLE  # before submitting so can be matched

    la $t0, puzzle_sol
    sw $t0, SUBMIT_SOLUTION    # submit soln!

    lw $ra, 0($sp)   # deallocate
    lw $s0, 4($sp)
    add $sp, $sp, 8
    jr $ra



# Once done, enter an infinite loop so that your bot can be graded by QtSpimbot once 10,000,000 cycles have elapsed
loop:
        j       loop