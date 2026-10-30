import sys

balances = {}
for line in sys.stdin.read().splitlines():
    cmd, *args = line.split()
    if cmd == "open":
        if args[0] in balances:
            print(f"error: account {args[0]} exists")
        else:
            balances[args[0]] = 0
        continue
    names = args[:2] if cmd == "transfer" else args[:1]
    missing = [x for x in names if x not in balances]
    if missing:
        print(f"error: no account {missing[0]}")
    elif cmd == "balance":
        print(balances[args[0]])
    elif cmd == "deposit":
        balances[args[0]] += int(args[1])
    else:
        amount = int(args[-1])
        if amount > balances[args[0]]:
            print("error: insufficient funds")
        else:
            balances[args[0]] -= amount
            if cmd == "transfer":
                balances[args[1]] += amount
