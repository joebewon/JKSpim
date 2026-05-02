.data
.align 4
bunnies_info: .space 484                                        # Space for the BunniesInfo Struct

puzzle: .space 268                                              # Space for the LightsOut Puzzle

solution: .space 256                                            # Space for the solution to the LightsOut Puzzle

num_puzzles_requested: .word 0                                  # The number of puzzles that have been requested

timestamp_can_unlock_enemy: .word 0                             # The timestamp, in cycles, of when we can next unlock the enemy's playpen

time_between_playpens: .word 0                                  # The number of cycles it would take to travel between the two playpens

playpen_x: .word 0                                              # The x-cooridnate of our playpen
playpen_y: .word 0                                              # The y-cooridnate of our playpen
other_playpen_x: .word 0                                        # The x-cooridnate of their playpen
other_playpen_y: .word 0                                        # The y-cooridnate of their playpen

.align 1
has_bonked: .byte 0                                             # Bonk Interrupt

puzzle_received: .byte 0                                        # Puzzle Received Interrupt

has_timer: .byte 0                                              # Whether or not we should actually respect the timer interrupt

fsm_state: .byte 0                                              # Current state of the FSM

# import Arctan2lookup.s