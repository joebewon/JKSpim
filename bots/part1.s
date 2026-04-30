### syscall constants
PRINT_STRING            = 4
PRINT_CHAR              = 11
PRINT_INT               = 1

### MMIO addrs
ANGLE                   = 0xffff0014
ANGLE_CONTROL           = 0xffff0018
VELOCITY                = 0xffff0010

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

BONK_INT_MASK           = 0x1000      ## Bonk
BONK_ACK                = 0xffff0060  ## Bonk
TIMER_INT_MASK          = 0x8000      ## Timer
TIMER_ACK               = 0xffff006c  ## Timer
EX_CARRY_LIMIT_INT_MASK = 0x4000      ## Exceeding Carry Limit
EX_CARRY_LIMIT_ACK      = 0xffff002c  ## Exceeding Carry Limit

MMIO_STATUS             = 0xffff204c

.data
.align 2
bunnies: .space 484
# If you want, you can use the following to detect if a bonk has happened.
has_bonked: .byte 0

.text
main:
    # enable interrupts
    li      $t4     1
    or      $t4     $t4     TIMER_INT_MASK
    or      $t4,    $t4,    BONK_INT_MASK             # enable bonk interrupt
    or      $t4,    $t4,    1 # global enable
    mtc0    $t4     $12

    li $t1, 0
    sw $t1, ANGLE
    li $t1, 1
    sw $t1, ANGLE_CONTROL
    li $t2, 0
    sw $t2, VELOCITY

    # YOUR CODE GOES HERE!!!!!!

    # searching for bunnies
bunny_loop:
    la $s4, bunnies        
    sw $s4, SEARCH_BUNNIES   

wait_for_bunnies:
    lw $s5, 0($s4)  # how many bunnies
    beq $s5, $0, bunny_loop
    addi $t0, $s4, 4 # for first bunny
    lw $s0, 0($t0)          
    lw $s1, 4($t0)          


# dealing with x-coordinate
x_loop:
    lw $t1, BOT_X # curr. x
    beq $t1, $s0, stop_x # has bot reached bunny?

    blt $t1, $s0, move_right # current position < bunny's position
    li $t2, 180  # if not, then we have to go other way
    j move_x

move_right:
    li $t2, 0

move_x:
    # set angle and turn it
    sw $t2, ANGLE  
    li $t2, 1
    sw $t2, ANGLE_CONTROL
    li $t2, 10
    sw $t2, VELOCITY
    j x_loop # until reach bunny's x-coordinate

stop_x:
    sw $0, VELOCITY   # stop if we have reached

# dealing with y-coordinate
y_loop:
    lw $t1, BOT_Y # curr. y
    beq $t1, $s1, stop_y # has bot reached bunny?

    blt $t1, $s1, move_south # current position < bunny's position
    li $t2, 270  # if not, then we have to go other way
    j move_y

move_south:
    li $t2, 90

move_y:
    # set angle and turn it
    sw $t2, ANGLE  
    li $t2, 1
    sw $t2, ANGLE_CONTROL
    li $t2, 10
    sw $t2, VELOCITY
    j y_loop # until reach bunny's x-coordinate

stop_y:
    sw $0, VELOCITY   # stop if we have reached
    li $t1, 1
    sw $t1, CATCH_BUNNY



# playpen logic

    lw $t0, PLAYPEN_LOCATION
    srl $s2, $t0, 16 # for playpen X (upper 16 bits)
    sll $s3, $t0, 16 
    srl $s3, $s3, 16  # for playpen Y (lower 16 bits)

# horizontal movement
playpen_x:

    lw $t1, BOT_X   # get X pos.
    beq $t1, $s2, stop_x_and_move_y  # if X reached, move to Y
    blt $t1, $s2, go_right  #  current position < target position
    li $t2, 180 # else go left
    j deliver_x

go_right:
    li $t2, 0

deliver_x:
    sw $t2, ANGLE  
    li $t3, 1
    sw $t3, ANGLE_CONTROL # absolute angle
    li $t3, 10
    sw $t3, VELOCITY
    j playpen_x # until we match x-coord.

stop_x_and_move_y:
    sw $0, VELOCITY


# vertical playpen
playpen_y:

    lw $t1, BOT_Y   # get X pos.
    beq $t1, $s3, stop_y_and_deliver  # if X reached, move to Y
    blt $t1, $s3, go_south  #  current position < target position
    li $t2, 270 # else go up
    j deliver_y

go_south:
    li $t2, 90

deliver_y:
    sw $t2, ANGLE  
    li $t3, 1
    sw $t3, ANGLE_CONTROL # absolute angle
    li $t3, 10
    sw $t3, VELOCITY
    j playpen_y # until we match y-coord.

stop_y_and_deliver:
    sw $0, VELOCITY

    lw $t1, NUM_BUNNIES_CARRIED 
    sw $t1, PUT_BUNNIES_IN_PLAYPEN
      
    j bunny_loop             


# Once done, enter an infinite loop so that your bot can be graded by QtSpimbot once 10,000,000 cycles have elapsed
loop:
        j       loop

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


interrupt_dispatch:                 # Interrupt:
    mfc0    $k0, $13                # Get Cause register, again
    beq     $k0, 0, done            # handled all outstanding interrupts

    and     $a0, $k0, BONK_INT_MASK     # is there a bonk interrupt?
    bne     $a0, 0, bonk_interrupt

    and     $a0, $k0, TIMER_INT_MASK    # is there a timer interrupt?
    bne     $a0, 0, timer_interrupt

    li      $v0, PRINT_STRING       # Unhandled interrupt types
    la      $a0, unhandled_str
    syscall
    j       done

bonk_interrupt:
    sw      $0, BONK_ACK
    #Fill in your bonk handler code here
    j       interrupt_dispatch      # see if other interrupts are waiting

timer_interrupt:
    sw      $0, TIMER_ACK
    #Fill in your timer interrupt code here
    j       interrupt_dispatch      # see if other interrupts are waiting

non_intrpt:                         # was some non-interrupt
    li      $v0, PRINT_STRING
    la      $a0, non_intrpt_str
    syscall                         # print out an error message
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
