# Main Game Strategy

## Psuedocode
```
loop:
  loop until bunny picked up:
    pick bunny
    move to bunny
    attempt pick up bunny
    check if bunny picked up
  move to our playpen
  lock playpen if needed
  drop bunny
  move to opponent playpen
  unlock opponent playpen if needed
```

## Details

This will be implemented as an FSM such that the state is stored in memory and the trasistions are handled by the interrupt handler.

The idea is that wehenver we are stopped by either the timer interrupt (we reached our destination) or bonk interupt (we hit the wall), we move onto the next step in the strategy.

This way, the main spimbot code can just be an infinite loop of solving puzzles that is then paused everytime we need to do something other than move. This makes the code very easy to manage, and jumping is handled automatically by the Coprocessor 0.

