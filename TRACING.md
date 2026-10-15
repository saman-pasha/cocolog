# Tracing

cocolog carries a four-port tracer: `Call`, `Exit`, `Redo` and `Fail`
lines in SWI-Prolog's own format, written to stderr for every goal the
engine proves. It is held to SWI port for port by the suite's `trace`
case, so a trace read here reads the same as one read there.

## Turning it on

```console
$ cocolog --trace run program.pl "goal"
$ cocolog --trace --kb demo query "ancestor(tom, X)"
```

`--trace` traces the whole run, in any of the four knowledge-base
arrangements. From inside a program, `trace/0` switches the tracer on
from the next goal and `notrace/0` switches it off at once, exactly as
SWI's do — so a single predicate can be bracketed:

```prolog
..., trace, the_suspect(X), notrace, ...
```

Neither appears in its own trace. The ports go to stderr and the
program's own output to stdout, so the two never tangle:

```console
$ cocolog --trace run program.pl "goal" 2>trace.txt
```

`--backtrace` runs the same tracer and prints nothing: what it keeps is
for an error's backtrace (below), which then names every call the error
was raised in.

## Reading the ports

```console
$ cocolog --trace query "member(X, [a,b]), X == b"
   Call: (1) member(_G0,[a,b])
   Exit: (1) member(a,[a,b])
   Call: (1) a==b
   Fail: (1) a==b
   Redo: (1) member(_G0,[a,b])
   Call: (2) member(_G0,[b])
   Exit: (2) member(b,[b])
   Exit: (1) member(b,[a,b])
   Call: (1) b==b
   Exit: (1) b==b
```

Each line is `Port: (Depth) Goal`.

* **Call** — the goal is entered, printed as it stands, before so much
  as a clause head is looked at. The depth is how many calls deep the
  proof is; siblings share one.
* **Exit** — the goal has proven, printed with everything its proof
  bound: `sum([2], _G75)` goes in, `sum([2], 2)` comes out.
* **Redo** — backtracking re-enters the goal for another way, printed
  with the bindings just undone — which is why the `Redo` above shows
  `member(_G0, [a,b])` again, not `member(a, [a,b])`. It is printed for
  two things, as SWI prints it for both: a call that had **exited** asked
  for another answer (the `member/2` above), and a call whose clause
  **failed** going on to its next clause (`Call`, the clause's ports,
  `Redo`, the next clause's) — a retry within one search for an answer.
  Only the first says the call is nondeterministic: a predicate of fifty
  clauses each guarded by a cut shows a Redo for every clause it passes,
  and is deterministic all the same. Count a Redo that follows an `Exit`
  of the same call; `library(flow/debug)`'s XML marks each redo
  `exited="true"` or `"false"` (1.10.25).
* **Fail** — the goal is out of ways, for good.

Every `Call` eventually meets its `Exit` or its `Fail`; a `Redo`
reopens the pair. Determinate goals — builtins, `is/2`, comparisons —
show `Call`/`Exit` or `Call`/`Fail` and never `Redo`.

## What counts as a goal

User predicates, the builtins (`=`, `is`, the type tests, comparisons —
all of them), `true` and `fail`. The control glue does not: `,`, `;`,
`->`, `*->`, `!`, `\+` and `call/N` never print a port of their own,
which is SWI's reading too. What they *do* is visible through the goals
inside them — and through four subtleties the tracer reproduces
deliberately, because SWI has them:

* **Taking the other arm is a Redo of the call it sits in.** A `;` in a
  clause body, the else of an `->`, the way out of a failed `\+` — each
  prints `Redo` on the *enclosing* call, bindings undone. At the
  toplevel there is no enclosing call, and nothing prints.
* **A deeper Redo reopens its ancestors.** Once backtracking re-enters
  a call's subtree, that call is live again, and its `Fail` prints when
  the failure finally crosses it — even though its own `Exit` had
  already been reported. Only the calls the Redo is *inside*: in
  `d0, member(X, [1,2]), X > 5` the `d0` that exited before `member/2`
  was called stays exited, and SWI fails it no more than cocolog does
  (through 1.10.22 every shallower call below a Redo was reopened, and
  `Fail: d0` was printed).
* **A cut does not hide a Fail.** `cutfail :- !, fail.` prints
  `Fail: cutfail`, as SWI does: the cut takes away the call's other
  clauses and everything its body left to try, but under trace the
  call's own frame stays, spent, and failing back into it is the call's
  `Fail` — or nothing, once it has exited. Through 1.10.22 the cut took
  that frame too, and every call whose clause cut and then failed ended
  with no `Fail` at all (in a window, a call with no end: the
  `fate="open"` of `library(flow/debug)`).
* **Heads that cannot match make no noise.** A call that exited and is
  later backtracked *past* — its remaining clause heads all failing to
  unify — is discarded in silence. That is the quiet SWI's clause
  indexing buys by never keeping the frame at all; cocolog, which tries
  clauses in order, buys the same silence by remembering the exit.
* **The engine's own plumbing is invisible.** The `fail` a bare `->`
  desugars to, the `true`/`fail` arms of `\+` — the program never wrote
  them, so the trace never shows them.

## How it is held to SWI

`test/trace.pl` — the `trace` case of `make test` — asks both tracers
the same thirty-three queries over `test/trace-program.pl` and compares the port
lines one for one: same ports, same order, same relative depths, same
goals. Three things are normalised first, because the two writers are
entitled to them: the depth base (SWI's toplevel starts about ten
frames deep, cocolog at one), the names of unbound variables (`_438`
there, `_G34` here), and spacing inside terms. The case SKIPs without
`swipl` on PATH.

Two knowing divergences, both outside the ports themselves: SWI jumps
several frame depths entering a `findall` (its inner machinery) where
cocolog's inner engine continues at the natural depth, and SWI prefixes
meta-predicates with `^` and library goals with their module
(`lists:member`) — cocolog has neither modules nor the prefix.

There is no interactive mode — no creep, skip or leap at a leashed
port. The tracer is a printer, and the machine itself is the stepper:
`start`/`step --steps N` advances a suspended machine one slice at a
time, and the two compose — a stepped machine under `--trace` prints
the ports of exactly the inferences that turn spent.

## The inference clock

**A traced run counts what an untraced one counts** (since 1.10.12):
`statistics(inferences, N)`, `call_metered/4` and a machine's turns read
the same number with the tracer on or off, so an inference names the same
goal in both. Through 1.10.11 they did not: the Exit marker below was
taken as a step of its own, and naive reverse of eight, 47 inferences,
counted 93 under `--trace`. And **a machine stepped in turns finishes at
the count of one turn**: `step --steps 12` suspends at 12 (it printed 13,
counting the goal it stopped at, which the next turn counted again).

## Where an error was raised

An error nothing caught is followed on stderr, after its message, by
where it was raised (1.10.17). At full speed that is the goal that raised
it and the goals each engine still had to run, innermost first. With

```prolog
main :- step1(3), write(done), nl.
step1(N) :- N1 is N - 1, step2(N1, R), write(R), nl.
step2(N, R) :- member(X, [1,2]), oops(N, X, R).
oops(N, X, R) :- R is N / (X - X).
```

in `t.pl`:

```console
$ cocolog -s t.pl
ERROR: -s main: Arithmetic: evaluation error: `zero_divisor'
ERROR: In:
ERROR:   _G38 is 2/(1-1)
ERROR:   then write(_G38)
ERROR:   then nl
ERROR:   then write(done)
ERROR:   then nl
ERROR: Note: what each goal had left to run, not the calls it was made in;
ERROR: run with --backtrace to see those.
```

A run at full speed keeps no record of its calls -- the continuation is
the goals still to run, and a call last in its body leaves nothing at
all -- so that is what there is to show. A goal still to run in a body
with an if-then-else, a negation or a disjunction lives in that clause's
environment, which knows its clause, and says so: `then N is N0+1
(clause 2 of len/2)`. Under `--backtrace` (or `--trace`) every call
leaves its `'$trace_exit'` marker on the continuation, and the backtrace
is SWI's, depth by depth:

```console
$ cocolog --backtrace -s t.pl
ERROR: -s main: Arithmetic: evaluation error: `zero_divisor'
ERROR: In:
ERROR:   [5] _G66 is 2/(1-1)
ERROR:   [4] oops(2,1,_G66)
ERROR:   [3] step2(2,_G66)
ERROR:   [2] step1(3)
ERROR:   [1] main
```

* **Inside a builtin's engine** -- `findall/3`, `forall/2`,
  `aggregate_all/3`, `call_metered/4`, `with_output_to/2` -- the goals
  inside come first, then the builtin, then the goals after it: the
  builtin throws the ball again in its own engine and keeps the lines the
  first throw wrote.
* **Each engine shows its first eight entries and its last four**, with
  a count of those between (`... 49 more ...`); a goal past 240
  characters is cut (` ...`).
* **A load's reports have one too**: a directive's, an initialization
  goal's, `initialization(main, main)`'s -- after the message, which stays
  word for word swipl's (`test/directives.pl`). A load under a `catch/3`
  reports its directive's error itself, and so writes its lines.
* **Nothing is written that the message already says**: a goal that is
  itself the whole query asked (`cocolog query 'X is 1/0'`, `:- foo.`
  with `foo` unknown) has no backtrace. `--no-backtrace` turns them off.
* **swipl prints a backtrace only with library(prolog_stack) loaded**, in
  the same `ERROR: In:` shape; cocolog always does.

The lines are written by the throw itself, before anything unwinds -- the
one moment the run is still there to read -- and only for a ball no catch
on the chain of engines would take, so a program that throws and catches
pays a walk over its choice frames and writes nothing. `test/backtrace.pl`
holds both shapes to the letter.

## A window, recorded

The tracer has a second mode, which writes no line: it RECORDS each port
as a term, with what the printer has no port for — the clause a call
entered, each head before it the selection tried that did not unify (a
clause the first-argument index passes over is never tried, and since
1.11.2 is not recorded either), an exception raised and where a `catch/3`
took it. `'$trace_window'(Goal, Options, Events, End)`
runs Goal at full speed, untraced, up to the inference a window opens at
(`from(I)`), and records from there (`to(J)`); the window opens in place,
inside whichever engine — a `findall/3`'s too — reaches that inference.
It records the ports the printer prints, one for one -- a retry's Redo
only once the retry enters a clause, as the printer writes it (1.10.13;
through 1.10.12 a Redo was recorded as every retry began, so a call that
had exited and was backtracked past quietly showed one the printer never
wrote). It is what `library(flow/debug)` stands on: lib/builtins.cicili
has the contract, DESIGN-flow.md 9.5 the plan, and `test/window.pl` holds
the recorder to the printer over the trace case's queries, and a window
to a recording of the whole run, event for event.

A window can also ASK (1.10.16): `ask(Cond, Holds)` proves Cond once
where the run stopped -- its last inference, its answer, its failure --
over the bindings the run left there, before anything is undone; Holds is
`true`, `false`, `limit` or `exception(Ball)`. A run stopped at `to(I)`
and asked is how "when did X become 5?" is answered without a debugger
in the run: `library(flow/debug)`'s `flow_when/4` bisects over such runs.

## A journal, and a replay answered from it

A run is its clauses and whatever came in from outside. With
`journal(record(File))` among its options, `'$trace_window'/4` writes
File: a line `j(I, Module, Name/Arity, CallText, Outcome)` for each
PORTAL call the run makes -- a call of a module that reaches the world:
the clock, the environment, a file, a stream, a socket, a process, a
thread and its channels, the knowledge base under `--kb` -- at inference
I, its text as `writeq` writes it (variables `_0`, `_1`, ...), and how it
went: `exit(Goal)` with what it bound, `fail`, `throw(Ball)`, or
`error(Message)`. A float is written so it reads back to the bit. With
`journal(replay(File))` each of those calls is answered from its entry and
NOT RUN -- the file is not appended to again, the thread not started, the
clock reads what it read -- and a replay that leaves the recorded run
stops where it does, its end `diverged(I, Want, Got)`: the journal's call
at inference I and the replay's, each `portal(I, Module, Name/Arity,
CallText)` or `none`, for another call where the journal holds one,
another argument, a call the journal holds made early or late, one past
its last, and a call passed by that nothing made. A run without a journal
dispatches exactly as before: the module seam's hooks are wrapped only
while a journal's window runs. `test/journal.pl` holds it to a record and
its replay in one process and in two, under collections every 2000 cells,
and to each divergence; `library(flow/debug)`'s `journal(true)` is the
same pair, a probe that records and a replay that replays (DESIGN-flow.md
9.2).

## How it works

The engine's design pays for itself here. The continuation is a term,
so the `Exit` port is nothing but a marker — `'$trace_exit'(Goal,
Depth, Parent)` — pushed behind a call's body: when the body has proven
its way through to it, the call has exited. Taking it is no inference
(the step the loop counted is given back), so the clock stays the
untraced run's. It sits below the choice
frame's heap mark, so no amount of backtracking into the call can lose
it — the same trick `catch/3` plays with its `'$catch'` term. `Redo`
and `Fail` live on a shadow of the choice stack: one tracer entry per
frame, index-aligned, deliberately **outside** the frozen format — a
machine frozen mid-trace thaws anywhere, carries its pending exits with
it (they are heap terms), and simply starts its shadow empty. Under
trace the last matching clause keeps its frame, because failing back
past it is what prints the `Fail` port; without trace it is popped, as
ever, and a loop runs in constant space. So does a call whose own cut
would take the frame (1.10.24): the cut leaves it, marked SPENT --
nothing to try -- with everything above it gone, and backtracking into
it prints the `Fail` and drops it. Whether a frame is a call's is told by
its depth, never by its goal: a goal can be heap cell 0, the first term a
fresh machine reads, and through 1.10.22 `cocolog --trace run F t` never
printed `Fail: t` for an atom goal `t` written first in the query.

## From Emacs

[cocolog-mode](emacs/README.md) drives all of this. `C-c C-e` traces a
goal over the buffer's file — the rule at point's own `?-` test comment
is the goal offered — into a `*coco trace*` buffer, each port in its
own colour, under whichever arrangement the `cocolog-coco` settings
name. And the tracer runs even when nobody asks: every execution graph
the mode draws (`C-c C-t`) is certified against the cocolog binary on
the spot, and the four-port trace of the rule's first query refreshes
alongside — the mode's own engine draws, coco has the last word.
