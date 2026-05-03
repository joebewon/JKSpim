    CS2T:
        move    $a0, $s5                                    # $a0 = board_ptr
        lw      $a1, 36($sp)                                # $a1 = board_buff
        move    $a2, $s3                                    # $a2 = num_rows
        move    $a3, $s4                                    # $a3 = num_cols
        jal     CopyT                                       # CopyT(board_ptr, board_buff, num_rows, num_cols);

        lw      $s5, 36($sp)                                # $s5! = board_buff

        # First Pass
        li      $s0, 1                                      # <$s0!> int i = 1;
        CS2T_1Pass_OFor:
            bge     $s0, $s4, CS2T_1Pass_ORof               # if i >= num_cols, goto CS2T_1Pass_ORof
            li      $s1, 0                                  # <$s1!> int j = 0;
            CS2T_1Pass_IFor:
                bge     $s1, $s3, CS2T_1Pass_IRof           # if i >= num_rows, goto CS2T_1Pass_IRof

                # $t0 = board_buff[i - 1][j]
                sub     $t0, $s0, 1                         # $t0 = i - 1
                mul     $t0, $t0, $s3                       # $t0 = (i - 1)*num_rows
                add     $t0, $t0, $s1                       # $t0 = (i - 1)*num_rows + j
                add     $t0, $s5, $t0                       # $t0 = &board_buff[i - 1][j]
                lbu     $t0, 0($t0)                         # $t0 = board_buff[i - 1][j]
                bne     $t0, 1, CS2T_1Pass_IFor_Inc         # if board_buff[i - 1][j] != 1, goto CS2T_1Pass_IFor_Inc

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

                CS2T_1Pass_IFor_Inc:
                    add     $s1, $s1, 1
                    j       CS2T_1Pass_IFor
            CS2T_1Pass_IRof:
                # pass and directly increment i
                add     $s0, $s0, 1
                j       CS2T_1Pass_OFor
        CS2T_1Pass_ORof:
            # Done Check @todo - Something is wrong with the function
            move    $a0, $s5                                # $a0 = board_buff
            jal     BoardDone
            beq     $v0, 1, CS2_Return                      # if (BoardDone(board_buff)) return true;

            # const int last_row_residual = EncodeResidual2(board_buff, num_cols, num_rows);
            li      $s1, 0                                  # int j = 0;
            li      $t2, 0                                  # <$t2> int last_row_residual = 0;
            sub     $t0, $s4, 1                             # $t0 = num_cols - 1
            mul     $t0, $t0, $s3                           # $t0 = (num_cols - 1)*num_rows

        CS2T_Encode_Residual_For:
            bge     $s1, $s3, CS2T_Encode_Residual_Rof      # if j >= num_rows, goto CS2T_Encode_Residual_Rof
            add     $t1, $t0, $s1                           # $t1 = (num_cols - 1)*num_rows + j
            add     $t1, $s5, $t1                           # $t1 = &board_buff[num_cols - 1][j]
            lbu     $t1, 0($t1)                             # $t1 = board_buff[num_cols - 1][j]
            
            add     $t2, $t2, $t1                           # last_row_residual += board_buff[num_rows - 1][j];
            sll     $t2, $t2, 1                             # last_row_residual <<= 1;

            add     $s1, $s1, 1
            j CS2T_Encode_Residual_For

        CS2T_Encode_Residual_Rof:
            # CLTLUT2 $t3, $s4, $s3 - Somehow @TODO - Assume $t3 has the correct address for now
            mul     $t2, $t2, 2                             # $t2 = last_row_residual*2
            add     $t3, $t3, $t2                           # $t3 = &CLT_LUT_2[num_cols][num_rows][last_row_residual]
            lhu     $t3, 0($t3)                             # <$t3?> int first_row_enumerate = CLT_LUT_2[num_cols][num_rows][last_row_residual];

            move    $v0, $0
            beq     $t3, $0, CS2_Return                     # if first_row_enumerate == 0, return false;

        move    $s1, $0                                     # int j = 0;
        CS2T_Toggle_Top_For:
            bge     $s1, $s3, CS2T_Toggle_Top_Rof           # if j >= num_rows, goto CS2T_Toggle_Top_Rof
            srlv    $t4, $t3, $s1                           # $t4 = first_row_enumerate >> j
            and     $t4, $t4, 1                             # $t4 = (first_row_enumerate >> j) & 1
            bne     $t4, 1, CS2T_Toggle_Top_For_Inc         # if ((first_row_enumerate >> j) & 1) != 1, goto CS2T_Toggle_Top_For_Inc
            
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

            CS2T_Toggle_Top_For_Inc:
                add     $s1, $s1, 1                         # ++j;
                j       CS2T_Toggle_Top_For

        CS2T_Toggle_Top_Rof:
            # Second Pass
            li      $s0, 1                                  # <$s0!> int i = 1;
        CS2T_2Pass_OFor:
            bge     $s0, $s4, CS2T_2Pass_ORof               # if i >= num_cols, goto CS2T_2Pass_ORof
            li      $s1, 0                                  # <$s1!> int j = 0;
            CS2T_2Pass_IFor:
                bge     $s1, $s3, CS2T_2Pass_IRof           # if i >= num_rows, goto CS2T_2Pass_IRof

                # $t0 = board_buff[i - 1][j]
                sub     $t0, $s0, 1                         # $t0 = i - 1
                mul     $t0, $t0, $s3                       # $t0 = (i - 1)*num_rows
                add     $t0, $t0, $s1                       # $t0 = (i - 1)*num_rows + j
                add     $t0, $s5, $t0                       # $t0 = &board_buff[i - 1][j]
                lbu     $t0, 0($t0)                         # $t0 = board_buff[i - 1][j]
                bne     $t0, 1, CS2T_2Pass_IFor_Inc         # if board_buff[i - 1][j] != 1, goto CS2T_2Pass_IFor_Inc

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

                CS2T_2Pass_IFor_Inc:
                    add     $s1, $s1, 1
                    j       CS2T_2Pass_IFor
            CS2T_2Pass_IRof:
                # pass and directly increment i
                add     $s0, $s0, 1
                j       CS2T_2Pass_OFor
        CS2T_2Pass_ORof:
            li      $v0, 1                                  # $v0 = true
            j       CS2_Return                              # return true;