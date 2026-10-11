# Flows: a program drawn as it can run, and as it ran

**A plan, with three steps built**, on the work branch
`claude/cocolog-llm-agent-design-rh7t3t`: F0, the look (`7a11896`); F1,
`library(flowchart)` in full -- `library/flowchart.pl` and its parts in
`library/flow/`, `tools/flow/`, `test/flowchart.pl` and
`tutorials/library/50-flowchart.pl`; and F3, the findings (section 8). F2
and `library(flowdebug)` are planned. Each phase lands on master when the
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
  leave a choice point), else down the rail to the next clause -- from the
  last clause, straight out through the panel's left border at the lane's
  own height, the fail port (through 1.10.4 it dropped to the bottom corner
  first) -- else, past a cut, to a red `fail !` tag under the cut: the whole
  call fails. The end
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
* **The SVG is a `library(xml)` term**, presentation attributes only, with a
  tooltip on every box giving its full text and its kind. (F1 writes it a
  piece at a time, section 4.5.)

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
flow_chart(+Spec, +Base, +Options, -Findings)
flow_graph(+Spec, -Graph, +Options)   % the analysis as a term: what the tests check
flow_findings(+Graph, -Findings)      % what is wrong, and where (section 8)
flow_svg(+Graph, -Svg)                % library(xml) terms, for a program that
flow_svg(+Graph, -Svg, +Options)      % wants the documents and not the files
flow_xml(+Graph, -Xml)
```

`Spec` is a call pattern (`report(+, +, -)`), `Name/Arity` (every argument
`?`), or `Name//Arity` for a nonterminal, whose two list arguments are then
`+` and `-` (parsing). Options: `source(File)` (the program), `title(T)`,
`libraries(none | reach | all)` (section 4.6: `none`, the default, never
opens a library predicate; `reach` opens one on a path that reaches C), and
for the picture alone `depth(D)` and `only(Preds)` (section 4.5). A program
in several files (`files(Files)`) is not built yet: a file's own
`use_module` directives load the rest, which the chart reaches as
libraries.

For an agent in any language, one command writes both files:

```sh
cocolog -s tools/flow/chart.pl -- 'report(+,+,+)' demo.pl out/report [depth=N] [only=a/2,b//1] [libraries=reach]
# out/report.svg and out/report.xml; exit 0, 1 for no such predicate, 2 for an error
# then each finding as a compiler writes one:
# test/flowchart/faults.pl:35:5: error: total/2: S is free on every path to here, and is/2 evaluates it: ... [instantiation p2.c1.g1]
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
* **A dynamic predicate** is one the file declares (`:- dynamic p/1.`, read
  with the clauses), or one with no clause that the store defines --
  declared by a file the program loads, or asserted and emptied. It is
  drawn with the clauses the file starts it with, if any, and what it
  answers is not taken from them: it may bind any argument, fail, or answer
  again (1.10.3).

### 4.3 Classifying a goal

In the engine's own dispatch order: a control construct, a test, a
unification, a C builtin, a C function of a module (a portal), a dynamic
predicate, the program's own predicate, a library predicate, the Prolog half
of a module, or unknown -- an existence error when it runs, and a finding
(section 8). A goal known only when it runs -- a variable, or `call/N` with
a closure the source does not name -- is a closure. A concurrency primitive
(section 7) is today a portal or a library call like any other; F2 gives it
a kind of its own.

**Dynamic or unknown is the engine's own question**, and the chart asks
the engine: a call to a predicate with no clause fails when it is declared
dynamic and raises `existence_error` when it is not, and
`current_predicate/1` answers yes only for a predicate with a clause or a
declaration (section 11 has why that needed 1.10.3).

**The tables.** `tools/flow/tables.pl` reads the builtin tables in
`lib/*.cicili` and each module's dispatch rows in `modules/*/*.cicili` with
their signature comments (`("re_first" 3 coco_x_first) ; re_first(+Pat,
+Text, -MatchCodes)`); torch, tensorflow and bigint dispatch by hand and get
their rows by hand. `make modules` writes the result to
`library/flow/tables.pl` (`sh tools/flow/build.sh`, which needs a built
cocolog), git ignores it, and the library names the command when it is
missing. The
hand-kept mode table -- a line per way of calling a builtin, as SWI's manual
lists them, so `length(+L, -N)` is det and `length(-L, -N)` nondet -- is
source, in `library/flow/modes.pl`, and `test/flowchart.pl` requires a line
for every C builtin the generated table names.

### 4.4 Modes and determinism

* F0's inference -- which variables are bound when each goal runs, each
  predicate's success pattern remembered per call pattern -- with the
  recursion taken to a fixed point. A PAIR is a predicate and a call pattern;
  each pair the query reaches is analysed against what its callees are known
  to do so far (a call not yet known to succeed binds nothing, and its
  clause counts for nothing past it), and again whenever one of those answers
  changes, until none does.
* **A worklist, not rounds.** F1 first analysed every pair again each round;
  on the translator that took 26 rounds, 2.1 G inferences, 244 s and 6.6 GB,
  the set of pairs swinging between 3000 and 5500 because calls past a goal
  not yet known to succeed made pairs of their own. Now a pair is analysed
  again only when an answer it read has changed -- new pairs first, so
  callees settle before their callers come round, re-analyses last -- and a
  call past a goal not known to succeed makes no pair. On the translator:
  6887 analyses of 2978 pairs, 266 M inferences, 28 s, 1 GB. A pair whose
  answer changes 16 times is widened to the answer that says least, so the
  analysis ends whatever the program; the translator's most changed 5 times.
* **A goal past a call that never succeeds is drawn, unreached**: the XML
  says `reached="false"`, its tooltip says why, and what it would call gets
  no panel.
* **A predicate met with two call patterns gets a panel for each**, since its
  modes, its determinism and its lanes differ.
* **What a test says, and what never runs** (1.10.4, from F3: the
  translator's first findings were three false ones from these gaps). A
  type test that succeeds says what it holds of is bound -- `atom/1`,
  `number/1`, `atomic/1`, `string/1`, `ground/1` and their kin -- or at
  least partly -- `nonvar/1`, `compound/1`, `callable/1`, `is_list/1` -- and
  an arithmetic comparison that succeeds says both sides were numbers. A
  test that can never hold -- `atom/1` of a variable free on every path,
  `var/1` of a bound one -- ends the clause there, as `fail`, `throw/1` and
  a call the engine refuses do: what follows is drawn, unreached. A head
  with one variable in two input places can fail to match (`p(X, X)` called
  `(+, +)`), and a head argument that is a structure leaves the caller's
  variable partly bound, not free (`wrap(box(_))`). A partly bound argument
  meets either side of a builtin's mode line when no line fits exactly --
  `G =.. [C, W]` with `W` free is the `(-, +)` line, so `G` is bound after
  it -- and where it stands for an output the answer is unified with it, so
  a det line can fail there (`A =.. [K, which(W)]` tests what `A` is). On the
  translator the same 999 predicates have 2554 call patterns where they had
  2897: patterns merged where a test now binds.
* **`call/N` is the goal it makes**: `call(double, X, Y)` and
  `call(double(X), Y)` are analysed and drawn as `double(X, Y)`. A closure
  the source does not name -- `call(Goal, X)` with `Goal` a variable, or a
  variable goal -- is a CLOSURE box: it may fail, may leave a choice, and may
  bind what it is handed (until 1.10.3 an explicit `call/N` of one was
  `unknown`, and a closure was taken to leave no choice). A closure passed
  to a library is not followed yet: `maplist(foo, L)` is a box with its
  table line (`:` for the closure), and a call to `foo/N+k` is the next
  step.

### 4.5 Scale

The yardstick is the translator: `reason_translate(+, -)` over
`library/reasoning/translate.pl`, 1066 predicates and 3255 clauses in 19 815
lines, reaches 2897 panels.

* **The XML is never pruned; the SVG may be.** `depth(D)` draws panels at
  most D calls deep, `only(Preds)` those predicates' panels, and a panel a
  drawn one calls that is not drawn itself is a STUB: its moded head, its
  determinism, why it is not drawn, and how many panels hang from it. A C
  function is drawn whenever its caller is. With neither option a chart of
  more than 150 panels is drawn to the deepest level that fits with its
  stubs, and says so under its title.
* **Both files are written a piece at a time** (`library/flow/write.pl`),
  the bytes `library(xml)` writes (the case checks it), because
  `library(xml)` makes a document as one code list: the translator's XML is
  45.6 million codes (52 s, 251 M inferences) and its SVG ran the process out
  of memory -- the first chart of the translator ended with exit 1 and no
  word after 334 s at 9 GB. The writer escapes a value with one
  `split_string/4` to see whether there is anything to escape, and an
  attribute is one `format/3`: the XML takes 8.8 s and 51 M inferences.
* **Measured** (`cocolog -s tools/flow/chart.pl -- 'reason_translate(+,-)'
  library/reasoning/translate.pl out/tr`, this box): 45.5 s and 1.69 GB at
  the peak; the SVG is 1.28 MB, 57 of 2897 panels drawn to depth 4 with 83
  stubs; the XML is 45.6 MB. Reading the file takes about 4 s, the analysis
  about 28 s, the XML about 15 s to build and write (separate runs, so the
  parts do not sum exactly). The analysis's dearest pairs are the
  largest clauses: a state is a list searched by `==`, so a clause costs about
  goals x variables^2 (`tr_read0/4`, 72 clauses of up to 77 variables, is a
  million inferences an analysis) -- the next thing to make cheaper.

### 4.6 Builtins are drawn, and never gone inside (the owner, 2026-10-11)

"Add a flag to default not go through builtins", and then, of what 1.10.2
made of it: "I mean show builtins predicate in chart but don't go through
them inside to trace", and "`⋯ 1` is not readable for user and hides the
information".

1.10.2 had read the first as keeping builtin work off the flow line: each run
of builtins, tests, unifications and library calls was folded into one `⋯ N`
box, its goals only in the tooltip. Half of the translator's 87 389 goals
are such work, so half of what the chart says was hidden. 1.10.5 takes that
out, and does what was asked:

* **Every goal is a box with its own text**, a builtin, a test, a
  unification and a library call as much as a call of the program's own:
  `code_type(C, alpha)`, `S1 = S0`, `length(Ws, N)` stand on their clause's
  line where they run, with the choice mark and the failure lanes they
  earn. Every goal the XML names is a box of its own in the SVG (the case
  checks all of them).
* **The chart never goes inside a builtin.** A C builtin of the engine never
  had a panel. A library predicate is now one too, a dashed box, unless
  `libraries(reach)` or `libraries(all)` asks for its clauses -- through
  1.10.4 `reach` was the default, and a library predicate standing on a path
  to C was opened into panels of its clauses and of the C under it (the
  gallery's `re_lines/3`, library(text)'s, and its `re_match/2`). Its
  clauses are still analysed, for what it binds and how it can end.
* **A construct still shows the goals it was handed** -- `findall/3`'s,
  `phrase/2`'s grammar, a condition -- because those are the program's own;
  only the builtins among them are leaves.
* **A C function called by the program is still its portal panel**
  (section 2: the chart ends there, naming its module, its C function and
  its table row).

The translator's chart on 1.10.5: 21 051 by 8072 px (15 157 wide folded in
1.10.2), the SVG 1.28 MB and the XML 38.6 MB, in 51 s on this box.

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
  input reads off the chart; a rule's panel head with no comment to name it
  calls the pair `S0` and `S` (`blanks(+S0, -S)`). A terminal is a
  unification box, its codes written `0'c` (`rest(A, V, [0'+|S0], S4)`).
* `{G}` is `G`; `!` is a cut, local to the rule as it is in the translation;
  `\+` is a negation; `call//N` is `call/N+2`; a pushback is a unification
  after the body; `phrase/2,3` and `call_dcg/3` are a box holding the
  nonterminal's call, with the list in and `[]` or the rest out.
* **In the XML**, a goal from a grammar body carries its grammar form --
  `dcg="terminal"`, `dcg="nonterminal word//1"`, `dcg="goal"` for a `{}`, and
  `dcg="pass"` for the `S1 = S0` the translator puts after a `{}` or a `!` --
  and the clause carries `dcg="true"` and its source text.
* **Grammar findings** (section 8): left recursion -- a nonterminal that can
  reach itself before consuming input, which loops when parsing -- and a
  nonterminal that can succeed without consuming anything where that is what
  closes such a loop.

## 6. Two outputs: an SVG for a person, an XML for an agent

Every front predicate writes both, from one graph term, so the two cannot
disagree. **They share their ids**: panel `p3`, its second clause `p3.c2`,
that clause's fourth goal `p3.c2.g4`; inside a construct the list a goal
stands in comes next -- `X.a1.if` and `X.a1` for an if-then-else's first
condition and its then, `X.else`, `X.b2` for a disjunction's second branch,
`X.try` and `X.recover` for `catch/3`, `X` itself for `\+` and a meta-call
-- so `p2.c1.g2.g1` is the first goal inside the `findall/3` that is
`p2.c1`'s second. In the SVG each box is a `<g>` carrying its id, so
whatever an agent finds in the XML it can point at in the picture. **An id
names one element**, in either document: an if-then-else's `<arm>` carries
only its number, its `<then>` the `X.a1` (through 1.10.3 both did), and a
finding points at places with `at=` and `ref=` (the case checks both
documents for a repeated id).

From `test/flowchart/demo.pl`, its `grep_count/3` (the clause's `<text>` and
the goals' `<arg>` children shortened):

```xml
<flow version="2" tool="library(flowchart)" title="report(+Pat, +Text, +Nums)" spec="report(+,+,+)" source="test/flowchart/demo.pl">
  <findings count="0" errors="0" warnings="0"/>
  <panel id="p2" pred="grep_count/3" kind="user" modes="+ + -" det="det" head="grep_count(+Pat, +Text, -N)" depth="2" clauses="1">
    <clause id="p2.c1" n="1" file="test/flowchart/demo.pl" line="20" col="1" head="grep_count(Pat, Text, N)" head_can_fail="false" redo="fail">
      <arg n="1" mode="+" text="Pat"/> ...
      <text>grep_count(Pat, Text, N) :- ...</text>
      <goal id="p2.c1.g1" kind="library" library="text" pred="codes_lines/2" text="codes_lines(Text, Lines)" modes="+ -" det="det" can_fail="false" choice="false" on_fail="fail" line="21" col="5"> ...
      <meta id="p2.c1.g2" name="findall" text="findall(L, …, Hits)" modes="? : -" can_fail="false" choice="false" on_fail="fail" line="22" col="5">
        <goal id="p2.c1.g2.g1" kind="library" library="lists" pred="member/2" text="member(L, Lines)" modes="- +" det="nondet" can_fail="true" choice="true" on_fail="p2.c1.g2:done" line="22" col="18"> ...
        <goal id="p2.c1.g2.g2" kind="c" module="text" pred="re_match/2" text="re_match(Pat, L)" modes="+ +" det="semidet" can_fail="true" choice="false" calls="p5" on_fail="p2.c1.g2.g1" line="22" col="36"> ...
      </meta>
      <goal id="p2.c1.g3" kind="library" library="lists" pred="length/2" text="length(Hits, N)" modes="+ -" det="det" can_fail="false" choice="false" on_fail="fail" line="23" col="5"> ...
    </clause>
  </panel>
  <panel id="p5" pred="re_match/2" kind="c" module="text" cfun="coco_x_match" file="modules/text/text.cicili" line="53" modes="+ +" det="semidet" head="re_match(+Pat, +Text)" depth="3"/>
</flow>
```

**What an agent can read off it.** For every goal: what it is (its text,
predicate and kind, and its file, line and column), its modes, whether it can
fail and whether it can leave a choice point, the panel it calls, where
control goes when it fails -- `on_fail`: the id of the goal that is tried
again, `next_clause`, `fail` (with `past_cut`, the cut's id, when a cut is
why), or inside a construct the next arm's condition (`X.a2.if`), the else
(`X.else`), the next branch (`X.b2`) or the construct done with its goal
(`X:done`: `\+` succeeds, `findall/3` has every solution) -- and
`reached="false"` when it stands past a call that never succeeds. For every
clause: where backtracking into it goes once it has exited (`redo`). For
every panel: its moded head, determinism, depth and source. For C: the
module, the C function and the table row's file and line.

**The findings come first** (section 8), so an agent reading the head of a
45 MB file meets them: `<findings count errors warnings>`, then a
`<finding n kind severity at in file line col text>` each, with a `<see
ref>` for each other place it involves:

```xml
  <findings count="10" errors="7" warnings="3">
    <finding n="1" kind="instantiation" severity="error" at="p2.c1.g1" in="total/2" file="test/flowchart/faults.pl" line="35" col="5" text="S is free on every path to here, and is/2 evaluates it: this call raises an instantiation error"/>
    <finding n="5" kind="left_recursion" severity="error" at="p9.c1.g1" in="ping/1" ... text="ping/1 reaches itself again first, with the inputs it was given (ping/1 -&gt; pong/1 -&gt; ping/1): once this clause is reached it repeats for ever">
      <see ref="p24.c1.g1"/>
    </finding>
```

It is written with `indent(2)`, in UTF-8, an element to a line, so `grep`
works on it as well as a parser does. The schema is versioned
(`version="2"`; version 1, F1's, had no findings) and documented in
`library/flow/xml.pl`'s header; changing it bumps that number. **The round trip is the test**: `test/flowchart.pl`
reads the XML back through `library(xml)` and checks it against values
worked out by hand.

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

**Built** (1.10.4, on the work branch): `library/flow/findings.pl`. The
analysis already knows things a programmer wants to be told, and a finding is
one only the flow analysis can see -- cocolint stays the linter (singletons,
the dialect's traps). Each is about one place, named by the id the XML and
the SVG give it, and says in a sentence what will happen there:

| kind | severity | what |
|---|---|---|
| `unknown_procedure` | error | a call nothing answers -- no clause, builtin, module or dynamic declaration -- raises `existence_error`; the same name at another arity, or a name one edit away (a swapped pair of letters is one), is offered: `lenght/2 ... did you mean length/2?` |
| `instantiation` | error | a call the engine refuses with an argument free on every path to it: arithmetic over a free variable (`T is S + 1` before `S` is bound), a builtin of the refusal table handed a free argument, a closure with no goal in it |
| `left_recursion` | error | a predicate whose first call reaches itself again with the inputs it was given -- through others too, `ping/1 -> pong/1 -> ping/1` -- so the search for its answers never ends; a grammar rule that calls itself before reading any input is named as the nonterminal, `xs//0`. With nothing bound it is one only when no clause can succeed: `size(L, N)` of free `L` and `N` is a generator, as `length/2` is |
| `unreachable_clause` | warning | an earlier clause's head matches every call of this pattern and every goal before its cut succeeds, so the clauses after it are never tried |
| `det_promise` | warning | a `%! p(...) is det` (or `semidet`) comment, for the call patterns its modes cover, against what the analysis infers -- and the goal that breaks it: `when phrase(ws(Ws), Text) fails, so does the whole call` |

**The refusal table** (`flow_raises_unbound/4`, `library/flow/modes.pl`)
says which builtins raise when given which arguments unbound, 52 rows, each
with an example the case calls and requires to raise. It is not the mode
table: that one's `+` says INPUT, and `write(X)` and `format(F, X)` take an
unbound `X` happily. It was checked against the engine rather than written
from SWI's manual: cocolog's `char_type(_, _)` raises where SWI enumerates,
and its `assertz(_)` fails where SWI raises (section 11).

**"Free on every path" is the analysis's own word**, `f`: no goal before,
on any path, could have bound the variable (section 4.4). So an
instantiation finding is certain whenever the call is reached, and the call
never succeeds -- nothing after it runs. Only the program's own panels are
looked at (a library's clauses are not the program's to fix), and a goal past
a call that never succeeds has no finding.

**Where they go.** In the XML, first, before the panels (section 6). In the
SVG, a numbered disc on the box each is about -- red for an error, amber for
a warning; a clause's on its head, a predicate's on its panel's top right
corner -- with its sentence on hover, a line under the chart with its place,
and the count beside the title.
`tools/flow/chart.pl` prints each as a compiler would, `FILE:LINE:COL: error:
IN: TEXT [KIND ID]`, and still exits 0: a finding is no failure of the
command.

**What the translator taught.** Its first findings were three, all false:
two `atom_concat/3` calls past an `atom(W)` the analysis did not take to bind
`W`, and a `tr_solve/1` handed a `G` from `G =.. [C, W]`, which no mode line
of `=..` met. Tests that bind and modes met loosely (section 4.4) took them
away; the loose meet's own false finding -- `A0 =.. [Kind, which(Ws, C)]`
taken to succeed, so the clause after it was "never tried" -- went with the
rule that a partly bound output is compared. The translator now has none:
`test/flowchart/faults.pl` keeps those three as near misses that must find
nothing, with eight others (the same goals in the right order, a variable
bound on one path only, a recursion on the tail, a test before the cut, a
kept semidet promise, a dynamic predicate, a head with one variable in two
inputs, a variable a head binds). The case was run on sixteen arms, each a
copy of the library with one rule taken out, and went red on every one. Of
the other fixtures only two
findings are true and stay: `fix.pl`'s `spin/1` loops for ever, and
`runtime.pl`'s `nosuch/1` is defined nowhere.

**Not yet**: the concurrency findings of section 7 (F2); a call against a
documented mode (`%! p(+X)` called with `X` free); left recursion through a
construct or a library predicate; promises of `multi` and `failure`.

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
| F1 | `library(flowchart)`: generated tables, the mode table a line per mode and checked against the engine, modes to a fixed point by a worklist, a panel per call pattern, grammar rules, source positions, unreached goals, the XML beside every SVG written a piece at a time, `depth(D)` and `only(Preds)` with stubs and a 150-panel budget, every goal drawn by name, builtins too, and a library predicate never opened unless `libraries(reach|all)` asks (1.10.5; 1.10.2 folded builtin work into `⋯ N` boxes), `tools/flow/chart.pl`, `test/flowchart.pl`, `tutorials/library/50-flowchart.pl` | none | built, on the work branch; proposes 1.11.0 |
| F2 | threads and processes: lanes, spawn and join, messages, locks, process portals, writes to a shared knowledge base | none | proposes a minor |
| F3 | findings, in the XML first and on the chart as numbered discs, from `tools/flow/chart.pl` as a compiler's diagnostics: unknown procedures with a near name, calls the engine refuses unbound (a refusal table checked against the engine), left recursion, clauses never tried, determinism promises not kept; the analysis made to bind through tests and to end clauses at what never succeeds | none | built, on the work branch; proposes a minor |
| D0 | the zero-overhead harness (callgrind on the untraced path); fast-forward with `start`/`step` and `--trace`; the inference-limit trigger | none | -- |
| D1 | the record-mode tracer, the new events, `'$trace_window'/4` | `lib/solve.cicili`, `lib/builtins.cicili` | a patch |
| D2 | `library(flowdebug)`: the run over the chart, discs, legend, tree view, the run's XML | none | proposes a minor |
| D3 | the journal, per thread and per process; replay; divergence | builtins, the module SDK | proposes a minor |
| D4 | questions over the inference clock: the first inference where something holds, why a goal failed | none | proposes a minor |

## 11. Engine findings on the way

* **`format/2`'s `~a` and `~s` copy their text through an 8192-byte buffer**
  (`lib/builtins.cicili:1112`): an atom or code list of 8192 bytes or more
  raises `format/2: ~s wants text`, which names the wrong cause. Measured:
  8191 codes are written, 8192 raise. The chart writer works around it by
  writing 2000 characters at a time (a character is up to four bytes). The
  fix is to put the text into the string builder by its length rather than
  through a fixed buffer, with a case and a patch bump of its own.
  `library(xml)`'s own `xml_write/1,2` writes its document with one `~s`, so
  it fails the same way on any document of 8 KB or more.
* **`write_term/2` ignores `variable_names`**, so the library writes terms
  with a grammar of its own (it needs each argument separately anyway, to
  colour it by its mode).
* **`read_term/3` accepts `term_position` and `subterm_positions` and does
  nothing with them**; positions come from `stream_position/2` and a scan of
  the clause's text (section 4.2).
* **There is no `predicate_property/2`**, and `current_predicate/1` answers
  about the knowledge base, not modules, which is why the tables are
  generated.
* **`catch(_ =.. _, E, true)` ends the program** (exit 2, `=.. wants a
  proper non-empty list`): the error is raised where `catch/3` cannot catch
  it, where SWI raises a catchable `instantiation_error`. Found probing the
  refusal table; `=..` is not in it.
* **`assertz/1`, `asserta/1` and `retract/1` fail on an unbound argument**,
  where SWI raises `instantiation_error`; and `arg(1, _, _)` fails where SWI
  raises. None is in the refusal table, which holds only what raises.
* **Fixed in 1.10.3: `current_predicate/1` answered for any name a call or
  `clause/2` had looked up.** Both make an entry in the store's predicate
  table, and `'$predicates'/1` listed every entry, so a name that raises
  `existence_error` when called read as defined, and the chart called an
  undefined predicate dynamic once `clause/2` had asked about it. SWI
  answers only for a predicate with a clause or a declaration, and so does
  cocolog now (`lib/builtins.cicili`, `coco_b_predicates`;
  `test/files/builtins.pl` holds it to SWI's answer).

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
