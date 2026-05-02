.data
.align 1
has_timer: .byte 1

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
    lb		$t0, 0($t0)                 # $t0 = has_timer
    beq     $t0, 0, interrupt_dispatch  # Shortcircuit if we are supposed to ignore this interrupt

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
    move    $at, $k1        # Restore $at
.set at
    eret

# import FSMTransitionFunction.s