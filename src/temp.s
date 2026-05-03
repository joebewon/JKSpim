# @function
#
# Solves a puzzle using a Chase The Lights Lookup Table for num_colors = 3
#
# @UsedTemporaries: None
#
# @Params: None
#
# @Returns:
# - $v0 (bool): Solved the Puzzle Correctly
CTLSolve3:
    # Stack Allocation
    sub     $sp, $sp, 40
    sw      $ra, 0($sp)

    sw      $s0, 4($sp)
    sw      $s1, 8($sp)
    sw      $s2, 12($sp)
    sw      $s3, 16($sp)
    sw      $s4, 20($sp)
    sw      $s5, 24($sp)

    sw      $a0, 28($sp)
    sw      $a1, 32($sp)
    sw      $a2, 36($sp)

    # Preprocessing
    move    $s2, $a1                                        # $s2! = solution
    lw      $s3, 0($a0)                                     # <$s3!> const int num_rows = puzzle->num_rows;
    lw      $s4, 4($a0)                                     # <$s4!> const int num_cols = puzzle->num_cols;
    add     $s5, $a0,12                                     # <$s5?> unsigned char* board_ptr = &puzzle->board;
    
    move    $a0, $s3                                        # $a0 = num_rows
    move    $a1, $s4                                        # $a1 = num_cols
    move    $a2, $s2                                        # $a2 = solution
    jal     ZeroBoard

    ble     $s3, 7, CS3                                     # if num_rows <= 7, goto CS3
    ble     $s4, 7, CS3                                     # if num_cols <= 7, goto CS3
    move    $v0, $0                                         # $v0 = false;
    j       CS3_Return                                      # return false;

    CS3:
        bgt     $s4, $s3, CS3T                                  # if num_cols > num_rows, goto CS3T
    CS3N:
        # First Pass
        li      $s0, 1                                      # <$s0!> int i = 1;
        CS3N_1Pass_OFor:
            bge     $s0, $s3, CS3N_1Pass_ORof               # if i >= num_rows, goto CS3N_1Pass_ORof
            li      $s1, 0                                  # <$s1!> int j = 0;
            CS3N_1Pass_IFor:
                bge     $s1, $s4, CS3N_1Pass_IRof           # if i >= num_cols, goto CS3N_1Pass_IRof

                # $t0 = board_ptr[i - 1][j]
                sub     $t0, $s0, 1                         # $t0 = i - 1
                mul     $t0, $t0, $s4                       # $t0 = (i - 1)*num_cols
                add     $t0, $t0, $s1                       # $t0 = (i - 1)*num_cols + j
                add     $t0, $s5, $t0                       # $t0 = &board_ptr[i - 1][j]
                lbu     $t0, 0($t0)                         # <$t0> int val = board_ptr[i - 1][j]
                beq     $t0, 0, CS3N_1Pass_IFor_Inc         # if board_ptr[i - 1][j] == 0, goto CS3N_1Pass_IFor_Inc

                # solution[i][j] = 1;
                mul     $t1, $s0, $s4                       # $t1 = i*num_cols
                add     $t1, $t1, $s1                       # $t1 = i*num_cols + j
                add     $t1, $s2, $t1                       # $t1 = &solution[i][j]
                li      $t2, 3                              # $t1 = 3
                sub     $t2, $t2, $t0                       # <$t2> int action = 3 - val;
                sb      $2, 0($t1)                          # solution[i][j] = action;

                move    $a0, $s5                            # $a0 = board_ptr
                move    $a1, $s0                            # $a1 = i
                move    $a2, $s1                            # $a2 = j
                li      $a3, $t2                            # $a3 = action
                jal     ToggleLight                         # ToggleLight(board_ptr, i, j, 1);

                CS3N_1Pass_IFor_Inc:
                    add     $s1, $s1, 1
                    j       CS3N_1Pass_IFor
            CS3N_1Pass_IRof:
                # pass and directly increment i
                add     $s0, $s0, 1
                j       CS3N_1Pass_OFor
        CS3N_1Pass_ORof:
            move    $a0, $s3                                # $a0 = num_rows
            move    $a1, $s4                                # $a1 = num_cols
            move    $a2, $s5                                # $a2 = board_ptr
            jal     BoardDone
            beq     $v0, 1, CS3_Return                      # if (BoardDone(num_rows, num_cols, board_ptr)) return true;

            # const int last_row_residual = EncodeResidual3(board_ptr, num_rows, num_cols);
            li      $s1, 0                                  # int j = 0;
            li      $t2, 0                                  # <$t2> int last_row_residual = 0;
            sub     $t0, $s3, 1                             # $t0 = num_rows - 1
            mul     $t0, $t0, $s4                           # $t0 = (num_rows - 1)*num_cols
        CS3N_Encode_Residual_For:
            bge     $s1, $s4, CS3N_Encode_Residual_Rof      # if j >= num_cols, goto CS3N_Encode_Residual_Rof
            add     $t1, $t0, $s1                           # $t1 = (num_rows - 1)*num_cols + j
            add     $t1, $s5, $t1                           # $t1 = &board_ptr[num_rows - 1][j]
            lbu     $t1, 0($t1)                             # $t1 = board_ptr[num_rows - 1][j]
            
            mul     $t2, $t2, 3                             # last_row_residual *= 3;
            add     $t2, $t2, $t1                           # last_row_residual += board_ptr[num_rows - 1][j];

            add     $s1, $s1, 1
            j CS3N_Encode_Residual_For

        CS3N_Encode_Residual_Rof:
            # CLTLUT3 $t3, $s3, $s4 - Somehow @TODO - Assume $t3 has the correct address for now
            mul     $t2, $t2, 2                             # $t2 = last_row_residual*2
            add     $t3, $t3, $t2                           # $t3 = &CLT_LUT_3[num_rows][num_cols][last_row_residual]
            lw      $t3, 0($t3)                             # <$t3?> int first_row_enumerate = CLT_LUT_3[num_rows][num_cols][last_row_residual];

            move    $v0, $0
            beq     $t3, $0, CS3_Return                     # if first_row_enumerate == 0, return false;

        move    $s1, $0                                     # int j = 0;
        CS3N_Toggle_Top_For:
            bge     $s1, $s4, CS3N_Toggle_Top_Rof           # if j >= num_cols, goto CS3N_Toggle_Top_Rof
            mul     $t0, $s2, 2                             # $t0 = j*2
            srlv    $t4, $t3, $t0                           # $t4 = first_row_enumerate >> (j*2)
            and     $t4, $t4, 3                             # <$t4?> int action = ((first_row_enumerate >> (j*2)) & 3);
            beq     $t4, 0, CS3N_Toggle_Top_For_Inc         # if action == 0, goto CS3N_Toggle_Top_For_Inc
            
            # solution[0][j] += action;
            # solution[0][j] -= (solution[0][j] >= 3) * 3;
            add     $t5, $s2, $s1                           # $t5 = &solution[0][j] equiv solution + j
            lbu     $t6, 0($t5)                             # $t6 = solution[0][j]
            add     $t6, $t6, $t4                           # $t6 = solution[0][j] + action equiv. solution[0][j] += action;
            sgeu    $t7, $t6, 3                             # $t7 = solution[0][j] {$t6} >= 3 ? 1 : 0
            mul     $t7, $t7, 3                             # $t7 = ((solution[0][j]+ action) >= 3) * 3
            sub     $t6, $t6, $t7                           # $t6 -= ((solution[0][j] + action) >= 3) * 3
            sb      $t6, 0($t4)                             # solution[0][j] -= (solution[0][j] >= 3) * 3;

            # ToggleLight(board_ptr, 0, j, 1);
            move    $a0, $s5                                # $a0 = board_ptr
            move    $a1, $0                                 # $a1 = 0
            move    $a2, $s1                                # $a2 = j
            li      $a3, $t4                                # $a3 = action
            jal     ToggleLight                              # ToggleLight(board_ptr, 0, j, action);

            CS3N_Toggle_Top_For_Inc:
                add     $s1, $s1, 1                         # ++j;
                j       CS3N_Toggle_Top_For

        CS3N_Toggle_Top_Rof:
            # Second Pass
            li      $s0, 1                                  # <$s0!> int i = 1;
        CS3N_2Pass_OFor:
            bge     $s0, $s3, CS3N_2Pass_ORof               # if i >= num_rows, goto CS3N_2Pass_ORof
            li      $s1, 0                                  # <$s1!> int j = 0;
            CS3N_2Pass_IFor:
                bge     $s1, $s4, CS3N_2Pass_IRof           # if i >= num_cols, goto CS3N_2Pass_IRof

                # $t0 = board_ptr[i - 1][j]
                sub     $t0, $s0, 1                         # $t0 = i - 1
                mul     $t0, $t0, $s4                       # $t0 = (i - 1)*num_cols
                add     $t0, $t0, $s1                       # $t0 = (i - 1)*num_cols + j
                add     $t0, $s5, $t0                       # $t0 = &board_ptr[i - 1][j]
                lbu     $t0, 0($t0)                         # $t0 int val = board_ptr[i - 1][j]
                beq     $t0, 0, CS3N_2Pass_IFor_Inc         # if val == 0, goto CS3N_2Pass_IFor_Inc

                li      $t1, 3                              # $t1 = 3
                sub     $t0, $t1, $t0                       # <$t0?> int action = 3 - val;
                # solution[i][j] += action;
                # solution[i][j] -= (solution[i][j] >= 3) * 3;
                mul     $t1, $s0, $s4                       # $t1 = i*num_cols
                add     $t1, $t1, $s1                       # $t1 = i*num_cols + j
                add     $t1, $s2, $t1                       # $t1 = &solution[i][j]
                lbu     $t2, 0($t1)                         # $t2 = solution[i][j]
                add     $t2, $t2, $t0                       # $t2 = solution[i][j] + action equiv. solution[i][j] += action;
                sgeu    $t3, $t2, 3                         # $t3 = solution[i][j] + action {$t1} >= 3 ? 1 : 0
                mul     $t3, $t3, 3                         # $t7 = ((solution[i][j]v+ action) >= 3) * 3
                sub     $t2, $t2, $t3                       # $t2 -= ((solution[i][j] + action) >= 3) * 3
                sb      $t2, 0($t1)                         # solution[i][j] -= (solution[i][j] >= 3) * 3;

                # ToggleLight(board_ptr, i, j, 1);
                move    $a0, $s5                            # $a0 = board_ptr
                move    $a1, $s0                            # $a1 = i
                move    $a2, $s1                            # $a2 = j
                li      $a3, $t0                            # $a3 = action
                jal     ToggleLight                         # ToggleLight(board_ptr, i, j, 1);

                CS3N_2Pass_IFor_Inc:
                    add     $s1, $s1, 1
                    j       CS3N_2Pass_IFor
            CS3N_2Pass_IRof:
                # pass and directly increment i
                add     $s0, $s0, 1
                j       CS3N_2Pass_OFor
        CS3N_2Pass_ORof:
            li      $v0, 1                                  # $v0 = true
            j       CS3_Return                              # return true;

    CS3T:
        move    $a0, $s5                                    # $a0 = board_ptr
        lw      $a1, 36($sp)                                # $a1 = board_buff
        move    $a2, $s3                                    # $a2 = num_rows
        move    $a3, $s4                                    # $a3 = num_cols
        jal     CopyT                                       # CopyT(board_ptr, board_buff, num_rows, num_cols);

        lw      $s5, 36($sp)                                # $s5! = board_buff

        # First Pass
        li      $s0, 1                                      # <$s0!> int i = 1;
        CS3T_1Pass_OFor:
            bge     $s0, $s4, CS3T_1Pass_ORof               # if i >= num_cols, goto CS3T_1Pass_ORof
            li      $s1, 0                                  # <$s1!> int j = 0;
            CS3T_1Pass_IFor:
                bge     $s1, $s3, CS3T_1Pass_IRof           # if i >= num_rows, goto CS3T_1Pass_IRof

                # $t0 = board_buff[i - 1][j]
                sub     $t0, $s0, 1                         # $t0 = i - 1
                mul     $t0, $t0, $s3                       # $t0 = (i - 1)*num_rows
                add     $t0, $t0, $s1                       # $t0 = (i - 1)*num_rows + j
                add     $t0, $s5, $t0                       # $t0 = &board_buff[i - 1][j]
                lbu     $t0, 0($t0)                         # $t0 = board_buff[i - 1][j]
                bne     $t0, 1, CS3T_1Pass_IFor_Inc         # if board_buff[i - 1][j] != 1, goto CS3T_1Pass_IFor_Inc

                # solution[j][i] = 1;
                mul     $t0, $s1, $s4                       # $t0 = j*num_cols
                add     $t0, $t0, $s0                       # $t0 = j*num_cols + i
                add     $t0, $s2, $t0                       # $t0 = &solution[j][i]
                li      $t1, 1                              # $t1 = 1
                sb      $t1, 0($t0)                         # solution[j][i] = 1;

                # ToggleLight(board_buff, i, j, 1);
                move    $a0, $s5                            # $a0 = board_buff
                move    $a1, $s0                            # $a1 = i
                move    $a2, $s1                            # $a2 = j
                li      $a3, 1                              # $a3 = 1
                jal     ToggleLight                         # ToggleLight(board_buff, i, j, 1);

                CS3T_1Pass_IFor_Inc:
                    add     $s1, $s1, 1
                    j       CS3T_1Pass_IFor
            CS3T_1Pass_IRof:
                # pass and directly increment i
                add     $s0, $s0, 1
                j       CS3T_1Pass_OFor
        CS3T_1Pass_ORof:
            move    $a0, $s4                                # $a0 = num_cols
            move    $a1, $s3                                # $a1 = num_rows
            move    $a2, $s5                                # $a2 = board_buff
            jal     BoardDone
            beq     $v0, 1, CS3_Return                      # if (BoardDone(num_cols, num_rows, board_buff)) return true;

            # const int last_row_residual = EncodeResidual2(board_buff, num_cols, num_rows);
            li      $s1, 0                                  # int j = 0;
            li      $t2, 0                                  # <$t2> int last_row_residual = 0;
            sub     $t0, $s4, 1                             # $t0 = num_cols - 1
            mul     $t0, $t0, $s3                           # $t0 = (num_cols - 1)*num_rows

        CS3T_Encode_Residual_For:
            bge     $s1, $s3, CS3T_Encode_Residual_Rof      # if j >= num_rows, goto CS3T_Encode_Residual_Rof
            add     $t1, $t0, $s1                           # $t1 = (num_cols - 1)*num_rows + j
            add     $t1, $s5, $t1                           # $t1 = &board_buff[num_cols - 1][j]
            lbu     $t1, 0($t1)                             # $t1 = board_buff[num_cols - 1][j]
            
            mul     $t2, $t2, 3                             # last_row_residual *= 3;
            add     $t2, $t2, $t1                           # last_row_residual += board_ptr[num_rows - 1][j];

            add     $s1, $s1, 1
            j CS3T_Encode_Residual_For

        CS3T_Encode_Residual_Rof:
            # CLTLUT3 $t3, $s4, $s3 - Somehow @TODO - Assume $t3 has the correct address for now
            mul     $t2, $t2, 2                             # $t2 = last_row_residual*2
            add     $t3, $t3, $t2                           # $t3 = &CLT_LUT_3[num_cols][num_rows][last_row_residual]
            lhu     $t3, 0($t3)                             # <$t3?> int first_row_enumerate = CLT_LUT_3[num_cols][num_rows][last_row_residual];

            move    $v0, $0
            beq     $t3, $0, CS3_Return                     # if first_row_enumerate == 0, return false;

        move    $s1, $0                                     # int j = 0;
        CS3T_Toggle_Top_For:
            bge     $s1, $s3, CS3T_Toggle_Top_Rof           # if j >= num_rows, goto CS3T_Toggle_Top_Rof
            srlv    $t4, $t3, $s1                           # $t4 = first_row_enumerate >> j
            and     $t4, $t4, 1                             # $t4 = (first_row_enumerate >> j) & 1
            bne     $t4, 1, CS3T_Toggle_Top_For_Inc         # if ((first_row_enumerate >> j) & 1) != 1, goto CS3T_Toggle_Top_For_Inc
            
            # solution[j][0] = 1 - solution[j][0];
            mul     $t4, $s1, $s4                           # $t4 = j*num_cols
            add     $t4, $s2, $t4                           # $t4 = &solution[j][0] equiv solution + j*num_cols
            lbu     $t5, 0($t4)                             # $t5 = solution[j][0]
            li      $t6, 1                                  # $t6 = 1
            sub     $t5, $t6, $t5                           # $t5 = 1 - solution[j][0]
            sb      $t5, 0($t4)                             # solution[j][0] = 1 - solution[j][0];

            # ToggleLight(board_buff, 0, j, 1);
            move    $a0, $s5                                # $a0 = board_buff
            move    $a1, $0                                 # $a1 = 0
            move    $a2, $s1                                # $a2 = j
            li      $a3, 1                                  # $a3 = 1
            jal ToggleLight                                 # ToggleLight(board_buff, 0, j, 1);

            CS3T_Toggle_Top_For_Inc:
                add     $s1, $s1, 1                         # ++j;
                j       CS3T_Toggle_Top_For

        CS3T_Toggle_Top_Rof:
            # Second Pass
            li      $s0, 1                                  # <$s0!> int i = 1;
        CS3T_2Pass_OFor:
            bge     $s0, $s4, CS3T_2Pass_ORof               # if i >= num_cols, goto CS3T_2Pass_ORof
            li      $s1, 0                                  # <$s1!> int j = 0;
            CS3T_2Pass_IFor:
                bge     $s1, $s3, CS3T_2Pass_IRof           # if i >= num_rows, goto CS3T_2Pass_IRof

                # $t0 = board_buff[i - 1][j]
                sub     $t0, $s0, 1                         # $t0 = i - 1
                mul     $t0, $t0, $s3                       # $t0 = (i - 1)*num_rows
                add     $t0, $t0, $s1                       # $t0 = (i - 1)*num_rows + j
                add     $t0, $s5, $t0                       # $t0 = &board_buff[i - 1][j]
                lbu     $t0, 0($t0)                         # $t0 = board_buff[i - 1][j]
                bne     $t0, 1, CS3T_2Pass_IFor_Inc         # if board_buff[i - 1][j] != 1, goto CS3T_2Pass_IFor_Inc

                # solution[j][i] = 1 - solution[j][i];
                mul     $t0, $s1, $s4                       # $t0 = j*num_cols
                add     $t0, $t0, $s0                       # $t0 = j*num_cols + i
                add     $t0, $s2, $t0                       # $t0 = &solution[j][i]
                lbu     $t1, 0($t0)                         # $t1 = solution[j][i]
                li      $t2, 1                              # $t2 = 1
                sub     $t1, $t2, $t1                       # $t1 = 1 - solution[j][i]
                sb      $t1, 0($t0)                         # solution[j][i] = 1 - solution[j][i];

                # ToggleLight(board_buff, i, j, 1);
                move    $a0, $s5                            # $a0 = board_buff
                move    $a1, $s0                            # $a1 = i
                move    $a2, $s1                            # $a2 = j
                li      $a3, 1                              # $a3 = 1
                jal     ToggleLight                         # ToggleLight(board_buff, i, j, 1);

                CS3T_2Pass_IFor_Inc:
                    add     $s1, $s1, 1
                    j       CS3T_2Pass_IFor
            CS3T_2Pass_IRof:
                # pass and directly increment i
                add     $s0, $s0, 1
                j       CS3T_2Pass_OFor
        CS3T_2Pass_ORof:
            li      $v0, 1                                  # $v0 = true
            j       CS3_Return                              # return true;
    CS3_Return:
        lw      $ra, 0($sp)

        lw      $s0, 4($sp)
        lw      $s1, 8($sp)
        lw      $s2, 12($sp)
        lw      $s3, 16($sp)
        lw      $s4, 20($sp)
        lw      $s5, 24($sp)

        add     $sp, $sp, 40
        jr      $ra
