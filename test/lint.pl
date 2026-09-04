%% cocolint over the calibration corpus, and the two rewrites it stands on.
%%
%% THE LINTER IS COCOLOG. tools/cocolint/clauses.pl and lint.pl are the whole
%% of it; the Python they replaced is gone, and with it the differential check
%% that proved the rewrite faithful. WHAT REPLACED THAT CHECK IS TWO FIXTURES
%% AND A PROBE, and the trade is worth naming: a second implementation catches
%% a regression by disagreeing, which is powerful and goes stale the moment
%% nobody maintains it; a fixture catches one by being SPECIFIC about cases
%% that actually broke something, and the store probe checks against the
%% interpreter itself, which is better ground truth than any second reader.
%%
%% Five things are checked, in cost order:
%%
%%   1. the dialect card's 42 citations still point at the code they claim
%%   2. the retrieval index's paths and anchors resolve
%%   3. clauses.pl reads selftest/reader.pl into exactly reader.expected --
%%      every shape that has ever fooled a clause reader here
%%   4. every rule still fires on selftest/traps.pl
%%   5. the findings over the corpus are still the pinned set, and the
%%      blocklist still matches what the running store says
%%
%% A FINDING IN 5 IS A LINTER BUG UNTIL SHOWN OTHERWISE, which is the point of
%% calibrating against code known to work. The twenty-two that survived are
%% listed below with the argument for each.
%%
%%     cocolog -s test/lint.pl        from the checkout root
%%
%% The linter's own entry points are tools/cocolint/tool.sh and lint.sh, and
%% this case drives them as the .sh did -- they are the tool under test, not
%% the harness.

:- use_module('test/prelude.pl').

main :-
    ( exists_file('tools/cocolint/lint.pl') -> true ; skip('no tools/cocolint') ),
    Agent = 'tools/cocolint',
    the_card(Agent), the_verdicts(Agent), the_index(Agent),
    shl([ 'sh ', Agent, '/tool.sh build >/dev/null 2>&1 || echo BUILD-FAILED' ]),
    ( sh_exit('sh tools/cocolint/tool.sh build >/dev/null 2>&1', 0) -> true ; skip('blocklist would not build') ),
    ( sh_exit('sh tools/cocolint/tool.sh card --facts >/dev/null 2>&1', 0) -> true ; skip('traps.pl would not build') ),
    the_reader(Agent), the_findings(Agent),
    checks_done.

%% ---- 1. the dialect card's citations -------------------------------------
the_card(Agent) :-
    section('the dialect card''s citations'),
    sh_join(['sh ', Agent, '/tool.sh card --check 2>&1'], Cmd),
    shell(Cmd, Out, Rc),
    indented(Out),
    check('the dialect card cites code that is still there, told from its namesakes', Rc, 0).

indented(Text) :-
    atom_codes(Text, Cs), codes_lines(Cs, Ls),
    forall(member(L, Ls), ( atom_codes(A, L), format("  ~w~n", [A]) )).

%% ---- 1b. and the three verdicts the checker can reach --------------------
%%
%% THE ACCEPTING CASE IS THE ONE WORTH PINNING. card.pl takes a moved anchor
%% on trust when the anchor is UNIQUE in its file -- the range was never
%% distinguishing anything there, so the code moving is a fact about the code
%% and not a defect in the card. That is a deliberate loosening, and a
%% loosening nobody tests is one that quietly becomes "never fails".
%%
%% All three verdicts run against a COPY of traps.jsonl with one cite broken
%% each way, through $COCOLOG_TRAPS; the real card is never written to. The
%% breakages are chosen for what they prove: N1's anchor occurs ONCE in
%% lib/kb.cicili (drift -- accepted), A2's `coco_new_int' occurs THREE times in
%% lib/term.cicili as a macro, a declaration and a definition (ambiguous --
%% refused, because the range is the only thing choosing between them), and an
%% anchor nobody wrote is gone (refused; that row needs rereading, not
%% renumbering).
%%
%% THE EDITS NAME A ROW AND A FILE, NOT A LINE RANGE, and that is not
%% tidiness: written with the ranges in them they broke the first time the
%% engine moved, which is the exact failure the checker under test exists to
%% absorb. A test for a drift detector must not itself drift.
the_verdicts(Agent) :-
    section('the three verdicts the checker can reach'),
    scratch(V),
    sh_join([Agent, '/traps.jsonl'], Traps),
    read_file_to_codes(Traps, Cs), codes_lines(Cs, Lines),
    vcase(Agent, V, drift, Lines, '"id": "N1"', '"lib/kb.cicili:[0-9-]*"', '"lib/kb.cicili:1-5"', 0, 'unique anchor, accepted'),
    vcase(Agent, V, ambiguous, Lines, '"id": "A2"', '"lib/term.cicili:[0-9-]*"', '"lib/term.cicili:1-5"', 1, 'the range is what picks the site'),
    %% The anchor this one breaks used to be `unsupported directive: %s/%u',
    %% which is not in the engine any more -- a directive is a goal now. Any
    %% anchor that really exists does the job; this is S2's.
    vcase(Agent, V, gone, Lines, '', 'set_prolog_flag: double_quotes takes', 'NO SUCH ANCHOR HERE', 1, 'is GONE from'),
    shl(['rm -rf ', V]).

%% one broken copy of the card: the rows matching RowPat get Pat replaced by
%% With (every row when RowPat is ''), then card --check over the copy must
%% exit WantRc and say WantText
vcase(Agent, V, Name, Lines, RowPat, Pat, With, WantRc, WantText) :-
    findall(L2, ( member(L, Lines), atom_codes(LA, L),
                  ( ( RowPat == '' ; sub_atom(LA, _, _, _, RowPat) ) -> re_replace_atom(Pat, With, LA, L2) ; L2 = LA ) ), Edited),
    atom_concat(V, '/traps.jsonl', Copy), fixture(Copy, Edited),
    sh_join(['COCOLOG_TRAPS=', Copy, ' sh ', Agent, '/tool.sh card --check 2>&1'], Cmd),
    shell(Cmd, Out, Rc),
    sh_join(['cites: ', Name, ' exits ', WantRc], L1), check(L1, Rc, WantRc),
    sh_join(['cites: ', Name, ' says so'], L2), has(L2, WantText, Out).

%% ---- 2. the retrieval index ----------------------------------------------
the_index(Agent) :-
    section('the retrieval index'),
    sh_join(['sh ', Agent, '/tool.sh index --check --no-run 2>&1'], Cmd),
    shell(Cmd, Out, Rc),
    indented(Out),
    check('the retrieval index names paths and anchors that resolve', Rc, 0).

%% ---- 3. the reader reads its fixture exactly ------------------------------
%%
%% EVERY SHAPE THAT HAS EVER FOOLED A CLAUSE READER HERE, with the answer
%% checked in: DCG heads at arity+2, a pushback head, the 0'c literal that is
%% four characters and not three, a prefix directive taking its argument
%% without parentheses, a `.' after a digit, a Module:Head clause, a quoted
%% head with a doubled quote, a `.' inside a quoted atom, commas inside
%% nesting, a /* */ spanning clauses, and a final clause with no `.' at all.
the_reader(Agent) :-
    section('the reader reads its fixture exactly'),
    scratch(T),
    atom_concat(T, '/files', RT),
    sh_join([Agent, '/selftest/reader.pl'], RF), fixture(RT, [RF]),
    cocolog(C),
    sh_join(['COCO_CC_BATCH= COCO_CC_FILES=', RT, ' ', C, ' --local run ', Agent, '/clauses.pl cc_dump 2>&1 | sed "s|^', Agent, '/selftest/||"'], Cmd),
    shell(Cmd, Got, _),
    sh_join([Agent, '/selftest/reader.expected'], EF), read_file_to_codes(EF, ECs),
    codes_lines(ECs, ELines),
    findall(L, ( member(L, ELines), L \== [], L \= [0'#|_] ), Kept),
    codes_lines(WantCs, Kept), atom_codes(Want, WantCs),
    (   Got == Want
    ->  atom_codes(Got, GCs), re_lines('.', GCs, GL), length(GL, N),
        format("  reader: ~w clauses of selftest/reader.pl, exactly as pinned~n", [N]),
        check('clauses.pl reads its own fixture the way it is pinned', same, same)
    ;   atom_concat(T, '/want', WF), atom_codes(Want, WCs), write_file_from_codes(WF, WCs),
        atom_concat(T, '/got', GF), atom_codes(Got, GCs2), write_file_from_codes(GF, GCs2),
        format("  reader: DIFFERS from selftest/reader.expected (expected < , got > ):~n", []),
        shl(['diff ', WF, ' ', GF, ' | sed ''s/^/    /'' || true']),
        check('clauses.pl reads its own fixture the way it is pinned', differs, same)
    ),
    shl(['rm -rf ', T]).

%% ---- 5. the findings themselves, 4. every rule fires, and the probe -------
the_findings(Agent) :-
    section('the findings over the corpus'),
    findall(P, ( member(Dir, ['tutorials/basics', 'tutorials/library', library]), directory_files(Dir, Fs),
                 member(F, Fs), re_match('\\.pl$', F), ( Dir == library -> true ; re_match('^[0-9]', F) ),
                 sh_join([Dir, '/', F], P) ), Corpus0),
    msort(Corpus0, Corpus), length(Corpus, NFiles),
    atomic_list_concat(Corpus, ' ', CorpusText),
    sh_join(['sh ', Agent, '/lint.sh ', CorpusText, ' 2>&1'], LintCmd), shell(LintCmd, Out, _),
    sh_join(['sh ', Agent, '/lint.sh ', Agent, '/selftest/traps.pl 2>&1'], SelfCmd), shell(SelfCmd, Self, _),
    %% Every finding as `file rule [trap]', with the line number dropped: a
    %% line that moves because somebody added a comment is not a change in
    %% what the linter found, and pinning it would fail this case for the
    %% wrong reason.
    atom_codes(Out, OCs), codes_lines(OCs, OLines),
    findall(G, ( member(L, OLines), atom_codes(LA, L),
                 re_match('^[^ :]+:[0-9]+:[0-9]+ (HARD|WARN) [A-Z0-9]+', LA),
                 re_replace_atom('^([^ :]+):[0-9]+:[0-9]+ (HARD|WARN) ([A-Z0-9]+) (\\[[A-Z0-9]+\\] )?.*', '\\1 \\2 \\3 \\4', LA, G0),
                 re_replace_atom(' *$', '', G0, G) ), Got0),
    msort(Got0, Got),
    forall(( member(L, OLines), atom_codes(LA, L), re_match('HARD|WARN', LA), \+ re_match('^ ', LA) ),
           ( atom_codes(LA2, L), format("  ~w~n", [LA2]) )),
    expected(Expect),
    %% ---- every rule still FIRES ----
    %%
    %% A CORPUS OF CORRECT CODE CANNOT SHOW THAT A RULE WORKS, only that it
    %% does not misfire -- so a rule whose pattern has quietly stopped
    %% matching is invisible above. selftest/traps.pl walks into every
    %% divergence on purpose, and this asserts each one is still caught.
    atom_codes(Self, SCs), codes_lines(SCs, SLines),
    findall(R, ( member(L, SLines), atom_codes(LA, L),
                 re_match('^[^ ]+ (HARD|WARN) [A-Z0-9]+', LA),
                 re_replace_atom('^[^ ]+ (HARD|WARN) ([A-Z0-9]+) (\\[[A-Z0-9]+\\])?.*', '\\2 \\3', LA, R0),
                 re_replace_atom(' *$', '', R0, R) ), Fired0),
    sort(Fired0, Fired),
    sh_join(['sh ', Agent, '/tool.sh card --patterns'], PatCmd), shell(PatCmd, Pats, _),
    atom_codes(Pats, PCs), codes_lines(PCs, PLines),
    findall(W, ( member(L, PLines), L \== [], atom_codes(LA, L), atomic_list_concat(Parts, ' ', LA), Parts = [First|_], sh_join(['S1 [', First, ']'], W) ), PatWants),
    %% D1 IS NOT IN THIS LIST ANY MORE. The rule retired with the divergence
    %% it named: a directive is a goal now, and an unsupported one is
    %% reported at load time rather than aborting the consult. What is left
    %% of that row is D2 -- `:- table p/1.' does not PARSE -- which is an S1
    %% pattern and comes in through `card --patterns' above.
    append(['N1', 'N2', 'N3', 'T1', 'A1 [A2]', 'Z1 [Z1]'], PatWants, Want0), sort(Want0, Want),
    findall(R, ( member(R, Want), \+ memberchk(R, Fired) ), Missing),
    the_probe(Agent, Probe),
    length(Want, NRules),
    ( Missing == [] -> format("all ~w rules fired on selftest/traps.pl~n", [NRules]) ; format("these rules did not fire on selftest/traps.pl: ~w~n", [Missing]) ),
    check('every rule still fires on selftest/traps.pl', Missing, []),
    format("probe: ~w~n", [Probe]),
    ( sub_atom(Probe, 0, _, _, 'BAD') -> check('the blocklist and the running store agree about every reserved name', Probe, agreed) ; check('the blocklist and the running store agree about every reserved name', agreed, agreed) ),
    (   Got == Expect
    ->  findall(x, ( member(G, Got), sub_atom(G, _, _, _, 'HARD') ), Hs), length(Hs, NH),
        findall(x, ( member(G, Got), sub_atom(G, _, _, _, 'WARN') ), Ws), length(Ws, NW),
        format("~w HARD, ~w WARN over ~w files -- the expected set exactly~n", [NH, NW, NFiles]),
        check('cocolint''s findings over the calibration corpus are the pinned set', same, same)
    ;   format("the set changed (expected < , got > ):~n", []),
        forall(( member(E, Expect), \+ memberchk(E, Got) ), format("  < ~w~n", [E])),
        forall(( member(G, Got), \+ memberchk(G, Expect) ), format("  > ~w~n", [G])),
        check('cocolint''s findings over the calibration corpus are the pinned set', changed, same)
    ).

%% ---- the twenty-two, and why each is kept rather than silenced -----------
%%
%% FOURTEEN OF THE TWENTY-TWO ARE TUTORIALS TEACHING THE VERY TRAP THE RULE
%% ENFORCES, which is the most satisfying kind of true positive there is --
%% and a standing argument that the rules point at real divergences, because
%% somebody thought each one worth a lesson:
%%
%%   basics/07  S1 [R1]  `( retract(seen(_)), fail ; true )', written to show
%%                       that the failure-driven loop removes exactly ONE
%%                       clause. The lesson IS the finding.
%%   library/04 S1 [F1]  `~t~20|' inside a catch/3 demonstrating the refusal.
%%   basics/09  S1 [C2]  `catch(atom_length(_,_), error(_, context(Who,_)), ...)',
%%                       written to show the half of C2 that surprises people:
%%                       the pattern does not fail to match, it matches by
%%                       BINDING an unbound context slot, so the handler runs
%%                       and reads back something it invented. The lesson says
%%                       so in the comment above the line.
%%   37-lint    S1 [H1] x2  the tutorial FOR the linter, writing `lit(halt)'
%%                       as a pattern term. H1 looks for halt after one of
%%                       ` \t\n,(;>' and a `(' is one of those, so naming the
%%                       trap in the notation that catches it trips it. The
%%                       alternative is to obscure the pattern the lesson
%%                       exists to show, which is a worse trade than one line
%%                       in this list.
%%   basics/04, 21-bigint, 25-der  A1 x6  `1000000000000000000 * 997' and the
%%                       wrapped answer, which 25-der calls "a wrong answer
%%                       returned confidently".
%%   38-main    S1 [P1]  the tutorial FOR argv, demonstrating that a flag
%%                       cocolog does not have FAILS -- which it does by
%%                       asking for one, `current_prolog_flag(bounded, _)'.
%%                       P1 is right that this is a flag with no answer; the
%%                       lesson's whole claim is that it has none. Naming the
%%                       trap in the notation that catches it, exactly as
%%                       37-lint does above.
%%   basics/10  N1 x2    defines digits//1 and digit//1, which are also
%%                       dcg_basics' at arity 3. A real collision, and the two
%%                       definitions DIFFER -- the tutorial's wants at least
%%                       one digit, dcg_basics' allows none. Latent rather than
%%                       harmful only because their first solutions agree.
%%
%% FOUR ARE REAL FINDINGS IN THE TREE, left for the owner rather than quietly
%% edited:
%%
%%   29-ray, 30-hex, 31-astar  S1 [H1]  their must/3 calls halt(1) on the
%%                       failure branch where the other 48 tutorials fail.
%%                       The exit code coincides, so it works; what it costs is
%%                       the remaining checks and any stdout not yet flushed --
%%                       the failure mode CLAUDE.md records under flush_output.
%%   36-llm     Z1       its main/0 is ~15 KB stored, twice the page budget.
%%                       Harmless only because the tutorial runs --local. The
%%                       same clause under a store is lost SILENTLY -- measured
%%                       under --embed: 8000 bytes reads back from a second
%%                       process, 8020 does not, and the writing process exits
%%                       0 with empty stderr both times.
%%
%% THREE ARE NO-OP IMPORTS already named in CLAUDE.md:
%%
%%   26-x509, 27-ca, library/astar.pl  T1  use_module for a tier-1 library.
%%
%% AND ONE IS AN EXTENSION POINT THAT IS NOT DECLARED AS ONE:
%%
%%   39-tensor-expr  N1  defines expr//2, which library(tensor_expr) also
%%                       defines -- ON PURPOSE. The grammar is open to a file's
%%                       own clauses and the lesson is exactly that: one line
%%                       of the tutorial adds `double(A)' to it. N1 is right
%%                       about the mechanism -- consult APPENDS, so the two
%%                       sets merge and which is tried first depends on how the
%%                       file is run -- and it is harmless HERE only because
%%                       every clause of the library's grammar cuts on a
%%                       different functor, so `double(A)' reaches the file's
%%                       clause either way. A library that wanted this excused
%%                       would DECLARE the hook the way library(httpd) declares
%%                       httpd_page/3, `H :- fail.', which the blocklist's
%%                       shape 4 excuses in both halves. library(tensor_expr)
%%                       does not, so the finding stands and is pinned; that is
%%                       the owner's call to make, not the linter's.
expected([ 'library/astar.pl WARN T1',
           'tutorials/basics/04-arithmetic.pl WARN A1 [A2]',
           'tutorials/basics/04-arithmetic.pl WARN A1 [A2]',
           'tutorials/basics/07-assert-and-retract.pl HARD S1 [R1]',
           'tutorials/basics/09-exceptions.pl HARD S1 [C2]',
           'tutorials/basics/10-grammars.pl HARD N1',
           'tutorials/basics/10-grammars.pl HARD N1',
           'tutorials/library/04-builtins.pl HARD S1 [F1]',
           'tutorials/library/21-bigint.pl WARN A1 [A2]',
           'tutorials/library/21-bigint.pl WARN A1 [A2]',
           'tutorials/library/25-der.pl WARN A1 [A2]',
           'tutorials/library/25-der.pl WARN A1 [A2]',
           'tutorials/library/26-x509.pl WARN T1',
           'tutorials/library/27-ca.pl WARN T1',
           'tutorials/library/29-ray.pl HARD S1 [H1]',
           'tutorials/library/30-hex.pl HARD S1 [H1]',
           'tutorials/library/31-astar.pl HARD S1 [H1]',
           'tutorials/library/36-llm.pl WARN Z1 [Z1]',
           'tutorials/library/37-lint.pl HARD S1 [H1]',
           'tutorials/library/37-lint.pl HARD S1 [H1]',
           'tutorials/library/38-main.pl HARD S1 [P1]',
           'tutorials/library/39-tensor-expr.pl HARD N1' ]).

%% ---- the blocklist, probed against the running store ---------------------
%%
%% THE STRONGEST CHECK HERE, and it costs two processes. One file defines
%% EVERY clause-defined tier-1 name at its recorded arity and asks the
%% oracle: each must come back COLLIDED, the store itself confirming the
%% extraction got the name and the arity right. A second does the same for
%% the C-dispatched names and expects the opposite -- they come back `own',
%% because a C name's record has library = 0 -- which is the oracle's blind
%% spot, measured not asserted.
%%
%% It has paid for itself three times: `sandbox/0' was a name nothing defines
%% (aggregate.pl writes `sandbox:safe_meta_predicate' and cocolog stores that
%% under the HEAD); `throw/1' sat in the clause set where the prompt would
%% have called it nondet; and gating clauses.pl itself found a 0'c literal
%% misread by BOTH clause readers at once.
%%
%% GENERATED FROM blocklist.pl, THE FACTS, not from the JSON -- one line per
%% name and the same list the linter reads, so the probe cannot be testing a
%% different extraction from the one it is checking. Operator names and the
%% arity -1 control constructs are skipped: `=(_,_).' is not a clause anybody
%% writes, and a construct is blocked at every arity so no single arity
%% probes it.
the_probe(Agent, Probe) :-
    scratch(PD),
    sh_join([Agent, '/blocklist.pl'], BL),
    gen(BL, cl_t1p, Clauses), atom_concat(PD, '/clauses.pl', CF), fixture(CF, ['myprog_marker(1).'|Clauses]),
    gen(BL, cl_t1c, CTable), atom_concat(PD, '/ctable.pl', TF), fixture(TF, ['myprog_marker(1).'|CTable]),
    sh_join(['sh ', Agent, '/oracle.sh ', CF, ' 2>/dev/null'], C1), shell(C1, CL, _),
    sh_join(['sh ', Agent, '/oracle.sh ', TF, ' 2>/dev/null'], C2), shell(C2, CT, _),
    shl(['rm -rf ', PD]),
    atom_codes(CL, CLCs), codes_lines(CLCs, CLL),
    findall(L, ( member(L, CLL), atom_codes(LA, L), sub_atom(LA, 0, _, _, own), \+ sub_atom(LA, _, _, _, myprog_marker) ), Leaks), length(Leaks, Leak),
    re_lines('^COLLIDED', CLCs, Coll), length(Coll, NC),
    atom_codes(CT, CTCs), codes_lines(CTCs, CTL),
    findall(L, ( member(L, CTL), atom_codes(LA, L), sub_atom(LA, 0, _, _, own), \+ sub_atom(LA, _, _, _, myprog_marker) ), Blind), length(Blind, NB),
    (   Leak =:= 0
    ->  sh_join([NC, ' of ', NC, ' clause-defined names confirmed taken by the store; ', NB, ' C-dispatched names come back visible, which is the blind spot N2 covers'], Probe)
    ;   sh_join(['BAD: ', Leak, ' clause-defined name(s) the blocklist blocks are free in the store'], Probe),
        forall(member(L, Leaks), ( atom_codes(LA, L), format("  ~w~n", [LA]) ))
    ).

%% the .sh's awk over blocklist.pl: every `FUNCTOR('name', arity, ...)' fact
%% becomes one clause head `name(_,...,_).' -- arities below zero and names
%% that are not plain identifiers skipped, each name/arity once
gen(BL, Functor, Clauses) :-
    read_file_to_codes(BL, Cs), codes_lines(Cs, Lines),
    atom_concat(Functor, '(', Prefix),
    findall(N/A, ( member(L, Lines), atom_codes(LA, L), sub_atom(LA, 0, _, _, Prefix),
                   atomic_list_concat(Parts, '''', LA), Parts = [_, N, AText|_],
                   re_replace_atom('[^0-9-]', '', AText, ADigits), atom_number(ADigits, A), A >= 0,
                   re_match('^[a-z][a-zA-Z0-9_]*$', N) ), Pairs0),
    sort(Pairs0, Pairs),
    findall(C, ( member(N/A, Pairs),
                 ( A =:= 0 -> atom_concat(N, '.', C)
                 ; length(Us, A), maplist(=('_'), Us), atomic_list_concat(Us, ',', Args), sh_join([N, '(', Args, ').'], C) ) ), Clauses).
