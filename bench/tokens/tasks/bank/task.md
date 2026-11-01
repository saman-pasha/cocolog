# Bank

Each line of the input is a command:

- `open NAME` opens an account named NAME with a balance of 0;
- `deposit NAME AMOUNT` adds AMOUNT to the account's balance;
- `withdraw NAME AMOUNT` takes AMOUNT from it;
- `transfer FROM TO AMOUNT` takes AMOUNT from account FROM and adds it to
  account TO, which is never FROM itself;
- `balance NAME` prints the account's balance.

Names are words of lowercase letters and amounts are positive integers.
Commands run in order, and only these print anything:

- `balance` prints the balance as a number on a line of its own;
- `open` of an account that is already open prints `error: account NAME
  exists`;
- any other command that names an account not yet opened prints `error: no
  account NAME`, for the first such account it names, and changes nothing;
- a `withdraw` or a `transfer` of more than the balance it takes from prints
  `error: insufficient funds` and changes nothing.

Example input:

```text
open ann
deposit ann 100
withdraw ann 30
transfer ann bob 10
open bob
transfer ann bob 80
balance ann
```

Example output:

```text
error: no account bob
error: insufficient funds
70
```
