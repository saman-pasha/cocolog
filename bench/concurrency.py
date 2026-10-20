#!/usr/bin/env python3
"""The coroutine lanes of bench/concurrency.sh: asyncio tasks on the spin
work, on no work at all, and on K yields each. Python's coroutines are the
comparison's coroutine library.

    python3 bench/concurrency.py work 8 200000
    python3 bench/concurrency.py light 10000
    python3 bench/concurrency.py lightyield 10000 100
"""

import asyncio
import sys

MODE = sys.argv[1]
N = int(sys.argv[2])
YIELD = 10000


async def spin(n):
    while n > 0:
        n -= 1
        if n % YIELD == 0:
            await asyncio.sleep(0)


async def noop():
    pass


async def yieldk(k):
    for _ in range(k):
        await asyncio.sleep(0)


async def run():
    if MODE == "work":
        m = int(sys.argv[3])
        await asyncio.gather(*(spin(m) for _ in range(N)))
    elif MODE == "light":
        await asyncio.gather(*(noop() for _ in range(N)))
    elif MODE == "lightyield":
        k = int(sys.argv[3])
        await asyncio.gather(*(yieldk(k) for _ in range(N)))
    else:
        raise SystemExit(2)
    print("answer(done)")


asyncio.run(run())
