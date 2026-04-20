# Optimized Puzzle Solving

## IsPrime

### Relevance
Lightsout Puzzles turn out to be a Gaussian elimination problem $mod$ the `num_colors`. Becuase of this modular arithmatic, plain Guassian Elimination does not work if `num_colors` is not prime, because there is a possibility that a row cannot be scaled to have a pivot of one. For example $2x = 1 (mod \ \ 6)$ has no solution. We could branch to a heavier analytical method like those that use Chinese Remainder Theorem or Smith Normal Form, but the given fallback is likely good enough, and can possibly optimized on its own.

In other words, the application of `IsPrime()` is as follows,
```cpp
bool solve(...) {
    if (IsPrime(num_colors)) {
        // Do modular gaussian
    } else {
        // Do Class given method 
    }
}
```

### Algorithm

To do `IsPrime` fast, we can store a boolean array as a 32bit number to encode the first 32 prime numbers, after that point, we can use trial division if the input is odd.

```cpp
// Bit array of the primness of the first 32 odd numbers from 3 to 65
#define ODD_PRIME_ARRAY_32
bool IsPrime(unsigned int x) {
    // No number less than 2 is prime
    if (x < 2) return false;

    // 2 is prime
    if (x == 2) return true;

    // Even numbers are never prime
    if (x & 1 == 0) return false;

    // Check the bit array for odd numbers
    // Using >> 1 as a MIPS ASM optimization, in lieu of / 2
    const unsigned int idx = ((x - 1) >> 1) - 1; 
    if (x <= 65) return bool((ODD_PRIME_ARRAY_32 >> idx) & 1);

    // Fallback to Division Trials
    for (unsigned int i = 3; i * i <= x; i += 2) {
        if (x % i == 0) return false;
    }
    return true;
}
```

## Modular Gaussian

### Relevance

