# Optimized Puzzle Solving

## First Row Enumeration

The instructors of the class gave us a recusive implementation of a First Row Enumeration Algorithm (FRE). However, as answered in [this thread on the CS 233 SP2026 Discord](https://discord.com/channels/1140638642851823656/1495511240586301601), `num_lights` will only ever be 2 or 3, meaning that there are optimizations that we can make to it.

### Runtime Analysis

They way FRE works is that, for every possible change in the top row $(l^m)$, we have a determined set of toggles to the following cells in row major order that we must apply to get us to the solved state $((n - 1)(m - 1))$. So what the algorithm does, is try that determined set of toggles for every possible change in the top row.

We are essentially setting the top row, then foreach subsequent row, only toggling the lights that will solve the previous row.

From this, we see that FRE is $O(l^m n m)$ where,
- $n$ is the number of rows
- $m$ is the number of columns
- $l$ is the number of possible light states

### Optimizations

All of this lends to the following immediate optimizations
- `board_done` only needs to check the bottom row
- If $n < m$, it is always better to tranpose the matrix as $n < m \rightarrow l^m < l^n$
- Make FRE iterative, as much as possible.

Then, we can do even better by aggressively taking advantage of the fact that $l$ can only be $2$ and $3$ by splitting the algoithm into those two cases.

#### `board_done`

We can aggresivly optimize `board_done` from $O(nm)$ to $O(m)$ by one, only checking the last row, and two, since there are a maximum of 16 bytes in each row, loading all 16 bytes directly into 4 words, adding them together, and checking if the sum is zero, bringing it to $O(m)$ to $O(1)$.

```c++
// -------------- optimized board_done
bool Board(unsigned char* board) {
    // Using an array to make pseudo code syntax short for doc purposes
    // Would actually load all four words directly into registers
    std::array<uint32_t, 4> words;
    // I don't care if there not word aligned, I want them now!!!
    const unsigned char* last_row = &board[15][0];
    std::memcpy(&words[0], last_row + 0, 4);
    std::memcpy(&words[1], last_row + 4, 4);
    std::memcpy(&words[2], last_row + 8, 4);
    std::memcpy(&words[3], last_row + 12, 4);

    return  !(words[0] | words[1] | words[2] | words[3]);
}
```

After some research, I found the `lwl` and `lwr` instructions in the MIPS ISA. In our case, the four `memcpy`s would become the following,

```mips
# $t9 = &board[15][0]

lwl $t0, 0($t9)
lwr $t0, 3($t9)

lwl $t1, 4($t9)
lwr $t1, 7($t9)

lwl $t2, 8($t9)
lwr $t2, 11($t9)

lwl $t3, 12($t9)
lwr $t3, 15($t9)
```

This is always better than a for loop, because a single iteration of the equivalent loop is at minimum 8 instructions.

However, we also need to zero out the tail of the board or else we will have dirty cells. However, since the last row will always fit inside the puzzle struct, we can have a lookup table that gives us the four bit masks to use on the four words. See [ZeroTailMaskLookup.s](/JKSpim/src/ZeroTailMaskLookup.s)

#### TEMP
```c++
// This is pseudocode, so the syntax isn't perfect
// This is not meant to be directly compiled

// ------------- num_lights == 2 case
bool fre_solve_2(LightsOuts* puzzle, unsigned char* solution, unsigned char* board_buff) {
    const int num_rows = puzzle->num_rows;
    const int num_cols = puzzle->num_cols;
    unsigned char* board_ptr = &puzzle->board;

    if (num_cols <= num_rows) {
        const uint32_t permutations = 2**num_cols;
        for (uint16_t mask = 0; mask < permutations; ++mask) {
            copy(board_ptr, board_buff, num_rows, num_cols);
            zero_board(solution, num_rows, num_cols);
    
            // i is directly the bit mask of how to toggle the top row
            // s.t. we toggle top_row[j] iff b_j == 1
            for (uint8_t j = 0; j < num_cols; ++j) {
                if ((mask >> j) & 1 == 1) {
                    toggle_light(board_buff, 0, j, 1);
                    solution[0][j] = 1;
                }
            }
    
            // Row major order iteration
            // Remember, our desired endstate is when all lights are 0,
            // so toggle iff the cell directly above the current cell is 1,
            // because we need to turn it off
            for (uint8_t i = 1; i < num_rows; ++i) {
                for (uint8_t j = 0; j < num_cols; ++j) {
                    if (board_buff[i - 1][j] == 1) {
                        toggle_light(board_buff, i, j, 1);
                        solution[i][j] = 1;
                    }
                }
            }
    
            if (board_done(board_buff)) return true;
        }
        
        return false;
    } else {
        const uint32_t permutations = 2**num_rows;
        for (uint16_t mask = 0; mask < permutations; ++mask) {
            // Remember, all indexing is on the transposed matrix, so it looks identical.
            // The only difference between this and the previous clause are the bounds,
            // and that we have to reverse the indexing into solution.

            // Transpose the board on copy.
            copy_T(board_ptr, board_buff, num_rows, num_cols);

            // Don't transpose when zeroing the board
            zero_board(solution, num_rows, num_cols);
    
            // i is directly the bit mask of how to toggle the top row
            // s.t. we toggle top_column[j] iff b_j == 1
            for (uint8_t j = 0; j < num_rows; ++j) {
                if ((mask >> j) & 1 == 1) {
                    toggle_light(board_buff, 0, j, 1);
                    solution[j][0] = 1; // Remember to reverse the indexing
                }
            }
    
            // Column major order iteration
            // Remember, our desired endstate is when all lights are 0,
            // so toggle iff the cell directly above the current cell is 1,
            // because we need to turn it off
            for (uint8_t i = 1; i < num_cols; ++i) {
                for (uint8_t j = 0; j < num_rows; ++j) {
                    if (board_buff[i - 1][j] == 1) {
                        toggle_light(board_buff, i, j, 1);
                        solution[j][i] = 1; // Remember to reverse the indexing
                    }
                }
            }
    
            if (board_done(board_buff)) return true;
        }
        
        return false;
    }
}
```

## Chase the Lights

Chase the lights is the most common algorithm that solves this puzzle. The idea is that, for a certain board configuration, every last row residual, corresponds to being unsolvable or at least one first row enumerate.

In other words, the following algorithm solves the puzzle if and only if a solution exists,

```
from row 2 to n:
    propgate on the original board, making row n - 1 all 0s
    the bottom row after this is done is known as the last row residual

if BoardDone:
    submit
    return true

put the last row residual into the look up table, getting a first row enumerate

if No Solution Exists:
    submit
    return false

the first row enumerate is the actions to perform on the top row
this is the thing that FRE is brute forcing
perform those actions on the top row of the residual board, not the original board

from row 2 to n:
    propagte on the residual + first row enumerate board
    when this finishes, the bottom row will be solved

submit
return true
```

### Time Complexity
This algorithm is very fast, faster than FRE, FRE Iterative, Guassian Elimination, and Pseudoinverse Left Multiplication.

The total work is 2 $O(nm)$ passes, with an $O(1)$ lookup.

This means that the algorithm is $O(nm)$.

However, this comes at the huge cost of space.

### Optimizations for Space
Every board configuration needs its own lookup table, which explodes very quickly, especially for $l = 3$.

The biggest issue is that `spimbot.s` can be a maximum of 5MB and all of the tables need to be hardcoded in the data segment. However, we can be smarter and but the total size of all of the tables stored down to fit within `spimbot.s`.

First, we can always transpose the board to have the shorter side as the columns, adding $O(nm)$ some of the time. However, this cuts the total size of the tables down in half.

Second, we can see that when $min(n,m) \gt 11$ and $l = 3$, the lookup tables are so huge, they take up the vast majority of the space, and the board space is so huge, that solving those puzzles will just take to long with any other method. Instead, we can just not store those lookup tables, and just skip those puzzles when we get them, as it will almost surely be better to scrap it and request a smaller one.

We can optimize the $l = 2$ case by storing half-words, but we still need the full word for the $l = 3$ case. Since we are transposing, the total amount of memory in bytes we need is described by the following expression:

```math
m(x,y) = 2\sum_{m=1}^{x}\sum_{n=m}^{16}2^{m} + 4\sum_{m=1}^{y}\sum_{n=m}^{16}3^{m}
```

Where $x$ and $y$ are the minimum dimensions allowed for the $l = 2$ and $l = 3$ cases respectively.

Since $l = 3$ exploads so much faster than $l = 2$, we can set $x = 16$, and not have any issues.

After some fiddling, we can see two valid options for $y$,
```math
m(16, 9) = 1527944 \ \ \text{bytes} \equiv 1.5 \text{MB} \newline
m(16, 10) = 3181316 \ \ \text{bytes} \equiv 3.2 \text{MB}
```

However, after generating the tables, we see that we are actually limited to $y = 7$, because the text file is way bigger than what is actually stored in memory.

Therefore, we will chose $y = 7$. I.e., if $l = 3$ and $min(n,m) > 7$, we just skip solving the puzzle entirely.

To even further optimize for file size, we can hardcode the first row enumerates as hexadecimal instead of decimal, squeezing every last bit of file space possible.

After a lot of prototyping on the puzzle board size bounds themselves with the assistance of Claude.ai, we were able to generate the tables, resulting in a file that is 2.866 MB in size, double that of our arctan2 lookup table.

### Algorithm
From the above observations, we can derive the following algorithms.

#### $l = 2$
```cpp
// This is pseudocode, so the syntax isn't perfect
// This is not meant to be directly compiled

bool CTLSolve2(LightsOuts* puzzle, unsigned char* solution, unsigned char* board_buff) {
    const int num_rows = puzzle->num_rows;
    const int num_cols = puzzle->num_cols;
    unsigned char* board_ptr = &puzzle->board;

    if (num_cols <= num_rows) {
        // Zero the solution board
        zero_board(solution, num_rows, num_cols);

        /**
         * Row major order iteration for the first pass.
         * Remember, our desired endstate is when all lights are 0,
         *      so toggle iff the cell directly above the current cell is 1,
         *      because we need to turn it off.
         */
        for (uint8_t i = 1; i < num_rows; ++i) {
            for (uint8_t j = 0; j < num_cols; ++j) {
                if (board_ptr[i - 1][j] == 1) {
                    solution[i][j] = 1;
                    toggle_light(board_ptr, i, j, 1);
                }
            }
        }

        // Shortcirucuit if we just so happen to be done.
        // It's this check is part of what allows the LUT to be as small as possible
        if (BoardDone(board_ptr)) return true;

        const int last_row_residual = EncodeResidual2(board_ptr, num_rows, num_cols);

        int first_row_enumerate = CLT_LUT_2[num_rows][num_cols][last_row_residual];

        // Shortcirucuit if the board is unsolvable.
        if (first_row_enumerate == 0) return false;

        // Toggle the top row based on the first row enumerate
        for (uint8_t j = 0; j < num_cols; ++j) {
            if (((first_row_enumerate >> j) & 1) == 1) {
                solution[0][j] = 1 - solution[0][j];
                toggle_light(board_ptr, 0, j, 1);
            }
        }

        /**
         * Row major order iteration for the second pass.
         * Remember, our desired endstate is when all lights are 0,
         *      so toggle iff the cell directly above the current cell is 1,
         *      because we need to turn it off.
         * Remember, we do not run the second pass on the original board.
         *      I.e., we run on the board we currently have after the first pass.
         */
        for (uint8_t i = 1; i < num_rows; ++i) {
            for (uint8_t j = 0; j < num_cols; ++j) {
                if (board_ptr[i - 1][j] == 1) {
                    solution[i][j] = 1 - solution[i][j];
                    toggle_light(board_ptr, i, j, 1);
                }
            }
        }

        // Because of the way the Lookup Table works, we know we will be solved by this point.
        return true;
    } else {
        // Remember, all indexing is on the transposed matrix, so it looks identical.
        // The only difference between this and the previous clause are the bounds,
        // and that we have to reverse the indexing into solution.

        // Transpose the board with a copy.
        copy_T(board_ptr, board_buff, num_rows, num_cols);

        // Zero the solution board
        zero_board(solution, num_rows, num_cols);

        /**
         * Column major order iteration for the first pass.
         * Remember, our desired endstate is when all lights are 0,
         *      so toggle iff the cell directly above the current cell is 1,
         *      because we need to turn it off.
         */
        for (uint8_t i = 1; i < num_cols; ++i) {
            for (uint8_t j = 0; j < num_rows; ++j) {
                if (board_buff[i - 1][j] == 1) {
                    solution[j][i] = 1; // Remember to reverse the indexing
                    toggle_light(board_buff, i, j, 1);
                }
            }
        }

        // Shortcirucuit if we just so happen to be done.
        // It's this check is part of what allows the LUT to be as small as possible
        if (BoardDone(board_buff)) return true;

        const int last_row_residual = EncodeResidual2(board_buff, num_cols, num_rows);

        int first_row_enumerate = CLT_LUT_2[num_cols][num_rows][last_row_residual];

        // Shortcirucuit if the board is unsolvable.
        if (first_row_enumerate == 0) return false;

        // Toggle the top row based on the first row enumerate
        for (uint8_t j = 0; j < num_rows; ++j) {
            if (((first_row_enumerate >> j) & 1) == 1) {
                solution[j][0] = 1 - solution[j][0]; // Remember to reverse the indexing
                toggle_light(board_buff, 0, j, 1);
            }
        }

        /**
         * Column major order iteration for the second pass.
         * Remember, our desired endstate is when all lights are 0,
         *      so toggle iff the cell directly above the current cell is 1,
         *      because we need to turn it off.
         * Remember, we do not run the second pass on the original board.
         *      I.e., we run on the board we currently have after the first pass.
         */
        for (uint8_t i = 1; i < num_cols; ++i) {
            for (uint8_t j = 0; j < num_rows; ++j) {
                if (board_buff[i - 1][j] == 1) {
                    solution[j][i] = 1 - solution[j][i]; // Remember to reverse the indexing
                    toggle_light(board_buff, i, j, 1);
                }
            }
        }

        // Because of the way the Lookup Table works, we know we will be solved by this point.
        return true;        
    }
}
```

#### $l = 3$
```cpp
// This is pseudocode, so the syntax isn't perfect
// This is not meant to be directly compiled

bool CTLSolve3(LightsOuts* puzzle, unsigned char* solution, unsigned char* board_buff) {
    const int num_rows = puzzle->num_rows;
    const int num_cols = puzzle->num_cols;
    unsigned char* board_ptr = &puzzle->board;

    // Board is too big, don't even bother.
    // Also not storing the lookup table for space efficiency
    // Likely check before entering the routine.
    // There is no reason to waste the stack frame in this case
    if (min(num_rows, num_cols) > 7) return false;

    if (num_cols <= num_rows) {
        // Zero the solution board
        zero_board(solution, num_rows, num_cols);

        /**
         * Row major order iteration for the first pass.
         * Remember, our desired endstate is when all lights are 0,
         *      so toggle iff the cell directly above the current cell is not 0,
         *      because we need to turn it off.
         */
        for (uint8_t i = 1; i < num_rows; ++i) {
            for (uint8_t j = 0; j < num_cols; ++j) {
                int val = board_ptr[i - 1][j];
                if (val != 0) {
                    int action = 3 - val;
                    solution[i][j] = action;
                    toggle_light(board_ptr, i, j, action);
                }
            }
        }

        // Shortcirucuit if we just so happen to be done.
        // It's this check is part of what allows the LUT to be as small as possible
        if (BoardDone(board_ptr)) return true;

        const int last_row_residual = EncodeResidual3(board_ptr, num_rows, num_cols);

        int first_row_enumerate = CLT_LUT_3[num_rows][num_cols][last_row_residual];

        // Shortcirucuit if the board is unsolvable.
        if (first_row_enumerate == 0) return false;

        // Toggle the top row based on the first row enumerate
        for (uint8_t j = 0; j < num_cols; ++j) {
            int action = ((first_row_enumerate >> (2*j)) & 3);
            if (action != 0) {
                solution[0][j] += action;
                solution[0][j] -= (solution[0][j] >= 3) * 3; // Slick trick, gamer.
                toggle_light(board_ptr, 0, j, action);
            }
        }

        /**
         * Row major order iteration for the second pass.
         * Remember, our desired endstate is when all lights are 0,
         *      so toggle iff the cell directly above the current cell is not 0,
         *      because we need to turn it off.
         * Remember, we do not run the second pass on the original board.
         *      I.e., we run on the board we currently have after the first pass.
         */
        for (uint8_t i = 1; i < num_rows; ++i) {
            for (uint8_t j = 0; j < num_cols; ++j) {
                int val = board_ptr[i - 1][j];
                if (val != 0) {
                    int action = 3 - val;
                    solution[i][j] += action;
                    solution[i][j] -= (solution[i][j] >= 3) * 3; // Slick trick, gamer.
                    toggle_light(board_ptr, i, j, action);
                }
            }
        }

        // Because of the way the Lookup Table works, we know we will be solved by this point.
        return true;
    } else {
        // Remember, all indexing is on the transposed matrix, so it looks identical.
        // The only difference between this and the previous clause are the bounds,
        // and that we have to reverse the indexing into solution.

        // Transpose the board with a copy.
        copy_T(board_ptr, board_buff, num_rows, num_cols);

        // Zero the solution board
        zero_board(solution, num_rows, num_cols);

        /**
         * Column major order iteration for the first pass.
         * Remember, our desired endstate is when all lights are 0,
         *      so toggle iff the cell directly above the current cell is not 0,
         *      because we need to turn it off.
         */
        for (uint8_t i = 1; i < num_cols; ++i) {
            for (uint8_t j = 0; j < num_rows; ++j) {
                int val = board_buff[i - 1][j];
                if (val != 0) {
                    int action = 3 - val;
                    solution[j][i] = action; // Remember to reverse the indexing
                    toggle_light(bourd_buff, i, j, action);
                }
            }
        }

        // Shortcirucuit if we just so happen to be done.
        // It's this check is part of what allows the LUT to be as small as possible
        if (BoardDone(board_buff)) return true;

        const int last_row_residual = EncodeResidual3(board_buff, num_cols, num_rows);

        int first_row_enumerate = CLT_LUT_2[num_cols][num_rows][last_row_residual];

        // Shortcirucuit if the board is unsolvable.
        if (first_row_enumerate == 0) return false;

        // Toggle the top row based on the first row enumerate
        for (uint8_t j = 0; j < num_rows; ++j) {
            int action = ((first_row_enumerate >> (2*j)) & 3);
            if (action != 0) {
                solution[j][0] += action; // Remember to reverse the indexing
                solution[j][0] -= (val >= 3) * 3; // Slick trick, gamer.
                toggle_light(board_buff, 0, j, action);
            }
        }

        /**
         * Column major order iteration for the second pass.
         * Remember, our desired endstate is when all lights are 0,
         *      so toggle iff the cell directly above the current cell is not 0,
         *      because we need to turn it off.
         * Remember, we do not run the second pass on the original board.
         *      I.e., we run on the board we currently have after the first pass.
         */
        for (uint8_t i = 1; i < num_cols; ++i) {
            for (uint8_t j = 0; j < num_rows; ++j) {
                int val = board_buff[i - 1][j];
                if (val != 0) {
                    int action = 3 - val;
                    solution[j][i] += action; // Remember to reverse the indexing
                    toggle_light(board_buff, i, j, action);
                    solution[j][i] -= (val >= 3) * 3; // Slick trick, gamer.
                }
            }
        }
        // Because of the way the Lookup Table works, we know we will be solved by this point.
        return true;        
    }
}
```