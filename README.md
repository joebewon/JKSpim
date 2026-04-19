# JKSpim

Repository for our entry for Lab 14 for CS 233 SP2026 Spimbot Tournament

## ToDos:
- [ ] Get diagonal movement working
  - [ ] Use timer interrupt
  - [ ] Optimize
    - There are things we can do to make trig fast, but I do not know what there OTOMH --Joseph Habisohn
  - Likely ok to stopping the bot within the interrupt handler as a hack as to make puzzle solving while moving easier to manage in code. It will keep code jumping as automatic as possible. --Joseph Habisohn
- [ ] Optimize Puzzle Solving
  - [ ] Get puzzle solving to work while moving
    - On its own, moving with the timer interrupt does this inherrently, we just need to figure out where in the strategy to start solving a puzzle. --Joseph Habisohn
    - We can possibly chunk the algorithm to make things easier to manage. --Joseph Habisohn
  - As fast as possible. It is deterministic and a solved problem. --Joseph Habisohn
- [ ] Implement a better bunny picking algorithm. See the Greedy Punny Picking Algorithm.
- [ ] Implement the playpen unlock interrupt
  - [ ] Determine is its needed
    - [ ] Determine where it would be in the strategy if it is
## Greedy Bunny picker Algorithm

Let $B$ be the set of bunnies. We can define the feasible set $B'$ to be the subset of bunnies we can actually reach. That is,
```math
B' := \{ b \in B \ \ | \ \ t_{reach}(\text{b}) < t_{jump}(b) \}
```

where:
- $t_{reach} : B \mapsto \mathbb{Z}$ s.t. $t_{reach}$ takes the number of cycles for the bot to reach the bunny
- $t_{jump} : B \mapsto \mathbb{Z}$ s.t. $t_{jump}$ takes the number of cycles until the bunny jumps

From here we can define the objective function $R: B \mapsto \mathbb{R}$:
$$
R(b) \coloneqq \frac{w(b)}{t_{reach}(b) + t_{jump}(b)}
$$

Therefore, our greedy choice is to maximize that ratio over bunnies in the feasible set $B'$, that is:
$$
b^* = \arg\max_{b \in B'} R(b)
$$

From here, we can see the following algorithm to pick $b^*$:
```cpp
PickBestBunny(B):
  let best_bunny = B[0]
  let biggest_ratio = 0
  for b in B:
    // Don't consider if not in B'
    if b.cycles_until_jump >= b.cycles_until_reach:
      continue
    
    // Compute R(b)
    let travel_time = (b.cycles_until_reach + b.cycles_until_jump)
    let ratio = b.weight / travel_time

    // Compute argmax R(b)
    if ratio > biggest_ratio:
      biggest_ratio = ratio
      best_bunny = b

    // Optional: By def of R, if two ratios are equal,
    //    then the bigger weight is always paried with
    //    the smaller total travel time. 
    // Therefore the bunny with the bigger weight is always better.
    else if ratio == biggest_ratio && b.weight > best_bunny.weight:
      biggest_ratio = ratio
      best_bunny = b

  // Return b^*
  return best_bunny
```

## Main Game Strategy
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
---

# How to work with spimbot

1. have docker daemon running

2. run the following command inside your terminal:

  ```sh
  docker compose pull 
  docker compose up -d
  ```

3. updating spimbot in your docker container
  
  The spimbot binary will be updated automatically when you open up a new terminal session, but if you wish to be extra safe, you can always run:

  ```sh
  update_spimbot
  ```
  
  manually to get the latest spimbot and test to see if your solution works as expected. The autograder will always use the latest version of spimbot.


4. submit your solution to PrairieLearn when you are ready :)
