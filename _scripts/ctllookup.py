import numpy as np
import sys
import time

def build_table(num_rows, num_cols, l):
    """
    num_rows = max_dim (longer side, chase direction)
    num_cols = min_dim (shorter side, top/last row width)
    Returns flat list indexed by last-row residual.
    l=2: residual = binary, value = binary (16-bit)
    l=3: residual = base-3, value = 2-bit-per-cell (32-bit)
    """
    n, m = num_rows, num_cols
    if l == 2:
        table_size = 1 << m
        top_space  = 1 << m
    else:
        table_size = 3**m
        top_space  = 3**m

    # Decode all top_codes: shape (top_space, m)
    if l == 2:
        top_actions = np.array(
            [[(c >> (m-1-j)) & 1 for j in range(m)] for c in range(top_space)],
            dtype=np.int8)
    else:
        top_actions = np.zeros((top_space, m), dtype=np.int8)
        tmp = np.arange(top_space, dtype=np.int64)
        for j in range(m-1, -1, -1):
            top_actions[:, j] = tmp % l
            tmp //= l

    boards = np.zeros((top_space, n*m), dtype=np.int8)

    def do_click(r, c, acts):
        for dr, dc in [(0,0),(1,0),(-1,0),(0,1),(0,-1)]:
            nr, nc = r+dr, c+dc
            if 0 <= nr < n and 0 <= nc < m:
                boards[:, nr*m+nc] = (boards[:, nr*m+nc].astype(np.int16) + acts) % l

    for c in range(m):
        do_click(0, c, top_actions[:, c])

    for r in range(1, n):
        for c in range(m):
            acts = (l - boards[:, (r-1)*m+c].astype(np.int16)) % l
            do_click(r, c, acts)

    last_row = boards[:, (n-1)*m:n*m].astype(np.int64)

    if l == 2:
        res_weights = np.array([1 << (m-1-j) for j in range(m)], dtype=np.int64)
        val_weights = res_weights  # same encoding for l=2
    else:
        res_weights = np.array([3**(m-1-j) for j in range(m)], dtype=np.int64)
        val_weights = np.array([1 << (2*(m-1-j)) for j in range(m)], dtype=np.int64)

    residuals = last_row @ res_weights
    values    = top_actions.astype(np.int64) @ val_weights

    table = np.zeros(table_size, dtype=np.int64)
    for i in range(top_space):
        r = residuals[i]
        if table[r] == 0:
            table[r] = values[i]

    return table.tolist()


def write_tables(outpath):
    out = open(outpath, 'w')

    out.write('.data\n\n')

    # ── l=2 tables ──────────────────────────────────────────────────────────
    # Convention: num_rows = max_dim >= num_cols = min_dim
    # Label: CTL_LUT_2_<min_dim>_<max_dim>
    print("Generating l=2 tables...", file=sys.stderr)
    for min_dim in range(1, 17):
        for max_dim in range(min_dim, 17):
            t0 = time.time()
            table = build_table(max_dim, min_dim, 2)
            elapsed = time.time() - t0
            label = f"CTL_LUT_2_{min_dim}_{max_dim}"
            print(f"  {label}: {len(table)} entries  ({elapsed:.2f}s)", file=sys.stderr)

            out.write(f"# CTL Lookup Table  l=2  min_dim={min_dim}  max_dim={max_dim}\n")
            out.write(f"# {len(table)} entries x 2 bytes"
                      f"  |  index = binary last-row residual (rightmost cell = LSB)\n")
            out.write(f"# value = compact 16-bit first-row enumerate (rightmost cell = LSB)\n")
            out.write(f"# 0x0000 means unsolvable\n")
            out.write(f"{label}:\n")
            for i in range(0, len(table), 8):
                chunk = table[i:i+8]
                vals  = ', '.join(f'0x{v:04x}' for v in chunk)
                out.write(f"    .half {vals}\n")
            out.write('\n')

    # ── l=3 tables ──────────────────────────────────────────────────────────
    # Label: CTL_LUT_3_<min_dim>_<max_dim>
    print("Generating l=3 tables...", file=sys.stderr)
    for min_dim in range(1, 8):
        for max_dim in range(min_dim, 17):
            t0 = time.time()
            table = build_table(max_dim, min_dim, 3)
            elapsed = time.time() - t0
            label = f"CTL_LUT_3_{min_dim}_{max_dim}"
            print(f"  {label}: {len(table)} entries  ({elapsed:.2f}s)", file=sys.stderr)

            out.write(f"# CTL Lookup Table  l=3  min_dim={min_dim}  max_dim={max_dim}\n")
            out.write(f"# {len(table)} entries x 4 bytes"
                      f"  |  index = base-3 last-row residual (rightmost cell = least significant trit)\n")
            out.write(f"# value = compact 32-bit first-row enumerate (rightmost cell in 2 LSBs)\n")
            out.write(f"# 0x00000000 means unsolvable\n")
            out.write(f"{label}:\n")
            for i in range(0, len(table), 8):
                chunk = table[i:i+8]
                vals  = ', '.join(f'0x{v:08x}' for v in chunk)
                out.write(f"    .word {vals}\n")
            out.write('\n')

    out.close()
    size = __import__('os').path.getsize(outpath)
    print(f"Done. Written to {outpath}  ({size:,} bytes = {size/1024**2:.2f} MB)", file=sys.stderr)


write_tables('/home/claude/ctl_tables.s')

##################### This script was written with the help of Claude.ai #####################