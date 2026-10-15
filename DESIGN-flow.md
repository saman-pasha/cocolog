# Flows: a program drawn as it can run, and as it ran

**A plan, with four steps built.** On master since 1.10.8: F0, the look
(`7a11896`); F1, `library(flow/chart)` in full -- `library/flow/chart.pl` and
its parts in `library/flow/`, `tools/flow/`, `test/flowchart.pl` and
`tutorials/library/50-flowchart.pl`; and F3, the findings (section 8). Since
1.10.9 and 1.10.11: F2, threads and processes (section 7).
`library(flow/debug)`: D0 to D2 built in 1.10.12 and 1.10.13 -- the clock, the
recorded window, the run drawn over the chart (section 9.5); D3 and D4 next. Each phase
lands on master when the owner says so, with its case, its lesson and its
version.

## 1. What the flows are for

Two libraries, one prefix:

* **`library(flow/chart)`** draws what a predicate CAN do: from the query down
  to every C function it reaches, and back, with the mode of every argument,
  the determinism of every call and where every failure goes. It is driven by
  the program, never by data, so it is not a debugger.
* **`library(flow/debug)`** draws what a query DID: the same chart with the
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

* **Names.** `library(flow/chart)` and `library(flow/debug)` --
  `library/flow/chart.pl` and `library/flow/debug.pl`, each beside its
  parts (the owner moved them there on 2026-10-11, from
  `library(flowchart)` and `library(flowdebug)`) -- and every predicate of
  both begins `flow_`. cocolog has no module system -- clauses of one name
  from two files join into one predicate without a word -- so the
  debugger's own helpers begin `flow_dbg_` and never share a name with the
  chart's.
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

## 4. `library(flow/chart)` in full (F1)

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

* **Source files with their variable names and their positions.** Each
  clause's byte range comes from `stream_position/2` taken before and after
  it, and each goal is found by scanning the clause's own text in reading
  order, past quoted atoms, strings, comments and `0'c`. Every clause and
  every goal gets a line and a column. The scan was written when
  `read_term/3` ignored `term_position` and `subterm_positions`; it answers
  both as SWI does since 1.10.7 (section 11), and moving the scan onto them
  is a change to the chart, not made yet.
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
a closure the source does not name -- is a closure. A goal of
`library(thread)` is a `thread` goal with its role, a spawn a `spawn` with
its type, a child process a `process` (section 7): what it binds and how it
ends are still read from what it is underneath, a portal or a library call.

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
* **A recovery runs with the ball in its catcher** (1.10.28, from
  cicili-lang): `catch(G, E, R)` analyses R with E bound, and with a
  pattern's variables partly bound -- `catch(work(F), error(K, C), why(K,
  C))` calls `why/2` `(?, ?)` -- where through 1.10.27 R saw the catcher as
  free, and `report(error(N, _)) :- N > 0` raised a false instantiation
  finding in `ccl_driver.pl`'s `dr_error/3`.
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
<flow version="4" tool="library(flow/chart)" title="report(+Pat, +Text, +Nums)" spec="report(+,+,+)" source="test/flowchart/demo.pl">
  <findings count="0" errors="0" warnings="0"/>
  <lanes count="1">
    <lane id="l0" kind="query" root="query"/>
  </lanes>
  <links/>
  <panel id="p2" pred="grep_count/3" kind="user" lane="l0" modes="+ + -" det="det" head="grep_count(+Pat, +Text, -N)" depth="2" clauses="1">
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
  <panel id="p5" pred="re_match/2" kind="c" lane="l0" module="text" cfun="coco_x_match" file="modules/text/text.cicili" line="53" modes="+ +" det="semidet" head="re_match(+Pat, +Text)" depth="3"/>
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

**Then where the code runs** (section 7): `<lanes>`, the query's `l0` and
one for each place a spawn sends a goal, and `<links>`, what crosses between
them; every panel says its lane.

It is written with `indent(2)`, in UTF-8, an element to a line, so `grep`
works on it as well as a parser does. The schema is versioned
(`version="4"`; version 1, F1's, had no findings, version 2, F3's, no
lanes, and version 3, F2's, no jobs and no order of messages) and
documented in `library/flow/xml.pl`'s header; changing it bumps
that number. **The round trip is the test**: `test/flowchart.pl`
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

**Built** (1.10.9, on master): `library/flow/lanes.pl`, with the
analysis, the layout, the XML and the findings taught what it finds.
`test/flowchart/threads.pl` is the fixture -- a worker fed down a channel, a
pool, an isolated proof, a crew, an httpd pool, locks by hand and by
`with_mutex/2`, two child processes and the writes of a counter, four
predicates wrong on purpose and six near misses -- and lesson 50 has a
section of its own.

* **A lane for each spawn SITE**: `thread_create/2`, `thread_pool/3`,
  `run_isolated/2`, `cowork_ask/2,3`, `cowork_post/2`, `cowork_start/3`'s
  `on_start(G)` and `httpd_serve/2,3` with `workers(N)` (whose lane runs
  `httpd_page/3`, its path and request handed to it). A lane's ROOT is a
  panel of one row, the goal as it was sent, and each lane has panels of its
  own: `report/1` reached from five places is drawn five times. A spawn
  inside a lane starts a lane of its own. The index keeps which panel each
  call of a lane goes to, `L-PK -> Id`, beside the lanes and the links.
* **The copy is analysed as a copy.** A spawned goal is analysed with what
  is bound where the spawn stands, and nothing it binds comes back but what
  the spawn hands back: a thread's handle, `run_isolated/2`'s status,
  `cowork_ask/3`'s copy -- and `cowork_ask/2`'s answer, which is unified
  into the caller's goal. So a variable only a thread binds is free after the
  join, and `B is A + 1` there is an instantiation finding (the fixture's
  `lost/1`), where the same line after `cowork_ask/2` is none.
* **Drawn**: each lane but the query's is a band, below everything placed
  before it, opening with a rule and a line (`lane l1 · thread -- a thread of
  its own, started at p2.c1.g2 in lane l0`); a heavy dashed violet wire from
  the spawn into the root, labelled with what it copies; a thin violet wire
  back to the spawn's jack for what comes back, dotted for the status a join
  in the same panel reads (a detach reads nothing); a plaque on each goal of
  `library(thread)` saying its role and its channel or mutex (`recv ch1`,
  `lock log`), `$` on a child process and `KB` on a write; and a dotted blue
  line from each send of a channel to each receive of it, across the lanes.
* **A channel is followed** from `channel_new/1,2` through the clause's own
  variables, `X = Y`, the arguments callers hand (by passes until none
  changes; two callers handing different channels make one nobody can
  follow) and across a spawn, whose root holds the spawner clause's very
  variables. **That is why no `findall/3` may stand between a clause and the
  lane made from it**: it copies, and three copies -- the scan's queue, the
  panels it made, the root's own list -- each left the worker's receive
  named `Ch` instead of `ch1` (the case's arms put each back and go red).
* **The XML** (version 3, and 4 since 1.10.11, below): `<lanes>` -- each
  lane's kind, root, site, the lane it was started from, the goal, what it
  copies and what comes back --
  and `<links>`: `<spawn>`, `<join>` (with what it carries: the status, or
  nothing for a detach), `<channel>` with its `<close>`, `<send>` and
  `<receive>` ends (`followed="false"` and the variable's name for one it
  cannot follow), `<lock>`, `<process>` (its command when written, and the
  file whose chart is its own when the command runs cocolog on one) and
  `<write>`. Every panel says `lane=`; a goal of `library(thread)` says
  `kind="thread"` and its `role`, with `channel=`, `mutex=`, `condition=`
  or `joins=`; a spawn `kind="spawn"`, its `type` and `lane`; a child
  process `kind="process"`; a write `kb="write"`.
* **Findings** (section 8): `thread_unjoined`, a `thread_create/2` whose
  handle nothing else in the clause or its head names; `lock_held`, a
  `mutex_lock/1` with a goal that can fail before the clause's
  `mutex_unlock/1`; `thread_visibility`, a dynamic predicate called in a lane
  that does not write it where another lane does. The plan's existence error
  for a predicate the parent only consulted was left out: whether a thread
  sees a file's clauses depends on how the file was loaded (`-s` makes it a
  module, which every thread sees; `run` consults it, which none does), and
  the chart cannot know which.
* **What it costs a program with no thread in it**: one walk of every goal,
  indexed on the node and then its kind, finds the clauses anything links
  (`link_rows`), and every later pass reads only those. The translator
  charts in the same time and 3 MB more, for 0.84 % more
  inferences -- the analysis 0.7 %, the findings 1.9 %, the XML 1.3 %, the
  picture 2 %. The first version cost 7.4 %: channel following built an
  environment for every clause, and the spawn scan appended its queue once a
  panel.

**And what it left** (1.10.11, on master): `test/flowchart/crossing.pl` is
the fixture, a predicate charted at a time, and lesson 50 follows a
question down one channel and its answer down another.

* **`cowork_map/3`** is a lane whose root has a row for each job the source
  writes -- `c1`, `c2`, ... in the XML's `<job n>` -- and one row more,
  `rest="true"`, a goal known only when it runs, for a list or a tail it
  does not write. Each job is proved on its own with what is bound at the
  spawn, so a variable one job binds is free in the next (the fixture's job
  1 halves what job 2 doubles: an instantiation finding). Drawn, every job
  is called through the left border and each one that can fail leaves
  through it, worded `failed` -- its answer -- and never into the next job;
  the head says how many (`cowork_map/3: 3 jobs`). The reader places each
  job of a list the source writes (a new kind of meta-call argument, `l`).
* **`httpd_serve/2,3` with no `workers(N)`** serves on the caller's thread:
  a construct (`name="httpd_serve"`) whose goal is `httpd_page(Path,
  Request, Reply)` called here, the first two bound, named as the httpd
  lane's root names them; a page that fails is a 404, so the construct
  never fails, and the XML says its goal's failure goes to `X:next`. Its
  page reads what its own lane writes: no `thread_visibility`, where the
  same page on a pool is one. A `workers(W)` the source does not write is
  neither, and stays a box.
* **What crosses is FOLLOWED, not looked for in one clause**: a channel,
  `ch(K)`, a thread's handle, `th(L)`, or a pool's list of them, `ths(L)`,
  each at a PATH inside a term, through a clause's head (what its callers
  hand), its root (the spawner clause's environment), `X = T` and `arg/3`,
  `member/2` over a pool's list, a call (what the callee's clauses give
  back in their heads -- their own values only, never one handed in, which
  would hand a channel to a caller that passed nothing), and a receive
  (what every send down that channel sends, when they agree). It is settled
  by passes, the callers of a panel that gives something back joining the
  next pass; two places that disagree make the value `unknown`, and nobody
  follows it. So a join in another clause than its spawn's -- the handle
  handed back up out of a helper, or on down into one -- knows its lane,
  `thread_join_all([A, B])` joins both, and a reply channel sent with a
  question is followed into the thread that answers on it (`via="ch1"`).
  The join's badge was there; a fine dotted violet line now runs from the
  lane's root to a join that stands outside its spawn's panel.
* **A channel's order**: a lane is walked as it runs, from its root, goals
  left to right and into each call, and each send and receive of a channel
  gets its place among its lane's sends (or receives) -- `n="1"`, or
  `n="2 3"` for a helper called twice. A place the walk cannot know has
  none, nor has any later one of its kind on that channel in that lane: in
  a recursion, in a predicate of several clauses, inside a construct that
  may skip or repeat it, after a goal that can be redone, or in a lane that
  runs more than once (a pool, an httpd pool, a crew's `on_start`, a spawn
  its parent's walk does not meet exactly once). Where one lane sends and
  one receives, every one with its place, the channel `pairs="true"`: the
  k-th send is the k-th receive's, and the picture draws those lines alone,
  `ch1 #2`.
* **A lane's root is proved once**: nothing backtracks into it after it
  exits, so it has no redo mark and no redo lane.
* **The XML is version 4**: `<job n>` (and `rest="true"`) in a jobs root,
  a `<meta name="httpd_serve">` whose goal's failure goes to `X:next`, and
  on a `<channel>` `via=` and `pairs="true"`, on its ends `n=`.
* **What it costs a program with no thread in it**: the translator charts
  the same graph, findings, XML and picture, byte for byte, for 0.001 % more
  inferences (the `httpd_serve` clause first cost 0.22 % of the analysis,
  tried for every goal, until its heads let the index pass it by). Each of
  the twenty-one rules was armed -- taken out of a copy of the library --
  and the case went red on every one.

**Not yet**: a value held in the knowledge base (`assertz(chan(Ch))`) or
carried by `findall/3`, `maplist/2..` or any list but a pool's;
`cowork_post/2`'s answer, which `cowork_poll/2,3` collects. Where two lanes
send on one channel, or two receive, its messages have no order to read,
and that is the answer rather than a gap.

## 8. Findings: what is wrong, and where (F3)

**Built** (1.10.4, on the work branch): `library/flow/findings.pl`. The
analysis already knows things a programmer wants to be told, and a finding is
one only the flow analysis can see -- cocolint stays the linter (singletons,
the dialect's traps). Each is about one place, named by the id the XML and
the SVG give it, and says in a sentence what will happen there:

| kind | severity | what |
|---|---|---|
| `unknown_procedure` | error | a call nothing answers -- no clause, builtin, module or dynamic declaration -- raises `existence_error`; the same name at another arity, or a name one edit away (a swapped pair of letters is one), is offered: `lenght/2 ... did you mean length/2?`. A WARNING under a `catch/3` whose catcher takes that error (1.11.4): the recovery runs in its place, as `catch(Table(K, V), _, fail)` over a table consulted at run time means it to |
| `instantiation` | error | a call the engine refuses with an argument free on every path to it: arithmetic over a free variable (`T is S + 1` before `S` is bound), a builtin of the refusal table handed a free argument, a closure with no goal in it |
| `left_recursion` | error | a predicate whose first call reaches itself again with the inputs it was given -- through others too, `ping/1 -> pong/1 -> ping/1` -- so the search for its answers never ends; a grammar rule that calls itself before reading any input is named as the nonterminal, `xs//0`. With nothing bound it is one only when no clause can succeed: `size(L, N)` of free `L` and `N` is a generator, as `length/2` is |
| `unreachable_clause` | warning | an earlier clause's head matches every call of this pattern and every goal before its cut succeeds, so the clauses after it are never tried |
| `det_promise` | warning | a `%! p(...) is det` (or `semidet`) comment, for the call patterns its modes cover, against what the analysis infers -- and the goal that breaks it: `when phrase(ws(Ws), Text) fails, so does the whole call` |
| `discontiguous` | warning | (1.10.27) the clauses of a predicate the chart has a panel for stand in more than one place in the file and no `:- discontiguous` declares it: cocolog joins them without a word, so a clause given a name already taken joins that predicate. One finding a predicate, at the first clause that stands apart, naming the clause of another predicate before it |
| `defined_twice` | error | (1.10.28, from cicili-lang's report) the same, but a later place DEFINES it again: a clause there repeats one of an earlier place's (renamed apart), or its head is covered by an earlier place's fact -- so the second definition never answers first and every answer it gives comes again on backtracking. It replaces the `discontiguous` warning for that predicate, a declaration or none, and names both clauses and their lines |

**A program of several files** is charted a file at a time with
`load(Files)` (1.10.28; `load=` on the command, `library(Name)` or a
path): each is loaded before the file is read, as the program's top file
would load it, so a call into a sibling is a box of a loaded library and
not an unknown procedure, and a load that loads nothing is refused by
name. **A long chart says where it is** with `progress(S)`: a line on
stderr every S seconds of the analysis (pairs met, analyses made, queued)
and at each later phase; the library is silent by default and the command
says every 10 s. **A root that calls a whole file** (cicili-lang's 1,521
predicates of `ccl_cpp.pl`, from one clause) charts in 81 s where it did
not end in 30 minutes: the budget's 150 caps the stubs as it caps the
panels, the note saying how many calls past it went unmarked, the near
name of an unknown call is asked once a chart, and left recursion keeps
each predicate's first calls in one table, where a scan of every edge a
step took its 50 s.

**What a program declares as it runs** (1.11.4, cicili-lang's gate): a
table declared in a clause -- `dynamic(t/2)`, `assertz(t(K, V))`, or a
declarer of the program's own (`reset(F/A) :- abolish(F/A),
dynamic(F/A)`) called with the name written out, one level of it -- is a
dynamic predicate's to the chart wherever it would otherwise be unknown.
The goals are found by reading the source, the files `load(Files)` names,
the libraries the Prolog halves of `modules(Files)` load, and the files
each of those loads by `use_module/1,2` or `ensure_loaded/1` (found on the
library path as `lb_find` finds them, cocolog's own libraries passed by):
`read.pl`'s `flow_scan/4`, 0.5 s a chart of `ccl_cpp.pl` (8,776 lines),
whose `cpp_item/2` went from 880 unknown procedures to 209. **A module of
the program's own** is read from its Cicili source, `modules(Files)`: each
`("name" Arity c_function)` row of its tables a portal -- the modes from the
row's comment, else the header's signature list -- written as
`flow_t_portal/8` rows and loaded beside the generated ones for the rest of
the process, as `load(Files)` is. Those rows are the extension point: a file
of them given to `load(Files)` does the same by hand. **A name the chart's
library has** -- a helper of the program's named `flow_trim/2` -- joins the
library's clauses and breaks the chart far from the cause (a type error
inside the signature reader, in cicili-lang's case): a `flow_` predicate the
store holds more clauses of than the program's files give it is refused by
name before anything is analysed, the tables a program may add rows to
(`flow_t_*`, `flow_mode/4`, `flow_raises_unbound/4`) excepted. Held to the
chart's files, that missed a file the program loaded itself -- an
`ensure_loaded/1` in its query, after the library -- and it said a
`flow_` predicate the library does not have was the library's when two of
the program's files gave it clauses; since 1.11.7 the store is held to the
LIBRARY's own files instead (read once a process, 0.04 s for its twenty):
a predicate of a loaded part with more clauses than its file gives it is
refused, naming the chart's file that gives it one when there is one, and
saying the program loaded it itself when none does.

**What a builtin's success says beyond its line** (1.11.4): a mode line
says what a call needs and binds for the line met, and a loose meet (a `?`
argument) bound nothing it did not have to. Two facts are kept beside the
lines (`modes.pl`): a SINK holds the text written -- `format(atom(A), ...)`,
`with_output_to(string(S), ...)` bind `A` and `S`, and a difference list's
tail is left partly bound -- and TEXT MADE FROM TEXT BINDS EVERY ARGUMENT
whichever way it ran (`atomic_list_concat/2,3`, `atom_codes/2`,
`sub_atom/5`, ... -- each checked against the engine: `atom_length/2`
and `split_string/4` take any term, and are not among them). Both were
false findings of cicili-lang's: `sub_atom(A, 0, 1, _, '-')` after a
`format/3` into `atom(A)`, and `atom_concat(conv_, K, W)` after
`atomic_list_concat([op, W|_], '.', Name)` with `Name` partly bound, whose
loose meet took the joining line and left `W` free.

**The refusal table** (`flow_raises_unbound/4`, `library/flow/modes.pl`)
says which builtins raise when given which arguments unbound, 58 rows, each
with an example the case calls and requires to raise. It is not the mode
table: that one's `+` says INPUT, and `write(X)` and `format(F, X)` take an
unbound `X` happily. It was checked against the engine rather than written
from SWI's manual: cocolog's `char_type(_, _)` and `arg(_, f(a), _)` raise
where SWI enumerates (every builtin here is deterministic), and through
1.10.5 its `assertz(_)`, `retract(_)` and `arg(1, _, _)` failed and `_ =..
_` ended the program where SWI raises -- fixed in 1.10.6 (section 11), when
those took their rows.

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

**And three about threads** (F2, section 7), each a warning about one goal:
`thread_unjoined`, `lock_held` and `thread_visibility`.

**Not yet**: a call against a documented mode (`%! p(+X)` called with `X`
free); left recursion through a construct or a library predicate; promises
of `multi` and `failure`.

## 9. `library(flow/debug)`: what a query did (D0-D4)

```prolog
flow_debug(+Goal, +Base, +Options)    % writes Base.svg and Base.xml
    % window(N), at(I), from(I), to(I), until(exception | fail | answer(K)), view(flow | tree),
    % journal(true), journal_file(F)
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
  inferences in every process (`call_metered/4`; since 1.12.2 the clock
  counts every goal, one a goal, and a program's count is it less the
  `true`s and `=/2`s, which are no inference, as in SWI);
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

**What D0 found: neither half of the clock held** (1.10.11).

* **A traced run counted more than an untraced one.** The tracer's Exit is a
  marker on the continuation, `'$trace_exit'/3`, and taking it was a step:
  naive reverse of eight, `go/1`, counts 47 inferences and counted 93 under
  `--trace` -- one more for each Exit of a predicate's call, 46 of them (a
  builtin's Exit is printed where it ran, and takes no marker). Every event
  a window recorded after its first would have carried a wrong number.
* **A stop at the inference limit counted the step it did not take.** The
  loop counts a step and then asks the limit, so the goal it stops at is
  counted, and counted again by the turn that resumes it. `step --steps
  12` printed `suspended at 13` (README's own first example: 26 after the
  second turn), and `go/1` stepped ten inferences at a time finished
  `after 51` where one turn finishes after 47. `call_metered/4` reads the
  same count -- a goal stopped at a ceiling of L answers that it used L +
  1, which `test/engine.pl` pins as where each ceiling stops -- but no turn
  resumes it, so nothing is counted twice there.

And a fast-forward cannot be a stop and a resume: a stop inside a nested
engine -- `findall/3`'s, which the limit is narrowed into -- throws the
nested search away, and the resumed outer engine starts the whole
`findall/3` again, counting it twice. So the window switches IN PLACE, as
the paragraph above first said: the limit's branch, taken once, finds a
recorder waiting for this very inference and turns tracing on for every
engine on the chain instead of stopping. D1 makes both counts true (9.5).

**Proving it costs nothing**: every new hook sits on a branch the untraced
engine never takes; callgrind's instruction counts on the untraced path
(nrev, queens, lookup) are identical before and after; `bench/langs.sh` runs
as within-run pairs.

**What D1 found of that promise** (1.10.12, `tools/flow/zero.sh` against
1.10.11): the hooks are never reached -- callgrind counts no instruction in
any of the recorder's functions over nrev, queens and lookup run untraced --
but the counts are not identical, for two reasons that are not work. The
jump padding every binary is built with (`-mbranches-within-32B-boundaries`)
moves with any change: `coco_try_clause`, untouched, ran three 2-byte no-ops
fewer and two more instructions an inference, so zero.sh reports the
padding and the work without it. And a hook in the step loop's limit branch
moves the loop's register allocation however it is written: written inline,
the window's opening was inlined into the loop and cost nrev 0.45 %, and with
every hook a `(weak)` function the compiler cannot inline -- clause
selection back to the original call, the clause events recorded after it
from branches tracing already takes -- what remains, the padding aside, is
nrev -57 instructions in 66.06 M, queens +13 807 in 42.67 M and lookup
-20 047 in 48.13 M: the loop's and `coco_backtrack`'s spills, of both signs,
at a few hundredths of a per cent. Time cannot see that on this box.

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

**As built** (D3, 1.10.15). The impure calls are the PORTALS: a module's
call that reaches the world. The modules that hold a piece of it are portals
whole -- zigurat (the knowledge base under `--kb`), os, process, stream,
thread, tcp, tls, curl, ray, opencv, torch, tensorflow, numpy, aes, x509:
what such a module hands out is a handle into a table only the run that made
it has, so a replay that answered the call that made one answers every call
that uses it -- and of the rest, by name: the files module's twenty (not the
four that only take a name apart), `getenv/2`, `setenv/2`, `unsetenv/1`,
`statistics/2`, `current_prolog_flag/2`, `sha_file/3`, and `format/3` to a
stream (to a term it writes nowhere). A module out of the tree names its
own (`coco_m_portal`, MODULES.md). There is no random-number source in
cocolog to journal; the clock is `get_time/1` and `statistics/2`, both
portals. **A core builtin is never one** -- `write/1` writes to standard
output, which no run reads back -- **nor is a load**: `use_module/1` reads
the program's own clauses, again in every run.

* **The journal is the module seam's**: its three hooks are wrapped while a
  journal's window runs and put back as it ends, so a run with none
  dispatches as before and the step loop has no new instruction. A replay
  never starts a thread or opens a stream: a write it makes to a stream it
  never opened goes nowhere, and a thread's messages are the journal's.
* **An entry** is `j(I, Module, Name/Arity, CallText, Outcome)`: the
  inference, the call as `writeq` writes it with its variables `_0`, `_1`,
  ..., and `exit(Goal)`, `fail`, `throw(Ball)` or `error(Message)`. Floats
  are written to read back to the bit. A replay matches a call by inference,
  predicate AND text: a failure has nothing to unify, so only the text tells
  another call from the journal's.
* **Divergence** is `end(diverged(I, Want, Got), Used, Answers)`, the run
  stopped where no `catch/3` sees it: another portal where the journal holds
  one, another argument, one the journal holds made early (stopped BEFORE it
  runs: the entries say which predicates are portals before any is called) or
  late, one past the journal's last, and a call passed by -- noticed at the
  next call a module answers, or at the run's end (`Got` none). Want and Got
  are each `portal(I, Module, Name/Arity, CallText)` or `none`.
* **Per thread and per process, not yet**: what reaches the run from a
  thread or a child -- `thread_join/2`, `channel_recv/2`, `proc_run/4` -- is
  journalled in the run that called it, and a replay takes it from there; a
  thread's own run, or a child's, is not recorded to be replayed on its own.
  9.3 stands as the plan for that.

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

### 9.5 The plan, phase by phase

**D0, the harness** (1.10.11's tree). `tools/flow/zero.sh [BINARY ...]`:
each binary runs nrev, queens and lookup from `bench/langs` untraced under
callgrind, and prints the instructions of the whole process and of the work
alone. One binary counted twice in one invocation answers the same to the
instruction, so a change that keeps 9.1's promise prints the old binary's
numbers exactly. And the two findings above.

**D1, the engine** (`lib/solve.cicili`, `lib/builtins.cicili`,
`cocolog.cicili`; a patch):

* **The clock.** `'$trace_exit'` takes back its step, so a traced run
  counts what an untraced one counts; a turn that stopped at its limit is
  saved with the steps it took (`suspended at 12`, and `go/1` stepped in
  any number of turns finishes after 47). `call_metered/4` is left as it
  is: it resumes nothing.
* **A record mode**: `trace` 2. Every port the printer would write is
  appended instead to a recorder on the machine (`m->rec`, so the nested
  engines `findall/3` and `call_metered/4` start record into it too): the
  port, the inference -- absolute: the steps of every engine on the chain
  out to the window's own -- the depth, the goal's heap cell (with the
  collector off for the window, the name of its call: a cell is used again
  only once backtracking has gone back past every call made after it), at a
  Call the cell of the call it is inside, and each argument as `writeq`
  writes it, cut at `text(N)` characters with its whole length kept. And
  what the printer has no port for: the clause a call entered (its number)
  and each head before it that the selection tried and did not unify
  (through 1.11.1 every clause before it, the index's skips too); an
  exception raised (its ball) and where a `catch/3` took it. Every hook is on a branch tracing
  already takes, and out of line -- a `(weak)` function, which the compiler
  never inlines into the loop: the clause events are read AFTER the
  selection, from the frame it left (`coco_rec_heads`), on the traced
  call's and the traced retry's own branches; an exception is no path
  zero.sh's programs take. (A copy of `coco_select_clause` that recorded as
  it went was the first try: it moved the untraced loop's code, 9.1.)
* **`'$trace_window'(:Goal, +Options, -Events, -End)`**: Goal proved in a
  nested engine on this store, untraced at full speed up to `from(F)`, then
  recorded through `to(T)` (no `to`: to the end); `answers(K)` goes on
  through K answers; `text(N)` as above. End is `end(How, Used, Answers)`,
  How `answer`, `false`, `exception(Ball)` or `limit`, Used the inferences
  spent and Answers the inference of each answer found (and `halt(Code)` for
  a run that halted, `error(Message)` for one that could not go on). Every
  binding is undone afterwards: it is for watching, not for answers. The
  window opens
  in place: the limit stops the run before inference F as any limit does,
  narrowed into every nested engine, and its branch finds the recorder
  waiting for F and switches the chain to recording instead of stopping. A
  window that opens inside `call_metered/4` gives that goal the window's end
  for a ceiling; the replay's End then differs from the probe's, which is
  how D2 knows.
* **Proven** by zero.sh (9.1: no instruction in a hook untraced); by the
  trace case, port for port; and by `test/window.pl`: a traced and an
  untraced run counting alike over the trace case's queries and the bench
  programs, a stepped machine finishing at one turn's count, and a window
  opened part way -- in the run's engine and in a `findall/3`'s -- holding
  event for event what a recording of the whole run holds there. Each rule
  has an arm that takes it out and goes red (STATUS.md).

**D2, `library(flow/debug)`** (built, 1.10.13; proposes a minor):

* `flow_debug(+Goal, +Base, +Options)` writes Base.svg and Base.xml, and
  `flow_debug/4` hands back the run as a term -- `run(How, At, Answers,
  window(From, To), Calls, Bindings, Diverged, Journal)` (Journal since D3).
  Options: `source(File)`
  (required); `until(end | answer(K))`; `window(N)`, how many inferences up
  to there are recorded (2000; a run that short is recorded whole);
  `from(I)` and `to(I)` instead; `discs(N)` (24); `text(N)` (60);
  `view(flow | tree)`; `names(['X'=X, ...])`; `timeout(Ms)`.
* **Each run is a child process**, `cocolog run FILE GOAL` with the window
  and the writing of its events as the goal: `run` consults the file into a
  knowledge base of its own, so what the probe asserted, or set as a
  global, cannot change the replay. The probe runs with `from(0)` and
  learns how the run ends and where; the replay runs to the probe's end and
  records the window, and must end as the probe did. One that does not is
  drawn all the same -- it is a true recording of a run of the program --
  under a red line that says both ends, and the XML says `diverged="true"`.
* **The events are matched to the chart** (`library/flow/dbgmatch.pl`): a
  call to the box it is, by walking each clause activation's events
  against a plan of the row -- where a call goes after each goal exits or
  fails, a condition's failure into the next arm or the else, a branch's
  into the next branch -- with the next box of the call's predicate as the
  fallback; a call whose own call began before the window is placed in a
  panel of its predicate, the one whose call pattern its arguments fit
  best, with no box. The expected box is what places a then's and an
  else's calls of one predicate apart: without it the else's call went to
  the then's box.
* **Drawn** (`library/flow/dbgdraw.pl`): the chart under a banner of how
  the run ended and what was recorded; each box the window reached heavy,
  red where its last call failed, purple where it raised an exception
  (outlined: a call the exception ended), a count over a box called more
  than once; a head red where its last try did not unify; a box, a panel
  and a wire the run never reached faded; and a numbered disc on a box's
  edge where a value crossed into a variable the source names -- given at a
  Call, bound at an Exit, undone (hollow) at a Redo or at the Fail of a call
  that had exited -- the last `discs(N)` of them, two rows to a box at
  most, and a line for each under the chart. A value is named by reading
  the argument's text back and unifying it with the argument as the source
  wrote it, so `foo([X|Xs])` names X and Xs; a value an activation already
  showed is not shown again. `view(tree)` draws the calls, a row each, a
  call inside another indented under it, a recursion more than seven deep
  by its first three levels and its last three.
* **The XML of the run** is the chart's with a `<run>` after its panels:
  how the run ended and where, the window, where a failed run's failure
  began or the last goal to fail, the call that raised an exception; a
  `<call>` for each call with its box, panel, clauses, heads and its
  arguments at its Call and Exit; every `<event>` in order; every
  `<binding>`, with its disc where the picture numbers it.
* `tools/flow/debug.pl` (`cocolog -s tools/flow/debug.pl -- GOAL FILE BASE
  [OPTION ...]`, exit 0/1/2), `test/flowdebug.pl`,
  `tutorials/library/51-flowdebug.pl`.
* **What it found in D1**: the recorder wrote a Redo as every retry began,
  where the printer writes one only once the retry enters a clause -- a
  call that had exited and was backtracked past quietly showed a Redo
  nobody printed. The Redo is now pending until the retry enters a clause
  (1.10.13), `test/window.pl` holds the recorder to the printer over the
  trace case's queries, and per function the untraced engine runs the
  same instructions as 1.10.12's on nrev, queens and lookup.

**D3, the journal** (built, 1.10.15; proposes a minor): 9.2 as built --
the answers of the portal calls recorded, a replay answered from them, and
each way of leaving the recorded run a divergence. In the engine,
`'$trace_window'/4`'s `journal(record(File))` and `journal(replay(File))`;
in `library(flow/debug)`, `journal(true)` and `journal_file(F)`: the probe
records, the replay replays, a box whose call reached the world through the
journal carries a teal ⇄ (the nearest box of the program's own: open/3
reaches it through `'$stream_open'/4`), the banner says how many calls the
journal held and answered, a replay that left it is drawn up to there under
a red line naming the journal's call and the replay's, and the XML's `<run>`
holds a `<journal>` with a `<portal>` per entry and a `<divergence>`.
`test/journal.pl` (39 checks: a record of every kind of portal and its
replay in one process and in two, under collections every 2000 cells; each
divergence; a raise; the refusals) and `test/flowdebug.pl`'s journal
section, lesson 51's visit counter. Each rule has an arm that takes it out
and goes red (STATUS.md): nine in the engine, six in the library. **What it
found**: an `exit` outcome catches a call with another argument by not
unifying, and hid that the text was never compared for a `fail` -- the
first arms of the text rule and of the passed-by rule stayed green until a
failing call and a non-portal module call were made the witnesses; and a
replay that left the journal's calls out could end where the record did,
which no call noticed -- the run's end is now asked (`coco_jr_settle`).
Per thread and per process: 9.2's last point. **And it costs the run it
journals nothing when it has none**: per function, the untraced engine runs
the same instructions as 1.10.14's on nrev, queens and lookup (zero.sh's
work less padding moved -136, -136 and +320 instructions in 66.06 M,
42.69 M and 48.11 M, none of them in the binary; the padding the same).

**D4, questions over the clock** (built, 1.10.16; proposes a minor): the
first inference at which something holds, by a search over fast runs each
stopped at one inference (`'$trace_window'` with `to(I)` and no `from`) and
asked there; and why a goal failed, read back from the recorded window --
the last failure and the failures it came from.

* **Asked where it stopped**: `'$trace_window'/4`'s `ask(Cond, Holds)`
  proves Cond once between the run's end and the undo, over the bindings the
  run left -- its last inference, its answer, its failure -- in an engine of
  its own (ten million inferences, no collection); Holds `true`, `false`,
  `limit` or `exception(Ball)`. Cond's cell is a root beside the goal's,
  since a collection on the way to the window moves both.
* **`flow_when(+Goal, +Cond, +Options, -When)`** (`library/flow/dbgwhen.pl`):
  Cond asked where the probe ended, then bisected over `[1, End]`, each step
  a child process stopped at `to(Mid)` and asked -- about twenty runs for a
  million inferences, each at full speed, and by default each a replay of
  the probe's JOURNAL, so they read what the probe read and do nothing it
  did twice. When is `at(I)`: Cond does not hold at I - 1 and does at I,
  whose call made it so -- or `never`. That is the first such inference when
  Cond, once true, stays true; one backtracking undoes may not hold at the
  end at all, and `step(N)` asks every N-th inference first and bisects
  inside the first step it holds at. `base(B)` draws the window that ends
  at I. A run that is not the same twice cannot be searched: a divergence is
  an error naming both ends. From a shell: `when=COND` (`step=N`).
* **`flow_why(+Run, -Whys)`** (`library/flow/dbgwhy.pl`): read from the
  calls flow_debug/4 recorded -- each failed call of the program's own (a
  panel on the chart), each clause it tried, `nohead(K)` or `entered(K,
  Goals)` with the calls its body made, down to the calls that failed with
  nothing of the program's to say why (a builtin's, a library's). A run
  that failed has the tree under its chart ("why it failed") and in the XML
  as `<why>`. **What it found**: a retry takes no inference, so a clause
  tried after one whose body failed is entered at the inference of the call
  that failed -- which is the earlier clause's; split by `<` it went to no
  clause at all, and two clauses that both enter and fail (`classify/2` in
  the case) showed the first with an empty body. And a collection's
  compaction leaves a moved term's old copy readable: the arm that asks the
  question's old cell stayed green until the check left garbage under the
  question and ended the run by building over where it had been.
* `test/window.pl` holds `ask` (the stop's bindings, an answer's, a
  failure's, a raise, a loop, collections in the way), `test/flowdebug.pl`
  `flow_when` -- each inference it names checked against the call a window
  of that one inference records there -- `flow_why` and the command;
  lesson 51 a list of squares and the basket's failure read back. Each rule
  has an arm that goes red (STATUS.md): three in the engine, eight in the
  library. Per function the untraced engine runs the same instructions as
  1.10.15's on nrev, queens and lookup.

**After D4: what debugging the translator asked for** (1.10.24-1.10.26),
from a session that used the library on `library/reasoning/translate.pl`:

* **A cut that is followed by a failure**: the tracer printed no Fail for a
  call whose clause cut and then failed (the cut took the frame the Fail is
  printed from), and a Redo failed calls it was not inside. A traced cut
  now keeps its own call's frame as SPENT, and a Redo opens only the calls
  it is inside (1.10.24, TRACING.md); each `<event port="redo">` says
  whether its call had exited (1.10.25).
* **The run as text** (`txt(true)`, `library/flow/dbgtext.pl`): Base.txt,
  a line a call -- its inference, the goal at its Call, how it ended, the
  clauses it entered and the heads it tried that did not unify, its box, and where
  the box is written: `:LINE:COL` in the file a `% file:` line names once,
  under the head (1.11.0; a window with places in several files keeps
  each line's `FILE:LINE:COL`). Through 1.10.28 every line carried the
  path, 93 of the 213 bytes a line of a failing translator run took
  (8.99 MB; reported from the reasoning session).
* **The chart kept** (`cache(Dir)`): the translator's chart took 52 of a
  run's 57 seconds and 26 MB of its XML, and is the same for every run of
  one program. It is built once for a call pattern of a file and a cocolog
  version and kept as KEY.chart (the graph, a term a part: one term of the
  whole graph read slower than building it) and KEY.xml; KEY.chart names
  each file it holds a clause of with its sha256, and a changed file builds
  it again. The run's XML is then its `<run>` alone, under a root naming
  KEY.xml: on the translator a hit takes 4.6 s, and the run's XML 54 KB.
* **Over a store** (`embed(Dir)`, `kb(Name)`): each child runs `cocolog
  --embed Dir [--kb Name] query`, the file loaded as `-s` loads it -- its
  clauses never written through -- where `run` would consult them into the
  store.
* **What it found**: `term_to_atom(T, '''''')` ended the process -- the
  reader copied the terminator of a token buffer nothing had been put in
  (section 11) -- and the translator's run met it in the text of an argument
  `atomic_list_concat/3` exited with.
* **Two runs compared** (`flow_diff/3`, `library/flow/dbgdiff.pl`, 1.10.27;
  `diff=FILE`, `diff_goal=GOAL`): the session's regression hunt, ported from
  its script. An INPUT is a predicate and its arguments' text at its Call,
  each `_G` name read as `_`; the inputs both runs called whose answers (the
  last Exit's arguments, or how the call ended) differ, deepest first --
  the first is where the difference began -- and the predicates only one
  run called. The first differing CALL is no use: a memoisation change made
  the session's first one.
* **Where the inferences went** (`profile(P)`, `library/flow/dbgprof.pl`,
  1.10.27; `profile=true`): a call is charged from its Call to its FIRST
  Exit or Fail (its last end charges it with the continuation a Redo comes
  back over: the session's first profile added to over 100 %), a call with
  neither up to the last inference under it, and a predicate with the union
  of its calls' spans, so a recursion is counted once.
* **Three more views, and windows along a run** (1.11.10, the reasoning
  session's points 7 and 8): `callers(C)`, each predicate's callers and
  how many calls each made; `repeats(R)`, the goals asked more than once, a
  goal's variables named in the order they come (`look(even,_1)`); and
  `flow_steps_text/2`, the window's inferences by what took them -- each
  predicate's calls and the steps of the control constructs, which make no
  call; `profile=all|inclusive,steps,callers,repeats`. `windows=N`
  (`flow_debug_windows/4`) records N windows along one run, each by a
  process of its own, J at a time, the chart built once, and
  `flow_profile_merge/4` adds their `profile_rows` up into BASE.prof. What
  a window FAR ALONG a long run cost was the library's, not the run's: one
  of 100 000 inferences at inference 15 000 000 of a 46 M-inference
  refusal of the translator took 100 s here -- the matching 36 (each event
  put into three AVL trees, and each child call finding its box's node
  again over the chart's 2 792 panels), the facts 13.5, the profile 6, the
  XML 23, BASE.txt's indentation a space at a time. Sorted instead of
  trees, the panels a box calls worked out once, the placing done down the
  call tree: matching 7 s, the profile 0.9, and with `svg=false xml=false`
  (the values that crossed are not worked out) the window is 31 s; three
  such windows with BASE.txt and every view, three at a time, 53 s.
* **Where a failed search got furthest** (`flow_why_furthest/2`, 1.10.27):
  the why of a reader that backtracks is the whole trace (2.84 MB for one
  refusal), and following its last failure down leads to the last
  fallback (`tr_byline/3`), not the cause. At each failed call the clause
  whose body got the most calls done, then the most inferences spent, then
  the earlier -- in the XML's `<furthest>`, at the foot of Base.txt and
  above the why on the picture.
* **Clauses not together** (`library(flow/chart)`'s finding
  `discontiguous`, 1.10.27): cocolog joins a predicate's clauses wherever
  they stand, without a word (SWI warns), so a helper given a name already
  taken joins that predicate. The file is read again for each clause's line
  and predicate (0.1 s over the translator's 3485) and its `:- discontiguous`
  declarations; a predicate with a panel whose clauses stand in more than
  one place has one finding, at the first clause that stands apart. The
  translator has 39, the number the session counted from the XML's clause
  lines.
* **The heads a call TRIED, and a matcher that grows with them** (1.11.2,
  the reasoning session's finding E): a window of 2000 inferences of the
  translator (1,379 calls) took 292 s and wrote 31.2 MB of XML, 215,525 of
  its events heads that did not unify -- every clause before the one a call
  entered, the index's skips among them: one failed call of a 32,046-fact
  table listed all 32,046. A head the index passes over is never tried, and
  is not recorded now: `coco_rec_heads` walks the index's candidates again
  with the key the selection read, kept before the selection binds the call
  (`coco_rec_hkey`: `p(K, 2)` entering `p(b, 2)` binds K, and walked with
  b's key, the head tried before it with none would be lost). A failed call
  of the program's that tried no clause is still why it failed --
  `why(S, P, In, [])`, "no clause tried" under it on the picture -- and the
  furthest path ends at it, no head having unified; the furthest step
  reads "clause K, the furthest of N tried", N the clauses tried. And the
  matcher appended each head to its call's list, n * n / 2 cells for n
  heads (on the session's box 20,000 skipped heads cost 19 s of a 37 s
  run): the list is built backwards and turned round once. Per function
  the untraced engine runs the same instructions as 1.11.0's on nrev,
  queens and lookup.
* **Whose calls the why explains, and why a run raised** (1.11.4,
  cicili-lang's report on debugging its compiler from a small top file):
  a call is explained by its clauses when it has a panel, so a program of
  several files had a why that stopped at the first call into another file.
  `own(all)` explains every call of a predicate with clauses (never a C
  builtin, a module's C or a construct, which have none to have tried),
  `own(Files)` those the files hold clauses of; `flow_why/3`,
  `flow_debug/4` (the picture, the XML, Base.txt) and `own=` take it, and
  `flow_why_call/3,4` is the why of the call made at one inference. A run
  that ended in an EXCEPTION had no why at all: `flow_why_raised/2` gives
  the calls it ended, from the top down -- at each level the last one made,
  since the raise is the last thing the run did -- and the failure it
  answered, the last call before the raise that failed having tried a
  clause, in the deepest body first: a driver that gives up with an error,
  `( Cond -> ... ; throw(...) )`, raises because Cond failed. `<raised>` in
  the XML, a block on the picture, lines at the foot of Base.txt. The
  furthest path now goes past an explicit `fail/0` or `false/0` -- `( Cond
  -> ... ; trace(...), fail )` failed because Cond did -- into the last
  call before it that failed having tried a clause. And a diverged run's
  line and Base.txt's head say both ends, the probe's and the replay's: a
  cache on disk the probe wrote sent cicili-lang's replay a shorter way,
  and the line said only the replay's end beside the probe's window.
* **Where a choice made the raise, where a recovery raised it, and where a
  throw stands** (1.11.7, cicili-lang's report). Its compiler refused
  `cpp_not_abstract/1` from the then of a condition that HELD
  (`cpp_abstract_class/1`) after one that failed by an exception its catch
  took (`nb_getval/2` in `catch(..., _, fail)`): 1.11.4's answered failure
  was the last call that failed having tried a clause, none of those had,
  and it named an older failure further out with nothing to do with it.
  Now, from the deepest body out, the first body where the raise stands in
  a branch a choice took -- the then of an arm whose condition held, the
  else, a disjunction's later branch -- is where it was chosen:
  `flow_why_raised/3`'s `chose(C)` names that clause, the construct's box,
  the branch, and every condition it ran, builtins included, a why node
  each; the answered failure is the last of them that failed having tried
  a clause. A body with no such choice answers as before, its failure in
  the raise's scope -- another clause's (why the raising clause ran) or one
  in no construct the raise is outside of. A raise in a catch's RECOVERY
  -- a driver that says the error and throws again, or whose saying raises
  one of its own -- also explains the exception the catch took
  (`caught(K)`), the same way, and a call of the catch's goal is no longer
  on the chain once the recovery ran. Both need to know where the raise
  STANDS, and a `throw/1` makes no call: the tracer records a throw event
  in the body it was raised in and no port, and the first build read the
  place from the body's last call -- after a then's last call exited it
  said the then, where the throw came after the whole if-then-else. So the
  matcher plans a throw as a place, and a throw the body makes where no
  call of it is running is put on the chart's throw box (or the goal that
  raised before its Call port: an unknown procedure, `call/1` of a
  variable) -- `thrown(Box, At)` among the call's clauses, `<thrown>` in
  its XML, `threw:BOX` on its line of Base.txt, the box painted as the one
  that raised; a raise whose place is not known is placed in no branch.
  The calls an exception ended in a clause the chart does not draw -- a
  program debugged from a small top file -- are placed by that clause's
  body read from the program's files, at `Name/Arity#cK.g1...`, an id no
  chart box has; a predicate the chart does draw, called from such a
  clause, is walked in its own panel. The run's banner named as the raiser the last call made
  in the body, though it had exited: it names a call only while it runs.

## 10. Phases

| phase | delivers | engine change | lands |
|---|---|---|---|
| F0 | the look, on two fixtures | none | built, on master |
| F1 | `library(flow/chart)`: generated tables, the mode table a line per mode and checked against the engine, modes to a fixed point by a worklist, a panel per call pattern, grammar rules, source positions, unreached goals, the XML beside every SVG written a piece at a time, `depth(D)` and `only(Preds)` with stubs and a 150-panel budget, every goal drawn by name, builtins too, and a library predicate never opened unless `libraries(reach|all)` asks (1.10.5; 1.10.2 folded builtin work into `⋯ N` boxes), `tools/flow/chart.pl`, `test/flowchart.pl`, `tutorials/library/50-flowchart.pl` | none | built, on master (1.10.8); proposes 1.11.0 |
| F2 | threads and processes: a lane for each spawn site and the copy analysed as a copy, spawns and joins, channels followed across lanes, locks, process portals, writes to a shared knowledge base, three findings; then `cowork_map/3`'s jobs, `httpd_serve` with no pool, channels and handles followed through heads, callers, terms and other channels, and the order of a channel's messages | none | built, on master (1.10.9, 1.10.11); proposes a minor |
| F3 | findings, in the XML first and on the chart as numbered discs, from `tools/flow/chart.pl` as a compiler's diagnostics: unknown procedures with a near name, calls the engine refuses unbound (a refusal table checked against the engine), left recursion, clauses never tried, determinism promises not kept; the analysis made to bind through tests and to end clauses at what never succeeds | none | built, on master (1.10.8); proposes a minor |
| D0 | the zero-overhead harness (callgrind on the untraced path, `tools/flow/zero.sh`); what it found: the traced clock and the stepped clock both wrong (9.1) | none | built (1.10.12) |
| D1 | the clock made true traced and stepped; the record-mode tracer, the new events, `'$trace_window'/4`, the window opened in place | `lib/solve.cicili`, `lib/builtins.cicili`, `cocolog.cicili` | built (1.10.12), a patch |
| D2 | `library(flow/debug)`: the run over the chart, discs, legend, tree view, the run's XML; the recorder's Redo only where the printer prints one | `lib/solve.cicili` (the pending Redo) | built (1.10.13); proposes a minor |
| D3 | the journal, per thread and per process; replay; divergence | builtins, the module SDK | proposes a minor |
| D4 | questions over the inference clock: the first inference where something holds, why a goal failed | none | proposes a minor |

## 11. Engine findings on the way

* **Fixed in 1.10.26: reading the empty atom `''` as the first token of a
  reader ended the process** (`term_to_atom(T, '''''')`, SIGSEGV). The
  reader's token buffer is allocated by the first character put in it, and
  `''` puts none: `coco_tok_name` copied its terminator from a nil pointer.
  A reader that has read anything else first has a buffer, which is why a
  consult never met it. library(flow/debug) reads every argument text a
  window wrote back with `term_to_atom/2`, and a call that exited with `''`
  -- `atomic_list_concat([], ' ', S)` in the translator -- ended the run's
  drawing. `test/syntax.cicili` reads `''` first.

* **Fixed in 1.10.6: `format/2`'s `~a` and `~s` copied their text through an
  8192-byte buffer**, and so did the format itself and `term_to_atom/2`
  reading an atom: text of 8192 bytes or more raised `format/2: ~s wants
  text`, which names the wrong cause (8191 were written, 8192 raised), and
  `library(xml)`'s `xml_write/1,2`, which writes its document with one `~s`,
  failed on any document of 8 KB or more. The text goes into the string
  builder by its length now (`coco_text_put`, `lib/builtins.cicili`).
  `test/files/format.pl` writes 20 000 characters each way and holds the
  answer to SWI's. The chart writer still writes 2000 characters at a time,
  which costs nothing.
* **Fixed in 1.10.6: `write_term/2` ignored `variable_names`**: every
  variable came out `_G` and a number. Each named variable still unbound is
  written as its name for that one write (the machine's `wcells`/`wnames`,
  read by the writer before it falls back to `_G`);
  `test/files/write_term.pl` holds it to SWI's output. The library keeps
  writing terms with a grammar of its own -- it needs each argument
  separately anyway, to colour it by its mode.
* **Fixed in 1.10.7: `read_term/3` accepted `term_position` and
  `subterm_positions` and bound nothing.** Both answer SWI's terms now:
  `subterm_positions` every shape -- `From-To`, `string_position/2`,
  `term_position/5` for a name or an operator, `list_position/4` with its
  tail or `none`, `brace_term_position/3`, `parentheses_term_position/3` --
  in characters from the start of the stream, and `term_position`
  `'$stream_position'(Char, Line, LinePos, Byte)` where the term begins, a
  tab to the next eighth column and a CR back to 0. `test/files/read_term.pl`
  holds both to SWI's output byte for byte over comments, a tab, a CR, a
  two-byte character and other reads between two read_terms. At the end of
  the file SWI puts `end_of_file` one character before the end, with a column
  of -1 after a final newline; cocolog puts it at the end. The reader is
  written once and emitted twice (`lib/syntax.cicili`): the parser every
  consult uses builds nothing, and a second family builds the positions;
  `library(stream)` counts characters, lines and columns over every byte it
  reads, and counts again from the start when a seek moved the file. With
  positions off, consulting the translator runs `coco_next_token`'s
  instructions exactly and the parser's within 0.13 %.
* **`predicate_property/2` exists since 1.10.28** (cicili-lang asked), and
  `current_predicate/1` answers about the program -- its own files too
  since then, `-s FILE` and `ensure_loaded/1` among them -- not the library
  or modules, which is why the tables are generated:
  `predicate_property/2` knows the engine's and the compiled-in modules' C
  predicates from the tables their dispatchers are built from, and a `.so`
  module's not at all. It went in as a patch (1.10.28), and the owner
  took the minor it is ("something new reachable from a program") as
  1.11.0.
* **Fixed in 1.10.6: `catch(_ =.. _, E, true)` ended the program** (exit 2,
  `=.. wants a proper non-empty list`), raised where `catch/3` could not see
  it. So did an arity below 0 for `functor/3` and an unknown arithmetic
  function of one argument or more. Each raises SWI's error now, in SWI's
  order: `_ =.. foo` type_error(list, foo), `_ =.. []`
  domain_error(non_empty_list, []), `_ =.. [f(a), b]` type_error(atom, f(a)),
  `functor(_, foo, -1)` domain_error(not_less_than_zero, -1), `X is foo(1,
  2)` type_error(evaluable, foo/2) -- an atom raised type_error(evaluable,
  foo) without its arity. `functor(_, _, 1)` is an instantiation error (it
  was a type error), and `functor(_, foo, a)` type_error(integer, a) (it was
  an instantiation error).
* **Fixed in 1.10.6: `assertz/1`, `asserta/1`, `assert/1` and `retract/1`
  failed on an unbound argument, and `arg(1, _, _)` failed**, where SWI
  raises. They raise SWI's errors now: an unbound clause or head
  instantiation_error, a head that is not callable type_error(callable, H),
  a body with a number or a string where a goal stands type_error(callable,
  Body) (`assertz((foo :- 3))` STORED the clause), a clause for a control
  construct permission_error(modify, static_procedure, N/A). A fact under a
  core builtin's name is kept, where SWI refuses it: the store is a database
  of terms as well as a program, and `library(reasoning)` keeps a lesson's
  word classes there -- `number(dos)` among them, read with `clause/2` --
  so the first build that refused it stopped `test/translate.pl` at its
  lesson. A module's predicate is kept likewise, since a module may decline
  a goal and send it on to the store, so `assertz(findall(a, b, c))`
  succeeds where SWI refuses it. `arg/3` raises for an unbound or atomic term
  and an index that is not an integer, and domain_error for one below 0.
  `test/files/catch.pl` holds all of it to SWI's answers. Two modes stay
  apart: `arg(N, f(a, b), A)` with `N` unbound and `char_type(C, alpha)`
  with `C` unbound raise where SWI enumerates, since every builtin here is
  deterministic.
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
