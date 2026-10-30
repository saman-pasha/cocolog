# The token benchmark: what an agent spends writing cocolog and Python

The language benchmark (`bench/langs.sh`) asks how fast a program runs.
This one asks what it costs a model to WRITE it: the tokens and the dollars
an LLM agent burns to get the same ten programs right in cocolog and in
Python, counting everything the loop that writes a program pays -- the
guide the model is given, its thinking (billed as output), the program, the
failures it reads back and the rounds it takes to pass.

```sh
cocolog -s bench/tokens.pl -- check            # every reference passes every case (no key)
cocolog -s bench/tokens.pl -- size             # the references' bytes and lines, the prompts' sizes
                                               # (and their tokens, with a key: count_tokens is free)
cocolog -s bench/tokens.pl -- replay DIR       # the whole loop, each reply read from DIR (no key)
cocolog -s bench/tokens.pl -- run              # the real thing: ANTHROPIC_API_KEY, money, the network
cocolog -s bench/tokens.pl -- report FILE      # the tables again, from a run's log
```

from the checkout root. `run` and `replay` take options as `NAME=VALUE`
and tasks by name (all ten when none is named):

| option | default | |
|---|---|---|
| `model` | `claude-opus-5-5` | any Claude model; the four priced ones are in `tk_price/5` |
| `effort` | `high` | `output_config.effort`: `low` `medium` `high` `xhigh` `max` |
| `max_tokens` | `16000` | per call, thinking included |
| `rounds` | `4` | a task's tries before it counts as failed |
| `reps` | `3` | episodes per task and arm |
| `arms` | `python,cocolog,cocolog-card` | |
| `timeout` | `10` | seconds a program has for one case |
| `fallbacks` | `off` | `default` turns on the API's server-side fallback (below) |
| `retries` | `5` | for a 429, a 5xx or no answer, after 2, 4, 8, ... seconds |
| `out` | `bench/tokens/runs/run-STAMP.jsonl` | the log (`DIR/replay.jsonl` for a replay) |

`test/tokens.pl` holds the harness to all of this without a key: every
reference passing every case, a replay end to end, the request it builds,
the echo rule and the pieces a reply is read for. It needs `python3` and
SKIPs without one, as `test/langs.pl` does.

## What is measured

**An episode** is one task, one arm, one repetition. Round 1 sends the
task. The first fenced code block of the reply is the program, and every
case runs it; the first case that fails comes back as the next user turn --
its input, the output wanted, the output got (or that there was none), the
exit status and the end of standard error, each clipped to forty lines --
until a round passes them all, the model refuses, or the rounds run out. A
reply with no closed code block is told so (and whether it was cut off at
`max_tokens`), and that is a round too.

**The conversation is append-only.** What the model sent back goes back as
it came, thinking blocks and their signatures included -- the API's
preserved thinking asks that of a harness, and it is what keeps the prompt
cache warm: the system prompt carries one cache breakpoint and the
top-level `cache_control` moves a second along the growing conversation.

**What is counted** is what the API reports for each call: `input_tokens`,
`cache_creation_input_tokens`, `cache_read_input_tokens` and
`output_tokens`, which includes the thinking. Nothing is estimated, except
by the replay backend, which has no model to ask: it logs a length / 4,
and its report says so on its first line.

**The answer is tokens and dollars per task solved**, per arm, and each
cocolog arm's ratio to Python's. Every call is a line of the log as well
(`kind: call`: the round, the stop reason, the four counts, the verdict,
the case that failed, the seconds), so a run can be read again any way.
Dollars are the list prices of 2026-10-06 (the claude-api skill's table):
Opus 5.5 $4 in, $20 out, $5 a cache write, $0.20 a cache read, per million.

## The arms

| arm | system prompt | |
|---|---|---|
| `python` | `prompts/python.md` | CPython 3.11, the standard library, `python3 prog.py` |
| `cocolog` | `prompts/cocolog.md` | "a Prolog close to SWI-Prolog", `cocolog -s prog.pl`, how to read standard input -- and nothing else |
| `cocolog-card` | `cocolog.md`, `card.md` and the dialect card | the card cocolint keeps (`tools/cocolint/traps.jsonl`, rendered by `tool.sh card --card`, about 17 000 characters): what the project gives an agent so that it does not write SWI-Prolog |

Each task prompt is the same for every arm: `tasks/NAME/task.md` and
`prompts/contract.md`. The two cocolog arms ask whether the card pays for
itself: it is a fixed cost every request carries (cached after the first),
against the rounds it saves.

## The tasks

Ten small programs a model writes in one go in either language, chosen so
that each exercises something a Prolog has to say differently from a
Python, and checked on 56 cases. Every `NN.out` was made by `ref.py`, and
`ref.pl` agrees on every one (`check`).

| task | cases | what | the Prolog-shaped part |
|---|---|---|---|
| `wordfreq` | 6 | the K most common words, ties alphabetical | text into words, a count, a sort with two keys |
| `rle` | 5 | run-length encode and decode | runs over codes, digits back to a number |
| `calc` | 6 | + - * / and parentheses, `error` for bad input | a grammar (a DCG), truncating division |
| `queens` | 7 | the count of N-queens placements and the first | search and backtracking |
| `paths` | 5 | breadth-first shortest paths, -1 unreachable | a queue, visited nodes |
| `topo` | 7 | a build order, smallest ready first, or `cycle` | Kahn's algorithm, a priority |
| `family` | 4 | ancestors, descendants, siblings, cousins | facts and rules: Prolog's home ground |
| `knapsack` | 6 | 0/1 knapsack, 50 items, capacity 10 000 | a table, where Prolog has no array |
| `bank` | 4 | accounts and transfers, three error messages | state through a fold, an association list |
| `jsonsum` | 6 | the sum of a JSON document's integers | a parser, or the library one |

`size` reads the references: Python's are 6 004 bytes in 245 lines and
cocolog's 10 142 in 322 -- 1.7 times the text before any model has
written a line, and not the same question as what a model spends.

## NO FALLBACK MODEL BY DEFAULT

The API can re-run a declined request on another model (`fallbacks`,
server-side), and once a conversation falls back it stays there for about
an hour. A benchmark that let that happen would measure two models under
one name, so by default a refusal is recorded as a refusal (`result:
refused`). `fallbacks=default` turns the fallback on (with its beta
header, `server-side-fallback-2026-07-01`); then every call's log line
names the model that served it, and the echo leaves out the thinking and
`tool_use` blocks before the last `fallback` block, as the API asks.

## What a run needs, and costs

* `ANTHROPIC_API_KEY` in the environment, read at each call and never
  written anywhere. On a Claude Code cloud session that is an environment
  secret, set in the environment's settings, which a new session picks up.
* `python3`, and the network to `api.anthropic.com`.
* **A box you would let a stranger's program run on.** The harness runs
  what the model wrote, as the user running it, each case in a scratch
  directory under the timeout. Run it in a container or a VM.
* Money. The thinking is most of it, and there is no knowing how much a
  model thinks before it has: a rough guess for the default (Opus 5.5,
  effort `high`, three reps of ten tasks on three arms, 90 episodes) is
  $5 to $30. Run `reps=1` first; its log says what the rest will cost.

## What building it found

No live run has been made yet (2026-10-30: the box that built it has no
key). Building it found three places where cocolog answers SWI-Prolog code
otherwise than SWI does -- exactly what an agent writing cocolog from what
it knows of SWI pays for in rounds:

* `aggregate_all(sum(X+1), ...)` raises `type_error(number, 1+1)`, and
  `max(X*2)` and `min(X-5)` the same, where SWI evaluates the expression
  (its clauses are `S is S0 + X` and `M is max(M0, X)`).
* `term_to_atom(answer(K, E), 'answer(cost,24.0)')` fails: a bound term is
  written and compared, where SWI parses the atom whenever it is bound.
* `print_message/2` does not exist (an existence error).

None of the three is on the card. And the card is wrong in a way that costs
the card arm: its row A1 tells the model that `atan/2`, `atan2/2`,
`copysign/2`, `random/1`, `random_float`, the hyperbolic functions,
`lgamma/1`, `erf/1`, `erfc/1`, `lsb/1`, `popcount/1`, `getbit/2`, `powm/3`,
`nexttoward/2`, `cputime` and `rational/1` are not evaluable, and every one
of them is, since 2.5.0 (only `log/2` is missing, and SWI 9.0.4 lacks it
too). A model that believes the row writes a workaround for nothing, so
the card wants reading again, row by row, before a live run measures it.

## Files

| path | what |
|---|---|
| `../tokens.pl` | the harness: the loop, both backends, the log and the report |
| `tasks/NAME/` | `task.md` (the task, with an example that is case 01), `ref.py`, `ref.pl`, `cases/NN.in` and `NN.out` |
| `prompts/` | the system prompts of the arms, the card's introduction, the contract every task ends with |
| `runs/` | a run's logs (git-ignored) |
