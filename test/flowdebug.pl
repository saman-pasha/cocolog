%% library(flow/debug) -- what a query did, drawn over its flowchart.
%%
%% WHAT IS WORTH CHECKING is what a person or an agent would act on and
%% could not see for themselves: WHICH BOX each call of a run is -- a call
%% placed on the wrong goal sends a reader to the wrong line -- how each
%% call ended, which values crossed into which of the source's variables,
%% how the run ended and whether the replay was the run the probe saw, and
%% that the picture and the XML name the same things. Each is checked
%% against a value worked out by hand from test/flowdebug/run.pl, whose
%% goals each move control through a clause one way:
%%
%%   top(5, Y)     an if-then-else's then, \+ over a call that fails,
%%                 findall/3 over member/2
%%   top(-3, Y)    the else, and a disjunction's second branch
%%   twice(A, B)   one predicate called twice in a clause
%%   choose(-1)    an else and a then that call one predicate
%%   pick(X)       a redo: a binding undone, and the next one made
%%   safe(E)       an exception raised, unwound and caught, and the
%%                 recovery called; oops(X), one nothing caught
%%   find(z, V)    a run that fails, and the goal its failure began at;
%%                 refuse(5), a clause that cuts and then fails
%%   parse(a)      a reader whose first clause gets furthest and whose
%%                 fallback fails last
%%   rec(30, R)     a recursion seen through a window of its last 100
%%                 inferences, and rec(12, R) drawn as a tree
%%   flip(F)       a run that is not the same twice -- and with a journal is
%%   grow(F)       a run that loads a file it then appends to, which leaves
%%                 its journal
%%   drive(5)      a run that raises after a step failed (1.11.4)
%%   build([solid])  a raise in the then of a condition that held after
%%                 three failed (1.11.7); checked_up(5), one in an else;
%%                 build_stop, build_throw and build_again, raises in a
%%                 catch's recovery; fallback_up(5), give_up_after(5) and
%%                 noted_up(1), raises no choice made
%%
%% and test/flowdebug/top.pl, a small top file whose chart does not draw
%% run.pl's clauses: top_build([solid]), top_stop([solid]) and
%% top_hooked([round, solid]).
%%
%% and two the case writes: a copy of run.pl charted once and kept, then
%% changed (cache(Dir)), and below(X), which reads a fact only a store
%% holds (embed(Dir)).
%%
%% How the picture LOOKS is judged by eye; that it reads back, carries the
%% run's marks and names every box by the chart's id, is checked.
%%
%%     cocolog -s test/flowdebug.pl      from the checkout root

:- use_module('test/prelude.pl').
:- use_module(library(stream)).
:- use_module(library(flow/debug)).
:- use_module(library(xml)).

main :-
    ( catch(use_module(library(stream)), _, fail) -> true ; skip('(no library/stream.so -- sh modules/stream/build.sh)') ),
    ( exists_file('library/flow/tables.pl') -> true ; skip('(no library/flow/tables.pl -- make modules)') ),
    scratch(D),
    placed(D),
    control(D),
    bindings(D),
    exceptions(D),
    failing(D),
    window(D),
    tree(D),
    diverged(D),
    journal(D),
    asked_when(D),
    asked_why(D),
    documents(D),
    command(D),
    kept(D),
    stored(D),
    compared(D),
    compared_own(D),
    profiled(D),
    viewed(D),
    timed(D),
    run_timed(D),
    furthest(D),
    raised(D),
    raised_choice(D),
    raised_caught(D),
    raised_place(D),
    raised_undrawn(D),
    many_heads,
    refusals(D),
    shl(['rm -rf ', D]),
    checks_done.

fx('test/flowdebug/run.pl').

%% the run of G, written to D/NAME.svg and D/NAME.xml
debugged(D, Name, G, Names, Opts, Run) :-
    fx(F),
    atomic_list_concat([D, '/', Name], B),
    flow_debug(G, B, [source(F), names(Names)|Opts], Run).

%% each call: Name/Arity-Box-Panel-Fate, in the order they were made
calls(run(_, _, _, _, Calls, _, _, _), Cs) :-
    findall(P-B-Pn-F, member(call(_, P, _, _, B, Pn, _, _, _, F), Calls), Cs).

%% the arguments the first call of P to exit exited with, as the window
%% wrote them (none when no call of P did)
exited(run(_, _, _, _, Calls, _, _, _), P, Out) :-
    (   member(call(_, P, _, _, _, _, _, _, Out0, exit), Calls) -> Out = Out0 ; Out = none ).

%% each binding: Port-Name-Value-Box, in the order they were made
binds(run(_, _, _, _, _, Xs, _, _), Bs) :-
    findall(P-N-V-B, member(x(_, P, _, N, V, B), Xs), Bs).

%% the untraced run's count: what call_metered/4 says the goal spends
metered(G, U) :-
    call_metered(G, 10000000, U, _).

%% ---- each call, the box it is ------------------------------------------

placed(D) :-
    section('each call of a run is the box it is in the chart, and enters the panel it calls'),
    debugged(D, top5, top(5, Y1), ['Y'=Y1], [], R1),
    calls(R1, C1),
    check('top(5, Y): the then, \\+ over a call that fails, findall/3 over member/2, each call its box',
          C1, [ top/2-'query.g1'-p1-exit, (>)/2-'p1.c1.g1.a1.if.g1'-none-exit,
                pos/2-'p1.c1.g1.a1.g1'-p2-exit, bad/1-'p1.c1.g2.g1'-p4-fail,
                findall/3-'p1.c1.g3'-none-exit, member/2-'p1.c1.g3.g1'-none-fail,
                member/2-none-none-fail, member/2-none-none-fail ]),
    R1 = run(How1, At1, Ats1, W1, Calls1, _, Div1, J1),
    metered(top(5, _), U1),
    check('...it answers where the untraced run does, recorded whole, as the probe ran, with no journal',
          How1-At1-Ats1-W1-Div1-J1, answer-U1-[U1]-window(1, U1)-false-none),
    findall(P-Cl, ( member(call(_, P, _, _, _, _, Cl, _, _, _), Calls1), memberchk(P, [top/2, bad/1, pos/2]) ), Cls1),
    %% bad(5) tries no head: bad/1's one clause is bad(b), which the index
    %% passes over -- a head never tried is not one that did not unify
    %% (1.11.2; it was nohead(1, 7))
    check('...the clause each entered, and none for bad(5): the index passes over bad(b)',
          Cls1, [top/2-[c(1, 1)], pos/2-[c(1, 5)], bad/1-[]]).

control(D) :-
    section('the else, a second branch, one predicate twice, a then and an else alike'),
    debugged(D, topm3, top(-3, Y2), ['Y'=Y2], [], R2),
    calls(R2, C2),
    check('top(-3, Y): the condition fails, the else is called, and neg/2''s second branch',
          C2, [ top/2-'query.g1'-p1-exit, (>)/2-'p1.c1.g1.a1.if.g1'-none-fail,
                neg/2-'p1.c1.g1.else.g1'-p3-exit, (=:=)/2-'p3.c1.g1.b1.g1'-none-fail,
                (is)/2-'p3.c1.g1.b2.g1'-none-exit, bad/1-'p1.c1.g2.g1'-p4-fail,
                findall/3-'p1.c1.g3'-none-exit, member/2-'p1.c1.g3.g1'-none-fail,
                member/2-none-none-fail, member/2-none-none-fail ]),
    debugged(D, twice, twice(A3, B3), ['A'=A3, 'B'=B3], [], R3),
    calls(R3, C3),
    check('twice(A, B): one predicate twice in a clause, each call its own box, one panel',
          C3, [ twice/2-'query.g1'-p1-exit, inc/2-'p1.c1.g1'-p2-exit, (is)/2-'p2.c1.g1'-none-exit,
                inc/2-'p1.c1.g2'-p2-exit, (is)/2-'p2.c1.g1'-none-exit ]),
    debugged(D, choose, choose(-1), [], [], R4),
    calls(R4, C4),
    check('choose(-1): after the condition fails the call is the else''s, though the then''s comes first',
          C4, [ choose/1-'query.g1'-p1-exit, (>)/2-'p1.c1.g1.a1.if.g1'-none-fail,
                inc/2-'p1.c1.g1.else.g1'-p2-exit, (is)/2-'p2.c1.g1'-none-exit,
                inc/2-'p1.c1.g2'-p2-exit, (is)/2-'p2.c1.g1'-none-exit ]).

%% ---- the values that crossed --------------------------------------------

bindings(D) :-
    section('the values that crossed into the variables the source names'),
    debugged(D, top5b, top(5, Y1), ['Y'=Y1], [], R1),
    binds(R1, B1),
    check('top(5, Y): X given to the test, Y bound by pos/2, Z = 1 undone at a Redo and Z = 2 as member/2 failed',
          B1, [ call-'X'-'5'-'p1.c1.g1.a1.if.g1', exit-'Y'-'5'-'p1.c1.g1.a1.g1',
                exit-'Z'-'1'-'p1.c1.g3.g1', redo-'Z'-'1'-'p1.c1.g3.g1',
                exit-'Z'-'2'-'p1.c1.g3.g1', fail-'Z'-'2'-'p1.c1.g3.g1',
                exit-'Y'-'5'-'query.g1' ]),
    debugged(D, topm3b, top(-3, Y2), ['Y'=Y2], [], R2),
    binds(R2, B2),
    findall(B, ( member(B, B2), B \= _-'Z'-_-_ ), B2a),
    check('top(-3, Y): X in each clause that reads it once, Y made by is/2, handed up by neg/2, answered',
          B2a, [ call-'X'-'-3'-'p1.c1.g1.a1.if.g1', call-'X'-'-3'-'p3.c1.g1.b1.g1',
                 exit-'Y'-'3'-'p3.c1.g1.b2.g1', exit-'Y'-'3'-'p1.c1.g1.else.g1',
                 exit-'Y'-'3'-'query.g1' ]),
    debugged(D, twiceb, twice(A3, B3), ['A'=A3, 'B'=B3], [], R3),
    binds(R3, B3s),
    check('twice(A, B): each activation of inc/2 its own X and Y, A shown once in twice/2''s clause',
          B3s, [ call-'X'-'1'-'p2.c1.g1', exit-'Y'-'2'-'p2.c1.g1', exit-'A'-'2'-'p1.c1.g1',
                 call-'X'-'2'-'p2.c1.g1', exit-'Y'-'3'-'p2.c1.g1', exit-'B'-'3'-'p1.c1.g2',
                 exit-'A'-'2'-'query.g1', exit-'B'-'3'-'query.g1' ]),
    debugged(D, pick, pick(X4), ['X'=X4], [], R4),
    binds(R4, B4),
    check('pick(X): X = 1 made, undone at the redo when 1 > 1 fails, X = 2 made, answered',
          B4, [ exit-'X'-'1'-'p1.c1.g1', redo-'X'-'1'-'p1.c1.g1', exit-'X'-'2'-'p1.c1.g1',
                exit-'X'-'2'-'query.g1' ]),
    R4 = run(_, _, _, _, Calls4, _, _, _),
    findall(F, member(call(_, _, _, _, 'p1.c1.g2', _, _, _, _, F), Calls4), F4),
    check('...the test called twice at its box: failed, then exited', F4, [fail, exit]).

%% ---- exceptions -----------------------------------------------------------

exceptions(D) :-
    section('an exception: the call that raised it, the calls it ended, the recovery'),
    debugged(D, safe, safe(E5), ['E'=E5], [], R5),
    calls(R5, C5),
    check('safe(E): is/2 raised, oops/1 was ended by it, noted/1 is the catch''s recovery',
          C5, [ safe/1-'query.g1'-p1-exit, oops/1-'p1.c1.g1.try.g1'-p2-unwound,
                (is)/2-'p2.c1.g1'-none-raised, noted/1-'p1.c1.g1.recover.g1'-p3-exit ]),
    binds(R5, B5),
    check('...and the ball, given to the recovery and answered',
          B5, [ call-'E'-'error(type_error(evaluable,foo/0),_)'-'p1.c1.g1.recover.g1',
                exit-'E'-'error(type_error(evaluable,foo/0),_)'-'query.g1' ]),
    debugged(D, oops, oops(X6), ['X'=X6], [], R6),
    R6 = run(How6, _, _, _, _, _, _, _),
    calls(R6, C6),
    (   How6 = exception(error(type_error(evaluable, foo/0), _)) -> H6 = exception ; H6 = How6 ),
    check('oops(X): nothing caught it -- the run ends with it, every call on the way ended',
          H6-C6, exception-[ oops/1-'query.g1'-p1-unwound, (is)/2-'p1.c1.g1'-none-raised ]).

%% ---- a run that fails -----------------------------------------------------

failing(D) :-
    section('a run that fails, and where its failure began'),
    debugged(D, findz, find(z, V7), ['V'=V7], [], R7),
    calls(R7, C7),
    check('find(z, V): member/2 finds no z-V and every call above it fails; pairs/1 had exited',
          C7, [ find/2-'query.g1'-p1-fail, lookup/2-'p1.c1.g1'-p2-fail, pairs/1-'p2.c1.g1'-p3-exit,
                member/2-'p2.c1.g2'-none-fail, member/2-none-none-fail, member/2-none-none-fail,
                member/2-none-none-fail ]),
    binds(R7, B7),
    check('...K given twice, once to each clause that reads it, and Ps made by pairs/1',
          B7, [ call-'K'-z-'p1.c1.g1', exit-'Ps'-'[a-1,b-2,c-3]'-'p2.c1.g1', call-'K'-z-'p2.c1.g2' ]),
    atom_concat(D, '/findz.xml', XF7),
    read_file_to_codes(XF7, XC7),
    xml_parse(XC7, element(flow, _, K7)),
    elements(K7, E7s), last(E7s, element(run, A7, _)),
    (   memberchk(ended=E7, A7) -> true ; E7 = none ),
    R7 = run(_, _, _, _, Calls7, _, _, _),
    (   memberchk(failed_from_call=FC7, A7), atom_number(FC7, N7),
        memberchk(call(N7, _, _, _, Box7, _, _, _, _, _), Calls7)
    ->  true
    ;   Box7 = none
    ),
    check('...the XML says it failed, and that its failure began at member/2''s box', E7-Box7, false-'p2.c1.g2'),
    debugged(D, refuse, refuse(5), [], [], R7b),
    calls(R7b, C7b),
    check('refuse(5): a clause that cuts and then fails -- the call fails, and so does its caller',
          C7b, [ refuse/1-'query.g1'-p1-fail, cut_none/1-'p1.c1.g1'-p2-fail,
                 (>)/2-'p2.c1.g1'-none-exit, fail/0-'p2.c1.g3'-none-fail ]).

%% ---- a window --------------------------------------------------------------

window(D) :-
    section('a window of the last 100 steps of a recursion'),
    debugged(D, nrevw, rec(30, R8), ['R'=R8], [window(100)], Run8),
    Run8 = run(How8, At8, _, window(F8, T8), Calls8, _, _, _),
    metered(rec(30, _), U8),
    F8x is U8 - 99,
    check('rec(30, R): it answers where the untraced run does, and the window is its last 100 steps',
          How8-At8-F8-T8, answer-U8-F8x-U8),
    findall(B, ( member(call(_, _, _, _, B, _, _, _, _, _), Calls8), B \== none ), Bs0),
    sort(Bs0, Bs8),
    findall(Pn, ( member(call(_, _, _, _, _, Pn, _, _, _, _), Calls8), Pn \== none ), Ps0),
    sort(Ps0, Ps8),
    check('...every call in it is app/3''s, and the only box reached is its recursive call',
          Bs8-Ps8, ['p3.c2.g1']-[p3]),
    Calls8 = [call(_, P8, _, Pa8, Bx8, Pn8, _, _, _, _)|_],
    check('...its first call, whose caller began before it, has a panel and no box',
          P8-Pa8-Bx8-Pn8, app/3-0-none-p3),
    atom_concat(D, '/nrevw.svg', SF8),
    read_file_to_codes(SF8, SC8),
    xml_parse(SC8, S8),
    findall(Id-O, ( svg_g(S8, As), memberchk(id=Id, As), memberchk(Id, [p1, p2, p3]),
                    ( memberchk(opacity=O, As) -> true ; O = '1' ) ),
            Op8),
    msort(Op8, Op8s),
    check('...the panels no call entered in it are drawn faded', Op8s, [p1-'0.4', p2-'0.4', p3-'1']),
    findall(K, ( svg_g(S8, As2), memberchk(id=Id, As2), atom_concat(d, KA, Id), atom_number(KA, K) ), Ks0),
    msort(Ks0, Ks8),
    Ks8 = [K0|_],
    last(Ks8, KL),
    Hidden is K0 - 1,
    format(atom(Pill), '+~d', [Hidden]),
    (   svg_text(S8, Pill) -> Pl8 = pill ; Pl8 = none ),
    numlist(K0, KL, Seq8),
    check('...a box with more bindings than two rows hold shows the last of them, after a +N for the rest',
          KL-Pl8-Ks8, 24-pill-Seq8).

%% ---- the tree ---------------------------------------------------------------

tree(D) :-
    section('view(tree): the calls themselves, a recursion''s middle left out'),
    debugged(D, nrevt, rec(12, R9), ['R'=R9], [view(tree)], _),
    atom_concat(D, '/nrevt.svg', SF9),
    read_file_to_codes(SF9, SC9),
    xml_parse(SC9, S9),
    findall(T, ( svg_text(S9, T), sub_atom(T, _, _, _, 'more levels of') ), Ts9),
    check('nrev/2 thirteen deep, and app/3 twelve, eleven and ten: each seen by its first and last three',
          Ts9, [ '⋯  7 more levels of nrev/2, and every call they made, left out',
                 '⋯  4 more levels of app/3, and every call they made, left out',
                 '⋯  5 more levels of app/3, and every call they made, left out',
                 '⋯  6 more levels of app/3, and every call they made, left out' ]).

%% ---- a replay that is not the run ---------------------------------------

diverged(D) :-
    section('a replay that does not end where the probe did is said to have diverged'),
    atom_concat(D, '/flip.bytes', BF),
    debugged(D, flip, flip(BF), [], [], R10),
    R10 = run(How10, _, _, _, _, _, Div10, _),
    (   Div10 = diverged(end(PH, _, _), end(RH, _, _)) -> W10 = PH-RH ; W10 = Div10 ),
    read_file_to_codes(BF, BC),
    atom_codes(BA, BC),
    check('flip(F): the probe answers on one byte, the replay fails on two, and both are said',
          How10-W10-BA, false-(answer-false)-xx),
    atom_concat(D, '/flip.svg', SF10),
    read_file_to_codes(SF10, SC10),
    xml_parse(SC10, S10),
    (   svg_text(S10, T10), sub_atom(T10, 0, _, _, 'THE REPLAY DIVERGED') -> Said10 = said ; Said10 = silent ),
    atom_concat(D, '/flip.xml', XF10),
    read_file_to_codes(XF10, XC10),
    xml_parse(XC10, element(flow, _, K10)),
    elements(K10, E10s), last(E10s, element(run, A10, _)),
    (   memberchk(diverged=DA10, A10) -> true ; DA10 = none ),
    (   memberchk(probe_ended=PE10, A10) -> true ; PE10 = none ),
    check('...on the picture and in the XML', Said10-DA10-PE10, said-true-answer),
    %% the command's line and BASE.txt say both ends: the window is the
    %% probe's, and a replay that ended elsewhere is no window of it (1.11.4,
    %% from cicili-lang's report)
    Div10 = diverged(end(_, PU10, _), end(_, RU10, _)),
    format(atom(Ends10), 'diverged yes (the probe: answer at step ~w; the replay: false at step ~w)', [PU10, RU10]),
    atom_concat(D, '/flipc.bytes', BF11),
    atom_concat(D, '/flipc', B11),
    fx(F11),
    atomic_list_concat(['-s tools/flow/debug.pl -- "flip(\'', BF11, '\')" ', F11, ' ', B11, ' txt=true'], A11),
    cocolog_run(A11, T11, E11),
    atomic_list_concat(Ls11, '\n', T11),
    last(Ls11, L11c), no_cpu(L11c, L11),
    ( sub_atom(L11, _, _, 0, Ends10) -> Y11 = said ; Y11 = L11 ),
    atom_concat(B11, '.txt', TF12),
    read_file_to_codes(TF12, TC12), atom_codes(TA12, TC12),
    atomic_list_concat([H12|_], '\n', TA12),
    atom_concat(Ends10, '; ', Ends12),
    ( sub_atom(H12, _, _, _, Ends12) -> Y12 = said ; Y12 = H12 ),
    check('...and the command''s line and BASE.txt''s first say both ends, the probe''s and the replay''s',
          E11-Y11-Y12, 0-said-said).

%% ---- the journal ---------------------------------------------------------
%%
%% flip/1's probe and replay with journal(true): the probe journals each
%% portal call its library calls make -- open/3's '$stream_open'/4, write/2's
%% format/3, close/1's, read_file_to_codes/2 -- and the replay is answered
%% from them, so it reads the one byte the probe wrote and answers too, and
%% the file holds that one byte. grow/1 loads a file, which no journal
%% answers, and appends to it: its replay takes the other way and leaves
%% the journal where the probe appended.

journal(D) :-
    section('journal(true): the replay answered from the probe''s journal, and where it left it'),
    atom_concat(D, '/flipj.bytes', BF),
    atom_concat(D, '/flip.jrnl', JF),
    debugged(D, flipj, flip(BF), [], [journal(true), journal_file(JF)], R1),
    R1 = run(How1, At1, _, _, _, _, Div1, J1),
    read_file_to_codes(BF, BC1), atom_codes(BA1, BC1),
    check('flip(F): the replay reads the byte the probe wrote, answers where it did, and writes none',
          How1-Div1-BA1, answer-false-x),
    (   J1 = journal(Es1) -> findall(M-P, member(j(_, M, P, _, _), Es1), MP1) ; MP1 = J1 ),
    check('...the journal: the stream opened, asked about twice, written to and closed, and the file read',
          MP1, [stream-'$stream_open'/4, stream-'$stream_open_p'/1, builtins-format/3,
                stream-'$stream_open_p'/1, stream-'$stream_close'/2, files-read_file_to_codes/2]),
    flow_dbg_read_terms(JF, JT2),
    findall(I2, member(j(I2, _, _, _, _), JT2), Is2),
    ( J1 = journal(Es2) -> findall(I2, member(j(I2, _, _, _, _), Es2), Is2r) ; Is2r = none ),
    ( last(Is2, L2), L2 < At1 -> Before2 = before ; Before2 = Is2 ),
    check('...kept in journal_file(F), an entry a line, each the run hands back, all before its answer',
          Is2-Before2, Is2r-before),
    atom_concat(D, '/flipj.svg', SF3),
    read_file_to_codes(SF3, SC3),
    xml_parse(SC3, S3),
    findall(Id-M3, ( member(Id, ['p1.c1.g1', 'p1.c1.g2', 'p1.c1.g3', 'p1.c1.g4', 'p1.c1.g5']),
                     ( svg_g_el(S3, Id, G3), svg_text(G3, M3), sub_atom(M3, 0, _, _, '⇄') -> true ; M3 = none ) ),
            Marks3),
    check('...each goal whose call reached the world carries the journal''s mark, with how many times',
          Marks3, ['p1.c1.g1'-'⇄', 'p1.c1.g2'-'⇄ ×2', 'p1.c1.g3'-'⇄ ×2', 'p1.c1.g4'-'⇄', 'p1.c1.g5'-none]),
    atom_concat(D, '/flipj.xml', XF4),
    read_file_to_codes(XF4, XC4),
    xml_parse(XC4, X4),
    x_el(X4, run, RA4),
    findall(K=V, ( member(K, [journal, portals, answered]), memberchk(K=V, RA4) ), JA4),
    findall(N, ( x_el(X4, call, CA4), memberchk(journal=true, CA4), memberchk(n=N, CA4) ), JC4),
    findall(A-O, ( x_el(X4, portal, PA4), memberchk(at=A, PA4), memberchk(outcome=O, PA4) ), PO4),
    findall(A, member(A-_, PO4), PAt4),
    check('...in the XML: the <run> says so, each <portal> is the <call> the window saw at its step',
          JA4-JC4, [journal=true, portals='6', answered='6']-PAt4),
    atom_concat(D, '/grow.pl', GF),
    fixture(GF, []),
    debugged(D, growj, grow(GF), [], [journal(true)], R5),
    R5 = run(How5, _, _, _, _, _, Div5, _),
    (   How5 = diverged(At5, portal(WI5, WM5, WP5, _), portal(GI5, GM5, GP5, GC5))
    ->  W5 = At5-WI5-WM5-WP5-GI5-GM5-GP5-GC5
    ;   W5 = How5
    ),
    check('grow(F): the replay''s load reads what the probe appended, and it leaves the journal where the append was due',
          W5, 7-7-files-append_file_from_codes/2-9-builtins-getenv/2-'getenv(''HOME'',_0)'),
    ( Div5 = diverged(end(answer, _, _), end(diverged(_, _, _), _, _)) -> D5 = said ; D5 = Div5 ),
    atom_concat(D, '/growj.svg', SF6),
    read_file_to_codes(SF6, SC6),
    xml_parse(SC6, S6),
    (   svg_text(S6, T6), sub_atom(T6, 0, _, _, 'THE REPLAY LEFT ITS JOURNAL at step 7') -> Said6 = said ; Said6 = silent ),
    atom_concat(D, '/growj.xml', XF6),
    read_file_to_codes(XF6, XC6),
    xml_parse(XC6, X6),
    (   x_el(X6, divergence, DA6), memberchk(at='7', DA6), x_el(X6, want, WA6), memberchk(pred=WP6, WA6),
        x_el(X6, got, GA6), memberchk(pred=GP6, GA6)
    ->  Div6 = WP6-GP6
    ;   Div6 = none
    ),
    check('...said on the picture, and in the XML as a <divergence> with the journal''s call and the replay''s',
          D5-Said6-Div6, said-said-('append_file_from_codes/2'-'getenv/2')),
    (   x_el(X6, journal, JA7), memberchk(count=C7, JA7), memberchk(answered=A7, JA7) -> N7 = C7-A7 ; N7 = none ),
    findall(P7, ( x_el(X6, portal, PA7), memberchk(answered=P7, PA7) ), Ps7),
    check('...and its two entries -- the append and the getenv/2 after it -- neither answered the replay',
          N7-Ps7, ('2'-'0')-[false, false]).

%% ---- questions over the clock (D4) ---------------------------------------
%%
%% flow_when/4 is checked against the window itself: the inference it
%% names is recorded on its own, and the call made there must be the goal
%% that made Cond true -- so no count is taken on trust.

%% the call a window of the one inference I saw
call_at(D, Name, G, I, P-In) :-
    debugged(D, Name, G, [], [from(I), to(I)], R),
    R = run(_, _, _, _, Calls, _, _, _),
    (   member(call(I, P, _, _, _, _, _, In0, _, _), Calls) -> maplist(flow_dbg_ung, In0, In)
    ;   P = none, In = none
    ).

asked_when(D) :-
    section('flow_when/4: the first step at which a question holds, searched over runs'),
    fx(F),
    flow_when(fill(L1), (nth1(3, L1, X1), X1 == 3), [source(F)], W1),
    ( W1 = at(I1) -> call_at(D, at1, fill(_), I1, C1) ; C1 = W1 ),
    check('fill(L): the third element is 3 from the call that bound it, X = I with I 3',
          C1, (=)/2-['_', '3']),
    flow_when(fill(L2), (nth1(3, L2, X2), X2 == 3), [source(F), journal(false)], W2),
    flow_when(fill(L3), (nth1(3, L3, X3), X3 == 3), [source(F), step(5)], W3),
    check('...the same without a journal, and stepping five steps at a time first', W2-W3, W1-W1),
    flow_when(fill(L4), (nth1(3, L4, X4), X4 == 4), [source(F)], W4),
    check('a question that does not hold where the run ends: never', W4, never),
    flow_when(pick(P5), P5 == 1, [source(F)], W5),
    flow_when(pick(P6), P6 == 1, [source(F), step(1)], W6),
    ( W6 = at(I6) -> call_at(D, at6, pick(_), I6, C6) ; C6 = W6 ),
    check('pick(X): X = 1 is undone by backtracking, so not where the run ends -- never; asked at every step, member/2''s call made it so',
          W5-C6, never-(member/2-['_', '[1,2,3]'])),
    atom_concat(D, '/whenw', B7),
    flow_when(fill(L7), (nth1(5, L7, X7), X7 == 5), [source(F), base(B7), window(10)], W7),
    atom_concat(B7, '.xml', XF7),
    read_file_to_codes(XF7, XC7),
    xml_parse(XC7, X7x),
    x_el(X7x, run, RA7),
    ( W7 = at(I7), memberchk(to=T7, RA7), atom_number(T7, I7), memberchk(from=Fr7, RA7) -> Win7 = Fr7 ; Win7 = W7-RA7 ),
    I7f is I7 - 9, atom_number(Fr7x, I7f),
    check('base(B): the window that ends where it began to hold, drawn', Win7, Fr7x),
    catch(( flow_when(fill(_), nosuch(x), [source(F)], _), E8 = none ), error(E8, _), true),
    ( E8 = flow_when_cond(nosuch(x), error(existence_error(procedure, P8), _)) -> R8 = P8 ; R8 = E8 ),
    check('a question that raises is an error naming it and its ball', R8, nosuch/1),
    answer(flow_when(fill(_), true, [], _), x, G9),
    answer(flow_when(fill(_), true, [source(F), step(0)], _), x, G10),
    check('no source, a step of nothing: refused by name', [G9, G10],
          [ error(error(existence_error(flow_option, source), flow_when/4)),
            error(error(domain_error(flow_when_option, step(0)), flow_when/4)) ]).

asked_why(D) :-
    section('flow_why/2: why a run failed, read back from the window -- and drawn, and in the XML'),
    debugged(D, whyz, find(z, V1), ['V'=V1], [], R1),
    flow_why(R1, W1),
    why_shape(W1, S1),
    check('find(z, V): its clause entered, lookup/2 failed in it -- its clause entered, pairs/1 exited and member/2 failed, a library''s',
          S1, [why(find/2, [entered(1, [why(lookup/2, [entered(1, [exited(pairs/1), failed(member/2)])])])])]),
    atom_concat(D, '/whyz.svg', SF2),
    read_file_to_codes(SF2, SC2),
    xml_parse(SC2, S2),
    findall(T, ( svg_text(S2, T), ( T == 'why it failed' ; sub_atom(T, _, _, _, 'failed, with no clause') ) ), Ts2),
    check('...under the chart: the block, down to member/2 failing with nothing of the program''s to say why',
          Ts2, ['why it failed', '✗ member(z-_, [a-1,b-2,c-3])   failed, with no clause of the program''s to say why  ·  call at 4']),
    atom_concat(D, '/whyz.xml', XF3),
    read_file_to_codes(XF3, XC3),
    xml_parse(XC3, X3),
    findall(N-P, ( x_el(X3, failed, A3), memberchk(call=N, A3), memberchk(pred=P, A3) ), F3),
    check('...and in the XML''s <why>, each <failed> its call and predicate', F3,
          ['1'-'find/2', '2'-'lookup/2', '4'-'member/2']),
    debugged(D, whyc, classify(3, C5), ['C'=C5], [], R5),
    flow_why(R5, W5),
    why_shape(W5, S5),
    check('classify(3, C): both clauses entered, and each failed at its own test',
          S5, [why(classify/2, [entered(1, [failed((>)/2)]), entered(2, [failed((>)/2)])])]),
    %% a Redo after an Exit asks for another answer; one after a failed
    %% clause is a retry -- the XML says which (exited=)
    findall(P-E, ( member(Nm, [pick, whyc]),
                   atomic_list_concat([D, '/', Nm, '.xml'], XFr),
                   read_file_to_codes(XFr, XCr), xml_parse(XCr, Xr),
                   x_el(Xr, event, Ar), memberchk(port=redo, Ar), memberchk(call=Cr, Ar),
                   x_el(Xr, call, Cs), memberchk(n=Cr, Cs), memberchk(pred=P, Cs),
                   ( memberchk(exited=E, Ar) -> true ; E = none ) ),
            R5r),
    check('...a redo says whether its call had exited: member/2 in pick(X) had, classify/2 had not',
          R5r, ['member/2'-true, 'classify/2'-false]),
    debugged(D, whyok, top(5, Y4), ['Y'=Y4], [], R4),
    flow_why(R4, W4),
    atom_concat(D, '/whyok.xml', XF4),
    read_file_to_codes(XF4, XC4),
    xml_parse(XC4, X4),
    ( x_el(X4, why, _) -> Y4w = said ; Y4w = none ),
    ( W4 = [exited(1, top/2, _, _)] -> W4s = exited ; W4s = W4 ),
    check('a run that answered: its top call exited, and no <why>', W4s-Y4w, exited-none),
    asked_why_own(D).

%% a program of two files debugged from its top: the chart has a panel for
%% the top's predicates alone, so the why stopped at the first call into the
%% other file -- own(all) and own(Files) explain those too, and
%% flow_why_call/3 any one call (1.11.4, from cicili-lang's report)
asked_why_own(D) :-
    atomic_list_concat([D, '/lib9.pl'], LF),
    atomic_list_concat([D, '/top9.pl'], TF),
    fixture(LF, ['l9_go(X) :- l9_step(X, Y), Y > 10.', 'l9_step(X, Y) :- Y is X * 2.']),
    format(atom(UL), ':- use_module(~q).', [LF]),
    fixture(TF, [UL, 't9 :- l9_go(3).']),
    atomic_list_concat([D, '/own9'], B9),
    flow_debug(t9, B9, [source(TF), txt(true)], R9),
    flow_why(R9, W9a), why_shape(W9a, S9a),
    flow_why(R9, W9b, [own(all)]), why_shape(W9b, S9b),
    flow_why(R9, W9c, [own([LF])]), why_shape(W9c, S9c),
    check('two files: the chart''s panels stop the why at l9_go/1; own(all) and own(Files) go on into it',
          S9a-S9b-S9c,
          [why(t9/0, [entered(1, [failed(l9_go/1)])])]
          -[why(t9/0, [entered(1, [why(l9_go/1, [entered(1, [exited(l9_step/2), failed((>)/2)])])])])]
          -[why(t9/0, [entered(1, [why(l9_go/1, [entered(1, [exited(l9_step/2), failed((>)/2)])])])])]),
    R9 = run(_, _, _, _, Calls9, _, _, _),
    once(member(call(S9, l9_go/1, _, _, _, _, _, _, _, _), Calls9)),
    flow_why_call(R9, S9, W9d), why_shape(W9d, S9d),
    ( flow_why_call(R9, 999, _) -> Y9e = found ; Y9e = none ),
    check('flow_why_call/3: one call''s why, its own clauses explained, and none for an step the window did not see',
          S9d-Y9e, why(l9_go/1, [entered(1, [exited(l9_step/2), failed((>)/2)])])-none),
    atomic_list_concat([D, '/own9b'], B9b),
    flow_debug(t9, B9b, [source(TF), txt(true), own(all)], _),
    atom_concat(B9, '.txt', T9a), atom_concat(B9b, '.txt', T9b),
    read_file_to_codes(T9a, C9a), atom_codes(A9a, C9a),
    read_file_to_codes(T9b, C9b), atom_codes(A9b, C9b),
    atomic_list_concat(L9a, '\n', A9a), atomic_list_concat(L9b, '\n', A9b),
    findall(L, ( member(L, L9a), sub_atom(L, 0, _, _, '%  ') ), F9a),
    findall(L, ( member(L, L9b), sub_atom(L, 0, _, _, '%  ') ), F9b),
    check('own(all) to flow_debug/4: BASE.txt''s furthest path goes into the other file''s calls',
          F9a-F9b,
          ['%  t9: clause 1, the furthest of 1 tried: 0 of its calls exited (call 1)',
           '%    l9_go(3): failed, nothing of the program''s to say why (call 2)']
          -['%  t9: clause 1, the furthest of 1 tried: 0 of its calls exited (call 1)',
            '%    l9_go(3): clause 1, the furthest of 1 tried: 1 of its calls exited (call 2)',
            '%      >(6,10): failed, nothing of the program''s to say why (call 5)']).

%% a why tree without its arguments
why_shape(L, S) :- is_list(L), !, findall(X, ( member(W, L), why_shape(W, X) ), S).
why_shape(why(_, P, _, Ts), why(P, Ss)) :- !, findall(X, ( member(T, Ts), why_shape(T, X) ), Ss).
why_shape(entered(K, Gs), entered(K, Ss)) :- !, why_shape(Gs, Ss).
why_shape(nohead(K), nohead(K)) :- !.
why_shape(exited(_, P, _, _), exited(P)) :- !.
why_shape(failed(_, P, _), failed(P)) :- !.
why_shape(ended(_, P, _, F), ended(P, F)).

%% ---- the two documents ----------------------------------------------------

documents(D) :-
    section('the picture and the XML read back, and name the same things'),
    debugged(D, docs, top(5, Y11), ['Y'=Y11], [], R11),
    atom_concat(D, '/docs.svg', SF),
    atom_concat(D, '/docs.xml', XF),
    read_file_to_codes(SF, SC),
    read_file_to_codes(XF, XC),
    answer(( xml_parse(SC, element(R1, _, _)), xml_parse(XC, element(R2, _, K2)), elements(K2, E2s), last(E2s, element(R3, _, _)) ),
           R1-R2-R3, G1),
    check('both read back through library(xml); the run is the flow''s last element', G1, svg-flow-run),
    xml_parse(SC, S),
    xml_parse(XC, X),
    findall(B, ( x_el(X, call, As), memberchk(box=B, As) ), CB),
    findall(B, ( member(B, CB), \+ ( svg_g(S, GA), memberchk(id=B, GA) ) ), NoBox),
    findall(B, ( member(B, CB), B \== 'p1.c1.g3', \+ ( x_el(X, goal, XA), memberchk(id=B, XA) ) ), NoGoal),
    check('every box a call names is a box of the picture and a goal of the chart''s XML (findall/3 a construct)',
          NoBox-NoGoal, ['p1.c1.g3']-[]),
    findall(K, ( svg_g(S, DA), memberchk(id=DId, DA), atom_concat(d, KA, DId), atom_number(KA, K) ), DK0),
    msort(DK0, DK),
    findall(K, ( x_el(X, binding, BA), memberchk(disc=KA, BA), atom_number(KA, K) ), XK0),
    msort(XK0, XK),
    check('each disc of the picture is a binding of the XML, by its number', DK-XK, [1,2,3,4,5,6,7]-[1,2,3,4,5,6,7]),
    svg_box(S, 'p1.c1.g2.g1', BadA),
    svg_box(S, 'p1.c1.g1.a1.g1', PosA),
    svg_box(S, 'query.g1', QA),
    check('bad(Y)''s box is red where its call failed, pos(X, Y) and the query heavy where theirs exited',
          [BadA, PosA, QA], ['#d62828'-'2.6', '#1f2933'-'2.6', '#1f2933'-'2.6']),
    findall(Id-O, ( svg_g(S, GAs), memberchk(id=Id, GAs), memberchk(Id, ['p1.c1.g1.else.g1', p3]),
                    memberchk(opacity=O, GAs) ),
            Faded0),
    msort(Faded0, Faded),
    check('the else the run never took is faded, and so is the panel only it calls',
          Faded, ['p1.c1.g1.else.g1'-'0.3', p3-'0.4']),
    R11 = run(_, _, _, _, _, Xs11, _, _),
    length(Xs11, N11),
    x_el(X, run, RA),
    memberchk(calls=NC, RA),
    findall(c, x_el(X, call, _), Cs),
    length(Cs, NCs),
    findall(b, x_el(X, binding, _), Bs),
    length(Bs, NBs),
    atom_number(NC, NCn),
    check('the XML holds every call and every binding of the run', NCn-NCs-NBs, 8-8-N11).

%% the <g> elements of a document, at any depth, by their attributes
svg_g(element(g, As, _), As).
svg_g(element(_, _, Ks), As) :- member(K, Ks), K = element(_, _, _), svg_g(K, As).

%% the text of every <text>, its spans joined
svg_text(element(text, _, Ks), T) :- !,
    findall(A, ( member(element(tspan, _, [A0]), Ks), ( A0 = str(Cs) -> atom_codes(A, Cs) ; A = A0 ) ), As),
    atomic_list_concat(As, T).
svg_text(element(_, _, Ks), T) :- member(K, Ks), K = element(_, _, _), svg_text(K, T).

%% the stroke and its width of a box's shape, by its id
svg_box(S, Id, Stroke-W) :-
    svg_g_el(S, Id, element(g, _, Ks)),
    member(element(Shape, SA, _), Ks), memberchk(Shape, [rect, polygon]), !,
    memberchk(stroke=Stroke, SA),
    memberchk('stroke-width'=W, SA).

svg_g_el(E, Id, E) :- E = element(g, As, _), memberchk(id=Id, As), !.
svg_g_el(element(_, _, Ks), Id, G) :- member(K, Ks), K = element(_, _, _), svg_g_el(K, Id, G), !.

%% the elements of a name in an XML document, at any depth
x_el(element(N, As, _), N, As).
x_el(element(_, _, Ks), N, As) :- member(K, Ks), K = element(_, _, _), x_el(K, N, As).

%% an element by its name, whole, anywhere in X
x_sub(X, N, X) :- X = element(N, _, _).
x_sub(element(_, _, Ks), N, E) :- member(K, Ks), K = element(_, _, _), x_sub(K, N, E).

%% ---- the command ------------------------------------------------------------

command(D) :-
    section('tools/flow/debug.pl: one command, two files, an exit status'),
    atomic_list_concat([D, '/cmd'], B),
    fx(F),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'find(z, V)\' ', F, ' ', B], A1),
    cocolog_run(A1, T1, E1),
    atom_concat(B, '.xml', XF),
    yes_no(exists_file(XF), Y1),
    atomic_list_concat(Ls1, '\n', T1),
    ( last(Ls1, L1c) -> no_cpu(L1c, L1) ; L1c = '', L1 = '' ),
    check('it writes BASE.svg and BASE.xml, says how the run ended, and exits 0',
          E1-Y1-L1, 0-yes-'find(z, V): false at step 7; recorded 1 to 7; diverged no'),
    %% and the CPU (1.13.7): the probe's, and the replay's before its window
    %% opened -- seconds, which no two runs share
    (   atomic_list_concat([_, C1], '; CPU: the probe ', L1c),
        atomic_list_concat([P1, B1], ' s, the replay ', C1),
        atom_concat(B1a, ' s before the window opened', B1),
        atom_number(P1, _), atom_number(B1a, _)
    ->  Cpu1 = said
    ;   Cpu1 = L1c
    ),
    check('...and the CPU the probe took, and the replay before its window opened', Cpu1, said),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'nosuch(X)\' ', F, ' ', B, ' 2>/dev/null'], A2),
    cocolog_run(A2, _, E2),
    check('a predicate the program does not have is exit 1', E2, 1),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'find(z, V)\' ', F, ' ', B, ' view=sideways 2>/dev/null'], A3),
    cocolog_run(A3, _, E3),
    check('an option it does not know is exit 2', E3, 2),
    atomic_list_concat([D, '/cmd.bytes'], BF4),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'flip(\'\\\'\'', BF4, '\'\\\'\')\' ', F, ' ', B, ' journal=true'], A4),
    cocolog_run(A4, T4, E4),
    atomic_list_concat(Ls4, '\n', T4),
    ( last(Ls4, L4c), no_cpu(L4c, L4), atomic_list_concat([_, Tail4], '; diverged no', L4) -> true ; Tail4 = T4 ),
    check('journal=true: the line says how many portal calls the journal held, and how many answered the replay',
          E4-Tail4, 0-'; journal 6 portal calls, 6 answered'),
    atomic_list_concat([D, '/cmdw'], B5),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'fill(L)\' ', F, ' ', B5, ' \'when=nth1(3, L, X), X == 3\' window=4'], A5),
    cocolog_run(A5, T5, E5),
    atomic_list_concat(Ls5, '\n', T5),
    ( last(Ls5, L5) -> true ; L5 = '' ),
    atom_concat(B5, '.svg', SF5),
    yes_no(exists_file(SF5), Y5),
    check('when=COND: where the question first holds, and the window of the last 4 steps up to it drawn',
          E5-Y5-L5, 0-yes-'fill(L): (nth1(3, L, X), X == 3) first holds at step 10; recorded 7 to 10'),
    %% (26, and 23 to 26, through 1.12.1, when fill/1's length(L, 5) was
    %% seventeen steps of clauses)
    %% depth= and only= bound the picture as chart.pl's do: the panels left
    %% out are stubs saying why, and the XML keeps every panel
    findall(O-E6-St6-NX6,
            ( member(O-Why, [ 'only=lookup/2'-'not drawn: not one of only(...)',
                              'depth=1'-'not drawn: deeper than depth(1)' ]),
              atomic_list_concat([D, '/cmdo'], B6),
              atomic_list_concat(['-s tools/flow/debug.pl -- \'find(z, V)\' ', F, ' ', B6, ' ', O], A6),
              cocolog_run(A6, _, E6),
              atom_concat(B6, '.svg', SF6), read_file_to_codes(SF6, SC6), atom_codes(SA6, SC6),
              atomic_list_concat(Ps6, Why, SA6), length(Ps6, NP6), St6 is NP6 - 1,
              atom_concat(B6, '.xml', XF6), read_file_to_codes(XF6, XC6), xml_parse(XC6, X6),
              findall(x, x_el(X6, panel, _), Pn6), length(Pn6, NX6) ),
            R6),
    check('depth= and only=: find/2 and pairs/1 stubs under only=lookup/2, lookup/2 one under depth=1, the XML''s four panels both times',
          R6, ['only=lookup/2'-0-2-4, 'depth=1'-0-1-4]),
    %% txt=true: BASE.txt, the run one line a call (a variable's _G name is
    %% a heap position, so it is read as _)
    atomic_list_concat([D, '/cmdt'], B7),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'find(z, V)\' ', F, ' ', B7, ' txt=true'], A7),
    cocolog_run(A7, T7, E7),
    atomic_list_concat(Ls7, '\n', T7),
    atom_concat(B7, '.txt', TF7),
    ( memberchk(TF7, Ls7) -> N7 = named ; N7 = unnamed ),
    read_file_to_codes(TF7, TC7),
    un_g(TC7, TU7),
    atom_codes(TA7, TU7),
    atomic_list_concat(TL7, '\n', TA7),
    check('txt=true: BASE.txt named, the run one line a call -- step, depth, goal, fate, clauses, box, where',
          E7-N7-TL7,
          0-named-[ '% find(z, V): false at step 7; recorded 1 to 7; diverged no; 7 calls',
                    '% file: test/flowdebug/run.pl',
                    '1 find(z,_) fail [c1] query.g1',
                    '2   lookup(z,_) fail [c1] p1.c1.g1 :35:15',
                    '3     pairs(_) exit pairs([a-1,b-2,c-3]) [c1] p2.c1.g1 :37:17',
                    '4     member(z-_,[a-1,b-2,c-3]) fail [h1 c2] p2.c1.g2 :37:28',
                    '5       member(z-_,[b-2,c-3]) fail [h1 c2] -',
                    '6         member(z-_,[c-3]) fail [h1 c2] -',
                    '7           member(z-_,[]) fail [h1 h2] -',
                    '% where it got furthest:',
                    '%  find(z,_): clause 1, the furthest of 1 tried: 0 of its calls exited (call 1)',
                    '%    lookup(z,_): clause 1, the furthest of 1 tried: 1 of its calls exited (call 2)',
                    '%      member(z-_,[a-1,b-2,c-3]): failed, nothing of the program''s to say why (call 4)',
                    '' ]),
    %% the file is named once when every place is in it (1.11.0: the
    %% translator's path was 93 of a line's 213 bytes); places in several
    %% files keep their FILE:LINE:COL, and a colon in a file's name stays
    list_to_assoc(['p1.c1.g1'-'/a/x.pl:3:5', 'p2.c1.g1'-'/b/y.pl:4:1', 'p3.c1.g1'-'/c:d/z.pl:7:2'], Ps8),
    findall(F8, ( member(Bs8, [['p1.c1.g1'], ['p1.c1.g1', 'p2.c1.g1'], ['p3.c1.g1'], [none]]),
                  findall(call(1, f/0, 0, x, B8, x, [], [], none, exit), member(B8, Bs8), Cs8),
                  flow_dbg_text_file(Cs8, Ps8, F8) ),
            Fs8),
    check('the file a window''s places are in: one is named, several or none are not, its own colons kept',
          Fs8, ['/a/x.pl', none, '/c:d/z.pl', none]).

%% _G followed by digits read as _
un_g([], []).
un_g([0'_, 0'G, C|Cs], [0'_|Out]) :- C >= 0'0, C =< 0'9, !,
    un_g_digits(Cs, Rest), un_g(Rest, Out).
un_g([C|Cs], [C|Out]) :- un_g(Cs, Out).

un_g_digits([C|Cs], Rest) :- C >= 0'0, C =< 0'9, !, un_g_digits(Cs, Rest).
un_g_digits(Cs, Cs).

%% ---- the chart, kept --------------------------------------------------------

kept(D) :-
    section('cache(Dir): the chart built once, read back, and built again when the program changes'),
    (   catch(use_module(library(sha)), _, fail)
    ->  kept_(D)
    ;   format("     (skipped: no library/sha.so -- sh modules/sha/build.sh)~n")
    ).

kept_(D) :-
    fx(F),
    atomic_list_concat([D, '/kept.pl'], P),
    shl(['cp ', F, ' ', P]),
    atomic_list_concat([D, '/charts'], C),
    atomic_list_concat([D, '/kept0'], B0),
    atomic_list_concat([D, '/kept1'], B1),
    flow_debug(find(z, V1), B0, [source(P), names(['V'=V1])], _),
    flow_debug(find(z, V2), B1, [source(P), names(['V'=V2]), cache(C)], _),
    kept_doc(B0, element(flow, A0, K0)),
    kept_doc(B1, element(flow, A1, K1)),
    elements(K0, E0), append(EC0, [Run0], E0),
    elements(K1, E1),
    (   A1 = [chart=XF|A0], exists_file(XF), kept_doc_file(XF, element(flow, AF, KF))
    ->  elements(KF, EF),
        yes_no(( E1 == [Run0], AF == A0, EF == EC0 ), Y1)
    ;   Y1 = no, XF = none
    ),
    kept_same(B0, B1, '.svg', S1),
    check('the run''s XML is its <run> alone under a root that names the chart''s, and the two are the uncached XML; the picture is the same',
          Y1-S1, yes-same),
    atom_concat(XC0, '.xml', XF), atom_concat(XC0, '.chart', CF),
    shl(['echo "% kept" >> ', CF]),
    atomic_list_concat([D, '/kept2'], B2),
    flow_debug(find(z, V3), B2, [source(P), names(['V'=V3]), cache(C)], R3),
    kept_last(CF, L3),
    kept_same(B0, B2, '.svg', S3),
    kept_same(B1, B2, '.xml', X3),
    R3 = run(How3, _, _, _, _, _, _, _),
    check('a second run reads the chart back -- the line added to it is still there -- and draws the same',
          L3-S3-X3-How3, '% kept'-same-same-false),
    shl(['echo "pairs([z-9])." >> ', P]),
    atomic_list_concat([D, '/kept3'], B3),
    flow_debug(find(z, V4), B3, [source(P), names(['V'=V4]), cache(C)], R4),
    kept_last(CF, L4),
    ( L4 == '% kept' -> K4 = read_back ; K4 = built ),
    R4 = run(How4, _, _, _, Cs4, _, _, _),
    ( memberchk(call(_, pairs/1, _, _, _, _, Cl4, _, _, _), Cs4) -> true ; Cl4 = [] ),
    findall(K, member(c(K, _), Cl4), Ks4),
    exited(R4, find/2, O4),
    check('a program changed is charted again, and the run enters its new clause',
          K4-How4-Ks4-O4, built-answer-[1,2]-[z, '9']),
    atomic_list_concat([D, '/kept4'], B5),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'find(z, V)\' ', P, ' ', B5, ' cache=', C], A5),
    cocolog_run(A5, T5, E5),
    atomic_list_concat(Ls5c, '\n', T5),
    maplist(no_cpu, Ls5c, Ls5),
    atom_concat(B5, '.svg', SF5), atom_concat(B5, '.xml', XF5),
    check('cache=DIR: the command names the chart''s XML after the two files',
          E5-Ls5, 0-[SF5, XF5, XF, 'find(z, V): answer at step 10; recorded 1 to 10; diverged no']).

kept_doc(B, X) :-
    atom_concat(B, '.xml', XF),
    kept_doc_file(XF, X).

kept_doc_file(XF, X) :-
    read_file_to_codes(XF, Cs),
    xml_parse(Cs, X).

kept_same(B0, B1, Ext, S) :-
    atom_concat(B0, Ext, F0), atom_concat(B1, Ext, F1),
    read_file_to_codes(F0, C0), read_file_to_codes(F1, C1),
    ( C0 == C1 -> S = same ; S = differs ).

kept_last(F, L) :-
    read_file_to_codes(F, Cs),
    atom_codes(A, Cs),
    atomic_list_concat(Ls, '\n', A),
    append(_, [L, ''], Ls), !.

%% ---- over a store -------------------------------------------------------------

stored(D) :-
    section('embed(Dir): the program run over a store, its file loaded as -s loads it'),
    atom_concat(D, '/probe.kb', P0),
    sh_join(['--embed ', P0, ' query true >/dev/null 2>&1'], A0),
    (   cocolog_run(A0, _, 0)
    ->  stored_(D)
    ;   format("     (skipped: this build has no embedded store -- the --embed half not run)~n")
    ).

%% below/1 reads limit/1, which only the store has: 2 in the main
%% knowledge base, 4 in the one named other
stored_(D) :-
    atomic_list_concat([D, '/kb'], KB),
    atomic_list_concat([D, '/seed.pl'], S1), fixture(S1, ['limit(2).']),
    atomic_list_concat([D, '/seed2.pl'], S2), fixture(S2, ['limit(4).']),
    atomic_list_concat([D, '/below.pl'], P),
    fixture(P, ['below(X) :- limit(L), between(1, 9, X), X > L.']),
    sh_join(['--embed ', KB, ' run ', S1, ' true >/dev/null 2>&1'], A1), cocolog_run(A1, _, _),
    sh_join(['--embed ', KB, ' --kb other run ', S2, ' true >/dev/null 2>&1'], A2), cocolog_run(A2, _, _),
    atomic_list_concat([D, '/below'], B),
    flow_debug(below(X1), B, [source(P), names(['X'=X1]), embed(KB)], R1),
    R1 = run(How1, _, _, _, _, _, _, _),
    exited(R1, limit/1, L1),
    exited(R1, below/1, O1),
    check('the run reads what the store holds: limit(2), and below(X) answers 3', How1-L1-O1, answer-['2']-['3']),
    flow_debug(below(X2), B, [source(P), names(['X'=X2]), embed(KB), kb(other)], R2),
    R2 = run(How2, _, _, _, _, _, _, _),
    exited(R2, below/1, O2),
    check('kb(other) is the store''s knowledge base of that name: limit(4), and 5', How2-O2, answer-['5']),
    %% the child over a store is `query', which writes its goal back proved;
    %% the driver's goal holds every event recorded, so through 1.10.28 the
    %% child wrote them all (12.5 MB on the translator) -- a goal that binds
    %% a list of 20000 numbers stands in for them here
    flow_dbg_cmd(embedded(P, KB, none), 'numlist(1, 20000, L5), length(L5, _)', Cmd5),
    proc_run(Cmd5, 60000, Out5, Rc5), length(Out5, N5),
    ( N5 < 2000 -> W5 = a_line ; W5 = N5 ),
    check('the child over a store writes a line, not what its goal bound', Rc5-W5, 0-a_line),
    %% asked by the exit status, as test/argv.pl's stored/2 asks: 0 when
    %% the procedure is there to ask (the answer echoes the query's text,
    %% so a word written by it would be read either way)
    sh_join(['--embed ', KB, ' query "below(_)" >/dev/null 2>&1'], A3),
    cocolog_run(A3, _, Rc3),
    ( Rc3 =:= 0 -> S3 = stored ; S3 = absent ),
    check('the program''s clauses were never written into the store, as under -s', S3, absent),
    flow_debug(below(_), B, [source(P)], R4),
    R4 = run(How4, _, _, _, _, _, _, _),
    ( How4 = exception(error(E4, _)) -> true ; E4 = How4 ),
    check('without embed(Dir) the program runs over a knowledge base of its own, which has no limit/1',
          E4, existence_error(procedure, limit/1)).

%% ---- two runs compared ----------------------------------------------------------

%% a running total and the same with add/3 doubling what it adds: the
%% difference begins in add/3, three calls deep, and double/2 runs in b only
compared(D) :-
    section('flow_diff/3: two runs compared -- the inputs both called that answered differently, deepest first'),
    atomic_list_concat([D, '/sum_a.pl'], PA),
    atomic_list_concat([D, '/sum_b.pl'], PB),
    Common = ['total(L, T) :- sumup(L, 0, T).', 'sumup([], T, T).',
              'sumup([X|Xs], A, T) :- add(A, X, A1), sumup(Xs, A1, T).'],
    append(Common, ['add(A, X, B) :- B is A + X.'], LA),
    append(Common, ['add(A, X, B) :- double(X, Y), B is A + Y.', 'double(X, Y) :- Y is X * 2.'], LB),
    fixture(PA, LA),
    fixture(PB, LB),
    atomic_list_concat([D, '/suma'], BA),
    atomic_list_concat([D, '/sumb'], BB),
    flow_debug(total([1,2,3], T1), BA, [source(PA), names(['T'=T1]), from(1), places(QA)], RA),
    flow_debug(total([1,2,3], T2), BB, [source(PB), names(['T'=T2]), from(1), places(QB)], RB),
    flow_diff(RA, RB, Df),
    Df = diff(Both, Ds, OA, OB),
    findall(P-In-AA-AB, member(differ(P, In, c(_, _, _, _, AA), c(_, _, _, _, AB)), Ds), Ks),
    check('three inputs both called answered differently, the deepest first: add/3 began it',
          Both-Ks,
          3-[ add/3-['0', '1', '_']-exit(['0', '1', '1'])-exit(['0', '1', '2']),
              sumup/3-['[1,2,3]', '0', '_']-exit(['[1,2,3]', '0', '6'])-exit(['[1,2,3]', '0', '12']),
              total/2-['[1,2,3]', '_']-exit(['[1,2,3]', '6'])-exit(['[1,2,3]', '12']) ]),
    check('double/2 is called in b only: three calls, the first at step 4, its box and panel',
          OA-OB, []-[only(double/2, 3, 4, 'p3.c1.g1', p4)]),
    flow_diff_text(Df, QA, QB, Text),
    atomic_list_concat(TLs, '\n', Text),
    TLs = [H, L1, L2, L3|_],
    append(_, [LL, ''], TLs),
    atomic_list_concat(['  a exit add(0,1,1) at step 3, p2.c2.g1 ', PA, ':3:24'], E2),
    atomic_list_concat(['  b exit add(0,1,2) at step 3, p2.c2.g1 ', PB, ':3:24'], E3),
    atomic_list_concat(['only in b: double/2, 3 calls, the first at step 4; defined ', PB, ':5:1'], ELL),
    check('as text: each input, each run''s answer and where the call is written, and where double/2 is defined',
          [H, L1, L2, L3, LL],
          ['% 3 inputs in both runs, 3 answered differently; 0 predicates only in a, 1 only in b',
           'differs at depth 3: add(0,1,_)', E2, E3, ELL]),
    atomic_list_concat([D, '/sumd'], BD),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'total([1,2,3], T)\' ', PA, ' ', BD, ' diff=', PB], A4),
    cocolog_run(A4, T4, E4),
    atomic_list_concat(Ls4, '\n', T4),
    atom_concat(BD, '.diff', DF4),
    yes_no(( memberchk(DF4, Ls4), exists_file(DF4) ), Y4),
    ( last(Ls4, L4) -> true ; L4 = '' ),
    check('diff=FILE: the command writes each run and BASE.diff, and says how the two compare',
          E4-Y4-L4,
          0-yes-'a total([1, 2, 3], T): answer at step 12; b total([1, 2, 3], T): answer at step 18; 3 inputs in both, 3 answered differently, 0 predicates only in a, 1 only in b'),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'total([1,2,3], T)\' ', PA, ' ', BD, ' \'diff_goal=total([1,2], T)\''], A5),
    cocolog_run(A5, T5, E5),
    atomic_list_concat(Ls5, '\n', T5),
    ( last(Ls5, L5) -> true ; L5 = '' ),
    check('diff_goal=GOAL: two goals over one program -- the four inputs they share answered alike',
          E5-L5,
          0-'a total([1, 2, 3], T): answer at step 12; b total([1, 2], T): answer at step 9; 4 inputs in both, 0 answered differently, 0 predicates only in a, 0 only in b').

%% a predicate whose name begins with $ is the engine's or a library's own
%% ('$pred_count'/3), and listed after the program's (1.11.0): on the
%% translator four of them came first, 22 and 16 deep, over the cause
%% (reported from the reasoning session). Here '$level'/1 answers
%% differently two calls under the program's own.
compared_own(D) :-
    section('flow_diff/3: a predicate named $... comes after the program''s, however deep'),
    atomic_list_concat([D, '/own_a.pl'], PA),
    atomic_list_concat([D, '/own_b.pl'], PB),
    Common = ['top(R) :- mid(R).', 'mid(R) :- low(R).', 'low(R) :- \'$level\'(R).'],
    append(Common, ['\'$level\'(1).'], LA),
    append(Common, ['\'$level\'(2).'], LB),
    fixture(PA, LA),
    fixture(PB, LB),
    atomic_list_concat([D, '/owna'], BA),
    atomic_list_concat([D, '/ownb'], BB),
    flow_debug(top(R1), BA, [source(PA), names(['R'=R1]), from(1)], RA),
    flow_debug(top(R2), BB, [source(PB), names(['R'=R2]), from(1)], RB),
    flow_diff(RA, RB, diff(_, Ds, _, _)),
    findall(P, member(differ(P, _, _, _), Ds), Ps),
    check('the program''s inputs deepest first, then the $ one deepest of all',
          Ps, [low/1, mid/1, top/1, '$level'/1]).

%% ---- where the inferences went ----------------------------------------------------

profiled(D) :-
    section('profile(P): where the window''s steps went -- a call spends up to its first Exit or Fail'),
    debugged(D, prof1, pick(X1), ['X'=X1], [profile(P1)], _),
    check('pick(X): member/2 spends to its first Exit -- the 1 > 1 its redo comes back past is pick''s',
          P1, profile(1, 6, 5, [prof(pick/1, 5, 1, 5), prof((>)/2, 2, 2, 1), prof(member/2, 2, 2, 1)])),
    debugged(D, prof2, rec(6, R2), ['R'=R2], [from(1), profile(P2)], _),
    P2 = profile(_, _, Spent2, Rows2),
    findall(P-I-N, ( member(prof(P, I, N, _), Rows2), memberchk(P, [nrev/2, app/3]) ), NA2),
    findall(P, ( member(prof(P, I, _, _), Rows2), I > Spent2 ), Over2),
    memberchk(prof(rec/2, IG2, _, _), Rows2),
    check('a recursion is counted once over its nested calls: nrev/2''s seven calls spend what the outermost does, and no predicate more than the window''s calls',
          IG2-NA2-Over2, Spent2-[nrev/2-28-7, app/3-21-21]-[]),
    flow_profile_text(P1, PT1),
    atomic_list_concat(PLs1, '\n', PT1),
    PLs1 = [PH1, _, PR1|_],
    check('as text: the window, then a row a predicate, the most inclusive first', PH1-PR1,
          '% 5 steps spent by the calls of the window 1 to 6, 5 of them inferences (true/0 and =/2 are none), 3 predicates -- a call spends from its Call to its first Exit or Fail'-'          5   100.0        1        5  pick/1'),
    fx(F),
    atomic_list_concat([D, '/profc'], B3),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'pick(X)\' ', F, ' ', B3, ' profile=true'], A3),
    cocolog_run(A3, T3, E3),
    atomic_list_concat(Ls3, '\n', T3),
    atom_concat(B3, '.prof', PF3),
    read_file_to_codes(PF3, PC3), atom_codes(PA3, PC3),
    ( Ls3 = [_, _, PF3, _] -> N3 = named ; N3 = unnamed ),
    check('profile=true: BASE.prof, named after the two files', E3-N3-PA3, 0-named-PT1).

%% ---- the profile's other views, and windows added up (1.11.10) --------------------

%% top/0 asks leaf/1 seven times from three callers, a(1) twice, g/1 twice
%% with fresh variables, and h/2 once with one variable twice and once with
%% two: the callers, the goals asked again and the steps are known by hand;
%% k(K) binds a value that would cross into K
viewed(D) :-
    section('callers, repeats and steps: who made the calls, the goals asked again, the steps by what took them (1.11.10)'),
    atomic_list_concat([D, '/views.pl'], F),
    fixture(F, ['top :- a(1), a(1), b(2), b(3), c, g(_), g(_), h(Z, Z), h(_, _), k(K), K > 0.',
                'a(X) :- leaf(X).', 'b(X) :- leaf(X), leaf(X).', 'c :- leaf(1).',
                'leaf(_).', 'g(_).', 'h(_, _).', 'k(5).']),
    atomic_list_concat([D, '/views'], B),
    flow_debug(top, B, [source(F), from(1), profile(P1), callers(C1), repeats(R1), svg(false), xml(false)], Run1),
    C1 = callers(_, _, CR1),
    check('callers: leaf/1''s seven calls, four of them b/1''s -- the most called first, its callers the most calling first, the query''s goal the query''s',
          CR1, [callers(leaf/1, 7, [b/1-4, a/1-2, c/0-1]), callers(a/1, 2, [top/0-2]), callers(b/1, 2, [top/0-2]),
                callers(g/1, 2, [top/0-2]), callers(h/2, 2, [top/0-2]), callers((>)/2, 1, [top/0-1]),
                callers(c/0, 1, [top/0-1]), callers(k/1, 1, [top/0-1]), callers(top/0, 1, ['(the query)'-1])]),
    R1 = repeats(_, _, RR1),
    check('repeats: leaf(1) three times, a(1) twice, g/1 twice with fresh variables -- h(Z, Z) and h(_, _) are two goals, b(2) and b(3) two',
          RR1, [repeats(leaf/1, 7, 3, ['leaf(1)'-3, 'leaf(2)'-2, 'leaf(3)'-2]), repeats(a/1, 2, 1, ['a(1)'-2]),
                repeats(g/1, 2, 1, ['g(_1)'-2])]),
    flow_steps_text(P1, ST1),
    atomic_list_concat(SL1, '\n', ST1),
    SL1 = [SH1, _, SA1|_],
    append(_, [SZ1, ''], SL1),
    check('steps: the window''s 20 steps, 19 of them calls, leaf/1''s seven the most, and the one a control construct took',
          [SH1, SA1, SZ1],
          ['% the 20 steps of the window 1 to 20, 20 of them inferences (true/0 and =/2 are none), by what took them: 19 calls of 9 predicates, a step each, and 1 by control constructs, which make no call (an if-then-else, a cut, catch/3 and its exit, \\+, call/N)',
           '        7    35.0  leaf/1',
           '        1     5.0  (control constructs)']),
    %% THE STEPS THAT WERE NO INFERENCE (1.13.5, the reasoning session's
    %% point): a call of true/0 or =/2 is a step the window numbers and no
    %% inference, and the header says both -- the inferences as statistics/2
    %% counts the same goal run in a child
    atomic_list_concat([D, '/frees.pl'], F9),
    fixture(F9, ['fr(0) :- !.',
                 'fr(N) :- true, X = f(N), X = f(_), ( N > 2 -> true ; Y = 1, Y == 1 ), N1 is N - 1, fr(N1).']),
    atomic_list_concat([D, '/frees'], B9),
    flow_debug(fr(5), B9, [source(F9), from(1), profile(P9), svg(false), xml(false)], _),
    flow_steps_text(P9, ST9),
    atomic_list_concat([SH9|_], '\n', ST9),
    atomic_list_concat(['run ', F9, ' \'(statistics(inferences, A), fr(5), statistics(inferences, B), C is B - A, write(c(C)), nl)\''], A9),
    cocolog_run(A9, T9, _),
    ( sub_atom(T9, Bc9, _, _, 'c('), sub_atom(T9, Bc9, _, 0, CT9), term_to_atom(TT9, CT9), TT9 = c(C9) -> true ; C9 = none ),
    format(atom(EH9), '% the 50 steps of the window 1 to 50, ~w of them inferences (true/0 and =/2 are none), by what took them: 38 calls of 6 predicates, a step each, and 12 by control constructs, which make no call (an if-then-else, a cut, catch/3 and its exit, \\+, call/N)', [C9]),
    check('a window''s steps less its calls of true/0 and =/2 are its inferences, as statistics/2 counts them (30 of fr(5)''s 50)',
          C9-SH9, 30-EH9),
    Run1 = run(_, _, _, _, _, Bs1, _, _),
    atom_concat(B, '.svg', SF1), atom_concat(B, '.xml', XF1),
    yes_no(exists_file(SF1), YS1), yes_no(exists_file(XF1), YX1),
    check('svg(false) and xml(false): neither document written, and the values that crossed not worked out',
          Bs1-YS1-YX1, []-no-no),
    %% two windows of one run: the calls of each predicate are the whole
    %% run's, and a call whose caller is in the other window is outside its
    debugged(D, merge0, rec(6, R2), ['R'=R2], [from(1), profile(P2), svg(false), xml(false)], Run2),
    debugged(D, merge1, rec(6, R3), ['R'=R3], [from(1), to(20), profile_rows(Rs3), svg(false), xml(false)], _),
    debugged(D, merge2, rec(6, R4), ['R'=R4], [from(21), profile_rows(Rs4), svg(false), xml(false)], _),
    flow_profile_merge([Rs3, Rs4], MP, MC, _),
    P2 = profile(_, T2, _, PR2),
    MP = profile(MW, _, _, MPR),
    findall(Pr-N, member(prof(Pr, _, N, _), PR2), PN2), msort(PN2, SPN2),
    findall(Pr-N, member(prof(Pr, _, N, _), MPR), MPN), msort(MPN, SMPN),
    check('two windows added up (flow_profile_merge/4): each predicate''s calls are the whole run''s, the windows named',
          SMPN-MW, SPN2-windows([1-20, 21-T2])),
    MC = callers(_, _, MCR),
    ( memberchk(callers(app/3, NA2, AC2), MCR) -> true ; NA2 = 0, AC2 = [] ),
    check('and a call whose caller began in the other window is outside its own: three of app/3''s 21',
          NA2-AC2, 21-[app/3-14, nrev/2-4, '(outside the window)'-3]),
    %% app/3's recursion is a last call, made with its caller's cell: the
    %% matcher asks which call the parent cell names before the Call names
    %% its own, or the call is its own parent
    Run2 = run(_, _, _, _, Cs2, _, _, _),
    findall(S2-Pa2, ( member(call(S2, _, _, Pa2, _, _, _, _, _, _), Cs2), Pa2 >= S2 ), Own2),
    check('every call''s caller was made before it', Own2, []),
    %% the translator records a Call made with its caller's own cell (a
    %% retry in a recursion, append/3's): the matcher asks which call the
    %% parent's cell names BEFORE the Call names its own cell (1.11.10), or
    %% the call is its own caller
    flow_dbg_index([call(1, 1, 100, 0, p, []), exit(1, 1, 100, p, []),
                    call(2, 2, 100, 100, q, [a]), fail(2, 2, 100, q, [a])], Cs7, _),
    check('a Call whose parent''s cell is its own cell is that cell''s last call''s child, not its own',
          Cs7, [c(1, p/0, 1, 0, [], [], [], exit), c(2, q/1, 2, 1, [], [a], none, fail)]),
    %% a window that closes on calls still running: each spends up to the
    %% last inference under it
    P3 = profile(_, _, _, PR3),
    debugged(D, open20, rec(6, R5), ['R'=R5], [from(1), to(20), profile(P3), svg(false), xml(false)], _),
    findall(Pr3-I3, ( member(prof(Pr3, I3, _, _), PR3), memberchk(Pr3, [rec/2, nrev/2]) ), Open3),
    check('a call the window closed on spends up to the last step made under it: rec/2 the whole window, nrev/2 from step 5',
          Open3, [rec/2-20, nrev/2-16]),
    statistics(inferences, I0), flow_dbg_text_spaces(1000, S1000), statistics(inferences, I1),
    atom_length(S1000, L1000), DI is I1 - I0,
    ( DI < 20 -> Cost = constant ; Cost = DI ),
    check('BASE.txt indents a call 500 levels deep at once, not a space a level (through 1.11.9, 100 000 steps far along a recursion took minutes)',
          L1000-Cost, 1000-constant),
    viewed_command(D).

%% the views and the windows from the command line
viewed_command(D) :-
    fx(F),
    atomic_list_concat([D, '/viewc'], B5),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'pick(X)\' ', F, ' ', B5, ' profile=all svg=false xml=false'], A5),
    cocolog_run(A5, T5, E5),
    atomic_list_concat(Ls5c, '\n', T5),
    maplist(no_cpu, Ls5c, Ls5),
    atom_concat(B5, '.prof', PF5),
    read_file_to_codes(PF5, PC5), atom_codes(PA5, PC5),
    atomic_list_concat(Secs5, '\n\n', PA5),
    findall(Top, ( member(Sec, Secs5), atomic_list_concat([L|_], '\n', Sec), sub_atom(L, 0, 89, _, Top) ), Tops5),
    check('profile=all svg=false xml=false: BASE.prof alone and the line, the five views in order (time since 1.13.3)',
          E5-Ls5-Tops5,
          0-[PF5, 'pick(X): answer at step 6; recorded 1 to 6; diverged no']-
            ['% 5 steps spent by the calls of the window 1 to 6, 5 of them inferences (true/0 and =/2 a',
             '% the 6 steps of the window 1 to 6, 6 of them inferences (true/0 and =/2 are none), by wh',
             '% the callers of the 3 predicates the window 1 to 6 called, the most called first: its ca',
             '% the goals the window 1 to 6 asked more than once, by predicate (0), the most repeats fi',
             '% the 6 steps of the window 1 to 6, 6 of them inferences (true/0 and =/2 are none), took ']),
    atomic_list_concat([D, '/vieww'], B6),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'rec(30, R)\' ', F, ' ', B6, ' window=40 windows=2 jobs=2 profile=steps,callers,time svg=false xml=false txt=true'], A6),
    cocolog_run(A6, T6, E6),
    atomic_list_concat(Ls6c, '\n', T6),
    maplist(no_cpu, Ls6c, Ls6),
    atomic_list_concat([B6, '.1.txt'], TF61), atomic_list_concat([B6, '.2.txt'], TF62),
    atom_concat(B6, '.prof', PF6),
    yes_no(( exists_file(TF61), exists_file(TF62), memberchk(PF6, Ls6) ), Y6),
    ( last(Ls6, L6) -> true ; L6 = none ),
    read_file_to_codes(PF6, PC6), atom_codes(PA6, PC6),
    atomic_list_concat([SH6|_], '\n', PA6),
    %% a caller's line, indented under its predicate: the header names
    %% (the query) too
    ( sub_atom(PA6, _, _, _, '    (the query)') -> Q6 = named ; Q6 = not_named ),
    %% and the time view of both, each window's probe under the clock
    ( sub_atom(PA6, _, _, _, '\n% the 80 steps of the 2 windows 211 to 250, 462 to 501, 80 of them inferences (true/0 and =/2 are none), took ') -> M6 = timed ; M6 = untimed ),
    check('windows=2: two windows of 40 steps, the second where the run ends, each BASE.K.txt, and BASE.prof of both -- no window began with the query -- their time added up too',
          E6-Y6-L6-SH6-Q6-M6,
          0-yes-'rec(30, R): answer at step 501; 2 windows: 211 to 250, 462 to 501'-
          '% the 80 steps of the 2 windows 211 to 250, 462 to 501, 80 of them inferences (true/0 and =/2 are none), by what took them: 79 calls of 1 predicate, a step each, and 1 by control constructs, which make no call (an if-then-else, a cut, catch/3 and its exit, \\+, call/N)'-
          not_named-timed),
    %% ... and each window's own (1.13.7): a cold window apart from a warm one
    atomic_list_concat([B6, '.1.prof'], PF61), atomic_list_concat([B6, '.2.prof'], PF62),
    findall(H6, ( member(PF, [PF61, PF62]), memberchk(PF, Ls6),
                  read_file_to_codes(PF, C6), atom_codes(A6c, C6),
                  atomic_list_concat([H6a|_], '\n', A6c), sub_atom(H6a, 0, 40, _, H6) ),
            Hs6),
    check('...and each window''s own BASE.K.prof, named on the output, of that window alone',
          Hs6, ['% the 40 steps of the window 211 to 250,', '% the 40 steps of the window 462 to 501,']),
    %% ... and the CPU each window's replay spent before it opened, which
    %% places it in the run's time; the run's line, its probe's
    findall(x, ( member(L, Ls6c), sub_atom(L, _, _, 0, ' s before the window opened') ), BW6),
    length(BW6, NBW6),
    ( last(Ls6c, L6c), sub_atom(L6c, _, _, _, '; CPU: the probe ') -> PR6 = said ; PR6 = not_said ),
    check('...and each window''s line the CPU its replay spent before it opened, the run''s line the probe''s',
          NBW6-PR6, 2-said).

%% a line of tools/flow/debug.pl without the CPU it ends with (1.13.7),
%% which no two runs share
no_cpu(L, C) :-
    (   atomic_list_concat([C0, _], '; CPU: ', L) -> C = C0 ; C = L ).

%% ---- where the time went (1.13.3) -------------------------------------------------
%%
%% t_go/1 counts down 200 twice -- its is/2 a guard its clause runs as it is
%% entered -- around one msort/2 of 20 000: one inference of the window's
%% eight hundred, and most of its time. What is held does not depend on how
%% fast the box is: the rows name the profile's calls, a guard has no time of
%% its own, a predicate's own time is its Call's inference, and the one
%% inference that costs a thousand is found.

timed(D) :-
    section('time(T): where the window''s time went -- the probe under a clock, the replay saying whose each step was (1.13.3)'),
    atomic_list_concat([D, '/timed.pl'], F),
    fixture(F, ['t_sort(X) :- numlist(1, 20000, L0), reverse(L0, L), msort(L, S), last(S, X).',
                't_count(0) :- !.', 't_count(N) :- N1 is N - 1, t_count(N1).',
                't_go(X) :- t_count(200), t_sort(X), t_count(200).']),
    atomic_list_concat([D, '/timed'], B),
    flow_debug(t_go(_), B, [source(F), from(1), profile(P1), time(T1), svg(false), xml(false)], R1),
    P1 = profile(PF1, PT1, _, PR1),
    T1 = time(TF1, TT1, total(Ns1, Reads1, _, _, _), TR1),
    findall(Pr-N, member(prof(Pr, _, N, _), PR1), PN1), msort(PN1, SPN1),
    findall(Pr-N, member(t(Pr, N, _, _, _, _, _), TR1), TN1), msort(TN1, STN1),
    W1 is PT1 - PF1 + 1,
    ( Ns1 > 0, Reads1 < W1 -> S1 = timed ; S1 = Ns1-Reads1-W1 ),
    check('the window the profile counts, its predicates and their calls; timed, and some of its steps not read',
          TF1-TT1-STN1-S1, PF1-PT1-SPN1-timed),
    ( memberchk(t(is/2, NI1, _, SI1, _, _, _), TR1) -> true ; NI1 = 0, SI1 = none ),
    check('is/2, a guard its clause runs as it is entered: 400 calls and no time of its own -- it is t_count/1''s',
          NI1-SI1, 400-0),
    findall(Se-Pr, member(t(Pr, _, _, Se, _, _, _), TR1), SPs1), max_member(_-Top1, SPs1),
    ( memberchk(prof(msort/2, IM1, NM1, _), PR1) -> true ; IM1 = 0, NM1 = 0 ),
    check('msort/2: one step in the profile, and in time the most of any predicate''s own',
          Top1-IM1-NM1, (msort/2)-1-1),
    ( memberchk(t(t_sort/1, 1, IS1, SS1, _, _, _), TR1), SS1 * 10 < IS1 -> O1 = own ; O1 = none ),
    check('a predicate''s own time is its Call''s step: t_sort/1''s is a tenth of what it takes inside',
          O1, own),
    %% WHERE THE LARGEST CALL IS (1.15.0, cicilang's ask): msort/2's one
    %% call, its window and the step it was made at -- the step the run's
    %% own call event carries, so a window can be recorded around it
    R1 = run(_, _, _, _, Cs1, _, _, _),
    ( memberchk(call(SM1, msort/2, _, _, _, _, _, _, _, _), Cs1) -> true ; SM1 = none ),
    ( memberchk(t(msort/2, _, _, _, _, AM1, _), TR1) -> true ; AM1 = none ),
    check('where msort/2''s largest call is: the window, and the step its call event names',
          AM1, at(PF1-PT1, SM1)),
    flow_time_text(T1, TX1),
    atomic_list_concat([TH1, _, TC1, TD1|_], '\n', TX1),
    format(atom(TP1), '% the ~d steps of the window ~d to ~d, ~d of them inferences (true/0 and =/2 are none), took ', [W1, PF1, PT1, W1]),
    ( atom_concat(TP1, _, TH1) -> H1 = header ; H1 = TH1 ),
    ( sub_atom(TD1, _, _, _, '  t_go/1  @1:') -> D1 = t_go ; D1 = TD1 ),
    check('as text: the window''s time, then a row a predicate, the most inclusive first, each with where its largest call is',
          H1-TC1-D1, header-'% inclusive us       %     self us       %    calls  largest us  predicate'-t_go),
    format(atom(MW1), '  msort/2  @1:~d', [SM1]),
    ( sub_atom(TX1, _, _, _, MW1) -> MT1 = placed ; MT1 = MW1 ),
    check('...msort/2''s row says @1:S, window 1 and its call''s step', MT1, placed),
    %% TWO WINDOWS ADDED UP keep the position of the one that held it: the
    %% run cut five steps before msort/2's call, so it is in the second
    K1 is SM1 - 5, K1b is K1 + 1,
    flow_debug(t_go(_), B, [source(F), from(1), to(K1), time(_), profile_rows(RsA1), svg(false), xml(false)], _),
    flow_debug(t_go(_), B, [source(F), from(K1b), time(_), profile_rows(RsB1), svg(false), xml(false)], _),
    flow_profile_merge([RsA1, RsB1], _, _, _, TM1),
    TM1 = time(windows(Ws1), none, _, MR1),
    ( Ws1 = [_, K1b-TB1] -> true ; TB1 = none ),
    ( memberchk(t(msort/2, _, _, _, _, MA1, _), MR1) -> true ; MA1 = none ),
    check('two windows added up: msort/2''s largest call is in the second, at its step',
          MA1, at(K1b-TB1, SM1)),
    flow_time_text(TM1, MX1),
    format(atom(MW2), '  msort/2  @2:~d', [SM1]),
    ( sub_atom(MX1, _, _, _, MW2) -> MT2 = placed ; MT2 = MX1 ),
    check('...and its row says @2:S', MT2, placed),
    %% A RETRY IS THE RETRIED PREDICATE'S (1.13.7): t_last/1's ==/2 fails
    %% at each of t_n/2's first 199 clauses, and each failure is a retry of
    %% t_n/2, whose next head binds twenty arguments. From step 3 the window
    %% holds the retries and not t_n/2's call
    atomic_list_concat([D, '/retry.pl'], F2),
    numlist(1, 20, As2), atomic_list_concat(As2, ',', AA2),
    findall(L2, ( between(1, 200, K2), format(atom(L2), 't_n(~d, t(~w)).', [K2, AA2]) ), Ns2),
    append(Ns2, ['t_last(X) :- t_n(X, _), X == 200.'], Ls2),
    fixture(F2, Ls2),
    atomic_list_concat([D, '/retry'], B2),
    flow_debug(t_last(_), B2, [source(F2), from(3), time(T2), svg(false), xml(false)], _),
    T2 = time(_, _, _, TR2),
    ( memberchk(t(t_n/2, NN2, IN2, SN2, _, _, _), TR2) -> true ; NN2 = none, IN2 = 0, SN2 = 0 ),
    ( SN2 > 0, IN2 =:= SN2 -> O2 = retried ; O2 = IN2-SN2 ),
    check('from(3), after t_n/2''s call: its 199 retries in the window, a row of 0 calls whose time, own and inclusive, is theirs',
          NN2-O2, 0-retried),
    ( memberchk(t((==)/2, NE2, IE2, SE2, ME2, _, _), TR2) -> true ; NE2 = 0, IE2 = 0, SE2 = 0, ME2 = 0 ),
    ( SE2 - ME2 < SN2 -> E2 = under ; E2 = SE2-ME2-SN2 ),
    ( IE2 =:= SE2 -> P2 = own ; P2 = IE2-SE2 ),
    check('==/2''s 200 calls: their own time, less the largest, under the retries'' -- a failure is not charged the retry after it -- and inside them too, each call over at its Fail',
          NE2-E2-P2, 200-under-own),
    %% to(10): t_last/1 is still running where the window ends, its last
    %% call ==/2 at 10 and the retry after it its own -- the query's time is
    %% the window's, to the nanosecond; and t_n/2's call is in the window,
    %% over at its Exit at 2, its retries after it its inclusive time too
    flow_debug(t_last(_), B2, [source(F2), from(1), to(10), time(T3), svg(false), xml(false)], _),
    T3 = time(_, _, total(Ns3, _, _, _, _), TR3),
    ( memberchk(t(t_last/1, 1, IL3, _, _, _, _), TR3) -> true ; IL3 = none ),
    ( memberchk(t(t_n/2, 1, IN3, SN3, _, _, _), TR3), IN3 =:= SN3 -> N3 = own ; N3 = none ),
    check('to(10): the window ends inside t_last/1, so the retry at its last step is its, and its time the window''s; t_n/2''s retries after its Exit are in its inclusive time',
          IL3-N3, Ns3-own),
    %% A LOAD, NOT A CALL (1.13.7): msort/2 of 20 000 and then of two, and
    %% t_w/1, whose first call sorts them in its body -- each one call most
    %% of its time, marked; t_e/1's two calls alike, and t_c/1's outermost
    %% call holding all its others, are not. Nor is t_r/1 (1.15.0), a
    %% recursion called twice alike, back to back: through 1.14.0 the 2 000
    %% calls inside its first were counted as its others, their mean nearly
    %% nothing, and it was marked -- lesson 51's count/1. The rule counts
    %% its OUTERMOST calls since, which the CALL TREE names: t_nat/1,
    %% backtracked into for its next answer until one reaches 30, makes its
    %% inner calls after its first Exit, where its span ends, and the spans
    %% alone count every one of its 31 calls outermost.
    %%
    %% THE TWO PAIRS ALIKE ARE BIG ENOUGH TO TIME: t_e/1 made a list of 300
    %% through 1.14.0, some 25 us, its first call some three times its
    %% second (a first call's own cost), and one stall of 50 us in it made
    %% the ten times that marks a load -- once in a run of the case. Of
    %% 3 000 and 2 000, eight runs put the larger call of each pair within
    %% 1.3 and 2.9 times the other
    atomic_list_concat([D, '/load.pl'], F4),
    fixture(F4, ['t_ms :- t_w(0), t_w(1), msort([b, a], _), t_e(1), t_e(2), t_c(200), t_r(2000), t_r(2000), t_n2.',
                 't_w(0) :- !, numlist(1, 20000, L0), reverse(L0, L), msort(L, _).', 't_w(_).',
                 't_e(_) :- numlist(1, 3000, _).',
                 't_c(0) :- !.', 't_c(N) :- N1 is N - 1, t_c(N1).',
                 't_r(0) :- !.', 't_r(N) :- N1 is N - 1, t_r(N1).',
                 't_n2 :- t_nat(X), X >= 30, !.',
                 't_nat(0).', 't_nat(N) :- t_nat(M), N is M + 1.']),
    atomic_list_concat([D, '/load'], B4),
    flow_debug(t_ms, B4, [source(F4), from(1), time(T4), svg(false), xml(false)], _),
    flow_time_text(T4, TX4),
    atomic_list_concat(TL4, '\n', TX4),
    findall(P4-M4, ( member(P4, ['msort/2', 't_c/1', 't_e/1', 't_r/1', 't_w/1']), load_mark(TL4, P4, M4) ), PM4s),
    check('a load, not a call: msort/2''s 20 000 and t_w/1''s first call marked, t_e/1''s two alike, the recursive t_c/1 and t_r/1 called twice alike not',
          PM4s, ['msort/2'-load, 't_c/1'-none, 't_e/1'-none, 't_r/1'-none, 't_w/1'-load]),
    T4 = time(_, _, _, TR4),
    findall(P5-O5, ( member(P5, [t_c/1, t_nat/1, t_r/1, t_w/1]), memberchk(t(P5, _, _, _, _, _, outer(O5, _)), TR4) ), PO5s),
    check('...the outermost calls the row counts: t_c/1''s one, t_nat/1''s one of its 31, made as it was redone, t_r/1''s two of its 4002, t_w/1''s two',
          PO5s, [t_c/1-1, t_nat/1-1, t_r/1-2, t_w/1-2]).

%% THE WHOLE RUN'S TIME, BY PREDICATE (1.15.0, cicilang's ask): the probe
%% alone, under a clock read at every step from the first, each step's
%% time charged to what its goal is named by (flow_run_time/3) -- over all
%% of the run, where the time view sees its window. Held: whose rows there
%% are, with how many steps, in which order, a retry's, the text, and the
%% shell's profile=run beside the window's views
run_timed(D) :-
    section('flow_run_time/3: each predicate''s own time over the whole run, the probe alone under the clock (1.15.0)'),
    atomic_list_concat([D, '/runtime.pl'], F1),
    fixture(F1, ['rt_go(X) :- rt_c(200), rt_s(X), rt_c(200), rt_z, rt_z, rt_p(Y), Y == c.',
                 'rt_s(X) :- numlist(1, 20000, L0), reverse(L0, L), msort(L, S), last(S, X).',
                 'rt_c(0) :- !.', 'rt_c(N) :- N1 is N - 1, rt_c(N1).',
                 'rt_z.',
                 'rt_p(a).', 'rt_p(b).', 'rt_p(c).']),
    flow_run_time(rt_go(_), [source(F1)], RT1),
    RT1 = run_time(end(How1, _, _), total(Ns1, Rd1, _, _, _), Rows1),
    ( Rows1 = [rt(Top1, _, _, _)|_] -> true ; Top1 = none ),
    findall(P1-S1, ( member(P1, [rt_c/1, rt_z/0, rt_p/1, (==)/2, (is)/2]),
                     ( memberchk(rt(P1, S1, _, _), Rows1) -> true ; S1 = none ) ),
            PS1),
    check('the whole run by predicate: msort/2''s own time the most; rt_c/1''s 402 steps, rt_z/0''s two, rt_p/1''s one, ==/2''s three, is/2 none -- the guard rt_c/1''s clause runs as it is entered',
          How1-Top1-PS1, answer-(msort/2)-[rt_c/1-402, rt_z/0-2, rt_p/1-1, (==)/2-3, (is)/2-none]),
    ( memberchk(rt(rt_p/1, _, _, RP1), Rows1), RP1 > 0 -> R1 = retried ; R1 = none ),
    findall(O1, ( member(rt(_, _, Se1, Re1), Rows1), O1 is Se1 + Re1 ), Os1),
    ( msort(Os1, Asc1), reverse(Asc1, Os1) -> Or1 = descending ; Or1 = Os1 ),
    ( Rd1 > 400, Ns1 > 0 -> T1 = read ; T1 = Rd1-Ns1 ),
    check('...rt_p/1 retried for its next clauses, its retries'' time its own; the rows by own time, the most first; every step but the guards read',
          R1-Or1-T1, retried-descending-read),
    flow_run_time_text(RT1, TX1),
    atomic_list_concat([H1, _, C1|Ls1], '\n', TX1),
    ( sub_atom(H1, 0, _, _, '% the whole run, answer at step ') -> HH1 = header ; HH1 = H1 ),
    ( Ls1 = [L1|_], sub_atom(L1, _, _, 0, '  msort/2') -> LL1 = msort ; LL1 = Ls1 ),
    check('as text: how the run ended and what the clock read, then a row a predicate, msort/2''s first',
          HH1-C1-LL1, header-'%    self us       %    retry us       %       steps  predicate'-msort),
    %% the shell's profile=run: the window's views and then the run's, one
    %% BASE.prof
    atomic_list_concat([D, '/runtime'], B2),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'rt_go(X)\' ', F1, ' ', B2, ' profile=time,run svg=false xml=false'], A2),
    cocolog_run(A2, O2, E2),
    atomic_list_concat([B2, '.prof'], P2),
    ( exists_file(P2) -> read_file_to_codes(P2, Cs2), atom_codes(PA2, Cs2) ; PA2 = '' ),
    ( sub_atom(PA2, W2, _, _, ' steps of the window '), sub_atom(PA2, R2, _, _, '% the whole run, answer at step '), W2 < R2
      -> V2 = both ; V2 = PA2 ),
    ( sub_atom(O2, _, _, _, 'runtime.prof') -> N2 = named ; N2 = O2 ),
    check('tools/flow/debug.pl profile=time,run: BASE.prof holds the window''s time and then the whole run''s, and is named',
          E2-V2-N2, 0-both-named).

%% P's row among the time view's LINES: `load' when it ends in the mark,
%% `none' when it ends in P -- past the ` @W:S' that says where its
%% largest call is (1.15.0)
load_mark(Lines, P, M) :-
    member(L, Lines),
    \+ sub_atom(L, 0, _, _, '%'),
    sub_atom(L, B, _, A, P),
    B >= 2, B2 is B - 2,
    sub_atom(L, B2, 2, _, '  '),
    sub_atom(L, _, A, 0, Tail0), !,
    load_tail(Tail0, Tail),
    (   Tail == '' -> M = none
    ;   sub_atom(Tail, 0, _, _, '   (one call: ') -> M = load
    ;   M = Tail
    ).

%% the tail with its ` @W:S' taken off: up to the mark, or to the end
load_tail(T0, T) :-
    (   sub_atom(T0, 0, _, _, '  @')
    ->  (   sub_atom(T0, B, _, _, '   (one call: ') -> sub_atom(T0, B, _, 0, T) ; T = '' )
    ;   T = T0
    ).

%% ---- where a failed search got furthest -------------------------------------------

furthest(D) :-
    section('flow_why_furthest/2: where a failed search got furthest -- not where it failed last'),
    debugged(D, far1, parse(a), [], [txt(true)], R1),
    flow_why(R1, W1),
    flow_why_furthest(W1, F1),
    check('parse(a): its first clause got furthest -- word/2 exited -- and check/1 had no head for aa; the fallback only failed last',
          F1, [step(1, parse/1, [a], 1, 1, 2), nohead(3, check/1, [aa])]),
    debugged(D, far2, find(z, V2), ['V'=V2], [], R2),
    flow_why(R2, W2),
    flow_why_furthest(W2, F2),
    findall(X, ( member(S, F2), functor(S, X0, _), arg(2, S, P), X = X0-P ), F2s),
    check('find(z, V): down one clause each to member/2, which failed with nothing of the program''s to say why',
          F2s, [step-find/2, step-lookup/2, failed-member/2]),
    atom_concat(D, '/far1.xml', XF3),
    read_file_to_codes(XF3, XC3),
    xml_parse(XC3, X3),
    findall(N-As, ( x_el(X3, N, As0), memberchk(N, [step, end]),
                    findall(V, ( member(K, [call, pred, clause, done, tried, how]), memberchk(K=V, As0) ), As) ),
            S3),
    check('in the XML, after <why>: <furthest>, a <step> a failed call, and the <end>', S3,
          [step-['1', 'parse/1', '1', '1', '2'], end-['3', 'check/1', nohead]]),
    atom_concat(D, '/far1.txt', TF4),
    read_file_to_codes(TF4, TC4), atom_codes(TA4, TC4),
    atomic_list_concat(TL4, '\n', TA4),
    append(_, [L41, L42, L43, ''], TL4),
    check('and at the foot of BASE.txt', [L41, L42, L43],
          ['% where it got furthest:',
           '%  parse(a): clause 1, the furthest of 2 tried: 1 of its calls exited (call 1)',
           '%    check(aa): failed, no clause''s head unified (call 3)']),
    atom_concat(D, '/far1.svg', SF5),
    read_file_to_codes(SF5, SC5),
    xml_parse(SC5, S5),
    findall(T, ( svg_text(S5, T), ( T == 'where it got furthest' ; sub_atom(T, 0, _, _, '▸ ') ) ), Ts5),
    check('and on the picture, above why it failed', Ts5,
          ['where it got furthest', '▸ parse(a)   clause 1, the furthest of 2 tried: 1 call of its body exited  ·  call at 1']),
    %% check(aa) and fallback(a) tried no clause: the index passed over
    %% check(bb) and fallback(zz), and a window records only the heads a
    %% call tried (1.11.2) -- each is still why it failed, with no head
    findall(T6, ( svg_text(S5, T6), ( sub_atom(T6, 0, _, _, '✗ ') ; sub_atom(T6, 0, _, _, 'no clause tried') ) ), Ts6),
    check('...where check(aa) ends the furthest path, and under why, the two calls that tried no clause, each said so',
          Ts6, [ '✗ check(aa)   failed there: no clause''s head unified  ·  call at 3',
                 '✗ parse(a)   failed  ·  call at 1',
                 '✗ check(aa)   failed  ·  call at 3',
                 'no clause tried: none has a head these arguments could unify with',
                 '✗ fallback(a)   failed  ·  call at 4',
                 'no clause tried: none has a head these arguments could unify with' ]),
    %% `( lowerable(X) -> ... ; note(X), fail )': the clause failed at the
    %% fail, which stands for the condition's failure (1.11.4)
    debugged(D, far7, lower(bad, Y7), ['Y'=Y7], [], R7),
    flow_why(R7, W7),
    flow_why_furthest(W7, F7),
    findall(X-P, ( member(S, F7), functor(S, X, _), arg(2, S, P) ), F7s),
    check('lower(bad, Y): past the explicit fail/0, into the condition that failed, lowerable/1',
          F7s, [step-lower/2, step-lowerable/1, failed-(\==)/2]),
    %% ONE clause holding a disjunction (1.13.7, the reasoning session's
    %% report, the translator's tr_read_ir/5): the last call that failed is
    %% the fallback's, which failed at once; the first branch's read spent
    %% the most, and is where the clause got furthest
    debugged(D, far8, read_ir([the, dog, sleeps, loudly]), [], [], R8),
    flow_why(R8, W8),
    flow_why_furthest(W8, F8),
    findall(X-P, ( member(S, F8), functor(S, X, _), arg(2, S, P) ), F8s),
    check('read_ir(...): one clause, two branches -- into the first branch''s read, which spent the most, not the fallback that failed last',
          F8s, [step-read_ir/1, step-into_ir/1, step-ir_words/2, step-ir_words/2, step-ir_words/2,
                step-ir_words/2, nohead-ir_word/1]),
    %% a call that exited and failed only when asked again is the trail of
    %% a later failure: exited, in the tree, and never where its clause failed
    debugged(D, far9, tally, [], [], R9),
    flow_why(R9, W9),
    ( W9 = [why(_, _, _, [entered(1, G9)])] -> true ; G9 = [] ),
    findall(X, ( member(N, G9), functor(N, X, _) ), K9),
    flow_why_furthest(W9, F9),
    findall(X-P, ( member(S, F9), functor(S, X, _), arg(2, S, P) ), F9s),
    check('tally: count_up/0 exited and failed only when asked again -- exited in the tree, and the path goes into judge/0, though count_up/0 spent more',
          K9-F9s, [exited, why]-[step-tally/0, step-judge/0, nohead-verdict/1]),
    %% an exception a catch took is no stall
    debugged(D, far10, caught_far, [], [], R10),
    flow_why(R10, W10),
    flow_why_furthest(W10, F10),
    findall(X-P, ( member(S, F10), functor(S, X, _), arg(2, S, P) ), F10s),
    check('caught_far: past the exception the catch took, though its goal spent the most, into the test that failed',
          F10s, [step-caught_far/0, step-far_test/1, failed-(>)/2]),
    %% two that spent alike: the later
    debugged(D, far11, tie_far(1), [], [], R11),
    flow_why(R11, W11),
    flow_why_furthest(W11, F11),
    ( last(F11, failed(_, _, In11)) -> true ; In11 = F11 ),
    check('tie_far(1): two tests that spent a step each -- the later', In11, ['1', '7']),
    %% ... and the exception a catch took when nothing else failed
    debugged(D, far12, caught_only, [], [], R12),
    flow_why(R12, W12),
    flow_why_furthest(W12, F12),
    findall(X-P, ( member(S, F12), functor(S, X, _), arg(2, S, P) ), F12s),
    check('caught_only: nothing failed but the exception the catch took and its recovery''s fail -- the exception',
          F12s, [step-caught_only/0, ended-long_raise/1]).

%% ---- why a run raised ------------------------------------------------------

raised(D) :-
    section('flow_why_raised/2: the calls an exception ended, and the failure it answered'),
    debugged(D, rais1, drive(5), [], [txt(true)], R1),
    flow_why_raised(R1, raised(C1, A1)),
    findall(P-F, member(ended(_, P, _, F), C1), Cs1),
    ( A1 == none -> As1 = none ; why_shape(A1, As1) ),
    check('drive(5): drive/1 and give_up/1 unwound; it answered step(5), whose ok_step(5) tried no clause',
          Cs1-As1, [drive/1-unwound, give_up/1-unwound]
                   -why(step/1, [entered(1, [exited((>)/2), why(ok_step/1, [])])])),
    ( A1 == none -> P1 = none ; flow_why_furthest([A1], P1) ),
    check('...and where that got furthest', P1, [step(3, step/1, ['5'], 1, 1, 1), nohead(5, ok_step/1, ['5'])]),
    debugged(D, rais2, find(z, V2), ['V'=V2], [], R2),
    ( flow_why_raised(R2, _) -> Y3 = raised ; Y3 = none ),
    check('a run that failed has none', Y3, none),
    atom_concat(D, '/rais1.txt', TF4),
    read_file_to_codes(TF4, TC4), atom_codes(TA4, TC4),
    atomic_list_concat(TL4, '\n', TA4),
    append(_, ['% where the exception was raised:'|Rest4], TL4),
    %% since 1.11.7 with the else that chose give_up/1, and step(5) that
    %% failed for it
    check('at the foot of BASE.txt', Rest4,
          [ '%  drive(5): unwound (call 1)',
            '%    give_up(5): unwound (call 6)',
            '% the branch it was raised in: the else (every condition failed), at p1.c1.g1 in drive(5) (call 1); the conditions it ran:',
            '%  step(5): failed in its clauses (call 3)',
            '% the failure it answered, where it got furthest:',
            '%  step(5): clause 1, the furthest of 1 tried: 1 of its calls exited (call 3)',
            '%    ok_step(5): failed, no clause''s head unified (call 5)',
            '' ]),
    atom_concat(D, '/rais1.xml', XF5),
    read_file_to_codes(XF5, XC5),
    xml_parse(XC5, X5),
    once(x_sub(X5, raised, element(raised, _, RK5))),
    findall(N-P5-F5, ( member(element(ended, EA5, _), RK5), memberchk(call=N, EA5),
                       memberchk(pred=P5, EA5), memberchk(fate=F5, EA5) ), E5),
    findall(N-P5, ( member(element(answered, _, AK5), RK5), member(AX5, AK5), x_el(AX5, failed, FA5),
                    memberchk(call=N, FA5), memberchk(pred=P5, FA5) ), A5),
    check('in the XML: <raised>, an <ended> a call, and <answered>',
          E5-A5, ['1'-'drive/1'-unwound, '6'-'give_up/1'-unwound]-['3'-'step/1', '5'-'ok_step/1']),
    atom_concat(D, '/rais1.svg', SF6),
    read_file_to_codes(SF6, SC6),
    xml_parse(SC6, S6),
    findall(T, ( svg_text(S6, T), memberchk(T, ['where the exception was raised', 'the failure it answered']) ), Ts6),
    check('and on the picture', Ts6, ['where the exception was raised', 'the failure it answered']).

%% ---- where a choice made the raise (1.11.7) -------------------------------

%% the panel the first call of P entered; the boxes of the throws its own
%% body made
entered_panel(run(_, _, _, _, Calls, _, _, _), P, Pn) :-
    memberchk(call(_, P, _, _, _, Pn, _, _, _, _), Calls).
own_throws(run(_, _, _, _, Calls, _, _, _), P, Bs) :-
    findall(B, ( member(call(_, P, _, _, _, _, Cl, _, _, _), Calls), member(thrown(B, _), Cl) ), Bs).

%% the predicates of a raise's chain
chain_preds(Chain, Ps) :-
    findall(P, member(ended(_, P, _, _), Chain), Ps).

%% a chose(C) or caught(K) answer's parts -- none, for an answer of none, so
%% a check names what it got rather than its section failing
chose_parts(chose(_, P, _, At, B, Cs), P, At, B, Cs) :- !.
chose_parts(_, none, none, none, []).
caught_parts(caught(_, P, _, At, R, H, K), P, At, R, H, K) :- !.
caught_parts(_, none, none, raised([], none), none, none).

%% the lines of BASE.txt from its first line equal to From
txt_from(D, Name, From, Ls) :-
    atomic_list_concat([D, '/', Name, '.txt'], F),
    read_file_to_codes(F, Cs), atom_codes(A, Cs),
    atomic_list_concat(L0, '\n', A),
    append(_, [From|Ls], L0), !.

raised_choice(D) :-
    section('flow_why_raised/3: the branch a choice took and the conditions it ran (1.11.7)'),
    %% cicili-lang's report: cpp_not_abstract/1 raised from the then of a
    %% condition that HELD after one that failed (a builtin, nb_getval/2,
    %% inside a catch/3), and 1.11.4's answer named an older failure further
    %% out that had nothing to do with it
    debugged(D, chos1, build([solid]), [], [txt(true)], R1),
    flow_why_raised(R1, raised(C1, A1), [chose(H1), caught(K1)]),
    chain_preds(C1, Ps1),
    chose_parts(H1, HP1, HAt1, HB1, HC1),
    why_shape(HC1, Xs1),
    entered_panel(R1, shape_ok/1, Pn1),
    atom_concat(Pn1, '.c1.g1', Ite1),
    ( HAt1 == Ite1 -> At1 = its_ite ; At1 = HAt1 ),
    check('build([solid]): raised in the then of shape_ok/1''s fourth arm -- three conditions failed (a builtin whose exception its catch took and the recovery''s fail/0, a call no head was for, a call that failed in its clause) and the fourth held',
          Ps1-HP1-At1-HB1-Xs1-K1,
          [build/1, shapes_ok/1, shape_ok/1, refuse_shape/1]-(shape_ok/1)-its_ite-then(4)
          -[ended(nb_getval/2, raised), failed(fail/0), why(round_shape/1, []),
            why(sized_shape/1, [entered(1, [exited(shape_area/2), failed((>)/2)])]),
            exited(abstract_shape/1)]
          -none),
    ( A1 = why(_, AP1, _, _) -> true ; AP1 = A1 ),
    check('...and what it answered is the last of them that failed having tried a clause -- not build/1''s sized/1, an if-then-else over before the raise',
          AP1, sized_shape/1),
    own_throws(R1, refuse_shape/1, TB2),
    entered_panel(R1, refuse_shape/1, Pn2),
    atom_concat(Pn2, '.c1.g1', T2),
    check('the throw/1 of refuse_shape/1''s own body is on its box, among the clauses of its call', TB2, [T2]),
    txt_from(D, chos1, '% where the exception was raised:', TL3),
    format(atom(BL3), '% the branch it was raised in: the then of arm 4 (its condition held), at ~w in shape_ok(solid) (call 7); the conditions it ran:', [Ite1]),
    check('at the foot of BASE.txt', TL3,
          [ '%  build([solid]): unwound (call 1)',
            '%    shapes_ok([solid]): unwound (call 6)',
            '%      shape_ok(solid): unwound (call 7)',
            '%        refuse_shape(solid): unwound (call 21)',
            BL3,
            '%  nb_getval(''$flow_test_shape'',yes): raised, and a catch took the exception (call 10)',
            '%  fail: failed, nothing of the program''s to say why (call 11)',
            '%  round_shape(solid): failed, no clause''s head unified (call 13)',
            '%  sized_shape(solid): failed in its clauses (call 15)',
            '%  abstract_shape(solid): exited (call 19)',
            '% the failure it answered, where it got furthest:',
            '%  sized_shape(solid): clause 1, the furthest of 1 tried: 1 of its calls exited (call 15)',
            '%    >(0,0): failed, nothing of the program''s to say why (call 17)',
            '' ]),
    format(atom(TT4), '[c1 threw:~w]', [T2]),
    txt_from(D, chos1, '% file: test/flowdebug/run.pl', CL4),
    ( member(L4, CL4), sub_atom(L4, 0, _, _, '21 '), sub_atom(L4, _, _, _, TT4) -> Y4 = yes ; Y4 = no ),
    check('...and refuse_shape/1''s line says where its body threw', Y4, yes),
    atom_concat(D, '/chos1.xml', XF5),
    read_file_to_codes(XF5, XC5),
    xml_parse(XC5, X5),
    once(x_sub(X5, raised, element(raised, _, RK5))),
    ( member(element(chose, CA5, CK5), RK5) -> true ; CA5 = [], CK5 = [] ),
    findall(N5, member(element(N5, _, _), CK5), Ns5),
    ( memberchk(branch=Br5, CA5) -> true ; Br5 = none ),
    ( memberchk(n=Nn5, CA5) -> true ; Nn5 = none ),
    findall(B5, ( x_sub(X5, call, element(call, CA5b, CK5b)), memberchk(pred='refuse_shape/1', CA5b),
                  member(element(thrown, TA5, _), CK5b), memberchk(box=B5, TA5) ), Bs5),
    check('in the XML: <chose branch="then" n="4"> with an element a condition, and a <thrown box> in refuse_shape/1''s <call>',
          Br5-Nn5-Ns5-Bs5, then-'4'-[ended, failed, failed, failed, exited]-[T2]),
    atom_concat(D, '/chos1.svg', SF6),
    read_file_to_codes(SF6, SC6),
    xml_parse(SC6, S6),
    findall(T6, ( svg_text(S6, T6), sub_atom(T6, 0, _, _, 'the branch it was raised in') ), Ts6),
    length(Ts6, NT6),
    check('and on the picture', NT6, 1),
    %% a throw/1 written in the else: no call is there, and the choice is
    %% read from where the throw stands
    debugged(D, chos2, checked_up(5), [], [], R7),
    flow_why_raised(R7, raised(_, A7), [chose(H7)]),
    chose_parts(H7, HP7, _, HB7, HC7),
    why_shape(HC7, Xs7),
    ( A7 = why(_, AP7, _, _) -> true ; AP7 = A7 ),
    check('checked_up(5): its throw/1 is written in the else -- every condition failed, up_step/1 in its clause, and that is what it answered',
          HP7-HB7-Xs7-AP7,
          (checked_up/1)-else-[why(up_step/1, [entered(1, [exited((>)/2), why(ok_up/1, [])])])]-(up_step/1)).

raised_caught(D) :-
    section('flow_why_raised/3: a raise in a catch''s recovery, and the exception the catch took (1.11.7)'),
    debugged(D, caug1, build_stop([solid]), [], [txt(true)], R1),
    flow_why_raised(R1, raised(C1, A1), [chose(H1), caught(K1)]),
    chain_preds(C1, Ps1),
    caught_parts(K1, KP1, KAt1, raised(KC1, KA1), KH1, KK1),
    chain_preds(KC1, Qs1),
    ( KH1 = chose(_, KHP1, _, _, KHB1, _) -> true ; KHP1 = none, KHB1 = none ),
    ( KA1 = why(_, KAP1, _, _) -> true ; KAP1 = KA1 ),
    entered_panel(R1, build_stop/1, Pn1),
    atom_concat(Pn1, '.c1.g1', Catch1),
    ( KAt1 == Catch1 -> At1 = its_catch ; At1 = KAt1 ),
    check('build_stop([solid]): raised by stop_with/1 under the recovery''s say_stop/1 -- and the exception the catch took was the builder''s, from shape_ok/1''s fourth arm',
          Ps1-A1-H1-KP1-At1-Qs1-KHP1-KHB1-KAP1-KK1,
          [build_stop/1, say_stop/1, stop_with/1]-none-none-(build_stop/1)-its_catch
          -[build/1, shapes_ok/1, shape_ok/1, refuse_shape/1]-(shape_ok/1)-then(4)-(sized_shape/1)-none),
    debugged(D, caug2, build_throw([solid]), [], [], R2),
    flow_why_raised(R2, raised(C2, _), [caught(K2)]),
    chain_preds(C2, Ps2),
    ( K2 = caught(_, KP2, _, _, raised(KC2, _), _, _) -> chain_preds(KC2, Qs2) ; KP2 = none, Qs2 = none ),
    own_throws(R2, build_throw/1, TB2),
    entered_panel(R2, build_throw/1, Pn2),
    atom_concat(Pn2, '.c1.g1.recover.g1', T2),
    check('build_throw([solid]): a recovery that only throws again -- the run raised there, at its throw/1, not in the builder, whose exception the catch took',
          Ps2-KP2-Qs2-TB2, [build_throw/1]-(build_throw/1)-[build/1, shapes_ok/1, shape_ok/1, refuse_shape/1]-[T2]),
    debugged(D, caug3, build_again([solid]), [], [], R3),
    flow_why_raised(R3, raised(C3, _), [caught(K3)]),
    chain_preds(C3, Ps3),
    ( K3 = caught(_, KP3, _, _, _, _, _) -> true ; KP3 = none ),
    own_throws(R3, build_again/1, TB3),
    entered_panel(R3, build_again/1, Pn3),
    atom_concat(Pn3, '.c1.g1.recover.g2', T3),
    check('build_again([solid]): says the error, then throws it again -- in the recovery too', Ps3-KP3-TB3,
          [build_again/1]-(build_again/1)-[T3]),
    txt_from(D, caug1, '% where the exception was raised:', TL4),
    format(atom(KL4), '% it was raised in the recovery of the catch/3 at ~w in build_stop([solid]) (call 1); the exception that catch took:', [Catch1]),
    ( append(Top4, [KL4|In4], TL4) -> true ; Top4 = TL4, In4 = [] ),
    ( In4 = [I4a, I4b|_] -> true ; I4a = none, I4b = none ),
    check('at the foot of BASE.txt, the exception the catch took told under its own line',
          Top4-I4a-I4b,
          [ '%  build_stop([solid]): unwound (call 1)',
            '%    say_stop(error(abstract(solid),shape_ok/1)): unwound (call 25)',
            '%      stop_with(abstract(solid)): unwound (call 27)',
            '% the failure it answered: none -- no call failed, having tried a clause, before the raise on its way down' ]
          -'%   where the exception was raised:'-'%    build([solid]): unwound (call 3)'),
    atom_concat(D, '/caug1.xml', XF5),
    read_file_to_codes(XF5, XC5),
    xml_parse(XC5, X5),
    ( x_sub(X5, caught, element(caught, KA5, KK5)) -> true ; KA5 = [], KK5 = [] ),
    ( memberchk(pred=KPr5, KA5) -> true ; KPr5 = none ),
    findall(N5, ( member(element(raised, _, RK5), KK5), member(element(N5, _, _), RK5) ), Ns5),
    check('in the XML: <caught pred> holding the <raised> it took -- its <ended> calls, its <chose> and its <answered>',
          KPr5-Ns5, 'build_stop/1'-[ended, ended, ended, ended, chose, answered]),
    atom_concat(D, '/caug1.svg', SF6),
    read_file_to_codes(SF6, SC6),
    xml_parse(SC6, S6),
    format(atom(KT6), 'raised in the recovery of the catch/3 at ~w in build_stop([solid]) (call at 1): the exception that catch took', [Catch1]),
    ( svg_text(S6, KT6) -> Y6 = yes ; Y6 = no ),
    check('and on the picture', Y6, yes).

raised_place(D) :-
    section('flow_why_raised/3 where no choice made the raise: the clause before, an if-then-else that was over (1.11.7)'),
    debugged(D, plac1, fallback_up(5), [], [], R1),
    flow_why_raised(R1, raised(_, A1), [chose(H1)]),
    ( A1 = why(_, AP1, _, _) -> true ; AP1 = A1 ),
    check('fallback_up(5): its second clause threw because its first failed -- what it answered is settled/1, the else of the first clause''s if-then-else, though the raise is in no construct of that clause',
          H1-AP1, none-(settled/1)),
    debugged(D, plac2, give_up_after(5), [], [], R2),
    flow_why_raised(R2, raised(_, A2), [chose(H2)]),
    check('give_up_after(5): a throw after an if-then-else that is over -- its failed condition is no part of why, and none of its branches chose the raise',
          H2-A2, none-none),
    debugged(D, plac3, noted_up(1), [], [], R3),
    flow_why_raised(R3, _, [chose(H3)]),
    own_throws(R3, noted_up/1, TB3),
    entered_panel(R3, noted_up/1, Pn3),
    atom_concat(Pn3, '.c1.g2', T3),
    check('noted_up(1): the then''s last call exited and the throw comes after the whole if-then-else, on its own box -- no branch chose it',
          H3-TB3, none-[T3]),
    atom_concat(D, '/plac3.svg', SF4),
    read_file_to_codes(SF4, SC4),
    xml_parse(SC4, S4),
    findall(T4, ( svg_text(S4, T4), sub_atom(T4, _, _, _, 'an exception raised by') ), By4),
    findall(T4b, ( svg_text(S4, T4b), sub_atom(T4b, _, _, _, 'an exception raised at step') ), At4),
    length(At4, NAt4),
    check('...and the banner names no call as its raiser: through 1.11.4 it named note/1, the last call made, which had exited',
          By4-NAt4, []-1).

raised_undrawn(D) :-
    section('flow_why_raised/3 from a small top file: the clauses its chart does not draw (1.11.7)'),
    atomic_list_concat([D, '/undr1'], B1),
    flow_debug(top_build([solid]), B1, [source('test/flowdebug/top.pl'), txt(true)], R1),
    flow_why_raised(R1, raised(C1, _), [chose(H1)]),
    chain_preds(C1, Ps1),
    chose_parts(H1, HP1, HAt1, HB1, HC1),
    why_shape(HC1, Xs1),
    own_throws(R1, refuse_shape/1, TB1),
    check('top_build([solid]): placed in run.pl''s clauses as read from the file -- shape_ok/1#c1.g1, the if-then-else that chose; by default its conditions explained as calls with no panel',
          Ps1-HP1-HAt1-HB1-Xs1-TB1,
          [top_build/1, build/1, shapes_ok/1, shape_ok/1, refuse_shape/1]-(shape_ok/1)-'shape_ok/1#c1.g1'-then(4)
          -[ended(nb_getval/2, raised), failed(fail/0), failed(round_shape/1), failed(sized_shape/1), exited(abstract_shape/1)]
          -['refuse_shape/1#c1.g1']),
    flow_why_raised(R1, _, [own(all), chose(H2)]),
    chose_parts(H2, _, _, _, HC2),
    why_shape(HC2, Xs2),
    check('...and with own(all), each by its clauses', Xs2,
          [ended(nb_getval/2, raised), failed(fail/0), why(round_shape/1, []),
           why(sized_shape/1, [entered(1, [exited(shape_area/2), failed((>)/2)])]),
           exited(abstract_shape/1)]),
    R1 = run(_, _, _, _, Calls3, _, _, _),
    findall(Bx3, member(call(_, abstract_shape/1, _, _, Bx3, _, _, _, _, _), Calls3), Bxs3),
    check('...abstract_shape/1''s call at its place in that clause', Bxs3, ['shape_ok/1#c1.g1.a4.if.g1']),
    atomic_list_concat([D, '/undr2'], B4),
    flow_debug(top_stop([solid]), B4, [source('test/flowdebug/top.pl')], R4),
    flow_why_raised(R4, _, [caught(K4)]),
    (   K4 = caught(_, KP4, _, KAt4, _, chose(_, _, _, KHAt4, KHB4, _), _) -> true
    ;   KP4 = none, KAt4 = none, KHAt4 = none, KHB4 = none
    ),
    check('top_stop([solid]): the catch in build_stop/1''s clause read from the file, and the choice inside the exception it took',
          KP4-KAt4-KHAt4-KHB4, (build_stop/1)-'build_stop/1#c1.g1'-'shape_ok/1#c1.g1'-then(4)),
    %% a predicate the chart draws, called again from a clause read from
    %% the file: that call is walked in the predicate's own panel
    atomic_list_concat([D, '/undr3'], B5),
    flow_debug(top_hooked([round, solid]), B5, [source('test/flowdebug/top.pl')], R5),
    flow_why_raised(R5, _, [chose(H5)]),
    chose_parts(H5, HP5, HAt5, HB5, _),
    entered_panel(R5, top_hook/1, Pn5),
    atom_concat(Pn5, '.c1.g1', Ite5),
    atom_concat(Ite5, '.a1.g1', T5),
    own_throws(R5, top_hook/1, TB5),
    ( HAt5 == Ite5 -> At5 = its_ite ; At5 = HAt5 ),
    check('top_hooked([round, solid]): top_hook/1, which the chart draws, called again from each_hook/2''s clause read from the file -- walked in its own panel, its throw placed there and the then that chose it named',
          HP5-At5-HB5-TB5, (top_hook/1)-its_ite-then(1)-[T5]).

%% ---- a call that tried many heads -----------------------------------------

many_heads :-
    section('a call that tried many heads costs the matcher their number, not its square'),
    %% through 1.11.1 each head was appended to the call's list: n heads
    %% copied n * n / 2 cells (the reasoning session's 20,000 took 19 s
    %% more than none), and the list is now built backwards and turned
    %% round once
    many_heads_cost(5000, I1, F1-L1),
    many_heads_cost(10000, I2, F2-L2),
    R is I2 / I1,
    ( R < 2.5 -> Grows = linearly ; Grows = R ),
    check('10,000 heads of one call cost the matcher twice what 5,000 do, and come out in the order tried',
          Grows-F1-L1-F2-L2, linearly-nohead(1, 1)-nohead(5000, 1)-nohead(1, 1)-nohead(10000, 1)).

%% the inferences flow_dbg_index/3 spends on the events of a call that
%% tried N heads, and its first and last head
many_heads_cost(N, I, F-L) :-
    numlist(1, N, Ks),
    findall(nohead(1, 1, 100, K), member(K, Ks), Hs),
    append([[call(1, 1, 100, 0, f, [a])], Hs, [fail(1, 1, 100, f, [a])]], Es),
    statistics(inferences, I0),
    flow_dbg_index(Es, [c(_, _, _, _, Cl, _, _, _)], _),
    statistics(inferences, I1),
    I is I1 - I0,
    Cl = [F|_],
    last(Cl, L).

%% ---- refusals -----------------------------------------------------------

refusals(D) :-
    section('refusals, by name'),
    atomic_list_concat([D, '/no'], B),
    fx(F),
    answer(flow_debug(_, B, [source(F)]), x, G1),
    answer(flow_debug(top(5, _), B, []), x, G2),
    answer(flow_debug(top(5, _), B, [source(F), view(sideways)]), x, G3),
    answer(flow_debug(top(5, _), B, [source(F), until(never)]), x, G4),
    answer(flow_debug(top(5, _), B, [source(F), window(-1)]), x, G5),
    answer(flow_debug(top(5, _), B, [source(F), journal(maybe)]), x, G6),
    answer(flow_debug(top(5, _), B, [source(F), journal_file(7)]), x, G7),
    answer(flow_debug(top(5, _), B, [source(F), txt(maybe)]), x, G8),
    check('an unbound goal, no source, a view, an until, a window, a journal and a txt it does not take',
          [G1, G2, G3, G4, G5, G6, G7, G8],
          [ error(error(instantiation_error, flow_debug/3)),
            error(error(existence_error(flow_option, source), flow_debug/3)),
            error(error(domain_error(flow_view, sideways), flow_debug/3)),
            error(error(domain_error(flow_until, never), flow_debug/3)),
            error(error(domain_error(flow_debug_option, window(-1)), flow_debug/3)),
            error(error(domain_error(flow_debug_option, journal(maybe)), flow_debug/3)),
            error(error(domain_error(flow_debug_option, journal_file(7)), flow_debug/3)),
            error(error(domain_error(flow_debug_option, txt(maybe)), flow_debug/3)) ]),
    atomic_list_concat([D, '/nope'], Nope),
    answer(flow_debug(top(5, _), B, [source(F), embed(Nope)]), x, G9),
    answer(flow_debug(top(5, _), B, [source(F), kb(other)]), x, G10),
    answer(flow_debug(top(5, _), B, [source(F), embed(D), kb(7)]), x, G11),
    answer(flow_debug(top(5, _), B, [source(F), cache(7)]), x, G12),
    answer(flow_when(top(5, _), true, [source(F), kb(other)], _), x, G13),
    check('a store that is not there, a kb(Name) with no store, and a kb or a cache that is not a name -- flow_when/4''s too',
          [G9, G10, G11, G12, G13],
          [ error(error(existence_error(directory, Nope), flow_debug/3)),
            error(error(existence_error(flow_option, embed), flow_debug/3)),
            error(error(domain_error(flow_debug_option, kb(7)), flow_debug/3)),
            error(error(domain_error(flow_debug_option, cache(7)), flow_debug/3)),
            error(error(existence_error(flow_option, embed), flow_when/4)) ]),
    answer(flow_debug(top(5, _), B, [source(F), own(nobody)]), x, G14),
    answer(flow_debug(top(5, _), B, [source(F), own([Nope])]), x, G15),
    check('an own(...) that is neither chart, all nor files that are there',
          [G14, G15],
          [ error(error(domain_error(flow_debug_option, own(nobody)), flow_debug/3)),
            error(error(domain_error(flow_debug_option, own([Nope])), flow_debug/3)) ]).

%% the elements among a node's children (an indented document has text
%% between them)
elements(Ks, Es) :-
    findall(E, ( member(E, Ks), nonvar(E), E = element(_, _, _) ), Es).
