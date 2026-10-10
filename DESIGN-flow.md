# Flows: a program drawn as it can run, and as it ran

**A plan, with its first step built.** F0, the look, is
`library/flowchart.pl` on the work branch `claude/cocolog-llm-agent-design-rh7t3t`
(`7a11896`). Nothing else here is built. Each phase lands on master when the
owner says so, with its case, its lesson and its version.

## 1. What the flows are for

Two libraries, one prefix:

* **`library(flowchart)`** draws what a predicate CAN do: from the query down
  to every C function it reaches, and back, with the mode of every argument,
  the determinism of every call and where every failure goes. It is driven by
  the program, never by data, so it is not a debugger.
* **`library(flowdebug)`** draws what a query DID: the same chart with the
  path taken, and the data that crossed it as numbered discs listed under the
  chart. Its hard problem is cost: it must not slow down the run it explains.

Each has three readers: a person reads the SVG, an agent reads the XML, and a
test reads the graph as a Prolog term. The owner's aim for the second reader:
agents that write large programs and grammars -- the translator in
`library/reasoning/`, the owner's cicilang compiler -- read the XML to find
what is wrong and where.

That is the thesis, *a language that talks to its developer*: both pictures
come from facts the system already holds, with no annotations and no
instrumented build.

## 2. Decided (the owner, 2026-10-10)

* **Names.** `library(flowchart)` and `library(flowdebug)`, and every
  predicate of both begins `flow_`. cocolog has no module system -- clauses
  of one name from two files join into one predicate without a word -- so
  flowdebug's own helpers begin `flow_dbg_` and never share a name with
  flowchart's.
* **Layout is our own, and clarity comes first:** better than Graphviz, by
  never asking a general graph layout to guess (section 3).
* **Modes.** A builtin's come from a hand-kept table; user code's are
  inferred, so a program with no declarations still gets them.
* **C is a portal.** The flows never trace inside C. The chart ends at a C
  function and names its module, its C function, and the file and line of
  the table row that maps one to the other.
* **Grammar rules are predicates** (section 5).
* **Every front predicate writes an SVG and an XML** (section 6).
* **Threads and processes are drawn** so that it is plain which code runs
  where, what crosses between them, and what never comes back (section 7).
* **The tables are generated at build time** from the sources; F0 borrows
  cocolint's, F1 has its own. Modules may export them at run time later.
* **The debugger's journal is opt-in**: the default run is untouched.

## 3. What F0 settled: the look

Measured on two fixtures, each drawn in under 0.3 s: `report(+, +, +)`,
six panels and the query's in 3417 by 951 pixels, and a gallery of every
construct, five panels and the query's in 3880 by 782.

* **A predicate is a PANEL**, numbered, in Byrd's box model: the call enters
  at the top left, the exit leaves at the top right, a failure leaves at the
  bottom left. Its header is the moded head (`grep_count(+Pat, +Text, -N)`),
  then its kind (and library), its determinism and its number of clauses.
* **A clause is a ROW**: its head in a rounded box, then its goals on one
  line. The clauses hang off the left RAIL, each numbered where the rail
  enters it.
* **Boxes by kind**: the program's own predicate (white, carrying the number
  of the panel it calls), a library predicate (dashed), a builtin (grey), a
  test (an amber hexagon), a unification (pale), a C function (teal, with a
  `C` plaque and the number of its panel), a cut (an orange bar).
* **Under each row a dashed red LANE says where each failure goes**: back up
  into the NEAREST goal to its left that can redo (`↻` marks a goal that can
  leave a choice point), else down the rail to the next clause, else -- past
  a cut -- to a red `fail !` tag under the cut: the whole call fails. The end
  of a row carries `↶`, where backtracking into the clause after it exited
  enters, and it follows the same rule. Because a failure always goes to the
  nearest such goal, two failures whose spans overlap share their target, and
  **lanes never cross**.
* **Constructs are boxes of TRACKS**: an if-then-else (each condition in a
  dotted frame, the else dropping in amber), `;` (a track per branch, the
  retries in red), `\+`, `findall/3,4`, `forall/2`, `aggregate_all/3`,
  `once/1` and `ignore/1` (each labelled with what it does: *every
  solution*, *for every one*), and `catch/3` (the throw going in purple to
  its recovery).
* **Between panels a dark lane takes the call (▶) and a green one brings the
  answer back (◀)**, six pixels apart, through a gutter whose tracks are
  ordered to cross as little as the wires allow. Each panel is placed level
  with the call that first reaches it, so most wires are straight. `↺` marks
  a call to itself.
* **Modes on every argument**: `+` blue, `-` orange, `?` purple, `:` green.
* **Determinism is read off the analysed goals**, not guessed from names: a
  choice left after a clause's last cut makes it nondet; it is det when no
  clause that can be reached can fail.
* **Names are the author's**: a `%% p(+A, -B)` comment, a library's own
  header (`;;;` lines in a module's Cicili), else the first clause head's
  variables.
* **The SVG is written through `library(xml)`**, presentation attributes
  only, with a tooltip on every box giving its full text and its kind.

**Why the layout can beat a general one.** Prolog's control is sequence and
choice, nested, so a panel is laid out from its clauses directly -- one main
line per clause, a row per choice, a lane per failure -- and the only general
problem left is the wires between panels, which run one way through gutters
whose track order is chosen by counting crossings.

## 4. `library(flowchart)` in full (F1)

### 4.1 The front predicates

```prolog
flow_chart(+Spec, +Base)              % writes Base.svg and Base.xml
flow_chart(+Spec, +Base, +Options)
flow_graph(+Spec, -Graph, +Options)   % the analysis as a term: what the tests check
flow_svg(+Graph, -Svg)                % library(xml) terms, for a program that
flow_xml(+Graph, -Xml)                % wants the documents and not the files
```

`Spec` is a call pattern (`report(+, +, -)`), `Name/Arity` (every argument
`?`), or `Name//Arity` for a nonterminal, whose two list arguments are then
`+` and `-` (parsing). Options: `source(File)` or `files(Files)` (the
program), `title(T)`, `libraries(reach | all | none)` (`reach`, the default,
makes a library predicate a panel only on a path that reaches C), and
`depth(D)`.

For an agent in any language, one command writes both files:

```sh
cocolog -s tools/flow/chart.pl -- 'report(+,+,+)' demo.pl out/report
# out/report.svg and out/report.xml; exit 0, 1 for no such predicate, 2 for an error
```

### 4.2 Reading a program

* **Source files with their variable names and their positions.**
  `read_term/3` keeps `variable_names` but ignores `term_position`, so each
  clause's byte range comes from `stream_position/2` taken before and after
  it, and each goal is found by scanning the clause's own text in reading
  order, past quoted atoms, strings, comments and `0'c`. Every clause and
  every goal gets a line and a column.
* **Library predicates and the Prolog half of a module** are read with
  `clause/2` and named from the library's header.
* **A dynamic predicate** is drawn with the clauses its files hold and marked
  as changing at run time.

### 4.3 Classifying a goal

In the engine's own dispatch order: a control construct, a test, a
unification, a C builtin, a C function of a module (a portal), the program's
own predicate, a library predicate, the Prolog half of a module, a
concurrency primitive (section 7), a dynamic predicate, or unknown -- an
existence error when it runs, and a finding (section 8).

**The tables.** `tools/flow/tables.pl` reads the builtin tables in
`lib/*.cicili` and each module's dispatch rows in `modules/*/*.cicili` with
their signature comments (`("re_first" 3 coco_x_first) ; re_first(+Pat,
+Text, -MatchCodes)`); torch, tensorflow and bigint dispatch by hand and get
their rows by hand. `make` writes the result to `library/flow/tables.pl`,
which git ignores, and the library names it when it is missing. The
hand-kept mode table -- a line per way of calling a builtin, as SWI's manual
lists them, so `length(+L, -N)` is det and `length(-L, -N)` nondet -- is
source, in `library/flow/modes.pl`, and `test/flowchart.pl` requires a line
for every C builtin the generated table names.

### 4.4 Modes and determinism

* F0's inference -- which variables are bound when each goal runs, each
  predicate's success pattern remembered per call pattern -- with the
  recursion taken to a fixed point. (F0 assumes a recursive call binds its
  outputs and stops there.)
* **A predicate met with two call patterns gets a panel for each**, since its
  modes, its determinism and its lanes differ.
* A closure whose name is known (`maplist(foo, L)`) is a call to `foo/N+k`;
  one that is not is a `call/N` box marked as decided at run time.

### 4.5 Scale

The yardstick is the translator: `library/reasoning/` is some 24 000 lines.
F1 measures the analysis time and the chart's size on it. **The XML is never
pruned**; the SVG may be (`depth(D)`, `only(Preds)`), and a pruned panel is a
stub that names what it hides.

## 5. Grammar rules are predicates

* **A nonterminal `name//N` is the predicate `name/N+2`**, analysed, numbered
  and wired exactly as one.
* **A rule is translated by the engine's own translator**, `'$dcg_goal'/4` in
  `lib/dcg.cicili` -- what `phrase/3` runs -- so the chart is of the clause
  that runs and not of a reimplementation. Its leading terminal is lifted into
  the head as the store does it (`coco_dcg_leading`): `a --> [x], b` is drawn
  as the stored `a([x|S1], S) :- b(S1, S)`, whose head can fail when the input
  is bound.
* **The hidden list arguments are named `S0`, `S1`, ... in reading order**
  (another letter when the rule already uses `S` names), so the thread of the
  input reads off the chart. A terminal is a unification box, its codes shown
  as a quoted string when they are printable.
* `{G}` is `G`; `!` is a cut, local to the rule as it is in the translation;
  `\+` is a negation; `call//N` is `call/N+2`; a pushback is a unification
  after the body; `phrase/2,3` and `call_dcg/3` are calls into the
  nonterminal.
* **In the XML**, a goal from a grammar body carries its grammar form
  (`dcg="terminal"`, `dcg="nonterminal" nt="digits//1"`, `dcg="goal"` for a
  `{}`), and the rule carries its source text.
* **Grammar findings** (section 8): left recursion -- a nonterminal that can
  reach itself before consuming input, which loops when parsing -- and a
  nonterminal that can succeed without consuming anything where that is what
  closes such a loop.

## 6. Two outputs: an SVG for a person, an XML for an agent

Every front predicate writes both, from one graph term, so the two cannot
disagree. **They share their ids**: panel `p3`, its second clause `p3.c2`,
that clause's fourth goal `p3.c2.g4`, and inside a construct the track and
the goal, `p3.c2.g4.t1.g2`. In the SVG each box is a `<g>` carrying its id,
so a finding in the XML points at a box in the picture.

```xml
<flow version="1" tool="library(flowchart)" spec="report(+,+,+)" source="demo.pl">
  <lane id="main" kind="thread"/>
  <panel id="p2" pred="grep_count/3" kind="user" lane="main" det="det"
         head="grep_count(+Pat, +Text, -N)" file="demo.pl" line="20">
    <clause id="p2.c1" line="20" col="1" head="grep_count(Pat, Text, N)" head_fails="false">
      <goal id="p2.c1.g1" line="21" col="5" kind="library" pred="codes_lines/2"
            text="codes_lines(Text, Lines)" modes="+ -" det="det"/>
      <findall id="p2.c1.g2" line="22" col="5" text="findall(L, …, Hits)" modes="? : -" det="det">
        <track id="p2.c1.g2.t1">
          <goal id="p2.c1.g2.t1.g1" kind="builtin" pred="member/2" text="member(L, Lines)"
                modes="- +" det="nondet" on_fail="done"/>
          <goal id="p2.c1.g2.t1.g2" kind="c" pred="re_match/2" calls="p5" text="re_match(Pat, L)"
                modes="+ +" det="semidet" on_fail="p2.c1.g2.t1.g1"/>
        </track>
      </findall>
      <goal id="p2.c1.g3" line="23" col="5" kind="builtin" pred="length/2"
            text="length(Hits, N)" modes="+ -" det="det"/>
      <redo to="fail"/>
    </clause>
  </panel>
  <panel id="p5" pred="re_match/2" kind="c" module="text" cfun="coco_x_match"
         file="modules/text/text.cicili" line="53" det="semidet" head="re_match(+Pat, +Text)"/>
</flow>
```

**What an agent can read off it.** For every goal: what it is (its text,
predicate and kind, and its file, line and column), its modes, whether it can
fail and whether it can leave a choice point, the panel it calls, and where
control goes when it fails (`on_fail`: the id of the goal that is redone,
`next_clause`, `fail` -- with the cut's id when a cut is why -- or, inside a
construct, `next_branch`, `else` or `done`). For every clause: where
backtracking into it goes once it has exited (`redo`). For every panel: its
moded head, determinism, lane and source. For C: the module, the C function
and the table row's file and line. And the findings.

It is written by `library(xml)` with `indent(2)`, in UTF-8, an element to a
line, so `grep` works on it as well as a parser does. The schema is versioned
(`version="1"`) and documented in the library's header; changing it bumps
that number. **The round trip is the test**: `test/flowchart.pl` reads the
XML back through `library(xml)` and checks it against the graph term.

## 7. Threads and processes (F2)

What the chart has to show, from the libraries themselves:

* **A thread shares nothing** (`modules/thread`): it is a goal proved on a
  machine, store and engine of its own. `thread_create/2` copies the goal as
  canonical text. A thread sees every module registered before it started
  and nothing the parent asserted or consulted. **Its bindings never come
  back**: `thread_join/2` answers `true`, `false` or `error(E)`.
* **A channel copies** terms as canonical text; a receive on a closed, empty
  channel fails.
* **A mutex serialises the world** -- files, sockets, the terminal -- not
  Prolog state. Mutexes are recursive, and an atom names a process-wide one.
* `run_isolated/2` proves a goal on a fresh machine and store and waits for
  it; an httpd `workers(N)` request is such a proof on a worker thread.
* A **cowork crew** (`library(cowork)`) is a set of worker threads started
  once; a job is a query proved once on some worker, its answer copied back
  (`cowork_ask/2,3`; `cowork_map/3` answers in input order;
  `cowork_post/2` with `cowork_poll/2,3`).
* **A child process** (`library(process)`) runs through `/bin/sh -c`:
  `proc_run/4` captures its output and its exit status, `proc_spawn/2`
  starts one in a session of its own, and `sh/1,2` are the short forms.
* **Processes share the knowledge base** under `--kb` and `--embed`, a
  commit at a time, and they share the world.

How it is drawn:

* **Lanes.** The chart is cut into horizontal bands, one for each place code
  runs: the query's thread, each `thread_create/2` site, each cowork crew,
  each httpd pool and each `run_isolated/2` site. A panel reached from two
  places is drawn in each, because the same code running in two places is
  exactly what the reader needs to see.
* **A spawn is a fork**: a heavy dashed wire into the new lane, labelled with
  what is copied, and no answer wire comes back. A join is a thin wire back
  that carries the status only. `run_isolated/2` is the same, but waits.
* **A channel the analysis can follow** (made by `channel_new/1,2` in one
  place and handed on in a goal or an argument) is named `ch1`, and its sends
  and receives are tied by dotted message lines across the lanes; one it
  cannot follow is named by its variable.
* **Locks.** `with_mutex(M, G)` is a construct box with a lock mark and `M`'s
  name; `mutex_lock/1` and `mutex_unlock/1` are brackets; `cond_wait/2,3`,
  `cond_signal/1` and `cond_broadcast/1` have marks of their own.
* **A child process is a PROCESS portal**: like C, the end of the chart,
  showing its command when the command is a literal. A literal command that
  runs cocolog on a file names that file's own chart; it is never merged
  into this one.
* **A write to the knowledge base** (`assertz/1`, `retract/1` and their kin)
  carries a mark: under `--kb` or `--embed`, other processes see it at commit.
* **In the XML** each lane is a `<lane>`, every panel names its lane, and
  spawns, joins, sends, receives and locks are elements with ids.

Its findings: a goal run in a thread that calls a predicate the parent only
consulted or asserted (an existence error in the thread, which sees modules
only); a `mutex_lock/1` with a way out that does not unlock; a thread that is
neither joined nor detached.

## 8. Findings: what is wrong, and where (F3)

The analysis already knows things a programmer would want to be told. Each
finding has a kind, a severity, a sentence, the id of the goal it is about
and its file, line and column. It is written in the XML and flagged on the
chart as a numbered red marker on the box, listed under the chart.

1. **Unknown procedure**: no clause, no builtin and no module answers the
   call.
2. **Instantiation risk**: a call whose table line needs `+` where the
   argument is free on every path, such as `X is Y + 1` with `Y` free.
3. **Left recursion**: a predicate or nonterminal that calls itself again
   with nothing more bound -- for a grammar, before consuming any input.
4. **A broken determinism promise**: a `%! p(...) is det` comment against
   the inferred word.
5. **A clause that is never reached**: an earlier clause matches every call
   of this pattern and cuts before anything can fail.
6. The concurrency findings of section 7.

cocolint stays the linter (singletons, the dialect's traps); a finding here
is one only the flow analysis can see.

## 9. `library(flowdebug)`: what a query did (D0-D4)

```prolog
flow_debug(+Goal, +Base, +Options)    % writes Base.svg and Base.xml
    % window(N), at(I), from(I), to(I), until(exception | fail | answer(K)), view(flow | tree)
```

* **The picture** is the flowchart with the path taken drawn heavy, the
  failed edges red and the untaken ones grey.
* **Numbered discs** mark where a value crossed: a binding at an exit, an
  argument at a call, and a binding undone on backtracking (drawn hollow).
* **Under the chart, a legend**: each disc's number, the variable by its
  source name, its value, the port, the clause and the inference number.
* **A tree view** unrolls recursion, eliding long runs.
* **The XML of the run** holds the events (inference number, thread, port,
  the goal's id in the chart, depth) and the bindings (disc, source name, the
  value as canonical text, cut to a length with the whole length given), the
  clause tried, the cut taken and the exception raised. It is joined to the
  chart's ids, so an agent can ask which goal failed last, and with what.

### 9.1 No overhead: replay instead of instrumenting

The run being explained is never instrumented. Three facts make that
possible:

* a run is determined by its clauses, the knowledge base and whatever came
  in through portals;
* **the inference count is a clock** that the fast engine and the tracer
  keep alike -- the same goal against the same clauses spends the same
  inferences in every process (`call_metered/4`);
* the tracer can be switched on part way through a run (`trace/0`).

So the debugger works in four steps: **probe** (run the goal untraced, to
learn its total inferences and the inference at which it failed or threw),
**fast-forward** (run it again untraced, at full speed, to N minus the
window), **record** (switch on a tracer that records instead of printing, so
only the window pays for tracing), and **draw**. "When did X become 5?" is
then a binary search over inference numbers: a handful of fast runs and one
recorded window.

Two things already exist for this. A machine started with `start` advances
with `step --steps N`, and under `--trace` a step prints exactly the ports of
the inferences it spent (TRACING.md): fast-forward-then-trace, with no engine
change, for a goal run as a machine. And the step loop already checks an
inference limit; a limit that switches the tracer on instead of stopping is
a branch taken once, at the limit, with no new test on the hot path. D0
checks both.

**Proving it costs nothing**: every new hook sits on a branch the untraced
engine never takes; callgrind's instruction counts on the untraced path
(nrev, queens, lookup) are identical before and after; `bench/langs.sh` runs
as within-run pairs.

### 9.2 What could make a replay differ: the journal

* **Inputs from outside**: the time, random numbers, the environment, I/O,
  sockets, child processes, and the knowledge base's fetches under `--kb`.
  An opt-in journal records their answers at the impure calls only, never in
  the step loop; a replay answers from the journal and does not repeat the
  side effects.
* **The knowledge base changing** between the run and the replay. The journal
  also records the inference count at each portal call, so a replay that
  reaches a portal at another count stops with *diverged at inference N*
  instead of drawing a wrong picture.

### 9.3 Threads and processes in the debugger

* **Sharing nothing makes a thread replayable on its own.** What reaches a
  thread from its siblings is what `channel_recv/2,3`, `thread_join/2` and a
  crew's answers hand it -- copies, already canonical text -- so a journal of
  those, per thread, is the whole of its input from the other threads. The
  interleaving needs no replaying, because no cell is shared; only the world
  is, and the world is journalled at its portals.
* **Each thread has its own inference clock** (`statistics/2` is about the
  calling thread). A message line between two lanes carries both ends'
  numbers: sent at inference 1 204 on `t1`, received at 87 on `main`.
* **A process is replayed as a process.** Its inputs are its command line,
  its environment, files and pipes, journalled the same way. The parent's
  debug run names the child's journal, and the child's chart is its own.

### 9.4 Engine work, all on paths only tracing takes

A record mode that appends fixed-size events to a buffer; new events for a
clause entered (with its number), a head that did not unify, a cut, and an
exception raised and caught; a builtin `'$trace_window'(Goal, From, To,
Events)`; and a journal call in the module SDK. The recorded events are
matched to the chart's boxes by walking each clause activation's calls in
order.

## 10. Phases

| phase | delivers | engine change | lands |
|---|---|---|---|
| F0 | the look, on two fixtures | none | built, on the work branch |
| F1 | `library(flowchart)`: generated tables, the mode table a line per mode and checked against the engine, modes to a fixed point, a panel per call pattern, grammar rules, source positions, the XML beside every SVG, `tools/flow/chart.pl`, `test/flowchart.pl`, `tutorials/library/50-flowchart.pl` | none | proposes 1.11.0 |
| F2 | threads and processes: lanes, spawn and join, messages, locks, process portals, writes to a shared knowledge base | none | proposes a minor |
| F3 | findings, in the XML and on the chart | none | proposes a minor |
| D0 | the zero-overhead harness (callgrind on the untraced path); fast-forward with `start`/`step` and `--trace`; the inference-limit trigger | none | -- |
| D1 | the record-mode tracer, the new events, `'$trace_window'/4` | `lib/solve.cicili`, `lib/builtins.cicili` | a patch |
| D2 | `library(flowdebug)`: the run over the chart, discs, legend, tree view, the run's XML | none | proposes a minor |
| D3 | the journal, per thread and per process; replay; divergence | builtins, the module SDK | proposes a minor |
| D4 | questions over the inference clock: the first inference where something holds, why a goal failed | none | proposes a minor |

## 11. Engine findings on the way (not fixed here)

* **`format/2`'s `~a` and `~s` copy their text through an 8192-byte buffer**
  (`lib/builtins.cicili:1112`): an atom or code list of 8192 bytes or more
  raises `format/2: ~s wants text`, which names the wrong cause. Measured:
  8191 codes are written, 8192 raise. The chart writer works around it by
  writing 4096 codes at a time. The fix is to put the text into the string
  builder by its length rather than through a fixed buffer, with a case and
  a patch bump of its own.
* **`write_term/2` ignores `variable_names`**, so the library writes terms
  with a grammar of its own (it needs each argument separately anyway, to
  colour it by its mode).
* **`read_term/3` accepts `term_position` and `subterm_positions` and does
  nothing with them**; positions come from `stream_position/2` and a scan of
  the clause's text (section 4.2).
* **There is no `predicate_property/2`**, and `current_predicate/1` answers
  about the knowledge base, not modules, which is why the tables are
  generated.

## 12. Prior art

Byrd's box model (1980); the Transparent Prolog Machine (Eisenstadt and
Brayshaw); SWI-Prolog's graphical tracer; the mode systems of Mercury and
Ciao; record-and-replay debuggers such as rr. In this tree, cocolog-mode
draws the SLD tree of a rule's test case in Emacs (`emacs/README.md`) and
TRACING.md's four-port tracer is held to SWI's port for port; the flows draw
the Byrd structure of a whole program instead, down to C, and keep the run
out of it until it is asked for.

What would be new: Byrd-box charts annotated with inferred modes that cross
into C as portals and show which thread runs what; a chart an agent reads as
easily as a person; and debugging with no overhead, by deterministic replay
keyed on an inference clock that the optimising engine and the tracer share
-- per thread, because the threads share nothing.
