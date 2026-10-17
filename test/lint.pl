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
%%   1. the dialect card's citations still point at the code they claim
%%   2. the retrieval index's paths and anchors resolve
%%   3. clauses.pl reads selftest/reader.pl into exactly reader.expected --
%%      every shape that has ever fooled a clause reader here
%%   3b. E1 pairs backslashes the way the reader does -- the one thing
%%      selftest/traps.pl cannot show, for it shows what is FOUND
%%   3c. E1's radix numeral needs a digit after its quote, so a quoted atom
%%      that ends in 16 is no finding -- the same thing, the same way
%%   3d. X2 is lifted where a library gives streams: library(stream), and
%%      library(websocket), which loads it -- by a directive or by a goal
%%   3e. an acknowledgement covers its own line, or the next when it stands
%%      alone; one with no reason, or whose finding has gone, is a U1
%%   4. every rule still fires on selftest/traps.pl, its acknowledgements
%%      ignored, and the file lints clean with them read
%%   5. the whole tree lints clean, and the blocklist still matches what the
%%      running store says
%%
%% A FINDING IN 5 IS A LINTER BUG OR A DEFECT IN THE TREE, and neither is
%% pinned: the corpus is every Prolog file the repository holds, and the
%% findings it is held to are none. A form a file commits on purpose -- a
%% lesson that teaches a trap by walking into it -- carries an
%% acknowledgement where it stands, `% cocolint: ID -- why', which the
%% linter reads and U1 keeps honest.
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
    the_reader(Agent), the_escapes(Agent), the_radix(Agent), the_lifts(Agent), the_acks(Agent),
    the_findings(Agent),
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
%% lib/kb.cicili (drift -- accepted), W1's `coco_bi_write_canonical' occurs
%% TWICE in lib/solve.cicili as a builtin row and a definition (ambiguous --
%% refused, because the range is the only thing choosing between them; it was
%% W1's `coco_write_canonical' in lib/syntax.cicili, a declaration and a
%% definition, until 2.2.5 moved the cite to where write_canonical/1 picks
%% its mode, and A2's `coco_new_int' until 2.0.0 retired that row), and an
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
    vcase(Agent, V, ambiguous, Lines, '"id": "W1"', '"lib/solve.cicili:[0-9-]*"', '"lib/solve.cicili:1-5"', 1, 'the range is what picks the site'),
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
    check('the retrieval index names paths and anchors that resolve', Rc, 0),
    %% AND IT SAYS NOTHING SOFT. A `thin' library documents almost none of
    %% its heads and an `unrouted' one no topic reaches; both are reports and
    %% not failures of the index, and both are defects of the tree, which
    %% has none (2.2.1: four reasoning programs whose headers named nothing,
    %% and library(cowork), which no row named).
    atom_codes(Out, OCs), codes_lines(OCs, OLs),
    findall(N, ( member(L, OLs), atom_codes(N, L),
                 ( sub_atom(N, 0, _, _, 'thin') ; sub_atom(N, 0, _, _, 'unrouted') ) ), Soft),
    check('and reports no library thin or unrouted', Soft, []).

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

%% ---- 3b. E1 reads the backslash the way the reader pairs them --------------
%%
%% THE SCAN SEES BYTES AND THE READER SEES PAIRS. E1 looks inside quotes for a
%% backslash, `u' and four hex digits, and in a quoted atom `\\u0041' is an
%% escaped backslash and the letters u0041 -- what every JSON test writes --
%% which matched at its SECOND backslash: six HARD findings in
%% test/serialize.pl over code that was right. selftest/traps.pl shows what a
%% rule FINDS and cannot show what it must leave alone, so the six shapes are
%% written here, with ~c so that this file says nothing the linter would read
%% as an escape: one backslash, two, three, four, a pair round x41, and a real
%% \x41\. The reader pairs from the left, so the one and the three (a pair and
%% an escape) and the real one are findings, at the backslash that opens them,
%% and the two, the four and the pair round x41 are not.
the_escapes(Agent) :-
    section('E1 reads the backslash the way the reader pairs them'),
    scratch(T), shl(['mkdir -p ', T]),
    sh_join([T, '/escapes.pl'], F),
    findall(Line, ( member(Fmt-Args, [ "a('~cu0041').~n"-[92],
                                       "b('~c~cu0041').~n"-[92, 92],
                                       "c('~c~c~cu0041').~n"-[92, 92, 92],
                                       "d('~c~c~c~cu0041').~n"-[92, 92, 92, 92],
                                       "e('~c~cx41~c~c').~n"-[92, 92, 92, 92],
                                       "f('a~cx41~cb').~n"-[92, 92] ] ),
                    format(atom(Line), Fmt, Args) ), Lines),
    atomic_list_concat(Lines, '', Text), atom_codes(Text, TCs), write_file_from_codes(F, TCs),
    sh_join(['sh ', Agent, '/lint.sh ', F, ' 2>&1'], Cmd), shell(Cmd, Out, _),
    atom_codes(Out, OCs), codes_lines(OCs, OLines),
    findall(LC, ( member(L, OLines), atom_codes(LA, L),
                  re_match('^[^ :]+:[0-9]+:[0-9]+ HARD S1 \\[E1\\]', LA),
                  re_replace_atom('^[^ :]+:([0-9]+:[0-9]+) .*', '\\1', LA, LC) ), Got),
    check('only the backslashes the reader would not have paired are findings (line:col)', Got, ['1:4', '3:6', '6:5']),
    shl(['rm -rf ', T]).

%% ---- 3c. E1's radix numeral has digits after its quote ---------------------
%%
%% `16'FF' is SWI's radix notation, which the reader here does not have, and E1
%% looks for it inside quotes like the rest. The pattern was the bytes `16'' and
%% nothing after them, so a QUOTED ATOM that ends in 16 matched at its own
%% closing quote: `'Content-Length: 16'' in test/httpd.pl, a HARD finding over
%% code that was right. A numeral has a digit after the quote, and now so does
%% the pattern. selftest/traps.pl shows what a rule FINDS, so what it must
%% leave alone is written here, with ~c for the quote of a numeral so that this
%% file says nothing the linter would read as one: an atom that ends in 16, the
%% atom `16', an escaped quote and a hex letter after a 16, and then two
%% numerals, with capital digits and with small ones. Only the two numerals
%% are findings, at the 16 that opens each.
the_radix(Agent) :-
    section('E1 flags a radix numeral, not a quoted atom that ends in 16'),
    scratch(T), shl(['mkdir -p ', T]),
    sh_join([T, '/radix.pl'], F),
    findall(Line, ( member(Fmt-Args, [ "a('Content-Length: 16').~n"-[],
                                       "b('16').~n"-[],
                                       "c('it''s 16''a').~n"-[],
                                       "d(X) :- X is 16~cFF.~n"-[39],
                                       "e(X) :- X is 16~cff.~n"-[39] ] ),
                    format(atom(Line), Fmt, Args) ), Lines),
    atomic_list_concat(Lines, '', Text), atom_codes(Text, TCs), write_file_from_codes(F, TCs),
    sh_join(['sh ', Agent, '/lint.sh ', F, ' 2>&1'], Cmd), shell(Cmd, Out, _),
    atom_codes(Out, OCs), codes_lines(OCs, OLines),
    findall(LC, ( member(L, OLines), atom_codes(LA, L),
                  re_match('^[^ :]+:[0-9]+:[0-9]+ HARD S1 \\[E1\\]', LA),
                  re_replace_atom('^[^ :]+:([0-9]+:[0-9]+) .*', '\\1', LA, LC) ), Got),
    check('only a numeral with its digits is a finding (line:col)', Got, ['4:14', '5:14']),
    shl(['rm -rf ', T]).

%% ---- 3d. X2 is lifted where a library gives streams ------------------------
%%
%% A LIFT IS A RULE LEAVING CODE ALONE, which selftest/traps.pl cannot show
%% either. One clause six times -- a session loop's test for the message
%% `close(Code, Why)', which a textual pattern cannot tell from a call --
%% with no import, under library(stream), under library(websocket), which
%% loads library(stream) itself, and under library(stream) loaded as a GOAL,
%% as test/stream.pl loads it so that it can skip without the module; and
%% then with the import written only in a comment, and only in a quote,
%% neither of which loads anything. The first and the last two are findings.
the_lifts(Agent) :-
    section('X2 is lifted by library(stream), by library(websocket), which loads it, and by either loaded as a goal'),
    scratch(T), shl(['mkdir -p ', T]),
    findall(Name-LCs,
            ( member(Name-Import, [ bare-[],
                                    stream-[':- use_module(library(stream)).'],
                                    websocket-[':- use_module(library(websocket)).'],
                                    goal-['loads :- catch(use_module(library(stream)), _, fail).'],
                                    comment-['% use_module(library(stream)) is not loaded here'],
                                    quoted-['says :- write(''use_module(library(stream))'').'] ]),
              atomic_list_concat([T, '/', Name, '.pl'], F),
              append(Import, ['ended(M) :- M = close(_, _).'], Lines),
              fixture(F, Lines),
              sh_join(['sh ', Agent, '/lint.sh ', F, ' 2>&1'], Cmd), shell(Cmd, Out, _),
              atom_codes(Out, OCs), codes_lines(OCs, OLines),
              findall(LC, ( member(L, OLines), atom_codes(LA, L),
                            re_match('^[^ :]+:[0-9]+:[0-9]+ HARD S1 \\[X2\\]', LA),
                            re_replace_atom('^[^ :]+:([0-9]+:[0-9]+) .*', '\\1', LA, LC) ), LCs) ),
            Got),
    check('close(Code, Why) is a finding only where no library gives streams (line:col)', Got,
          [bare-['1:17'], stream-[], websocket-[], goal-[], comment-['2:17'], quoted-['2:17']]),
    shl(['rm -rf ', T]).

%% ---- 3e. an acknowledgement, and U1 ----------------------------------------
%%
%% AN ACKNOWLEDGEMENT IS A RULE LEAVING CODE ALONE ON THE CODE'S OWN WORD,
%% and the five ways it can go are written here, each with ~c for the `%' of
%% the comment so that this file says nothing the linter would read as one:
%% after the code on its line (covered), alone on the line before (covered),
%% two IDs in one (both covered), one with no reason after `--' (not
%% covered, and a U1), and one whose finding is not on its line (a U1, the
%% stale kind). Under COCO_LINT_NO_ACK=1 none is read, and every R1 is back.
the_acks(Agent) :-
    section('an acknowledgement covers its line or the next, and U1 reports one that excuses nothing'),
    scratch(T), shl(['mkdir -p ', T]),
    sh_join([T, '/acks.pl'], F),
    findall(Line, ( member(Fmt-Args, [ "a :- ( retract(i(_)), fail ; true ).   ~c cocolint: R1 -- shown on purpose~n"-[37],
                                       "~c cocolint: R1 -- shown on purpose~n"-[37],
                                       "b :- ( retract(i(_)), fail ; true ).~n"-[],
                                       "c :- ( retract(i(_)), fail ; true ), format(\"~ct~cw\", [x]).   ~c cocolint: R1, F1 -- both~n"-[126, 126, 37],
                                       "d :- ( retract(i(_)), fail ; true ).   ~c cocolint: R1~n"-[37],
                                       "e :- true.   ~c cocolint: X3 -- nothing here~n"-[37] ] ),
                    format(atom(Line), Fmt, Args) ), Lines),
    atomic_list_concat(Lines, '', Text), atom_codes(Text, TCs), write_file_from_codes(F, TCs),
    findall(Env-Got, ( member(Env, ['', 'COCO_LINT_NO_ACK=1 ']),
                       sh_join([Env, 'sh ', Agent, '/lint.sh ', F, ' 2>&1'], Cmd), shell(Cmd, Out, _),
                       atom_codes(Out, OCs), codes_lines(OCs, OLines),
                       findall(LC, ( member(L, OLines), atom_codes(LA, L),
                                     re_match('^[^ :]+:[0-9]+:[0-9]+ (HARD|WARN) ', LA),
                                     re_replace_atom('^[^ :]+:([0-9]+:[0-9]+) (HARD|WARN) ([A-Z0-9]+) (\\[([A-Z0-9]+)\\] )?.*', '\\1 \\3\\5', LA, LC) ), Got) ),
            [_-Read, _-Ignored]),
    check('read: what is not acknowledged, and a U1 for each that excuses nothing (line:col rule)', Read,
          ['5:8 S1R1', '5:40 U1', '6:14 U1']),
    check('ignored: every finding is back, and no U1', Ignored,
          ['1:8 S1R1', '3:8 S1R1', '4:8 S1R1', '4:46 S1F1', '5:8 S1R1']),
    shl(['rm -rf ', T]).

%% ---- 5. the whole tree, 4. every rule fires, and the probe ----------------
the_findings(Agent) :-
    section('the findings over the whole tree'),
    lint_corpus(Corpus), length(Corpus, NFiles),
    atomic_list_concat(Corpus, ' ', CorpusText),
    %% FIVE MINUTES, NOT THE TWO shell/3 GIVES, because this step reads the
    %% whole tree and the tree grows with every sample the translator takes.
    %% It ran PAST two minutes unnoticed for a stretch of versions -- 243 s on
    %% 1.8.31, 160 s on 1.8.32 -- and a step that times out hands back an
    %% empty output, which this case would read as a clean tree: the summary
    %% line is asked for below, and an empty output has none. The linter's
    %% own two fixes took the old corpus to 75 s; the whole tree, three
    %% hundred files, is 55 s on 2.2.1.
    sh_join(['sh ', Agent, '/lint.sh ', CorpusText, ' 2>&1'], LintCmd), shell(LintCmd, Out, _, 300000),
    sh_join(['COCO_LINT_NO_ACK=1 sh ', Agent, '/lint.sh ', Agent, '/selftest/traps.pl 2>&1'], SelfCmd), shell(SelfCmd, Self, _),
    sh_join(['sh ', Agent, '/lint.sh ', Agent, '/selftest/traps.pl 2>&1'], AckCmd), shell(AckCmd, Acked, _),
    atom_codes(Out, OCs), codes_lines(OCs, OLines),
    findall(G, ( member(L, OLines), atom_codes(LA, L),
                 re_match('^[^ :]+:[0-9]+:[0-9]+ (HARD|WARN) [A-Z0-9]+', LA),
                 re_replace_atom('^([^ :]+):[0-9]+:[0-9]+ (HARD|WARN) ([A-Z0-9]+) (\\[[A-Z0-9]+\\] )?.*', '\\1 \\2 \\3 \\4', LA, G0),
                 re_replace_atom(' *$', '', G0, G) ), Got0),
    msort(Got0, Got),
    forall(( member(L, OLines), atom_codes(LA, L), re_match('HARD|WARN', LA), \+ re_match('^ ', LA) ),
           ( atom_codes(LA2, L), format("  ~w~n", [LA2]) )),
    %% ---- every rule still FIRES ----
    %%
    %% A CORPUS OF CORRECT CODE CANNOT SHOW THAT A RULE WORKS, only that it
    %% does not misfire -- so a rule whose pattern has quietly stopped
    %% matching is invisible above. selftest/traps.pl walks into every
    %% divergence on purpose, and this asserts each one is still caught --
    %% with its acknowledgements IGNORED, for each of its lines carries one.
    atom_codes(Self, SCs), codes_lines(SCs, SLines),
    findall(R, ( member(L, SLines), atom_codes(LA, L),
                 re_match('^[^ ]+ (HARD|WARN) [A-Z0-9]+', LA),
                 re_replace_atom('^[^ ]+ (HARD|WARN) ([A-Z0-9]+) (\\[[A-Z0-9]+\\])?.*', '\\2 \\3', LA, R0),
                 re_replace_atom(' *$', '', R0, R) ), Fired0),
    length(Fired0, NSelf),
    sort(Fired0, Fired),
    sh_join(['sh ', Agent, '/tool.sh card --patterns'], PatCmd), shell(PatCmd, Pats, _),
    atom_codes(Pats, PCs), codes_lines(PCs, PLines),
    findall(W, ( member(L, PLines), L \== [], atom_codes(LA, L), atomic_list_concat(Parts, ' ', LA), Parts = [First|_], sh_join(['S1 [', First, ']'], W) ), PatWants),
    %% D1 IS NOT IN THIS LIST ANY MORE. The rule retired with the divergence
    %% it named: a directive is a goal now, and an unsupported one is
    %% reported at load time rather than aborting the consult. What is left
    %% of that row is D2 -- `:- table p/1.' does not PARSE -- which is an S1
    %% pattern and comes in through `card --patterns' above.
    %% NOR IS RULE A1 (2.0.0), with the silent wrap at 2^60 it warned of:
    %% integers are 64 bits and a result past them raises; nor the card's
    %% trap A1's pattern (2.2.1), which could not tell `log(A, B)' from a
    %% predicate of that name -- the row is a prompt now.
    append(['N1', 'N2', 'N3', 'T1', 'Z1 [Z1]'], PatWants, Want0), sort(Want0, Want),
    findall(R, ( member(R, Want), \+ memberchk(R, Fired) ), Missing),
    the_probe(Agent, Probe),
    length(Want, NRules),
    ( Missing == [] -> format("all ~w rules fired on selftest/traps.pl~n", [NRules]) ; format("these rules did not fire on selftest/traps.pl: ~w~n", [Missing]) ),
    check('every rule still fires on selftest/traps.pl, its acknowledgements ignored', Missing, []),
    %% AND WITH THEM READ THE FIXTURE IS CLEAN, every finding acknowledged and
    %% every acknowledgement used: a stale one would be a U1 here.
    atom_codes(Acked, ACs), codes_lines(ACs, ALines),
    findall(A, ( member(L, ALines), atom_codes(A, L), re_match('^[^ ]+ (HARD|WARN) ', A) ), AckedFindings),
    atomic_list_concat(['0 HARD, 0 WARN over 1 file(s), ', NSelf, ' acknowledged'], AckWant),
    ( sub_atom(Acked, _, _, _, AckWant) -> AckSays = AckWant ; AckSays = Acked ),
    check('and with them read it is clean, every acknowledgement used', AckedFindings-AckSays, []-AckWant),
    format("probe: ~w~n", [Probe]),
    ( sub_atom(Probe, 0, _, _, 'BAD') -> check('the blocklist and the running store agree about every reserved name', Probe, agreed) ; check('the blocklist and the running store agree about every reserved name', agreed, agreed) ),
    %% THE SUMMARY LINE IS THE PROOF THE LINT RAN, and it says what was
    %% acknowledged and what was not read.
    (   member(LS, OLines), atom_codes(Sum, LS), sub_atom(Sum, 0, _, _, 'cocolint: ')
    ->  format("~w (~w files named)~n", [Sum, NFiles]), Ran = yes
    ;   Ran = no
    ),
    check('the lint over the whole tree ran to its summary', Ran, yes),
    check('the whole tree lints clean: no finding, HARD or WARN', Got, []).

%% THE CORPUS IS THE TREE: every .pl under the directories that hold Prolog,
%% less the three the build writes -- git-ignored, and data, not programs:
%% the card's facts quote every trap they describe. lib/swipl's eight are
%% named too, and the linter leaves them unread (SWI's own sources, which
%% the blocklist is read from) and counts them in its summary.
%%
%% ELEVEN FINDINGS WERE PINNED HERE until 2.2.1, each with the argument for
%% keeping it; the tree is held to none now. Six were lessons teaching the
%% trap the rule enforces, and they acknowledge it where it stands (07's
%% R1, 09's C2, 04's F1, 38's P1, and the case test/stream.pl's W1). Three
%% were no-op imports and are gone (26, 27, library/astar.pl); the files
%% swipl also runs keep theirs, acknowledged. Lesson 10's digits//1 and
%% digit//1 joined dcg_basics' and are numeral//1 and numeral_digit//1;
%% lesson 36's main/0, twice a page, is a predicate per section;
%% library(tensor_expr) declares expr//2 the extension point lesson 39 uses
%% (`expr(_, _, _, _) :- fail.'); and test/torch-graph.pl calls the builtin
%% file_base_name/2 it used to define again. The whole tree had 122 when
%% it was first linted: the other hundred were X2 in test/stream.pl, which
%% loads library(stream) as a goal, and A1's misfires on test/tls.pl's
%% log/5.
lint_corpus(Files) :-
    findall(P, ( member(D, [bench, coworker, demo, emacs, lib, library, test, tools, tutorials]),
                 lint_walk(D, P),
                 \+ memberchk(P, ['library/flow/tables.pl', 'tools/cocolint/blocklist.pl',
                                  'tools/cocolint/traps.pl']) ),
            Ps),
    msort(Ps, Files).

lint_walk(Dir, P) :-
    exists_directory(Dir),
    directory_files(Dir, Es),
    member(E, Es),
    \+ memberchk(E, ['.', '..', '.libs', build]),
    atomic_list_concat([Dir, '/', E], Path),
    (   exists_directory(Path)
    ->  lint_walk(Path, P)
    ;   atom_concat(_, '.pl', E),
        P = Path
    ).

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
