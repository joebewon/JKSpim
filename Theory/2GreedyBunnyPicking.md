# Greedy Bunny Picking Algorithm

Let $B$ be the set of bunnies. We can define the feasible set $B'$ to be the subset of bunnies we can actually reach. That is,
```math
B' := \{ b \in B \ \ | \ \ t_{reach}(\text{b}) < t_{jump}(b) \}
```

where:
- $t_{reach} : B \mapsto \mathbb{Z}$ s.t. $t_{reach}$ takes the number of cycles for the bot to reach the bunny
- $t_{jump} : B \mapsto \mathbb{Z}$ s.t. $t_{jump}$ takes the number of cycles until the bunny jumps

From here we can define the objective function $R: B \mapsto \mathbb{R}$:
```math
R(b) \coloneqq \frac{w(b)}{t_{reach}(b) + t_{playpen}(b)}
```

where:
- $t_{playpen} : B \mapsto \mathbb{Z}$ s.t. $t_{playpen}$ takes the number of cycles for the bot to reach the playpen from a bunny.

Therefore, our greedy choice is to maximize that ratio over bunnies in the feasible set $B'$, that is:
```math
b^* = \arg\max_{b \in B'} R(b)
```

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
    let travel_time = (b.cycles_until_reach + playpen.cylcles_until_reach)
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
