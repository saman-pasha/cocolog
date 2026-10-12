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
%%   go(30, R)     a recursion seen through a window of its last 100
%%                 inferences, and go(12, R) drawn as a tree
%%   flip(F)       a run that is not the same twice -- and with a journal is
%%   grow(F)       a run that loads a file it then appends to, which leaves
%%                 its journal
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
    check('...the clause each entered, and the head that did not unify',
          Cls1, [top/2-[c(1, 1)], pos/2-[c(1, 5)], bad/1-[nohead(1, 7)]]).

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
    section('a window of the last 100 inferences of a recursion'),
    debugged(D, nrevw, go(30, R8), ['R'=R8], [window(100)], Run8),
    Run8 = run(How8, At8, _, window(F8, T8), Calls8, _, _, _),
    metered(go(30, _), U8),
    F8x is U8 - 99,
    check('go(30, R): it answers where the untraced run does, and the window is its last 100 inferences',
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
    debugged(D, nrevt, go(12, R9), ['R'=R9], [view(tree)], _),
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
    check('...on the picture and in the XML', Said10-DA10-PE10, said-true-answer).

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
    check('...in the XML: the <run> says so, each <portal> is the <call> the window saw at its inference',
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
    (   svg_text(S6, T6), sub_atom(T6, 0, _, _, 'THE REPLAY LEFT ITS JOURNAL at inference 7') -> Said6 = said ; Said6 = silent ),
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
    section('flow_when/4: the first inference at which a question holds, searched over runs'),
    fx(F),
    flow_when(fill(L1), (nth1(3, L1, X1), X1 == 3), [source(F)], W1),
    ( W1 = at(I1) -> call_at(D, at1, fill(_), I1, C1) ; C1 = W1 ),
    check('fill(L): the third element is 3 from the call that bound it, X = I with I 3',
          C1, (=)/2-['_', '3']),
    flow_when(fill(L2), (nth1(3, L2, X2), X2 == 3), [source(F), journal(false)], W2),
    flow_when(fill(L3), (nth1(3, L3, X3), X3 == 3), [source(F), step(5)], W3),
    check('...the same without a journal, and stepping five inferences at a time first', W2-W3, W1-W1),
    flow_when(fill(L4), (nth1(3, L4, X4), X4 == 4), [source(F)], W4),
    check('a question that does not hold where the run ends: never', W4, never),
    flow_when(pick(P5), P5 == 1, [source(F)], W5),
    flow_when(pick(P6), P6 == 1, [source(F), step(1)], W6),
    ( W6 = at(I6) -> call_at(D, at6, pick(_), I6, C6) ; C6 = W6 ),
    check('pick(X): X = 1 is undone by backtracking, so not where the run ends -- never; asked at every inference, member/2''s call made it so',
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
    debugged(D, whyok, top(5, Y4), ['Y'=Y4], [], R4),
    flow_why(R4, W4),
    atom_concat(D, '/whyok.xml', XF4),
    read_file_to_codes(XF4, XC4),
    xml_parse(XC4, X4),
    ( x_el(X4, why, _) -> Y4w = said ; Y4w = none ),
    ( W4 = [exited(1, top/2, _, _)] -> W4s = exited ; W4s = W4 ),
    check('a run that answered: its top call exited, and no <why>', W4s-Y4w, exited-none).

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
    ( last(Ls1, L1) -> true ; L1 = '' ),
    check('it writes BASE.svg and BASE.xml, says how the run ended, and exits 0',
          E1-Y1-L1, 0-yes-'find(z, V): false at inference 7; recorded 1 to 7; diverged no'),
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
    ( last(Ls4, L4), atomic_list_concat([_, Tail4], '; diverged no', L4) -> true ; Tail4 = T4 ),
    check('journal=true: the line says how many portal calls the journal held, and how many answered the replay',
          E4-Tail4, 0-'; journal 6 portal calls, 6 answered'),
    atomic_list_concat([D, '/cmdw'], B5),
    atomic_list_concat(['-s tools/flow/debug.pl -- \'fill(L)\' ', F, ' ', B5, ' \'when=nth1(3, L, X), X == 3\' window=4'], A5),
    cocolog_run(A5, T5, E5),
    atomic_list_concat(Ls5, '\n', T5),
    ( last(Ls5, L5) -> true ; L5 = '' ),
    atom_concat(B5, '.svg', SF5),
    yes_no(exists_file(SF5), Y5),
    check('when=COND: where the question first holds, and the window of the last 4 inferences up to it drawn',
          E5-Y5-L5, 0-yes-'fill(L): (nth1(3, L, X), X == 3) first holds at inference 26; recorded 23 to 26').

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
    check('an unbound goal, no source, a view, an until, a window and a journal it does not take',
          [G1, G2, G3, G4, G5, G6, G7],
          [ error(error(instantiation_error, flow_debug/3)),
            error(error(existence_error(flow_option, source), flow_debug/3)),
            error(error(domain_error(flow_view, sideways), flow_debug/3)),
            error(error(domain_error(flow_until, never), flow_debug/3)),
            error(error(domain_error(flow_debug_option, window(-1)), flow_debug/3)),
            error(error(domain_error(flow_debug_option, journal(maybe)), flow_debug/3)),
            error(error(domain_error(flow_debug_option, journal_file(7)), flow_debug/3)) ]).

%% the elements among a node's children (an indented document has text
%% between them)
elements(Ks, Es) :-
    findall(E, ( member(E, Ks), nonvar(E), E = element(_, _, _) ), Es).
