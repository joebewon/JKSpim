# JKSpim

Repository for our entry for Lab 14 for CS 233 SP2026 Spimbot Tournament

## Theoretical Framworks

The [Theory](./Theory/README.md) directory contains documentation on the theory that will be applied in our project.

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
