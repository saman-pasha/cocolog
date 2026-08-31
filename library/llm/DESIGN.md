# Ashurbanipal — an LLM agent that turns natural language into working cocolog

**A design document, grounded in source reading. Nothing in this document was executed.**
There is no `./cocolog` binary in this container, no `../cicili`, no `../ZiguratIP`. Every
claim carries a `file:line` and was read, not run. §16 lists exactly which parts must be
checked against a live binary before anyone builds on them.

---

## 0. Reading guide

| you want | go to |
|---|---|
| the argument in one page | §1 |
| the actual dialect card text the model is conditioned on | §4 |
| the linter's rules and how its blocklist is built | §5 |
| the collision oracle, and the ordering finding that corrects all four input designs | §6 |
| exact verification commands | §7 |
| exact JSON schemas | §8 |
| exact prompt assembly | §9 |
| what a human sees, and how an impossible request is refused | §11 |
| the build plan, increment 1 first | §13 |
| honest limits | §15 |
| what was never executed and what to check first | §16 |

Names used throughout: **Ashurbanipal** is the whole system; **cocolint** is its
deterministic linter; **the oracle** is the `current_predicate/1` collision check;
**the card** is the dialect prompt block; **traps.jsonl** is the single file from which
both the card and half the linter are generated.

---

## 1. Thesis, and the seven decisions

The hard problem is not generation. A competent model writes correct Prolog first try.
The problem is that its Prolog is SWI's, and cocolog diverges from SWI at roughly forty
points where the divergent form **is syntactically valid, compiles, runs, and is wrong**.
`format(string(S), ...)`. `retract(X), fail`. `:- initialization(main).`
`main :- ..., halt.` A helper called `step/4`. The model cannot tell which of its habits
are habits: it has read thousands of SWI programs and zero cocolog programs, so every SWI
reflex arrives at maximum confidence with no marker on it.

You cannot fix that by lengthening a system prompt. You fix it by putting the load on the
repository: a **retrieved closed vocabulary** instead of a recalled one, a **checked
self-report** of which habits were suppressed, and **deterministic gates** that are not a
second model.

Seven decisions, with provenance:

| # | decision | from | why |
|---|---|---|---|
| 1 | Two model calls on the happy path — generate, and (sometimes) repair. No planner, no critic. | Cocolint | A second model shares the training distribution, so it is a *correlated judge on exactly the errors that matter*. The only uncorrelated judge is the binary. Always spend the call on repair, where the harness already knows what is wrong. |
| 2 | `divergences_applied[]` is a required, **grep-checked** output field. | Ashurbanipal | Converts a rule the model *read* into a rule the model *applied*, for a few hundred output tokens, falsified by `grep`. Cheapest accuracy-per-token in the design. |
| 3 | The collision oracle (`current_predicate/1` set difference) is a gate, **kept beside** a static blocklist, with its blind spot named. | Ashurbanipal + Cocolint's baseline fix | The oracle is exact and self-maintaining; it is structurally blind to the C-dispatch class and to `:- dynamic`-interned names. Neither mechanism alone is sound. |
| 4 | The card and the linter are **generated from one file** (`traps.jsonl`), and every row is anchored to a source substring. | library(coder) + Ashurbanipal | A rule in the prompt and the rule that enforces it cannot drift apart if they are the same row; a row cannot rot silently if the build fails when its anchor moves. |
| 5 | The verdict is never a model call, and a repair that adds a lint finding is rejected **before it is executed**. | Ratchet | Acceptance is monotone. GREEN has exactly one code path: observed exit 0 plus an observed `done` line. |
| 6 | Checks are written as `must/3` triples **before the code**, shown to the human first, and every public predicate needs one negative check. | Ratchet | The only cheap defence against a confidently green implementation of the wrong spec. |
| 7 | Increment one is a **standalone dialect linter with no model, no API key and no network**, shipped as `test/lint.sh` in the repo's own suite. | judge gaps 2.2 / 2.3 | It is useful on its own on day three, it is maintained by `make test` rather than by the agent's author, and it is developable in a container with no binary. |

**Dropped, on judge instruction:**

- **Ratchet's `cocoagent_check/3` wrapper.** As written the observed value is a free variable
  not appearing in the goal, so `Got == Want` fails and every check reports FAIL. Use `must/3`
  verbatim — 44 shipped files prove it correct — and add collecting behaviour as a separate
  library if it is wanted (§12).
- **Ratchet's K=2 parallel generation lanes.** Two samples from one model whose failure mode
  is a shared training prior agree on precisely the SWI-isms that motivate the system. Spend
  nothing; put the budget in repair.
- **library(coder)'s self-hosted transport** — the agent's own model call through
  `library(llm)` → `modules/curl`, and candidate execution through `modules/process`. That
  stacks four unbuilt dependencies (`make` builds no modules; every `build.sh` needs a Cicili
  checkout with sbcl; `library/llm.pl:119` says "THIS IS A SKELETON. Nothing in it has been
  RUN") on a build that already needs Cicili + sbcl + a built ZiguratIP, to buy a driver shell
  does in thirty lines. **Kept** from that design: the row schema, the ordered-clause policy
  table, `traps.jsonl` as one source for card and linter, and the impossibility table as data.

---

## 2. Corrections that changed a design decision

These claims were marked FALSE or PARTLY by adversarial verification. Each one is not merely
noted — it moved something.

| poisoned claim | correction | what changed here |
|---|---|---|
| "four registration shapes" | **Five.** `(DEFPARAMETER *construct-names* ...)` at `lib/solve.cicili:151-154` holds 22 control-construct names dispatched by interned id at `lib/solve.cicili:1149-1351`, **ahead of the builtin table** and never reaching the store. `once`, `ignore`, `not`, `call`, `catch`, `throw`, `trace`, `notrace` are in it. | cocolint gains rule **N3**, a separate and *more severe* class than the C-table class: a user `once/1` is dead code the oracle cannot see and the builtin blocklist does not contain. This is the worst case in the language and all four input designs missed it. |
| torch strcmp chain has 35 names | **37** (`grep -o 'strcmp name "[^"]*"' \| sort -u` = 37; bigint = 17, confirmed) | no count-based acceptance test on the extractor. |
| "530 tier-1 / 1,007 with tier 2; the fact base says 479" | Tier-1 halves substantially reproduce (**141 C-table exact**, 263–264 vendored, ~129–131 module-Prolog). Tier 2 **does not**: `library/*.pl` yields **222** unique heads, not 251; modules yield ~**287** by the same rules, not 226. | **No count checksum anywhere.** The build order's acceptance test for the extractor is *twenty hand-checked rows plus a clean pass over the shipped corpus*, never a total. And the scope question the numbers hid is now decided explicitly: **a module's names are reserved only when that module is imported**, so the blocklist is assembled per-request from the router's `tier2_imports`. |
| "eleven-name directive whitelist" | **Ten** names in `coco_directive` (`use_module` and `autoload` each at two arities), plus four conditional-compilation directives handled earlier in `coco_consult` — fourteen names total. Also: a `use_module`/`ensure_loaded` whose target is **found but will not load** is a stderr *warning* returning 1, not an abort; **not-found is completely silent** (`lib/library.cicili:452-456` maps −1 to hook success). | the linter's directive table is generated from the **enumerated list**, never from a count; and rule **T1** warns hard on tier-2 imports because absence is invisible until the first call. |
| "`query` exits 1 only for an uncaught exception or an unreadable goal" | There is a **third** path: a database commit failure sets `rc = -1` at `cocolog.cicili:775-781`, so a query that proved and printed `1 answer(s).` can still exit 1. | `query` is not used as a gate anywhere (it already was not, for the failure-exits-0 reason); the presenter's "reproduce this yourself" line uses `run`, and where a `query` appears in a cross-process gate the verdict is a marker line, per `library/kbs.pl:92-101`. |
| "stderr is unbuffered" | Nothing in the tree touches stderr's buffering. ISO C guarantees only "not fully buffered"; glibc's unbuffered stderr is a **platform** fact. | the harness never correlates the two streams by order. Separate capture files, always; `flush_output` after every generated marker. The reasoning ("2>&1 reorders") survives; the guarantee does not. |
| "nothing checks a clause's length between `assertz/1` and the wire" | True of the ~8000-byte **page** limit. There **is** a wire guard at **65535** bytes (`client/zigurat.c:911`, `ZG_MAX_TEXT` in `client/zigurat.h:100`). And 8000/8192 is sourced from two *comments* (`parsi/01-schema.parsi:23-33`, `client/zigurat.h:95-98`), not from anything executable here. | rule **Z1** handles **two thresholds with two different messages**, and treats ~8000 as a configurable page size rather than a law. |
| "`--answers 0` is needed for the oracle run" | `--answers` is inert for `run`: `cmd_run` calls `coco_engine_next` exactly once (`cocolog.cicili:2118-2173`, verified again this session). | the flag is **removed** from the gate command. The enumeration happens inside `forall/2`, not in the CLI loop. |
| "44/45 of 47 tutorials carry `must/3` verbatim" | **44** of 47 — 11/11 basics, 33/36 library. `29-ray.pl`, `30-hex.pl`, `31-astar.pl` carry a renamed-argument variant that **`halt(1)`s** instead of failing. | the generator emits the verbatim `fail` form; the linter matches on *structure* (`must/3` defined, two clauses, `==`, `fail`), never on the literal argument names `Label, Got, Want`. |
| `Makefile:150-160` | The `cocolog` recipe is **`Makefile:162-170`**; 150-161 is comment text. The substance (a built ZiguratIP is required even for `--local`; there is no reduced build) stands. | bootstrap doc cites the recipe, not the comment. |
| "633 raw reserved pairs from 123+241+277" | Not reproducible under any scoping. | no number is quoted anywhere in the shipped design as an extractor target. |

---

## 3. Architecture

Eight components. Two call a model. Everything else is Python, shell, or cocolog itself.

```
   request
     │
     ├──────────────► ROUTER (small model)  ──┐   feasibility, capabilities,
     │                                        │   tier-2 imports, request_divergences
     └──► RETRIEVER (no model) ───────────────┤
              ▲                               ▼
        .cocoindex/                    CONTEXT ASSEMBLER (no model)
              ▲                               │
      INDEX BUILDER (python, source only)     ▼
              ▲                        GENERATOR (large model)
      /home/user/cocolog                      │
                                              ▼
                              G0 shape ─► G1 cocolint ─► G2+G3 consult+oracle
                                              │                    │
                                              ▼                    ▼
                                    G4 run ─► G5 trace ─► G6 swipl diff ─► G7 kb_run
                                              │
                                    pass ─────┴───── fail ─► REPAIR (large model, ≤2)
                                     │                              │
                                     ▼                              ▼
                                 PRESENTER ◄──────────────── re-lint, ratchet
```

| component | file | model | responsibility |
|---|---|---|---|
| Clause reader | `tools/coco-agent/clauses.py` | none | Read a Prolog clause head to its terminating `.`; answer name/arity, **+2 when the neck is `-->`**. Respects `'`, `"`, `%`, `/* */`, bracket nesting. ~90 lines. |
| Index builder | `tools/coco-agent/build.py` | none | Read source only — **no binary, no `../cicili`, no `../ZiguratIP`** — and emit `.cocoindex/`. Verify every trap anchor; fail loudly on drift. |
| cocolint | `tools/coco-agent/lint.py` | none | 14 rule families over the read terms and the raw text. Also shipped standalone as `sh tools/coco-agent/lint.sh FILE...` and as suite case `test/lint.sh`. |
| Oracle probe | `tools/coco-agent/oracle.pl` | none | 12 lines of tier-1 Prolog, consulted *after* the candidate, enumerating `current_predicate/1`. |
| Router | model call | small | Feasibility verdict + capabilities + arrangement + tier-2 imports + **request_divergences** (§11). |
| Retriever + Assembler | `tools/coco-agent/retrieve.py`, `assemble.py` | none | Three dictionary lookups; prompt layout and budget ladder. No embeddings (§9). |
| Generator / Repair | model call | large | The one place judgement is required. |
| Verifier | `tools/coco-agent/verify.sh` | none | Gates 2–7, each command echoed verbatim into the transcript. |
| Presenter | `tools/coco-agent/present.py` | none | Verdict → program → transcript → receipts. |

Driver: `tools/coco-agent/agent.py` (Python, ~250 lines), a `while` loop with a counter.
Python rather than shell only because it shares `clauses.py` with the linter; **every process
it spawns is echoed into the transcript as a copy-pasteable line**, which is the auditability
property the shell version was chosen for.

Build output `.cocoindex/` is gitignored — the repo's own rule, "WHAT A `build.sh` MAKES IS
NEVER COMMITTED". `traps.jsonl`, `capabilities.json` and the linter are tracked source.

---

## 4. The dialect card

This is the content, not a description of it. It is **generated** from `traps.jsonl`
(`{id, swi, cocolog, why, cite, anchor, rule, severity}`), so every row here is also a linter
rule id or is explicitly marked *prompt-only*. ~1,900 tokens.

### Card §A — framing (60 tokens)

> You are writing **cocolog**, not SWI-Prolog. cocolog is a Prolog whose clauses are rows in
> a database. It is close enough to SWI that your instincts will compile, and far enough that
> they will be wrong. Where this card and your priors differ, this card wins. Every row below
> exists because someone lost a day to it. Three of them fail **silently**.

### Card §B — the divergence table (~1,300 tokens)

Ordered by frequency × silence: silent failures first, because a loud failure is repaired by
a gate for free.

| id | SWI writes | cocolog needs | because |
|---|---|---|---|
| **N1** | `step(A,B,C,D) :- …` (any of 479+ live names) | `myprog_step/4` — prefix **every** predicate you define | No module system. `:- module/2` is accepted and **ignored** (`lib/kb.cicili:721`). The eight vendored SWI libraries are consulted into the same store (`lib/library.cicili:415-424`, `:373-376`) and **consult appends** — your clauses join theirs. |
| **N2** | `memberchk(X,[X\|_]).` `sort/2` `format/2` `findall/3` `write/1` `is/2` | a prefixed name | Dispatch is construct → C builtin → module C half → knowledge base, short-circuited (`lib/solve.cicili:1352-1386`). A C-registered name never reaches the store: your clauses are **dead code** `listing/1` will happily show. |
| **N3** | `once(G) :- …` `not/1` `call/2` `ignore/1` `catch/3` | never define these | 22 names are **control constructs** matched by interned id before the builtin table (`lib/solve.cicili:151-154`, dispatched `:1149-1351`). Redefinition is dead code that no check in the language can see. |
| **N4** | `digit(D) --> [D].` | `myprog_digit//1` | A DCG head occupies **arity+2** (`lib/dcg.cicili:96-127`). `dcg_basics` owns `digit/3`, `digits/3`, `string/3`, `integer/3`, `number/3`, `blank/2`, `blanks/2`, `eol/2`, `white/2`. |
| **S1** | `format(string(S), F, A)` | `format(atom(A), F, A)` | No string type. Sinks are exactly `user_output user_error atom/1 chars/1,2 codes/1,2` — `lib/builtins.cicili:1120-1152`. |
| **S2** | `"abc"` as text | `"abc"` **is** `[97,98,99]`; write `'abc'`, or `str("abc")` into a serialiser | `double_quotes` is `codes` and `set_prolog_flag` refuses any other value (`lib/kb.cicili:745-771`). `string/1` exists and **always fails**, deliberately. |
| **R1** | `clear :- retract(item(_)), fail.` / `clear.` | `clear :- ( retract(item(_)) -> clear ; true ).` | `retract/1` is a C builtin: deterministic, no choice point (`lib/solve.cicili:123`). The loop removes **one** clause. `retractall/1` was rewritten for exactly this. |
| **R2** | *(the inverse)* "avoid failure-driven loops" | `between/3`, `member/2`, `select/3`, `sub_atom/5`, `clause/2`, `current_predicate/1`, `nth0/3` **do** backtrack | They are Prolog clauses (`lib/builtins.cicili:227-229, :236, :287-288`; `lib/lists.cicili`). The rule is structural: **C table ⇒ once; clauses ⇒ backtracks.** |
| **I1** | a defensive `!` on every clause to force determinism | omit it where the first arguments are distinct; keep it where the caller may leave arg 1 unbound | **First-argument indexing is live**, and it is a semantics fact here, not a speed one. `coco_arg_key` keys on the goal's first argument (`lib/kb.cicili:791-800`; an unbound or float arg keys 0 and constrains nothing) and `coco_pred_next_clause` selects on it, both from the engine's own clause loop (`lib/solve.cicili:695-712`). The declaration says it outright: *"THIS IS WHERE THE DETERMINISM COMES FROM, as much as the speed"* (`lib/kb.cicili:286-289`) — a predicate whose first arguments are distinct leaves **no choice point**. A cut added to force determinism the engine already gives you is not merely noise: on the calls where arg 1 *is* unbound it prunes solutions the program needed. `STATUS.md:2760` lists this under "Not started" and says clauses are tried in order; it is stale on both halves. |
| **H1** | `main :- …, halt.` | omit `halt` entirely | `halt/0` sets `halted`, and the engine tests `halted` **before** the empty-continuation test (`lib/solve.cicili:1121` vs `:1123`), so the goal reports no solution and `run`/`-s` exit **1 with nothing on stderr** — indistinguishable from failure. |
| **D1** | `:- initialization(main).` | nothing; the CLI names the goal | A directive outside the whitelist **aborts the whole consult** — `unsupported directive: initialization/1` (`lib/kb.cicili:772`, consult returns −1 at `:1196-1198`, `cmd_run` exits 1 at `cocolog.cicili:2140-2143`). |
| **D2** | `:- table p/2.` `:- thread_local p/1.` | nothing | Those names are not prefix operators, so the file does not even **parse** (`lib/syntax.cicili:97-100`: only `dynamic discontiguous meta_predicate multifile` at 1150 fx). |
| **D3** | `:- use_module(library(lists)).` | write nothing | Tier 1 is compiled in / preloaded: `apply builtins dcg files library lists zigurat` + `assoc pairs ordsets yall aggregate ugraphs dcg_basics dcg_high_order`. 26 such lines were deliberately removed from this tree. Harmless, but off-idiom. |
| **D4** | `:- use_module(library(dcg/basics)).` | nothing (it is tier 1 as `dcg_basics`) | `library(Dir/Name)` becomes the path `"Dir/Name"`, and the vendored file is `lib/swipl/dcg_basics.pl`. As a directive: silently ignored. As a **goal**: raises. |
| **C1** | `catch(findall(X,G,L), E, …)` | `findall(X, catch(G,E,fail), L)` | `findall/3,4`, `forall/2`, `aggregate_all/3`, `bagof/3`, `setof/3`, `with_output_to/2` run a nested engine that copies the error out as a **message** and drops the ball (`lib/solve.cicili:988-992`; `lib/builtins.cicili:449-452`). The catch never fires; the query ends. |
| **C2** | `catch(G, error(T, context(_,_)), …)` | `catch(G, error(T, _), …)` | The context here is a bare `name/arity`. Library and loader failures are the **non-ISO** `error(cocolog_error(Text), _)` — match it explicitly. |
| **A1** | `X is atan(Dy,Dx)` `log(2,N)` `random(10)` | compute it: `atan(Dy/Dx)` + quadrant; `log(N)/log(B)`; there is no random | An unknown arithmetic **functor** goes through `coco_fail_err` (`lib/solve.cicili:1691`, `:545-548`) — −1, **no ball**, uncatchably fatal. (An unknown arithmetic *atom* like `inf` raises a catchable `type_error(evaluable, inf)`.) |
| **A2** | `X is 1 << 62`, 64-bit ids | keep below 2^59 | A cell is a u64 with 3 tag bits; an INT is `v<<3\|2` with **no range check** (`lib/term.cicili:81-86, :110, :641-642`). Silent wrap at 2^60. |
| **A3** | `X is 2 ** 10` → `1024.0` | here it is the **integer** `1024`; `**` and `^` are the same operation | `lib/solve.cicili:1645-1657`. Force with `float(…)`. |
| **O1** | `sort/2` / `==` / `compare/3` over large integers | do not; key on atoms | Standard order casts both numbers to **double** (`lib/term.cicili:894-898`), so distinct integers above 2^53 compare **equal** while `=` still separates them (`:790-791`). |
| **G1** | `b_setval/2` for a backtrackable scope | thread an accumulator argument | `b_setval` **is** `nb_setval` — same C function (`lib/builtins.cicili:76-79`); the table is a file-scope static outside the machine. |
| **F1** | `~t ~\| ~+` for alignment | pad by hand | Refused by name (`lib/builtins.cicili:1015-1018`). |
| **W1** | `write_canonical(T)` for portable text | `write_term(T,[quoted(true),ignore_ops(true)])` | cocolog's `write_canonical/1` **keeps** operators — identical to `writeq/1` (`lib/syntax.cicili:1414-1415`). |
| **W2** | `write_term(T,[max_depth(5),portray(true)])` | there is no depth limit and no portray | Only `quoted(true)` and `ignore_ops(true)` are read; every other option is silently ignored (`lib/builtins.cicili:1617-1636`). |
| **L1** | `functor(T,'[|]',2)` | `functor(T,'.',2)` or `T = [_\|_]` | A list cell is `'.'/2` (`lib/syntax.cicili:1305`). |
| **L2** | `--> Codes` with a bound code list | walk it: `raw([]) --> [].` / `raw([C\|Cs]) --> [C], raw(Cs).` | A variable body translates to `phrase(Cs,S0,S)` — a **call** to a predicate named after the list's head (`library/json.pl:274-283`). |
| **X1** | `string_concat/3` `split_string/4` `sub_string/5` `atom_string/2` `term_string/2` | atoms and `atom_concat/3`, `sub_atom/5`, `atom_codes/2` | None exist. |
| **X2** | `open/3,4` `close/1` `read/1` `read_term/2,3` `nl/1` `write/2` `current_output/1` | there is **no stream layer** | `format/3` takes a *sink*, not a stream. `read_file_to_codes/2` + a DCG is the read path. |
| **X3** | `setup_call_cleanup/3` `predsort/3` `numbervars/3` `nb_current/2` `assertion/1` `freeze/2` `dif/2` `when/2` `call_with_inference_limit/3` | absent; the last is deliberately spelled `call_limited/3` | so ported code errors instead of silently differing (`lib/builtins.cicili:420-428`). |
| **P1** | `current_prolog_flag(bounded,B)` | fails | Exactly **one** flag answers: `executable` (`lib/library.cicili:153-172`). Every portability shim takes the wrong branch. |
| **E1** | `\xHH\` `\NNN\` `\uXXXX` `\e` `\s`, backquotes, `16'FF`, `1_000_000`, unquoted non-ASCII | write the bytes as codes; write `1000000` | Not in the reader's escape set; each is a syntax error refusing the whole file (`lib/syntax.cicili:622-634, :526-544, :660-726`). |
| **T1** | assuming a `:- use_module(library(tcp)).` header loaded something | probe by **calling** inside `catch/3` | A library not on the path makes the directive succeed in **total silence** (`lib/library.cicili:452-456`); the absence surfaces later as `existence_error(procedure, tcp_listen/2)`, naming the predicate and not the module. |
| **T2** | `current_predicate/1` as an availability probe for a library | catch `existence_error` around the real call | `current_predicate/1` is about the **knowledge base**; a module's predicates are not clauses in it, so it says no for a library that is loaded and working. |
| **Z1** | one long clause / one big atom asserted | chunk at ≤3800 bytes and assert the completion mark **in the same turn** | A row must fit a page (~8000 stores, 8192 is `allocation overflow`, per `parsi/01-schema.parsi:23-33` — a comment, not code). Nothing in-process checks it; the refusal arrives at the turn's flush. A single term over **65535** bytes fails earlier and differently, in the client (`client/zigurat.c:911`). |
| **M1** | `cocolog run prog.pl helpers.pl` | `cocolog run prog.pl helpers.pl main` | With more than one argument after `run`, the **last is the goal** (`cocolog.cicili:2350-2356`). Otherwise `helpers.pl` is read as a term to prove. |

### Card §C — house style (~700 tokens)

> **File shape.** A `%%` header block first: (1) one line naming the thing, (2) tier and how
> to import it, (3) the public surface as an indented signature list, (4) what it refuses to
> guess, (5) honest limits. Then directives. Then code in `%% ---- section ----` bands.
>
> **Comment voice.** A capitalised decision clause, then the failure it prevents. Never
> restate the code. `%% A BODY ITEM THAT IS A VARIABLE IS A CALL, not a literal.`
>
> **Throw rather than guess.** Every writer ends with a catch-all clause that throws naming
> the term: `emit(T,_,_) --> { throw(error(type_error(my_term, T), my_codes/2)) }.` The
> second argument of `error/2` names the **public** entry point.
>
> **Codes out, codes-or-atom in.** Writers answer codes (`*_codes/2,3`) with `*_atom/2,3` as
> a convenience; readers take either through a three-clause normaliser whose last clause
> throws.
>
> **Options are a list of one-argument terms**, every one with a default, all defaults in one
> place, none required.
>
> **Determinism is stated.** A clause meant to be deterministic carries a cut and a comment
> saying why.

### Card §D — the entry-point contract (~300 tokens)

> No entry directive exists. The CLI names the goal:
> `cocolog --local run FILE... main`, exit 0 **iff** `main` proved.
> Do not call `halt`. End `main` with `format("done~n")`; the harness requires that as the
> last line of stdout, because exit 0 alone is satisfied by `main :- true.`
> Every claim your program makes about itself is a `must/3`, and this block is repeated
> **verbatim at the foot of every file** — deliberately duplicated, so a program you copy
> anywhere still runs:
>
> ```prolog
> show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).
>
> must(Label, Got, Want) :-
>     (   Got == Want
>     ->  format("   ~w = ~q~n", [Label, Got])
>     ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
>         fail
>     ).
> ```
>
> Call `flush_output` after any progress marker a long run prints: stdout is block-buffered
> into a pipe (nothing calls `setvbuf` on it) and a killed run loses what it has not flushed.

### Card §E — the naming law (~150 tokens), placed last for recency

> Every predicate you define is prefixed with the program's own name — helpers, DCG
> non-terminals, and `main`'s callees included. You may **call** only: a name in the SYMBOLS
> block of this request, a name you define in this file, or one of the 22 control constructs
> (`true fail false , ! ; -> *-> \+ not once ignore call catch throw trace notrace` and the
> engine's own `$`-prefixed ones, which you never write). A gate checks this against the
> running binary and rejects collisions by name.

---

## 5. cocolint — the deterministic linter

`tools/coco-agent/lint.py`, plus `lint.sh` (a human-facing wrapper) and `test/lint.sh`
(the suite case). It reads terms with `clauses.py` and applies fourteen rule families.
Findings are `{file, line, col, rule, severity, name_arity, message, fix, cite}`.

### 5.1 The blocklist, and the five registration shapes

Extracted by `build.py` in one pass over source. **No total is used as an acceptance test**
(§2). The scope decision, made explicitly because the disputed numbers were hiding it:
**tier-1 names are always blocked; a module's names are blocked only when the router's
`tier2_imports` names that module.**

| # | shape | where | reproduced this session |
|---|---|---|---|
| 1 | `(DEFPARAMETER *X-predicates*/*builtins* '(("name" arity fn) …))` | `lib/*.cicili` | **141** unique tier-1 pairs (`grep -ohE '\("[^"]+" +[0-9]+ +[a-z_][A-Za-z0-9_]*\)' lib/*.cicili \| sort -u`) |
| 2 | `(DEFPARAMETER *X-prolog* (FORMAT NIL "~{~A ~}" (LIST "clause…" …)))` | `lib/*.cicili`, `modules/*/*.cicili` | ~129–131 tier-1 heads after unescaping and running the clause reader |
| 3 | `strcmp` chain nested under `(== arity N)` | **only** `modules/torch` (**37**) and `modules/bigint` (**17**) | verified: `grep 'strcmp name' modules/*/*.cicili` hits only those two |
| 4 | clause heads at column 0 | `lib/swipl/*.pl` (263–264), `library/*.pl` (**222**) | DCG heads recorded at **arity+2** |
| 5 | `(DEFPARAMETER *construct-names* …)` | `lib/solve.cicili:151-154` | **22** names, **no arity** — blocked at every arity |

Tier-2 C tables in `modules/*/*.cicili`: **109** pairs, loaded per-import.

**Why a clause reader and not a regex.** On `lib/swipl/dcg_basics.pl` a regex over heads
gives `digit/1`, `digits/1`, `string/1`, `blank/0`; the store holds `digit/3`, `digits/3`,
`string/3`, `blank/2`. A regex blocklist is under-broad *in exactly the arity that collides*.
The reader also strips `/* */` and `%` regions, without which `yall.pl`'s `/** <module> */`
header contributes a bogus `call/1..4`, `atom_concat/3`, `maplist/3`, and `aggregate.pl`'s
contributes `smallest_country/2`.

### 5.2 The rules

| id | severity | checks | message shape |
|---|---|---|---|
| **P1** parse | HARD | Reads every clause. Converts the reader's **byte offset** to `line:col` — the interpreter only ever says `syntax error at offset %lu: %s` (`lib/syntax.cicili:589`) and there are no line numbers anywhere in the pipeline. | `gen/solver.pl:14:23 expected . ending a clause` |
| **D1** directive | HARD | Every `:- D.` against the enumerated fourteen. | *"`initialization/1` is not a directive here; it aborts the whole consult (`lib/kb.cicili:772`). The CLI names the goal: `cocolog --local run gen/solver.pl main`."* |
| **N1** collision-append | HARD | Defined heads ∩ clause-defined reserved set. | *"`step/4` is `lib/swipl/aggregate.pl`'s and `lib/swipl/ugraphs.pl`'s. Consult appends — see §6 for which set of clauses is tried first, and note that it depends on how the file is run. Rename to `solver_step/4`."* |
| **N2** collision-dead | HARD | Defined heads ∩ C-table set (141 + imported modules' 109 + torch/bigint's 54). | *"`memberchk/2` is dispatched before the knowledge base (`lib/solve.cicili:1352-1386`). Your clauses will never run."* |
| **N3** collision-construct | HARD | Defined head names ∩ the 22 construct names, **any arity**. | *"`once` is a control construct matched by interned id (`lib/solve.cicili:151-154`) before the builtin table and before the store. Your clauses are unreachable and no runtime check can see them."* |
| **N4** dcg-arity | HARD | Every `-->` head recorded at arity+2 before N1–N3 run. | folded into the N-messages |
| **E1** existence | WARN | Called goals ∉ (defined ∪ constructs ∪ retrieved symbol scope). | *"`split_string/4` does not exist; `existence_error(procedure, split_string/4)` at run time. cocolog has no string type — see card row X1."* |
| **T1** tier-import | HARD-WARN | A call into a tier-2 library with no `:- use_module`, **and** the inverse: a `use_module` for a tier-1 library (advisory only). | names the exact `sh modules/X/build.sh` |
| **S1** banned-forms | HARD | ~24 regex/term patterns generated from `traps.jsonl` rows whose `rule` field is set: `format(string(`, `~t`/`~|`/`~+`, `write_canonical(`, `b_setval(`, `retract(…), fail` (term-level, not textual), `halt` on a success path, `atan(_,_)`, `log(_,_)`, `random`, `string_concat/split_string/sub_string/atom_string`, `'[|]'`, `:- table`, `:- initialization`, `catch(findall(`, `\xHH\`, `1_000`, backquotes, `16'FF`, `call_with_inference_limit`, `setup_call_cleanup`, `nb_current`, `current_prolog_flag` with any flag but `executable`. | each message is the card row, verbatim, with its `cite` |
| **S2** divergence-report | HARD | For each `divergences_applied[].swi` the model claimed to suppress, grep the emitted file for that form. Present ⇒ fail. | *"You reported suppressing `format(string(S), …)` but line 31 still contains it."* |
| **A1** arithmetic-range | WARN | Integer literals or literal products ≥ 2^59. | card row A2 |
| **Z1** size | WARN | (a) a clause whose canonical text exceeds the configured page budget (default 7900, `--page-bytes`); (b) any single term exceeding 65535 bytes. Two distinct messages. | *(a)* refused by the server at the turn's flush, after the assert that caused it; *(b)* refused by the client with `a Text is limited to 65535 bytes` |
| **C1** contract | HARD | `main/0` defined; last goal of `main` writes `done`; a `must/3` **structurally** matching the house form is defined; every declared public predicate has ≥1 `must/3` and ≥1 negative check. | |
| **C2** self-shadow | HARD | Two files in the manifest defining one name/arity; a duplicate inside `predicates[]`. | |

**Calibration corpus, and the reason it is a suite case.** `test/lint.sh` runs cocolint over
the **47** basics+library tutorials and the **10** `library/*.pl`. Every one must come back
with zero HARD findings. A finding there is a linter bug, not a repo bug — with two documented
exceptions the case whitelists by name and prints: `library/astar.pl:41` is a no-op
`use_module(library(ordsets))` (tier 1), and `astar.pl`'s `insert_all/3` and `insert_open/3`
are genuinely unprefixed helpers in a one-namespace world. Those two exceptions are the
argument for the rule, so the case prints them rather than hiding them.

`test/lint.sh` follows the house shape exactly: an early unconditional SKIP path when
`python3` is absent, and `GREEN`/`SKIP` as the **last line**, because `test/run.sh` discards
each shell case's exit code (`out=$(sh "$script" 2>&1) || true`) and reads only the last line.
It is added to `test/run.sh`'s case list, taking the suite from 40 cases to 41.

---

## 6. The collision oracle — and the ordering finding

### 6.1 The mechanism

Four source sites, all re-read this session:

1. `lib/kb.cicili:1052` — `(if (coco_store_is_muted st) (set ($ (nth pi (-> st preds)) library) 1))`.
   One write; grep finds no clear anywhere.
2. `lib/module.cicili:453/:466` — `coco_module_load` mutes the store around every module's
   Prolog half. The eight vendored libraries and every tier-1 Coco half load through it.
3. `lib/kb.cicili:566-577` — `coco_pred_make` returns the **existing** record when the
   name/arity is already interned. A user's `step/4` lands in the library's record.
4. `lib/builtins.cicili:1731-1753` — `coco_b_predicates` emits a pair only when
   `library == 0`; `current_predicate(N/A) :- '$predicates'(L), '$cp_member'(N/A, L).`
   at `:239-241`.

**Therefore: a predicate that collided is invisible to `current_predicate/1`; a fresh one is
visible.** The gate is a set difference computed in the safe direction —
`COLLISION = DECLARED \ VISIBLE` — which needs no baseline for the common case and cannot be
tripped into a false pass by extra visible names.

**The hole, and its fix.** `coco_pred_dynamic` (`lib/kb.cicili:603-611`, re-read) interns and
sets `dynamic` but **never touches `library`**. So a predicate a muted module declared
`:- dynamic` and never gave a clause to keeps `library = 0` and *is* visible. In tier 1 that
is exactly one name — `goal_expansion/2`, from `lib/swipl/yall.pl:427`, the only `:- dynamic`
in `lib/swipl` — and in tier 2 it is whatever the imported libraries declare. Ashurbanipal's
direction is immune (an extra visible name cannot hide a collision) but it produces a false
`UNDECLARED` finding, so the harness subtracts a **baseline**: the same probe run with only
the candidate's `:- use_module` lines present, cached per sorted import set, invalidated on the
binary's mtime+size. For a tier-1-only program the baseline is one constant computed once.

**The blind spot, stated rather than hidden.** A collision with a **C-dispatched** name or a
**control construct** creates or reuses a record with `library = 0`, so it is *visible* and
the oracle reports nothing — while the clauses are dead. That is why rules N2 and N3 exist and
stay even if the oracle is perfect. Neither mechanism is sound alone.

### 6.2 The oracle outside `--local` — the gap nobody covered

`coco_b_predicates` calls `coco_store_warm st` **before** enumerating (verified this session,
`lib/builtins.cicili:1733`). Under `--local` `warm` is nil (`cocolog.cicili:600-605`;
`coco_store_init` is a memset) and the set is exactly this process's own predicates. Under
`--kb` or `--embed`, `warm` pulls the backend's predicate names in, and the difference stops
being about this file: every predicate any other process wrote to that base appears in
`VISIBLE` and lands in `UNDECLARED`.

**Decision: the oracle is a `--local`-only gate, and the presenter says so** whenever the
router routed the program to `--kb`, `--embed` or `--http`. It is not run in another
arrangement and no result from another arrangement is interpreted.

### 6.3 ORDER — a correction to all four input designs

All four inputs tell the human that a collided predicate's clauses run **after** the library's.
Under the arrangement all four verify in, that is **backwards**, and the arrangement decides it.

Verified this session:

- `cmd_run` (`cocolog.cicili:2118-2173`) consults every file in `argv` **first**, then calls
  `coco_engine_ask_text` and `coco_engine_next`.
- `coco_engine_next` (`lib/solve.cicili:1091-1102`) loads the module registry's clauses at the
  **top of its first call** — "Here and not in `coco_engine_ask` because a store can be emptied
  under a running engine" — via `coco_extern_load` → `coco_module_load`, which consults each
  library's Prolog half *muted*.
- `cmd_script` (`cocolog.cicili:711-748`) builds the goal `use_module('FILE'), main`, so the
  first `coco_engine_next` loads the whole registry **before** `use_module` consults the script.

| arrangement | order of clauses in the shared predicate | tried first |
|---|---|---|
| `cocolog run FILE main` | **user's, then the library's** | **the user's** |
| `cocolog -s FILE` | library's, then the user's | the library's |
| a thawed machine / warmed store | store reset sets `libs` to 0 (`lib/kb.cicili:428-461`), so the registry re-consults; ordering is whatever that turn produces | unpredictable |

So a colliding program **can pass every gate under `run` and answer differently under `-s`**,
and the collision message every input design proposed is misleading. Ashurbanipal's N1 message
therefore says: *"the two sets of clauses merge, and which is tried first depends on how the
file is run — `run` puts yours first, `-s` puts the library's first. Rename."* The presenter
repeats it. This is the strongest single argument for making N1 a **HARD** finding rather than
a warning: the bug is not merely silent, it is arrangement-dependent.

*(A secondary consequence worth knowing: because the library's muted consult sets `library = 1`
on the shared record even when the user asserted into it first, a colliding user predicate is
also invisible to `listing/0` — `lib/solve.cicili:2266-2272` filters the same flag. So the
oracle works in both orders, but the program's own introspection lies in both too.)*

---

## 7. The verification loop — exact commands

Run from the repo root; the library path probes `./library` **relative to the working
directory** before `<exedir>/library` (`lib/library.cicili:193-237`), and
`coco_library_preload` resolves the eight always-loaded libraries through the same `lb_find`
(`:415-424`). So generated code runs in a scratch directory that contains no `library/`, with
the path pinned:

```sh
ROOT=/home/user/cocolog
SCRATCH=$(mktemp -d)                      # contains NO library/ subdirectory
export COCOLOG_LIBRARY="$ROOT/library:${COCOLOG_LIBRARY}"   # ours first, theirs kept
```

Every command below is echoed verbatim into the human transcript.

### G0 — shape (free)
JSON validates; `predicates[]` non-empty and duplicate-free; a `library/*.pl` deliverable is
accompanied by `tutorials/library/NN-name.pl`; `run[]` names a goal explicitly (card row M1).

### G1 — cocolint (free)
```sh
python3 "$ROOT/tools/coco-agent/lint.py" --scope tier1,json,curl gen/*.pl
```
HARD findings block. No process has started, so the message is exact and the fix mechanical.

### G2+G3 — consult and oracle (one process)
```sh
cd "$SCRATCH" && timeout 60 "$ROOT/cocolog" --local \
  run "$WS/solver.pl" "$ROOT/tools/coco-agent/oracle.pl" coco_oracle \
  >oracle.out 2>oracle.err
```
`oracle.pl`, tier 1 only — `findall/3`, `msort/2`, `format/2`, `forall/2`,
`current_predicate/1` — and it **never calls the candidate**:

```prolog
%% Consulted AFTER the candidate. Enumerates only what the store calls the
%% PROGRAM'S OWN: '$predicates'/1 skips every record whose library flag is
%% set (lib/builtins.cicili:1731-1753), and that flag is set on any clause
%% asserted while the store was muted (lib/kb.cicili:1052) and never cleared.
%% A head that collided with a tier-1 library is therefore ABSENT here.
coco_oracle :-
    findall(N/A, current_predicate(N/A), L0),
    msort(L0, L),
    forall(member(N/A, L), format("coco_oracle_name ~q ~w~n", [N, A])),
    write(coco_oracle_end), nl.
```

Three named predicates (`coco_oracle/0` and nothing else — `member/2` and the rest are tier 1)
are subtracted by the harness.

Signals:

| stderr / exit | meaning |
|---|---|
| exit 0 and a `coco_oracle_end` line | consulted cleanly; oracle output is complete |
| `cocolog: FILE: syntax error at offset N: <one of twelve reasons>` | **G1 escape** — log it as a linter bug, convert N to line:col, repair |
| `cocolog: FILE: unsupported directive: N/A` | **G1 escape**; the whole consult aborted |
| `cocolog: FILE: not a clause` | a term the asserter refused |

Then, free:
```sh
grep '^coco_oracle_name ' oracle.out | awk '{print $2"/"$3}' | sort > visible.txt
comm -13 baseline.txt visible.txt > new.txt
comm -23 declared.txt new.txt      > collisions.txt   # MUST be empty
comm -13 declared.txt new.txt      > undeclared.txt   # MUST be empty
```

**Note `--answers` is absent.** It is inert for `run` — `cmd_run` calls `coco_engine_next`
exactly once — and the enumeration happens inside `forall/2`. Passing it would be a flag
applied by reflex, which is how the earlier design got this wrong.

### G4 — execute (one process)
```sh
cd "$SCRATCH" && timeout 60 "$ROOT/cocolog" --local \
  run "$WS/solver.pl" main >run.out 2>run.err ; rc=$?
[ $rc -eq 0 ] && [ "$(tail -1 run.out)" = done ]
```
Both conditions. This is `test/tutorials.sh:89-90`'s contract, which verifies all 47
basics+library lessons. Exit 0 alone is satisfied by `main :- true.`

Streams **never** merged. stdout is block-buffered into a file (the only `setvbuf` in the tree
is a swarm worker's log at `cocolog.cicili:1899`); stderr's buffering is a platform default,
not a repository guarantee — so a merged capture's ordering is meaningless and a
`timeout`-killed run loses unflushed stdout.

Signals from `run.out`: each `   Label = Got  BUT THIS LESSON SAYS Want` is a failed check with
both values — the cheapest possible repair evidence, needing no trace.
From `run.err`: `cocolog: uncaught exception: <ball>` is catchable and escaped;
`cocolog: <anything>` with **no** `uncaught exception:` prefix is a `coco_fail_err` message no
`catch/3` could ever have seen. Exit 124 is `timeout`'s kill.

### G5 — trace localiser (conditional: G4 failed with no `must/3` line)
```sh
cd "$SCRATCH" && timeout 60 "$ROOT/cocolog" --local --trace \
  run "$WS/solver.pl" "( main -> true ; true )" 2>trace.err >/dev/null
grep -E '^\s*(Call|Exit|Redo|Fail):' trace.err | tail -40
```
The if-then-else wrapper makes a failing goal a *traced failure* rather than a differing
toplevel (`test/trace.sh:34`'s own recipe). Parsed with the suite's own regex,
`^\s*[?^]?\s*(Call|Exit|Redo|Fail):\s*\((\d+)\)\s*(.*?)\s*$` (`test/trace-diff.py:14`); the
line format is `   %s: (%d) %s\n` (`lib/solve.cicili:514-523`), the goal written quoted with
operators, unbound variables as `_G<n>`.

**What it localises, stated in the repair prompt so the model does not invent more:** the
innermost sub-goal that ran out of ways, with its arguments as they stood, at a call depth.
**Not** a clause, a file, or a line. Control glue (`,` `;` `->` `!` `\+` `call/N`) prints no
port, and a call backtracked past with no matching head left is discarded in silence.

### G6 — differential swipl (conditional; **the gap nobody covered**)
```sh
command -v swipl >/dev/null || { echo "SKIP no swipl"; exit 0; }
swipl -q -g main -t halt "$WS/solver.pl" >swipl.out 2>swipl.err ; src=$?
diff -u run.out swipl.out
```
Eligibility, decided by the harness and never by the model: the program uses only tier-1
predicates whose semantics are SWI-identical, defines no `op/3`, prints no unbound variable
(`_G<n>` differs), and compares no integer above 2^53 under the standard order. When eligible,
this is a **second, independent verdict on the answers** rather than on the shape — the repo
already does exactly this in `test/files.sh` and `test/trace.sh`, byte-for-byte against swipl.
A difference is reported to the human as a finding, never auto-repaired: it may be cocolog
diverging correctly.

`apt-get install swi-prolog-nox` is the install line; absence is a **skip**, printed, never a
pass and never a red.

### G7 — cross-process (conditional; the claim the repo exists to make)
Only when the router chose `--kb`, and only when a server answered preflight. Uses
`library(kbs)` verbatim rather than reinventing it:

```sh
"$ROOT/cocolog" --kb "$KB" --host 127.0.0.1 --tcp 2160 --timeout 10 vacuum
"$ROOT/cocolog" --kb "$KB" --host 127.0.0.1 --tcp 2160 --timeout 10 forget
"$ROOT/cocolog" --kb "$KB" --host 127.0.0.1 --tcp 2160 --timeout 60 run "$WS/solver.pl" main
"$ROOT/cocolog" --kb "$KB" --host 127.0.0.1 --tcp 2160 --timeout 60 --answers 0 \
  query "( readback -> write(kbs_proved), nl ; write(kbs_refused), nl )" 2>&1 || true
```
The verdict is the `^kbs_proved$` line, **never `$?`** — `query` exits 0 for a goal that merely
failed, and (correction §2) can exit 1 for a *commit* failure after printing a success line.
`--answers 0` **is** required here: the default is 10 and truncates in silence. `|| true`
because a child that threw exits non-zero and the transcript must still be read. `run` for the
write because `run` rolls a failed goal back whole while `query` commits it.

### Preflight (once per session, cached)
```sh
[ -x "$ROOT/cocolog" ]
"$ROOT/cocolog" --kb probe --host 127.0.0.1 --tcp 2160 --timeout 10 list   # server?
pgrep ziguratip                                                            # before believing green
"$ROOT/cocolog" query "use_module(library(tcp))"   # per tier-2 lib, AS A GOAL
command -v swipl
```
A tier-2 library is probed **as a goal**, not as a directive: the directive maps not-found to
success and says nothing (card row T1). As a goal it raises
`error(cocolog_error('use_module: library(tcp): not found on the library path'), _)`.
This is `test/tutorials.sh:42-46`'s own probe.

### Never used, and why
- `cocolog query` as a gate — exits 0 on plain failure.
- `cocolog -s` for a first run — it loads through `use_module`, and `coco_module_load` discards
  the reader's error buffer (`lib/module.cicili:462-464`), leaving only *"its clauses would not
  consult"*: no offset, no reason. The byte offset is the highest-value repair signal there is.
- `--steps N` as a runaway bound — read at exactly one site, inside `cmd_step`
  (`cocolog.cicili:1475`); `run`, `query`, `-s`, `start` and the REPL all set `max_steps` to 0.
- `--timeout S` as a wall clock — it is a socket deadline, never read under `--local`.

**In-process bounding**, when the router flags a search whose termination is not obvious, the
generator emits `call_limited(Goal, 200000, R), R == true`. It re-raises an inner exception so
an enclosing `catch/3` matches, and it is `once/1` with a budget — one `coco_engine_next` — so
the limit goes **outside** a `findall`, never inside it. It bounds runaway recursion and
infinite backtracking; it does **not** bound a hang inside one C builtin (an inference is one
engine-loop iteration) and it does not bound memory (no GC, no heap ceiling). Only the external
`timeout` catches those.

---

## 8. Structured output schemas

### Router
```json
{ "feasibility": "native | native_with_caveat | needs_module | needs_engine | impossible",
  "capabilities": ["json", "http_client", "assert_retract"],
  "arrangement": "local | kb | embed | http",
  "tier2_imports": ["json", "curl"],
  "multi_file": false,
  "request_divergences": [
    { "phrase": "return it as a string",
      "issue": "cocolog has no string type",
      "ask": "an atom, or a code list?",
      "cite": "lib/builtins.cicili:1120-1152" } ],
  "refusals": [ { "want": "streaming response",
                  "because": "modules/curl binds no multi interface",
                  "layer": "loadable module + a frozen-Cicili binding",
                  "nearest": "one whole response via curl_post/6",
                  "cite": "modules/curl/curl.cicili header" } ],
  "restatement": "..." }
```

`request_divergences` is the third judge panel's gap #3 and the cheapest intervention in the
system: it classifies whether **the human's own wording** already carries a divergence
("give me a string", "format into a string sink", "table this predicate", "read from stdin")
before a token of code exists. It is shown to the human first (§11) and renegotiated there.

### Generator / Repair
```json
{ "verdict": "code | impossible | needs-a-layer",
  "files": [ { "path": "gen/solver.pl", "role": "program|library|tutorial", "content": "..." } ],
  "run":  ["--local", "run", "gen/solver.pl", "main"],
  "predicates": [ { "name": "solver_step", "arity": 4, "public": true } ],
  "checks": [ { "label": "three routes found",
                "goal": "findall(R, solver_route(a,z,R), L), length(L,N)",
                "expect": "N == 3", "negative": false },
              { "label": "no route to an island",
                "goal": "( solver_route(a,q,_) -> R = yes ; R = no )",
                "expect": "R == no", "negative": true } ],
  "divergences_applied": [
    { "swi": "format(string(S),\"~w\",[X])", "cocolog": "format(atom(A),\"~w\",[X])",
      "rule": "S1", "cite": "lib/builtins.cicili:1120-1138" } ],
  "uncertain": ["whether sort/4 raises or fails on a partial list"],
  "refusal": null }
```

`predicates[]` feeds the oracle and forces the DCG-arity question (declaring `foo//1` makes the
model write `foo/3`). `divergences_applied[]` is falsified by rule S2. `checks[]` is shown to
the human **before** the code.

**The model-under-declares hole, honestly.** `COLLISION = DECLARED \ VISIBLE` is empty if the
model omits a head from `predicates[]`. Ashurbanipal does not rely on the declaration: `G0`
recomputes `DECLARED` **mechanically** with `clauses.py` from the emitted files and uses that;
the model's `predicates[]` is compared against it and a mismatch is itself a G0 finding
(usually a sign the model mis-tracked DCG arity). This is the one place the design costs more
than Cocolint's and buys soundness for it.

---

## 9. Prompt assembly

### System prompt — fixed, ~4,500 tokens, byte-identical on every call including repair

Order, each justified: **§A framing** first because it reframes everything after it;
**tier inventory** early because it is reference consulted while planning; **exemplars** in the
middle (largest block, most cacheable, position matters least); **§C house style**;
**§B the divergence table late**, nearest the generation, because these are the reflexes being
overridden and recency is the cheapest lever available; **§D contract**; **§E naming law last**.
Then the output contract, with the note that `divergences_applied` is checked.

*This ordering claim is folk wisdom and is scheduled for ablation (§14). It is stated as a
hypothesis, not a finding.*

### User turn — ~10,000–16,000 tokens

| block | size | content |
|---|---|---|
| A. the request, verbatim | var | first, so the model reads what was asked before what it may use |
| B. router verdict | ~250 | feasibility, caveat, arrangement, imports, and any `request_divergences` the human accepted |
| C. retrieved **surface** | 1.5–5k | the verbatim `%%` header comment block of each named library. Header blocks are the *only* authority: `library/json.pl` has 87 clause heads and documents about ten, so a clause-head listing would offer `json_hex4/3` as API. 44 KB across the ten libraries; `httpd.pl` alone is 10.6 KB and is a budget decision the assembler makes explicitly |
| D. retrieved **symbols** | 0.8–2k | name/arity rows for the tier-1 core plus exactly the imported tier-2 libraries, each with a derived `deterministic` flag (C table ⇒ true; clauses ⇒ false). Framed as a closed vocabulary: *"these are the names that exist; anything else raises `existence_error` at run time"* |
| E. reserved **short names** | ~600 | the single-word, no-underscore tier-1 names as a flat list — `step/4 insert/5 delete/3 table/5 balance/2 before/2 extend/3 compose/3 edges/2 vertices/2 prefix/2 reachable/3 digit/3 string/3 blank/2 once call not ignore …` Cheap, and the one place the model needs a *blocklist* rather than a vocabulary, because the temptation is to **name** a helper, not to call one |
| F. exemplars | 4–6k | 2–3 **whole** tutorials, verbatim, plus **their recorded stdout** (§9.1) |
| G. *(repair only)* | 2–4k | previous files, the failed gate with its exact message at `line:col`, the matched trap rows, the trace tail. Placed **after** the exemplars so the good shape is read before the broken one |

**Budget ladder.** Hard cap 24k on the user turn. Drop order: third exemplar → second exemplar
→ largest header block → symbol scope trimmed to imported libraries only. **Never** dropped:
block E and the router verdict.

**Explicitly not in context:** the full reserved table (~2k tokens the model cannot reliably
apply while generating, and which the gate checks perfectly); `README.md`, `STATUS.md`,
`MODULES.md`, `CLAUDE.md`. Those four are dense, mostly accurate, and demonstrably stale —
`STATUS.md:2717` still says the directive handler ignores `use_module` when `lib/kb.cicili:712-740`
dispatches it through a hook; `lib/builtins.cicili:16-32` lists six predicates as missing that
all exist; `tutorials/basics/04-arithmetic.pl:25` says integers are 64 bits and they are 61.
Prose is indexed only as a **source of trap candidates for a human to verify**.

### 9.1 Exemplars are anchored by substring, and they are RUN

Two mechanisms, both from judge gaps:

- **Anchored spans.** No exemplar is pinned to a line range; line-range citations rot faster
  than file citations. An `exemplars.jsonl` row is
  `{path, start_anchor, end_anchor, why}` — e.g. `library/json.pl` from
  `"json_emit(V, _, _) --> { var(V) }"` to `"json_raw([C|Cs]) --> [C], json_raw(Cs)."`. The
  builder resolves anchors to offsets and **fails the build** when either does not match
  exactly once. Eight lines of code; it stops a prompt silently teaching half a predicate after
  an unrelated edit.
- **Recorded output.** Each exemplar row carries `recorded_stdout`, produced by running
  `cocolog --local run <path> main` at index time and stored beside the source. The prompt shows
  the file *and what it actually prints*. This is the only grounding signal in the repository
  that a stale comment cannot corrupt — the model sees behaviour, not just appearance — and it
  is free, because `test/tutorials.sh` already runs all 47.

Chosen exemplars, by capability tag:

| tag | file | why |
|---|---|---|
| self-checking program | `tutorials/basics/01-facts-and-rules.pl` | the template for most requests: header, sections, `main` walking claims, the two helpers at the foot |
| assert/retract | `tutorials/basics/07-assert-and-retract.pl` | the correct `retract` recursion, and it *counts* the removals |
| grammar | `tutorials/basics/10-grammars.pl` | a DCG over codes, `0'0` character codes, `{ }` placement |
| a tier-2 library | `library/astar.pl` | the shortest complete one in the tree — full header template plus the callback idiom. Shipped **with a note on its own two defects** (a no-op tier-1 `use_module`, two unprefixed helpers). Showing a real file and what is wrong with it beats a sanitised one |
| parser / refusal discipline | `library/json.pl` (two anchored spans) | ordered-clause DCG dispatch, `var/1` guard first, `type_error` catch-all last, and the bound-code-list-is-a-call rule nothing in an SWI corpus teaches |
| cross-process | `tutorials/library/34-kbs.pl` | goals as terms, marker-line verdicts, the honest-skip idiom |
| bulk KB write | `coworker/balancer/worker.pl` | chunk, then the completion mark, in one turn; every clause ends in a cut because consult appends |

### 9.2 No embeddings

The corpus that must be resident on **every** request is ~3.5k tokens of divergences; anything
that fits should be resident, not retrieved. What retrieval would nominally serve — the tier-2
surface and the exemplars — is an **exact-match** problem over 47 documents with one
hand-labelled topic each ("the user said certificates" → `library(x509)`, `library(ca)`), not a
similarity problem. `capabilities.json` is ~20 hand-written rows and the builder validates every
path it names.

**Add retrieval when:** the tier-2 surface index exceeds ~4k tokens (today ~1.2k across ten
libraries) or the exemplar set must exceed ~10 files. **And when it arrives, try `grep` over
header blocks first and expect it to be enough.** The mechanism exists natively if it is ever
really wanted — `cocolog::tensors` has a `Vector<Double>` column (`parsi/01-schema.parsi:165`)
and `modules/torch` has `tensor_binary(matmul, …)` — but there is **no distance operator in any
Parsi procedure**, so similarity is a torch matmul or an O(N) Prolog walk.

---

## 10. Repair, failure taxonomy, terminal states

### Repair vs regeneration — the gap nobody priced

**A class-A (syntax) failure is regenerated, not repaired.** The broken file is the largest
block in a repair prompt and the one thing known to be wrong; carrying it into the next turn
spends ~2–4k input tokens teaching the model the shape of its own error. For a mechanical parse
failure the harness re-runs the **generation** prompt with one added line naming the offending
construct and its `line:col`, and no previous file. Every other class is repaired, because the
evidence is about behaviour and the file is the subject.

### The taxonomy

| class | fingerprint | response |
|---|---|---|
| **A** syntax | `syntax error at offset N: <one of twelve reasons>` | **regenerate** with the reason; a G1 escape is logged as a linter bug |
| **B** refused directive | `unsupported directive: N/A` | G1 escape by construction — log, then repair with the whitelist quoted |
| **C** existence_error | exact predicate named | **first decide whether the environment is wrong.** If the name matches a tier-2 library's documented surface and its `.so` is absent, this is an environment failure: report `sh modules/X/build.sh` and **stop**. Repairing here is the worst outcome — the model removes the correct call. Otherwise repair as a typo |
| **D** failed check | `Label = Got  BUT THIS LESSON SAYS Want` | cheapest and most common; needs no trace |
| **E** `main` failed, no check line | G4 exit 1, empty stderr | fire G5, hand back the deepest `Fail` with no later `Exit` at that depth |
| **F** uncaught ball | `cocolog: uncaught exception: <ball>` | repair with the ball |
| **G** uncatchable | `cocolog: <msg>` with **no** `uncaught exception:` prefix | `coco_fail_err` — no ball, nothing could have caught it. Advice is *"move the `catch/3` inside the collected goal"* or *"that evaluable does not exist here"*, never *"handle the error"* |
| **H** silent exit 1 | exit 1, no output, no stderr | the fingerprint of `halt` on a success path (card H1). Gets its own class because it is the most idiomatic SWI shape and produces the least informative failure available |
| **I** non-termination | exit 124, or `inference_limit_exceeded after N inference(s)` naming a check | repair with the instruction to wrap the recursion in `call_limited/3`; note that the partial transcript may be lost |
| **J** swipl divergence (G6) | `diff` non-empty | **never auto-repaired.** Surfaced to the human as a finding |

### The ratchet

A repair diff is applied, **re-linted, and rejected without ever being executed** if it
introduces a new finding — costing one retry (capped at 1 per round), not a round. Acceptance
is monotone. Two rounds, then stop: a third prompt on the same evidence is not new information,
and the human now has strictly more context than the agent.

**Deliberately excluded from a repair prompt:** the text of previous failed diffs. Only their
one-line diagnoses are carried. A repair prompt holding three failed diffs teaches the model to
produce a fourth like them.

### Terminal states — the harness alone decides

- **GREEN** — G0–G4 pass, every declared check reported passing, plus G6 when eligible and G7
  when the request touched the knowledge base and a server answered.
- **AMBER** — it runs, and some check could not run: a tier-2 `.so` absent, no server, no swipl.
  **A skipped check is never dressed as a pass.** A check whose goal raised
  `error(cocolog_error('use_module: … not found on the library path'), _)` is reclassified from
  failure to skip *before* the verdict is computed, and the message names the exact
  `sh modules/X/build.sh`.
- **RED** — it does not run. Class, locus, every repair attempted and why each failed.

There is no code path in the presenter that produces the word GREEN from anything but the
harness's observed verdict. There is no model turn that summarises the outcome and no wording
softener on RED. Note that Ashurbanipal deliberately does **not** imitate `test/run.sh`'s verdict
logic (`out=$(sh "$script" 2>&1) || true`, last line wins, skips uncounted): that discipline is
right for a suite and wrong for a gate.

**Flakes are reported, never smoothed.** A GREEN candidate is re-run once; disagreement is a
FLAKE and blocks GREEN. Known sources, all silent: the standard order's double cast above 2^53;
`_G<n>` names in any check comparing printed text; store ageing under a server.

---

## 11. What the human sees, and how an impossible request is refused

### The transcript, in this order

**1. The verdict, before any code.** Feasibility, and any `request_divergences` the router
found in the human's own wording:

```
FEASIBILITY  native_with_caveat
  You wrote "return the result as a string". cocolog has no string type:
  "abc" IS [97,98,99] and string/1 always fails, deliberately
  (lib/builtins.cicili:1120-1152, lib/kb.cicili:745-771).
  I will answer an ATOM. Say "codes" if you want a code list instead.
```

**2. The checks, as a table, before the code.** A check the human disagrees with is the
cheapest thing in the pipeline to fix, and showing it first is the only defence against a
confidently green implementation of the wrong spec.

**3. The program.**

**4. The gate transcript**, one line per gate with the exact command:

```
G0  shape             PASS  4 predicates declared, 4 found mechanically
G1  cocolint          PASS  0 hard, 1 advisory (D3: use_module on tier-1 lists, removed)
G2  consult + oracle  PASS  cocolog --local run gen/solver.pl tools/coco-agent/oracle.pl coco_oracle
G3  collisions        PASS  4 new, 0 collisions, 0 undeclared    [--local only]
G4  run               PASS  timeout 60 cocolog --local run gen/solver.pl main  (exit 0, last line: done)
G5  trace             n/a
G6  swipl differential PASS  identical stdout, 41 lines
G7  cross-process     SKIP  no server answered 127.0.0.1:2160 — the --kb claim is UNVERIFIED
```

**5. The receipts** — `divergences_applied[]`, each with its citation, plus a note on anything
the gates could not see:

```
wrote  format(atom(A), ...)      not format(string(S), ...)     [S1] lib/builtins.cicili:1120-1138
named  solver_step/4             not step/4                     [N1] aggregate.pl + ugraphs.pl own step/4
       and note: which set of clauses is tried first DEPENDS ON HOW YOU RUN THE FILE —
       `run` puts yours first (cocolog.cicili:2118-2173 consults before the first
       coco_engine_next), `-s` puts the library's first (the registry loads inside
       use_module's own engine call). That is why the rename is mandatory, not stylistic.
omitted  :- use_module(library(lists)).   lists is tier 1; the directive is a no-op    [D3]
```

On RED after two attempts: the last program, every gate result, the trace, and a one-paragraph
account of what the agent believes is wrong — never a partial file presented as finished.

### Refusing what cocolog cannot do

The router's `impossible` verdict is **checked** against a data table, not trusted. The table
lives in `.cocoindex/impossible.json`, generated from `traps.jsonl` rows marked `structural`:

| id | what is absent | evidence |
|---|---|---|
| `streams` | no `open/3,4`, `close/1`, `read/1`, `read_term/2,3`, `nl/1`, `write/2`, `current_output/1` — there is no stream layer at all | grep of `lib/`, `library/`; `format/3` takes a sink (`lib/builtins.cicili:1120-1152`) |
| `strings` | no string type; `double_quotes` is fixed at `codes` | `lib/kb.cicili:745-771` |
| `tabling` | `:- table` does not parse — `table` is not a prefix operator | `lib/syntax.cicili:97-100` |
| `coroutining` | no `freeze/2`, `dif/2`, `when/2`, `setup_call_cleanup/3` | grep of `lib/` |
| `bt_global` | `b_setval` **is** `nb_setval` | `lib/builtins.cicili:76-79` |
| `bignum` | integers are 61 bits, wrapping silently at 2^60 (`library(bigint)` is tier 2 and needs a built ZiguratIP) | `lib/term.cicili:81-86, :110, :641-642` |
| `modules` | `:- module/2` accepted and **ignored**; one flat namespace | `lib/kb.cicili:721` |
| `random` | no `random/1`, `random_float/0`, and reaching for one is **uncatchably** fatal | `lib/solve.cicili:1691, :545-548` |
| `streaming_llm` | no SSE; `modules/curl` binds no multi interface | `modules/curl/curl.cicili` header |
| `http_write` | `assert/1` over `--http` **succeeds** and changes only this process's store — the Zeytun backend leaves `on_assert` null | `lib/zeytun-kb.cicili:139-152` |

Two rules around the table:

1. **A model claim of impossibility that matches no row is downgraded to "hard" and drafted
   anyway** — the model's intuition about what cocolog cannot do is SWI's intuition, and that
   is exactly the intuition that is wrong here.
2. **A refusal that names no substitute is not a refusal a human can act on.** Every refusal
   carries `layer` and `nearest`:

| layer | means | example |
|---|---|---|
| a `.pl` library | ~150 lines of tier-2 Prolog + a tutorial in the same commit | *"this is `library(csv)`"* |
| a loadable module | a `.cicili`, a `build.sh`, an entry point; not part of `make` | *"this needs readline"* |
| an engine change | a new `lib/*.cicili` and a builtin-table entry | *"a real stream layer is `lib/streams.cicili` plus a `coco_stream` table plus ~12 builtins; a week, and it touches `lib/solve.cicili`"* |
| `cocolog.cicili` | a new CLI verb | |
| frozen upstream | **a diagnosis and a proposed patch, never an applied one** | *"this is a Cicili limitation"* |

**Scope boundary, drawn on purpose: v1 does not write Cicili.** A `needs_module` verdict emits
a spec plus the module's **Prolog half** (the `*X-prolog*` clauses), the tutorial, and a
`build.sh` sketch — and explicitly not the `.cicili`. Cicili is Lisp-syntax C with ~20
documented traps of its own (`defer` is a variable attribute not a statement; `break` is a bare
keyword; `(out (T *))` is wrong and `(out T *)` right; a macro must emit exactly one form; a
`#define` is invisible; lambda-list markers must be uppercase). It is a second dialect problem
as large as the first, and Cicili is frozen, so a transpiler-level failure gets a diagnosis and
not a patch. A v2 would build a second index and a second card; v1 says so rather than producing
plausible Cicili that will not compile.

---

## 12. State, memory, and multi-file work

### The agent is stateless per request

Everything it knows lives in `.cocoindex/`, derived from source. Two things persist:
`.cocoindex/baseline-<hash>.txt` (the oracle baseline, keyed on the sorted import set plus the
binary's mtime and size) and `.agent/runs/<id>.json` (the transcript, for the human and for
offline evaluation, **never read back into a prompt**).

Two append-only learning files, both tracked, both human-reviewed before they take effect:
`traps.jsonl` (the presenter emits a *candidate row* with observed failure, fix, and suggested
citation when a repair loop converges on an uncovered divergence; a human verifies citation and
anchor and commits) and `capabilities.json`. **The card only ever grows by human hand** — an
agent that edits its own dialect card drifts exactly the way the prose drifted.

### Why the knowledge base is not the agent's memory

The obvious move is wrong here, for three costs that can be named:

1. Every `assert` rewrites the **whole** predicate — `on_assert` → `coco_zg_sync_pred` forgets
   the predicate and re-asserts every surviving clause (`lib/zigurat-kb.cicili:343-432`).
   Appending message 1,000 to `msg/3` writes 1,000 rows and deletes 1,000.
2. A clause row must fit a page and **nothing in-process checks it**; the refusal arrives at the
   turn's flush, so the `assertz` that caused it succeeded and a `catch/3` around it never fired.
3. `retract/1` is a linear scan plus a whole-predicate rewrite, so nothing may be a mutable queue.

Files hold bulk; the knowledge base holds what several processes must **agree** on; a clause
holds a path. **Add KB state when** more than one agent process must agree — and then copy
`coworker/`'s pattern exactly: chunk well under the page budget and commit the completion mark
**in the same turn** as the chunks, so a peer that sees the mark sees every chunk.

### Why not machines (`start`/`step`/`finish`)

They suspend a *proof* across processes, and they are genuine for a long-running search whose
state is a choice stack. A generation turn's state is a request, a plan and a file — nothing
about it backtracks. The costs are concrete and were established by the fourth design's own
source work: there is **no `yield`** (suspension is budget-driven at whatever goal boundary
`max_steps` hits); **a claim is not a lease** (`parsi/02-procedures.parsi:313-317`), so a
600-second model call inside a turn holds row locks nothing can take away; a save **deletes and
reinserts** every chunk row, so every turn costs O(whole machine); and every thaw resets the
store, so the next `coco_engine_next` re-consults ~130 KB of vendored libraries and interns every
atom they mention. Files carry it for nothing.

### Multi-file

Three constraints, all in the card and all checked:

1. `cocolog run a.pl b.pl main` — the goal must be named (card M1); `run[]` is linted for it.
2. Multi-file is **one namespace split across files**. `:- module/2` hides nothing, so N1–N4 and
   E1 run over the **union** of all files, and C2 rejects two files defining one name/arity.
3. `run` vs `-s` is a semantic choice, not a style one. `-s` loads through `use_module` and
   `coco_module_load` mutes the store, so a `-s`-loaded file's clauses never reach `on_assert`
   and never write through. When the program seeds a knowledge base, `run`. When the deliverable
   is a library, or pages served by a `library(httpd)` worker pool, `use_module` — a worker's
   fresh store is filled from the process-wide module registry, and a consulted page is a
   **silent 404**.

**The contrarian default: one file.** A second file is not encapsulation, it is more clauses in
the same namespace, and it buys a longer run line and one more chance to collide. Three cases
are genuinely multi-file and the router names them: a library **plus its tutorial** (the repo's
own definition of done — `MODULES.md:163-191` — and G0 rejects the library without it); an httpd
program plus its pages; a `library(kbs)` multi-KB script where each base's seed is its own file.

---

## 13. Build order

Increment one is small, useful on its own, needs no model, no API key, no network, and — the
point — **no built binary**, so it is developable in exactly this container.

| # | deliverable | needs | days | acceptance |
|---|---|---|---|---|
| **1** | `tools/coco-agent/clauses.py` | nothing | 0.5 | On `lib/swipl/dcg_basics.pl` it answers `digit/3`, `digits/3`, `string/3`, `blank/2` — not `digit/1`, `blank/0`. Comment regions stripped: `call/1..4` and `smallest_country/2` absent. |
| **2** | `build.py` → the blocklist, **five shapes** | nothing | 1 | 141 tier-1 C pairs exactly; 37 torch, 17 bigint; the 22 construct names present with no arity; **twenty rows hand-checked against source.** No total is an acceptance test. |
| **3** | **`lint.py` rules P1, D1, N1–N4, C2 + `lint.sh` + `test/lint.sh`, added to `test/run.sh`** | nothing | 1.5 | Zero HARD findings over the 47 tutorials and 10 `library/*.pl`, with the two `astar.pl` exceptions printed by name. **This is the shippable product of increment one: a cocolog dialect linter a human runs by hand.** |
| **4** | `traps.jsonl` (~40 rows) + the anchor checker + `make index` + `make dialect-check` + a pre-commit hook | nothing | 2 | `build.py --check` green; every row's `cite` and `anchor` verified by hand. Slowest step, because every row is a manual verification. Note the authoring rule learned the hard way: **anchor on the code, not on prose near it** — the column-directive refusal is written as character codes 116/124/43, not the word "column". |
| **5** | `surface.jsonl`, `exemplars.jsonl` (substring-anchored), `capabilities.json` | nothing | 0.5 | The builder validates every path and every anchor; `library/json.pl` yields ~10 surface entries, not 87. |
| **6** | `verify.sh` gates G4 and G5, validated against the 47 tutorials | **a built binary** | 0.5 | All 47 pass G4 through `verify.sh` rather than through `test/tutorials.sh`. |
| **7** | **BOOTSTRAP** — Cicili + sbcl + a built ZiguratIP + `make` + `make schema` | — | **1–3** | see §13.1 |
| **8** | The oracle: `oracle.pl`, baseline cache, G2+G3 | step 7 | 0.5 | Three probes, in the first hour, that would kill the design: a file defining `step/4` must come back with `step/4` **absent**; `myprog_ok/1` present; `:- dynamic myprog_seen/1.` **present**; `goal_expansion(a,b).` present (the known hole — and if it is absent, the baseline run can be dropped entirely). |
| **9** | Exemplar output recording; Generator + Assembler, router stubbed | 7 | 2 | 25 fixed requests, first-pass gate results measured. This number is the design's baseline; everything after is measured against it. |
| **10** | Router + feasibility table + `request_divergences` | 9 | 0.5 | |
| **11** | Repair, the ratchet, Presenter | 9 | 1 | |
| **12** | `lint.py` rules E1, T1, S1, S2, A1, Z1, C1 | 9 | 1 | Deliberately last: E1 will false-positive on `call/N`, `=..` and `phrase/2,3` and wants the eval corpus to calibrate against. It may end advisory rather than blocking. |
| **13** | G6 (swipl differential), G7 (cross-process) | 7, a server | 1 | G6 skips honestly with no swipl; G7 skips honestly with no server. |
| **14** | The eval set (§14) | 9 | 2 | Produces every number this design's "add it when" thresholds refer to. |

Total ≈ 15 days, of which **increment one is 3 days and ships a standalone product**.

### 13.1 The bootstrap, priced — the largest line item nobody costed

The agent's own container needs three repositories and a C++ build before it can run one
generated line. `Makefile:162-170`: the `cocolog` target runs `embed/build.sh` and links
`.libs/cocolog.o` with `embed/.libs/embed.o` against `-L$(ZIGURATIP)/home/lib -lCore
-lStreamIO` with an rpath. There is no reduced `--local`-only build.

```sh
export CICILI=/path/to/cicili                    # a checkout, and sbcl on PATH
export ZIGURATIP=/path/to/ZiguratIP              # BUILT
export ZIGURATIP_HOME=$ZIGURATIP/home
make && make schema
```

Four documented failure modes, each of which reads as something it is not:

- **`$HOME` is not where the checkouts are.** Every `build.sh` defaults to
  `${CICILI:-$HOME/cicili}`. Getting it wrong fails loudly but far from the cause — a Lisp
  backtrace about `embed/mvccs-lib.cicili` not existing, which is a **symlink** `embed/build.sh`
  made pointing wherever `$HOME` was last time. A stale symlink is not repaired by `make`;
  delete it and re-run.
- **ZiguratIP's engine gauntlet aborts its `make` AFTER the artefacts are built.** So the agent's
  bootstrap has a documented failure mode that reads as a build failure and is not one. On macOS
  `contention_test`'s "rewrite vs index" fails and passes on Linux. **Check for the artefacts
  before believing the exit code.**
- **`make schema` is separately required and separately breaks.** On a Mac it dies inside libc++
  (`std::binary_function`, removed in C++17); the owner's road is
  `ZIGURATIP_CONF=<a copy with -D_LIBCPP_ENABLE_CXX17_REMOVED_BINARY_FUNCTION> make schema`.
- **The server needs its own libraries on the path**, and started plainly it dies at once with
  `libStreamIO.so: cannot open shared object file` — after which every database case SKIPs and
  the suite still says `red: 0`.
  ```sh
  setsid env LD_LIBRARY_PATH="$ZIGURATIP_HOME/lib" "$ZIGURATIP_HOME/bin/ziguratip" >/tmp/zig.log 2>&1 &
  ./cocolog --kb main --host 127.0.0.1 --tcp 2160 --timeout 10 list   # must answer a sentence
  ```

Budget **1 day on Linux with the checkouts present, up to 3 otherwise.** This step gates gates
2–7 of every design considered, and it should be attempted before step 4 is written so a
failure is discovered early.

---

## 14. Evaluation, cost, and break-even

### The eval set

40 held-out natural-language requests with expected verdicts (`code` / `impossible` /
`needs-a-layer`), in `tools/coco-agent/eval/`, run in `test/run.sh`'s shape (last line
`GREEN`/`SKIP`). Five measured quantities:

1. **First-attempt gate pass rate** — lint clean and G4 green with zero repair rounds.
2. **Rounds-to-green distribution** and calls-per-request p50/p90.
3. **Collision-gate catch count** — *the number that justifies this whole design*. If it is near
   zero on real requests, the prompt's naming law is doing the work and the gate is insurance;
   say so and consider demoting it.
4. **Lint escape rate** — every class-B and class-C localisation is by construction a linter bug
   and is logged to a defect ledger, which is the linter's backlog and the mechanism by which the
   system improves with no model training.
5. **False-green rate** — measured against a held-out adversarial check the agent never saw,
   appended by the harness and run separately. **This is the only number that can invalidate the
   design**, and it should exist before anyone relies on the agent.

### The card ablation — the gap nobody covered

Every input design's central bet is that its hand-written card lowers the SWI-ism rate, and every
one pays real maintenance for it. **Not one proposed measuring it.** The eval harness runs three
arms over the same 40 requests:

| arm | system prompt | tells you |
|---|---|---|
| full | card + gates | the shipping number |
| **card off** | framing + contract + naming law only; gates unchanged | **how much the card buys versus how much the gates buy** |
| gates off | card, G0/G1 only | how much of the card the model actually applies |

That single comparison decides whether the card is worth its maintenance, whether the token
budget should go to traps or to exemplars, and whether the linter could carry the load alone.
A secondary A/B on trap **ordering** (§9's admitted folk wisdom) rides on the same harness.

### Cost

| turn | in | out |
|---|---|---|
| router | ~2.5k | ~300 |
| generate | ~20k (of which ~9k a cached system prefix) | ~2.5k |
| repair | ~24k | ~2k |

p50 = 1 large call + 1 small; p90 = 2 large + 1 small; hard cap 3 large. Processes: **2 on the
happy path** (G2+G3 merged, G4), 3 on a baseline-cache miss, 4 if G5 or G6 fires. Process count
is the latency cost — start-up is 441–469 ms bare per `CLAUDE.md`'s own measurement, more with
the embedded store and libtorch linked in. **Both figures are arithmetic over specified prompt
sizes and a quoted measurement, not observation.**

### Break-even, stated because nobody stated one

There is no measurement of what the same task costs a competent human. The honest frame:

- A **Prolog-literate engineer new to cocolog** spends most of a first 100-line program on the
  divergences in §4 — the reading pass that produced this document took several hours per area.
  Call it 1–3 hours for the first program and under an hour once the card is internalised.
- **Increment one alone** (3 days, the standalone linter) breaks even at roughly **20 hand-written
  cocolog files**, and it keeps paying for every file anyone writes afterwards, agent or not.
  Against the 47 tutorials + 10 libraries already in the tree it would have paid for itself twice.
- **The full agent** (~15 days including bootstrap) needs on the order of **50+ generated
  programs**, or one user who is not cocolog-literate at all, to break even. If the intended use
  is "a few programs a month by someone who already knows the dialect", **build increment one and
  stop.** That is a real recommendation, not a hedge.

### What is deliberately not built, with a threshold and a price

| omitted | add it when | cost when it arrives |
|---|---|---|
| a planner / decomposer call | p90 output exceeds ~6k tokens, or first-attempt G4 failure exceeds 40% on multi-file requests | one call, ~500 tokens out, same prompt |
| a critic model | human-rejected-but-all-gates-green exceeds ~15% — i.e. failures are semantic, not dialectal | one call per request; strengthen the `must/3` obligation first, which is free |
| RAG / embeddings | tier-2 surface index exceeds ~4k tokens (today ~1.2k) or exemplars exceed ~10 files | try `grep` over header blocks first |
| machines / KB as agent memory | more than one agent process must **agree** on something | copy `coworker/`'s chunk-plus-mark pattern |
| K>1 generation lanes | never on this evidence — see §1 | — |
| the agent written **in** cocolog | `library(llm)` has its tutorial (`tutorials/library/36-llm.pl`, owed and absent) and is green in `make test` | the driver becomes `llm_json/4` + `proc_run/4` + the same `lint.py` port; writing tutorial 36 is a good first task to *give* this agent |
| a `library(agent)` collecting `check/3` | measured rounds-to-green shows `must/3`'s stop-at-first-failure roughly doubling repair rounds | ~40 lines of tier-2 Prolog + `tutorials/library/NN-agent.pl` in the same commit |

**Every threshold above is invented**, and item 14 of the build order is what replaces them with
numbers. A design whose architecture is an argument about what not to build should measure before
it trusts its own triggers.

---

## 15. Limits — what this will get wrong

1. **The oracle is unobserved.** It rests on four source sites read but not run. If the `library`
   flag is cleared somewhere not found, or a colliding definition gets a fresh record, the oracle
   answers "no collisions" for ever — wrong in the safe-looking direction. Build step 8 exists to
   falsify it in the first hour, and **the static blocklist stays even if the oracle works**,
   precisely so nothing rests on one unverified mechanism.
2. **The oracle is `--local`-only** and blind to two whole classes (C-dispatch, control
   constructs). Under `--kb` or `--embed`, `coco_store_warm` makes the set difference stop being
   about this file (§6.2).
3. **Three of four arrangements are lint-only.** `--kb`, `--embed` and `--http` are never executed
   unless a server happens to answer. The claim this repository exists to make is cross-process,
   and an in-process test cannot make it. G7 closes it when a server is present and drags in the
   store-ageing hazard when it is (a long-lived store slows every run until a timeout reads as a
   hang; `cocolog vacuum` in setup, `pgrep ziguratip` before believing green).
4. **The card degrades by going incomplete, not by going wrong.** Anchors prove a cited line still
   says what it said. They cannot notice a *new* divergence appearing where no row cites. The
   candidate-row mechanism helps only after a failure has been paid for.
5. **The extraction is not proven complete.** Five shapes were found; the fifth was found only by
   adversarial re-derivation, which is direct evidence that a sixth could exist. A name the
   extractor misses is a name the blocklist waves through. The `sha` and `aes` Prolog halves in
   particular returned implausibly few heads in an earlier pass and nobody chased why.
6. **E1 will false-positive.** A call-graph existence check cannot follow `call/N`, `=..` or
   `phrase/2,3`, and cannot see a DCG non-terminal's translated arity without translating the
   body. It is built last so the eval corpus can calibrate it, and it may end advisory.
7. **G4 proves the program's own `must/3` claims held. It does not prove those were the right
   claims.** The heuristic (≥1 check and ≥1 negative check per declared public predicate) is
   satisfiable vacuously by a model that has learned the heuristic. There is no coverage measure
   and no cheap way to add one. The only real defences are procedural: show the checks first, and
   surface any G6 divergence.
8. **Cold-path failures pass every gate.** `X is atan(Dy,Dx)` on a branch `main` does not exercise;
   an over-long `~a` argument; a 2^60 wrap in an untested path. These are exactly the failures that
   surface later in production, and this design catches them least well.
9. **`./library` is a genuine sandbox hole and the mitigation is discipline, not a mechanism.**
   Every invocation must have CWD in a scratch directory with no `library/`. One careless `cd`
   reintroduces it silently, because a wrong `library(assoc)` produces wrong answers rather than an
   error. A `--no-cwd-library` flag would be a mechanism; it is a change to the repo and is not
   proposed here.
10. **No Cicili.** The agent can program cocolog, not extend it. Every request whose honest answer
    is a new module ends in a document rather than a deliverable.
11. **Two model calls is an assertion.** If the real first-pass rate is 50%, the loop is four calls
    typical and the cost roughly doubles. Build step 9 settles it before anyone commits to a cost
    model.
12. **The bootstrap may simply fail.** Three repositories, sbcl, a C++ build with a documented
    post-artefact abort, and a separate `make schema` that breaks separately. Increments 1–5 were
    sequenced to be useful without it; gates 2–7 all wait on it.

---

## 16. Provenance: nothing here was executed *(see §16.1 — it has been now)*

There is no `./cocolog`, no `../cicili`, no `../ZiguratIP` in this container. Every behavioural
claim in this document is read from `.cicili`, `.pl`, `.parsi`, `Makefile` and `test/*.sh` source,
and the corpus sizes were counted this session (**10** `library/*.pl`, **11** basics + **36**
library tutorials, **14** module directories, **44** verbatim `must/3`, **141** tier-1 C-table
pairs, **109** module C-table pairs, torch **37** / bigint **17** strcmp names, **22** construct
names). The prose in `README.md`, `STATUS.md`, `MODULES.md` and `CLAUDE.md` is dense, mostly
accurate, and demonstrably stale in named places; source is the truth and every claim above cites
it.

One row was added to Card §B after synthesis, by the same source-only standard: **I1**,
first-argument indexing. No input design and no reader raised it, and it is the one card row
that tells the generator to write *less* code rather than more.

**Check these six against a live binary before building on them, in this order.** Each is one
command and each gates a component. Add a seventh for I1: define `p(a,1). p(b,2).` and check
that `p(a,X)` leaves no choice point (`cocolog --local run f.pl "p(a,X), write(X), nl"` under
`--trace` shows `Exit` with no later `Redo`).

| # | check | gates | why first |
|---|---|---|---|
| 1 | A file defining `step/4` and `myprog_ok/1`, run through `oracle.pl`: `step/4` must be **absent**, `myprog_ok/1` present. | the whole oracle (G2+G3) | The single largest unobserved mechanism in the design. If it fails, N1 becomes the only defence and the static blocklist becomes load-bearing alone. |
| 2 | `:- dynamic myprog_seen/1.` → **present**; `goal_expansion(a,b).` → **present**. | the baseline-subtraction step | If `goal_expansion/2` comes back absent, the hole is smaller than read and the baseline run can be dropped entirely, saving a process per request. |
| 3 | `main :- write(x), nl, halt.` → `cocolog --local run f.pl main` really exits **1** with nothing on stderr. | card row H1, lint rule S1, localiser class H | The highest-frequency generated-code trap in the design. If the reading is wrong, the linter rejects correct programs. |
| 4 | **The ordering finding (§6.3).** Define `member/2` in a file; run it under `run` and under `-s`; see which clauses answer first. | every N1 message, and the arrangement-dependence warning | Read from `cocolog.cicili:2118-2173` + `lib/solve.cicili:1091-1102` + `cocolog.cicili:711-748` and consistent across all three, but never observed — and all four input designs asserted the opposite. |
| 5 | `catch(findall(X, throw(oops), L), E, true)` really ends the query rather than binding `E`; and `X is 1<<60` really comes back negative. | card rows C1 and A2, localiser class G | Two of the three genuinely silent traps. |
| 6 | `cocolog --local run f.pl true` really consults and proves; a `--trace` `Fail` port prints the goal with bindings in place or already undone (TRACING.md is explicit for Exit and Redo and **silent for Fail**). | G2's load-only shape, G5's parse rules | Small, and the localiser's advice is wrong in a hard-to-notice way if the second half is wrong. |

If check 1 fails, the design still works — the static blocklist plus rules N1–N4 catch the same
class, less exactly and with a table to maintain. If check 3 or check 4 fails, a card row and a
linter rule are wrong and must be rewritten before anything is generated against them. That is the
worst case the sequencing is built to survive: **the parts most likely to be wrong are the parts
scheduled to be tested first.**
### 16.1 What the binary answered — the seven checks, run

§16 was written in a container with no `./cocolog`, no `../cicili` and no `../ZiguratIP`. All
three were built afterwards, and **all seven checks above have now been run**. The commands and
outputs are reproducible from a built tree; each is one line.

| # | check | answer |
|---|---|---|
| 1 | `step/4` **absent**, `myprog_ok/1` present, through `oracle.pl` | **CONFIRMED.** The single largest unobserved mechanism works exactly as read. |
| 2 | `:- dynamic myprog_seen/1.` present; `goal_expansion(a,b).` present | **HALF, and the design gets simpler.** `myprog_seen/1` is present. `goal_expansion/2` is **absent** — so, in the design's own words, "the baseline run can be dropped entirely". |
| 3 | `main :- write(x), nl, halt.` exits **1** with nothing on stderr | **CONFIRMED**, byte for byte: `rc=1`, `x` on stdout, stderr empty. Without the `halt`, `rc=0`. |
| 4 | the ordering finding (§6.3) | **CONFIRMED, and it is arrangement-dependent as claimed.** One program: `run` answers `order([mine,[]])`, `-s` answers `order([[],mine])`. |
| 5 | `catch(findall(…), E, true)` ends the query; `1<<60` is negative | **CONFIRMED, both.** The throw escapes as `cocolog: uncaught exception: oops`; `1<<60` is `-1152921504606846976` and `1<<59` is correct, so 2^59 is the right place to warn. |
| 6 | `run FILE true` consults and proves; what the `Fail` port prints | **CONFIRMED, and the silent half resolved.** `Fail: (2) myprog_q(1)` — **bindings in place**, which is what makes G5's "with its arguments as they stood" correct. `Redo` prints the goal *un*bound; `main` itself gets no `Fail` port under the if-then-else wrapper. |
| 7 | first-argument indexing leaves no choice point | **CONFIRMED.** `myprog_p(a,X)` against `p(a,1). p(b,2).` shows `Exit` with no later `Redo`; unbound, `findall` still gets both. Row I1 stands and `STATUS.md:2760` is stale. |

**Check 2 is the one that changes the design.** The tier-1 oracle baseline is **empty** — an
otherwise-bare candidate yields exactly its own predicates plus `coco_oracle/0` — so the
"cached per sorted import set, invalidated on the binary's mtime+size" machinery in §6.1 is
not needed for a tier-1-only program, which is most of them. The hole it existed to paper over
does not open: `goal_expansion/2` is invisible because `yall.pl` gives it a *clause* (its
`system:` qualifier is stripped, there being no module system), and a clause asserted while
muted sets the flag. A muted library that declares `:- dynamic` and never gives a clause would
still produce a false `UNDECLARED`; there is no such name in tier 1.

**Two corrections to Card §B**, both from running rather than reading:

* **C2 was backwards for builtins.** A builtin leaves `error/2`'s second argument **unbound**,
  and an unbound argument unifies with `context(_,_)` — so SWI's pattern catches builtin errors
  perfectly well here. What it does not catch is the house style §C itself prescribes,
  `throw(error(type_error(a,b), my_codes/2))`, whose context is a bare `Name/Arity`. The row is
  split: **C2** keeps the `cocolog_error/1` half, **C3** carries the correction.
* **Z1 is worse than documented.** §4 says a too-big row is refused at the turn's flush.
  Measured under `--embed`: a clause of 8000 bytes reads back from a second process and one of
  8020 does not, and the writing process reports **exit 0, empty stderr and `done` on stdout**
  either way. Nothing anywhere says the clause was lost, which makes the lint rule the only
  warning there is.

**One refinement to §6.3's parenthetical.** A collided predicate is hidden from `listing/0` —
confirmed, only the fresh `myprog_own/1` prints — but `listing(Name/Arity)` shows **both** sets
of clauses, in the order the arrangement will try them. That makes it the one in-language
diagnostic for a collision, and worth naming in the N1 message.

These answers live in `tools/coco-agent/traps.jsonl` as `empirical` fields on the rows they
correct, so the linter's messages carry them and `traps.py --check` keeps every citation
pointing at the code it claims.
