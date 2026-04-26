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
bool board_done(unsigned char* board) {
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

#### FRE
In addition, we no longer need to pass in `int row` and `int col` anymore becuase we are not recursing. Hence, the removal of `int row` and `int col` in the function headers.

Since we need to copy the board on every try anyway, we can transpose the matrix while copying it if need be. This allows us to still use the $O(1)$ `board_done`
.

##### 1.Where $l = 2$:
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

##### 2. Where $l = 3$:
```c++
// ------------- num_lights == 3 case
bool fre_solve_3(LightsOuts* puzzle, unsigned char* solution) {
    const int num_rows = puzzle->num_rows;
    const int num_cols = puzzle->num_cols;
    unsigned char* board_ptr = &puzzle->board;

    // Toggle mask with a base 3 increment. Least significant trit is mask[0], while mask[num_cols|num_rows] handles overflow
    unsigned char mask[17] = {0};
    if (num_cols <= num_rows) {
        // const uint32_t permutations = 2**num_cols;
        while (mask[num_cols] == 0) {
            unsigned char* board_cpy = copy(board_ptr);
            zero_board(solution, num_rows, num_cols);
    
            for (uint8_t j = 0; j < num_cols; ++j) {
                const int action = mask[j];
                if (action != 0) {
                    toggle_light(board_cpy, 0, j, action);
                    solution[0][j] = action;
                }
            }
    
            // Row major order iteration
            // Remember, our desired endstate is when all lights are 0,
            // so toggle iff the cell directly above the current cell is 1 or 2,
            // because we need to turn it off
            for (uint8_t i = 1; i < num_rows; ++i) {
                for (uint8_t j = 0; j < num_cols; ++j) {
                    const int action = board_cpy[i - 1][j];
                    if (action != 0) {
                        action -= 3;
                        toggle_light(board_cpy, i, j, action);
                        solution[i][j] = action;
                    }
                }
            }
    
            if (board_done(board, num_rows, num_cols)) return true;
            
            // Increment the mask
            for (int t = 0; t <= num_cols; ++t) {
                ++mask[t];
                
                if (mask[t] < 3) {
                    break;
                }
                
                mask[t] = 0;
            }
        }
        
        return false;
    } else {
        while (mask[num_rows] == 0) {
            // Remember, all indexing is on the transposed matrix, so it looks identical.
            // The only difference between this and the previous clause are the bounds,
            // and that we have to reverse the indexing into solution.

            // Transpose the board on copy.
            unsigned char* board_cpy = copy_T(board_ptr);

            // Don't transpose when zeroing the board
            zero_board(solution, num_rows, num_cols);
    
            // i is directly the bit mask of how to toggle the top row
            // s.t. we toggle top_column[j] iff b_j == 1
            for (uint8_t j = 0; j < num_rows; ++j) {
                const int action = mask[j];
                if (action != 0) {
                    toggle_light(board_cpy, 0, j, action);
                    solution[j][0] = action;
                }
            }
    
            // Column major order iteration
            // Remember, our desired endstate is when all lights are 0,
            // so toggle iff the cell directly above the current cell is 1,
            // because we need to turn it off
            for (uint8_t i = 1; i < num_cols; ++i) {
                for (uint8_t j = 0; j < num_rows; ++j) {
                    const int action = board_cpy[i - 1][j];
                    if (action != 0) {
                        action -= 3;
                        toggle_light(board_cpy, i, j, action);
                        solution[j][i] = action; // Remember to reverse the indexing
                    }
                }
            }
    
            if (board_done(board_cpy, num_cols, num_rows)) return true;
            
            // Increment the mask
            for (int t = 0; t <= num_cols; ++t) {
                ++mask[t];
                
                if (mask[t] < 3) {
                    break;
                }
                
                mask[t] = 0;
            }
        }
        
        return false;
    }
}
```

## Gaussian Elimination

In certain circumstances, Gaussian Elimination can beat FRE

### IsPrime

#### Irrelevance
Lightsout Puzzles turn out to be a Gaussian elimination problem $mod$ the `num_colors`. Becuase of this modular arithmatic, plain Guassian Elimination does not work if `num_colors` is not prime, because there is a possibility that a row cannot be scaled to have a pivot of one. For example $2x = 1 (mod \ \ 6)$ has no solution. We could branch to a heavier analytical method like those that use Chinese Remainder Theorem or Smith Normal Form, but the given fallback is likely good enough, and can possibly optimized on its own.

However, since `num_lights` will only ever be 2 or 3, which are both prime numbers. This means that we never have to check for primeness because the number of light colors will always be prime.

### Modular Gaussian

#### Relevance

First the Gaussian Method in of itself, is very useful and can be very efficient because we can take advantage of spatial locality to optimize cache performace. Gaussian Elimination has been written in many assembly languages since basically the dawn of time so it comes dows to just choosing one that seems good.

Its application here is described in a [Wolfram MathWorld Blog](https://mathworld.wolfram.com/LightsOutPuzzle.html) for the `num_lights == 2` case. After some converstaion with ChatGPT, we determined that we only need to edit whatever existing Gaussian Elminiation algorithm we find and turn all operations into modular operations. Alternativly, already find a MIPS ASM implementation for modular Gaussian Elimination.

#### Optimizations

We have a couple of options. According to our theoretical conversations with ChatGPT, tiling could be useful, but is unlikely given that our maximum augmented matrix size is only 256x257. What is likely better is SIMD for the row update. This gives the possible following algorithm,

```
for pivot = 0..N-1
    find pivot row
    swap rows

    inv = inverse(pivot_value)

    normalize pivot row

    for each row j != pivot
        factor = matrix[j][pivot]
        if factor != 0
            SIMD/tight loop over k:
                row_j[k] -= factor * row_pivot[k]
```