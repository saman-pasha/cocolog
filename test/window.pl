%% The inference clock and a window of a run, recorded (1.10.12) -- what
%% library(flow/debug) stands on (DESIGN-flow.md 9.1 and 9.5).
%%
%% THE CLOCK. A run is explained by replaying it, numbered by the
%% inferences an untraced run spent, so the count must be the same however
%% the run is watched. Through 1.10.11 it was not: the tracer's Exit marker
%% was taken as a step (naive reverse of eight, 47 inferences, counted 93
%% under --trace), and a machine stopped at its budget counted the goal it
%% stopped at twice (47 stepped ten at a time finished after 51). Both are
%% held here: a traced and an untraced run count alike, and a machine
%% stepped in turns finishes at the count of one run.
%%
%% THE WINDOW. `'$trace_window'(Goal, Options, Events, End)' proves Goal
%% untraced up to the inference a window opens at and records from there.
%% A window is held to a recording of the whole run -- the same events at
%% the same inferences -- whether it opens in the goal's own engine or
%% inside findall/3's, and to its contract: how a run ends, its answers,
%% an exception raised and caught, an argument cut at its length, the
%% refusals, and nothing bound afterwards.
%%
%%     cocolog -s test/window.pl        from the checkout root
%%
%% Children only where they must be: --trace is a command-line switch, and
%% a stepped machine is saved by one process and taken up by the next.

:- use_module('test/prelude.pl').
:- use_module('test/trace-program.pl').

main :-
    clock, printed, turns, window, tried, asked, checks_done.

%% ---- the programs the windows watch -----------------------------------

w_app([], L, L).
w_app([H|T], L, [H|R]) :- w_app(T, L, R).

w_nrev([], []).
w_nrev([H|T], R) :- w_nrev(T, RT), w_app(RT, [H], R).

w_go(R) :- w_nrev([1,2,3], R).

w_pick(X) :- member(X, [1,2,3]), X > 1.

w_all(L) :- findall(X-Y, ( member(X, [1,2]), w_nrev([X,Y0], [Y|_]), Y = Y0 ), L).

w_bad(X) :- X is foo + 1.

w_safe(E) :- catch(w_bad(_), E, true).

%% garbage, and a collection asked for every thousand turns -- one step
%% whether a collection runs or not, so a run that collects and one that
%% does not count alike
w_churn(0) :- !.
w_churn(N) :-
    _ = f(N, [N, N, N]),
    ( N mod 1000 =:= 0 -> garbage_collect ; true ),
    N1 is N - 1,
    w_churn(N1).

%% a call that exits and is backtracked past with no clause left to try
w_look(K, V) :- w_pairs(Ps), member(K-V, Ps).
w_pairs([a-1, b-2]).

%% heads the selection tries and heads the index passes over (1.11.2): a
%% call keyed on its first argument tries only the clauses whose first
%% argument could match it, and one unbound there tries them all
w_kv(a, 3).
w_kv(b, 2).
w_kv(d, 3).
w_kvs(K) :- w_kv(K, 3), K \== a.

%% a list filled one element at a time; a loop; and a term made before
%% collections, for a question asked after them (1.10.16)
w_fill(L) :- length(L, 3), w_fill_(L, 1).
w_fill_([], _).
w_fill_([X|Xs], I) :- X = I, I1 is I + 1, w_fill_(Xs, I1).
w_loop :- w_loop.
w_hold(L, N) :- L = [a, b, c], w_churn(N), numlist(1, 50000, _).
%% garbage left below whatever is built next: a list nothing keeps
w_junk :- numlist(1, 20000, _).
%% the window's goal and its question built on top of that garbage, so a
%% collection in the run slides them down, and the list the run ends by
%% building lands where they were
w_asked_gc(H) :- '$trace_window'(w_hold(L, 5000), [ask(L == [a, b, c], H)], _, _).

%% garbage below, and a collection asked for between two readings of the
%% collector's count, inside a call whose Exit comes after it
w_gc :- w_churn(500), w_gc2.
w_gc2 :- w_hc(_), garbage_collect, w_hc(_).
w_hc(N) :- statistics(heap_collections, N).

%% ---- the clock ---------------------------------------------------------

clock :-
    section('the clock: a traced run counts what an untraced run counts'),
    %% the trace case's queries over its own program, each counted untraced
    %% and recorded from its first inference
    findall(Q-U-R, ( clock_query(Q),
                     G = ( Q -> true ; true ),
                     '$trace_window'(G, [], _, end(H, U, _)),
                     '$trace_window'(G, [from(1)], _, end(H, R, _)),
                     U \== R ),
            Off1),
    check('the trace case''s 33 queries: recorded, each counts what it counts untraced', Off1, []),
    %% and printed: --trace on the command line, against the same run without
    findall(P-A-B, ( member(P-Goal, [ 'nrev.pl'-'main(30,2)', 'queens.pl'-'main(6,1)',
                                      'lookup.pl'-'main(50,2)' ]),
                     clock_counted(P, Goal, '', A),
                     clock_counted(P, Goal, '--trace ', B),
                     A \== B ),
            Off2),
    check('nrev, queens and lookup under --trace count what they count untraced', Off2, []),
    %% D0's own pair: 47 and 93 on 1.10.11
    clock_counted_file(Untraced3, ''),
    clock_counted_file(Traced3, '--trace '),
    check('naive reverse of eight: 47 inferences, traced and untraced', Untraced3-Traced3, 47-47).

clock_query(Q) :-
    member(Q, [ (anc(tom, _), fail), anc(tom, ann), anc(ann, _), sum([1,2], _),
                (sum([1,2,3], S), S > 5), (pick(_), fail), pick(b), fst(_, [7,8]),
                (memb(X, [1,2]), X > 1), memb(9, [1,2]), classify(-3, _), classify(0, _),
                classify(7, _), either(5), either(1), 3 < 2, _ = f(_), atom(foo),
                (Y is 2 + 2, Y > 3), np(2), np(1), len3(abc), len3(ab),
                cutfail, cpos(5), cpos(-1), (cmem(_), fail), (cmem(Z), Z > 1),
                (cor(_), fail), cin(5), (cutfail ; true), sib, csib ]),
    S = S, X = X, Y = Y, Z = Z.

%% the inferences between two statistics/2 calls around Goal, in a child,
%% with SWITCHES on the command line
clock_counted(Program, Goal, Switches, N) :-
    cocolog(C),
    sh_join([C, ' ', Switches, 'run bench/langs/', Program, ' "statistics(inferences, A), ',
             Goal, ', statistics(inferences, B), D is B - A, format(''count(~w)~n'', [D])" 2>/dev/null'],
            Cmd),
    proc_run(Cmd, 120000, Out, _),
    (   re_first_atom('count\\([0-9]+\\)', Out, A1) -> sub_atom(A1, 6, _, 1, T), atom_number(T, N)
    ;   N = none
    ).

clock_counted_file(N, Switches) :-
    scratch(D),
    atom_concat(D, '/nrev8.pl', F),
    fixture(F, [ 'app([], L, L).',
                 'app([H|T], L, [H|R]) :- app(T, L, R).',
                 'nrev([], []).',
                 'nrev([H|T], R) :- nrev(T, RT), app(RT, [H], R).',
                 'go(R) :- nrev([1,2,3,4,5,6,7,8], R).' ]),
    cocolog(C),
    sh_join([C, ' ', Switches, 'run ', F, ' "call_metered(go(_), 1000000, U, _), format(''count(~w)~n'', [U])" 2>/dev/null'], Cmd),
    proc_run(Cmd, 120000, Out, _),
    (   re_first_atom('count\\([0-9]+\\)', Out, A1) -> sub_atom(A1, 6, _, 1, T), atom_number(T, N)
    ;   N = none
    ),
    shl(['rm -rf ', D]).

%% ---- the recorder and the printer --------------------------------------
%%
%% THE RECORDER RECORDS THE PORTS THE PRINTER PRINTS, and the printer is
%% held to SWI's by the trace case. A retry prints its Redo only once it
%% enters a clause: through 1.10.12 a window recorded one as every retry
%% began, so a call that had exited and was backtracked past with no clause
%% left -- which goes quietly -- showed a Redo the printer never printed,
%% and a call that failed out loud showed a Redo before its Fail.

printed :-
    section('the recorder records the ports the printer prints, one for one'),
    findall(Q-R1-P1, ( clock_query(Q),
                       G = ( Q -> true ; true ),
                       recorded_ports(G, R1),
                       printed_ports('test/trace-program.pl', G, P1),
                       R1 \== P1 ),
            Off1),
    check('the trace case''s 33 queries: the same ports, at the same depths, of the same goals', Off1, []),
    scratch(D),
    atom_concat(D, '/look.pl', F),
    fixture(F, [ 'w_look(K, V) :- w_pairs(Ps), member(K-V, Ps).', 'w_pairs([a-1, b-2]).' ]),
    recorded_ports(w_look(z, _), R2),
    printed_ports(F, w_look(z, _), P2),
    check('a call that exited and is backtracked past with no clause left goes quietly in both',
          R2-P2, P2-[ call-0-w_look, call-1-w_pairs, exit-1-w_pairs, call-1-member, call-2-member,
                      call-3-member, fail-3-member, fail-2-member, fail-1-member, fail-0-w_look ]),
    shl(['rm -rf ', D]).

%% Port-Depth-Name, each depth from the first port's
recorded_ports(G, Ps) :-
    '$trace_window'(G, [from(1)], Es, _),
    findall(K-D-N, ( member(E, Es), E =.. [K, _, D, _|Rest],
                     memberchk(K, [call, exit, fail, redo]),
                     ( K == call -> Rest = [_, N, _] ; Rest = [N, _] ) ),
            Ps0),
    rel_depths(Ps0, Ps).

printed_ports(File, G, Ps) :-
    format(atom(GA), '~q', [G]),
    cocolog(C),
    sh_join([C, ' --trace run ', File, ' "', GA, '" 2>&1 >/dev/null'], Cmd),
    proc_run(Cmd, 60000, Out, _),
    atom_codes(OA, Out),
    atomic_list_concat(Lines, '\n', OA),
    findall(P, ( member(L, Lines), atom_codes(L, LCs), phrase(port_line(P), LCs) ), Ps0),
    rel_depths(Ps0, Ps).

port_line(K-D-N) -->
    blanks, string_without(":", PCs), ": (", digits(DCs), ") ", remainder(GCs),
    { atom_codes(PA, PCs), port_kind(PA, K),
      number_codes(D, DCs),
      atom_codes(GA, GCs), catch(term_to_atom(G, GA), _, fail), functor(G, N, _) }.

port_kind('Call', call).
port_kind('Exit', exit).
port_kind('Fail', fail).
port_kind('Redo', redo).

rel_depths([], []).
rel_depths([K-D0-N|Ps], [K-0-N|Rs]) :-
    findall(K1-D1-N1, ( member(K1-D-N1, Ps), D1 is D - D0 ), Rs).

%% ---- a machine stepped in turns ---------------------------------------

turns :-
    section('a machine stepped in turns finishes at the count of one turn'),
    scratch(D),
    atom_concat(D, '/kb', KB),
    make_directory(KB),
    atom_concat(D, '/nrev8.pl', F),
    fixture(F, [ 'app([], L, L).',
                 'app([H|T], L, [H|R]) :- app(T, L, R).',
                 'nrev([], []).',
                 'nrev([H|T], R) :- nrev(T, RT), app(RT, [H], R).',
                 'go(R) :- nrev([1,2,3,4,5,6,7,8], R).',
                 'cnt(0, A, A) :- !.',
                 'cnt(N, A0, A) :- A1 = [N|A0], true, M is N - 1, cnt(M, A1, A).',
                 'go2(L) :- cnt(10, [], L).' ]),
    cocolog(C),
    sh_join(['timeout 60 ', C, ' --embed ', KB, ' consult ', F, ' >/dev/null 2>&1 && timeout 60 ',
             C, ' --embed ', KB, ' start tens "go(R)" >/dev/null 2>&1 && timeout 60 ',
             C, ' --embed ', KB, ' start one "go(R)" >/dev/null 2>&1 && timeout 60 ',
             C, ' --embed ', KB, ' start fives "go2(L)" >/dev/null 2>&1 && timeout 60 ',
             C, ' --embed ', KB, ' start once "go2(L)" >/dev/null 2>&1'], Setup),
    (   sh_exit(Setup, 0)
    ->  findall(At, ( between(1, 5, _),
                      sh_join(['timeout 60 ', C, ' --embed ', KB, ' --steps 10 step tens 2>&1'], Step),
                      proc_run(Step, 60000, Out, _),
                      ( re_first_atom('(suspended at|finished after) [0-9]+', Out, At) -> true ; At = none ) ),
                Ats),
        check('ten inferences a turn: suspended at 10, 20, 30, 40, finished after 47',
              Ats, ['suspended at 10', 'suspended at 20', 'suspended at 30',
                    'suspended at 40', 'finished after 47']),
        sh_join(['timeout 60 ', C, ' --embed ', KB, ' step one 2>&1'], One),
        proc_run(One, 60000, OneOut, _),
        ( re_first_atom('finished after [0-9]+', OneOut, At1) -> true ; At1 = none ),
        check('the same goal in one turn finishes after 47', At1, 'finished after 47'),
        %% A TURN'S BUDGET IS IN INFERENCES (1.12.2), and the steps that are
        %% none -- each of cnt/3's turns takes a `=/2' and a `true' -- are
        %% carried in the machine from one turn to the next
        findall(At2, ( between(1, 5, _),
                       sh_join(['timeout 60 ', C, ' --embed ', KB, ' --steps 5 step fives 2>&1'], Step2),
                       proc_run(Step2, 60000, Out2, _),
                       ( re_first_atom('(suspended at|finished after) [0-9]+', Out2, At2) -> true ; At2 = none ) ),
                Ats2),
        sh_join(['timeout 60 ', C, ' --embed ', KB, ' step once 2>&1'], Once3),
        proc_run(Once3, 60000, OnceOut3, _),
        ( re_first_atom('finished after [0-9]+', OnceOut3, At3) -> true ; At3 = none ),
        check('five inferences a turn of a goal whose `true\'s and `=/2\'s are none: the count of one turn, 24',
              Ats2-At3, ['suspended at 5', 'suspended at 10', 'suspended at 15', 'suspended at 20',
                         'finished after 24']-'finished after 24')
    ;   check('could set up a machine in a scratch store', failed, done)
    ),
    shl(['rm -rf ', D]).

%% ---- the window --------------------------------------------------------

window :-
    section('a window: how the run ends, and what it did'),
    answer('$trace_window'(w_go(_), [], E1, End1), E1-End1, G1),
    check('a probe records nothing and says how the run ended: its answer, at 12', G1,
          []-end(answer, 12, [12])),
    '$trace_window'(w_go(_), [from(1)], Es2, End2),
    maplist(win_key, Es2, Ks2),
    win_first(11, Ks2, Head2),
    %% w_nrev([], []) is not tried for a list: the index passes over it, and
    %% a head never tried is not one that did not match (1.11.2)
    check('from the first inference: the calls and the clauses they entered',
          Head2,
          [ call(1, w_go, ['_']), clause(1, 1), call(2, w_nrev, ['[1,2,3]', '_']),
            clause(2, 2), call(3, w_nrev, ['[2,3]', '_']), clause(3, 2),
            call(4, w_nrev, ['[3]', '_']), clause(4, 2),
            call(5, w_nrev, [[], '_']), clause(5, 1), exit(5, w_nrev, [[], []]) ]),
    check('...and it ends as the probe did', End2, end(answer, 12, [12])),
    last(Ks2, Last2),
    check('the goal''s own Exit is the last event, with what the proof bound', Last2,
          exit(11, w_go, ['[3,2,1]'])),
    win_paired(Es2, Unpaired2),
    check('every Exit, Fail and Redo names a call recorded before it, by its cell', Unpaired2, []),

    %% A WINDOW SEES THE CALLS MADE IN IT: a call that began before it was
    %% made untraced, with no Exit marker and no shadow of its frame, so its
    %% Exit, Redo and clauses are not in the window -- the events compared
    %% are those of calls made from the window's first inference on
    section('a window opened part way holds what a whole recording holds there'),
    '$trace_window'(w_go(_), [from(5), to(9)], Es3, End3),
    maplist(win_key, Es3, Ks3),
    win_span(Es2, 5, 9, Span2),
    check('from 5 to 9: the same events at the same inferences as the whole run''s', Ks3, Span2),
    check('...and it stops past 9', End3, end(limit, 9, [])),
    Es3 = [First3|_],
    arg(4, First3, Parent3),
    check('a call made inside a call that began before the window has no parent in it', Parent3, 0),
    %% A WINDOW'S LAST INFERENCE KEEPS ITS EXITS (1.12.2): w_nrev([], []) is
    %% called at 5 and exits by the tracer's marker, which gives back the
    %% step taking it -- the stop at 5 came before the marker through 1.12.1
    '$trace_window'(w_go(_), [from(5), to(5)], Es3b, _),
    maplist(win_key, Es3b, Ks3b),
    win_span(Es2, 5, 5, Span3b),
    check('to 5: the Exit at 5 a whole recording has, there too', Ks3b-Span3b,
          [call(5, w_nrev, [[], '_']), clause(5, 1), exit(5, w_nrev, [[], []])]-Ks3b),
    '$trace_window'(w_all(_), [from(1)], Es4, End4),
    '$trace_window'(w_all(_), [from(6), to(12)], Es5, _),
    maplist(win_key, Es5, Ks5),
    win_span(Es4, 6, 12, Span4),
    check('opened inside findall/3''s engine: the same events again, counted across both engines',
          Ks5, Span4),
    check('...and findall/3''s run ends where its probe does', End4, end(answer, 23, [23])),
    %% the collector runs on the way to the window -- garbage_collect/0 at
    %% the 3000th, 2000th and 1000th turns (six inferences a turn: the
    %% window is the last 850) -- and not in it, where a cell is a call's
    %% name
    '$trace_window'(w_churn(3000), [], _, end(_, Used6, _)),
    From6 is Used6 - 5100,
    statistics(heap_collections, C6a),
    '$trace_window'(w_churn(3000), [from(From6)], Es6, End6),
    statistics(heap_collections, C6b),
    '$trace_window'(w_churn(3000), [from(1)], Es6w, _),
    maplist(win_key, Es6, Ks6),
    win_span(Es6w, From6, Used6, Span6),
    ( C6b > C6a -> Coll6 = collected ; Coll6 = none ),
    check('garbage collected on the way, and the last 5100 inferences as a whole recording has them',
          Coll6-End6, collected-end(answer, Used6, [Used6])),
    check('...event for event', Ks6, Span6),
    win_paired(Es6, Unpaired6),
    check('...each Exit by the cell its Call had', Unpaired6, []),
    %% a collection asked for INSIDE the window does not come: the count
    %% read on either side of garbage_collect/0 is one number, and w_gc2's
    %% Exit names the cell its Call had -- in a window opened part way and in
    %% one recorded from the first inference
    '$trace_window'(w_gc, [], _, end(_, Used7, _)),
    From7 is Used7 - 6,
    '$trace_window'(w_gc, [from(From7)], Es7a, _),
    '$trace_window'(w_gc, [from(1)], Es7b, _),
    win_hc(Es7a, Hc7a), win_paired(Es7a, Un7a),
    win_hc(Es7b, Hc7b), win_paired(Es7b, Un7b),
    check('a collection asked for in the window does not come, and no cell moves',
          [Hc7a, Un7a, Hc7b, Un7b], [same, [], same, []]),

    section('answers, exceptions and texts'),
    '$trace_window'(w_pick(_), [from(1), answers(2)], Es7, End7),
    check('answers(2): the run goes on to the second answer, and says where each came',
          End7, end(answer, 9, [6, 9])),
    maplist(win_key, Es7, Ks7),
    win_kinds(Ks7, redo, Redo7),
    check('the Redo of member/2 after 1 > 1 fails, and after the first answer',
          Redo7, [redo(3, member, ['_', '[1,2,3]']), redo(6, member, ['_', '[2,3]'])]),
    '$trace_window'(w_safe(_), [from(1)], Es8, End8),
    maplist(win_key, Es8, Ks8),
    win_kinds(Ks8, throw, Th8), win_kinds(Ks8, catch, Ca8),
    check('a throw recorded in the body of the call that raised it, and where catch/3 took it',
          Th8-Ca8, [throw(4, 2, 'error(type_error(evaluable,foo/0),_)')]-[catch(4, 1)]),
    check('...and the run answers', End8, end(answer, 6, [6])),
    '$trace_window'(w_bad(_), [from(1)], _, End9),
    End9 = end(How9, Used9, Ats9),
    ( How9 = exception(error(type_error(evaluable, foo/0), _)) -> W9 = exception ; W9 = How9 ),
    check('an exception nothing caught ends the run, the ball handed back', W9-Used9-Ats9,
          exception-2-[]),
    numlist(1, 30, L10),
    '$trace_window'(w_nrev(L10, _), [from(1), to(1), text(10)], [Call10|_], _),
    Call10 = call(_, _, _, _, _, [Cut10|_]),
    check('text(10): an argument longer than ten characters is its first ten and its length',
          Cut10, cut('[1,2,3,4,5', 82)),
    answer(( '$trace_window'(w_go(R11), [from(1)], _, _), var(R11) ), unbound, G11),
    check('nothing the goal bound is bound afterwards', G11, unbound),

    section('refused by name'),
    win_refused([from(-1)], R12),
    win_refused([to(3), from(5)], R13),
    win_refused([answers(0)], R14),
    win_refused([depth(3)], R15),
    check('a negative from, a window ending before it opens, no answer asked, an option it does not know',
          [R12, R13, R14, R15], [domain, domain, domain, domain]),
    answer('$trace_window'(_, [], _, _), x, G16),
    ( G16 = error(error(instantiation_error, _)) -> W16 = instantiation ; W16 = G16 ),
    check('an unbound goal is an instantiation error', W16, instantiation),
    '$trace_window'('$trace_window'(true, [], _, _), [], _, End17),
    (   End17 = end(exception(error(permission_error(open, trace_window, _), _)), U17, _)
    ->  W17 = permission-U17
    ;   W17 = End17
    ),
    check('a window inside a window is refused, one recorder to a machine: the run''s exception',
          W17, permission-1).

%% ---- the heads tried ---------------------------------------------------
%%
%% A WINDOW RECORDS THE HEADS THE SELECTION TRIED (1.11.2). Through 1.11.1
%% every clause before the one entered was a head that did not match, the
%% ones the index passed over too: a failed call of a table of 32,046 facts
%% recorded 32,046 of them, most of a translator window's 31 MB of XML
%% (reported from the reasoning session). The heads are walked again with
%% the key the selection read, kept before it bound the call -- the clause
%% entered may bind the argument the call is keyed on.

tried :-
    section('the heads a window records are the ones the selection tried'),
    win_keys(w_kv(_, 2), K1),
    check('w_kv(K, 2): K unbound, so every clause is tried -- w_kv(a, 3) did not match, w_kv(b, 2) entered and bound K',
          K1, [call(1, w_kv, ['_', '2']), nohead(1, 1), clause(1, 2), exit(1, w_kv, [b, '2'])]),
    win_keys(w_kv(d, _), K2),
    check('w_kv(d, V): the index passes over the clauses for a and b, and they are not recorded',
          K2, [call(1, w_kv, [d, '_']), clause(1, 3), exit(1, w_kv, [d, '3'])]),
    win_keys(w_kv(e, _), K3),
    check('w_kv(e, V): no clause is for e -- none tried, none recorded, and the call fails',
          K3, [call(1, w_kv, [e, '_']), fail(1, w_kv, [e, '_'])]),
    win_keys(w_kvs(_), K4),
    win_kinds(K4, redo, R4),
    append(_, [redo(I4, w_kv, ['_', '3'])|After4], K4),
    win_first(3, After4, Next4),
    check('a retry: w_kv(K, 3) again with K unbound -- w_kv(b, 2) tried and not matched, w_kv(d, 3) entered',
          R4-Next4, [redo(I4, w_kv, ['_', '3'])]-[nohead(I4, 2), clause(I4, 3), exit(I4, w_kv, [d, '3'])]),
    forall(between(1, 10000, I5), ( atom_concat(k, I5, A5), assertz(w_many(A5, I5)) )),
    '$trace_window'(w_many(k9999, _), [from(1)], Es5, _),
    length(Es5, N5),
    win_kinds(Es5, nohead, H5),
    length(H5, NH5),
    check('w_many(k9999, V) over 10,000 facts: its Call, the one clause tried, its Exit -- 9,998 heads the index passed over not recorded',
          N5-NH5, 3-0).

%% the keys of a recording of G from its first inference
win_keys(G, Ks) :-
    '$trace_window'(G, [from(1)], Es, _),
    maplist(win_key, Es, Ks).

%% an event without its depth and cells, `_G' names as `_': what a recording
%% says that another recording of the same run must say too
win_key(call(I, _, _, _, N, As), call(I, N, Bs)) :- !, maplist(win_text, As, Bs).
win_key(exit(I, _, _, N, As), exit(I, N, Bs)) :- !, maplist(win_text, As, Bs).
win_key(fail(I, _, _, N, As), fail(I, N, Bs)) :- !, maplist(win_text, As, Bs).
win_key(redo(I, _, _, N, As), redo(I, N, Bs)) :- !, maplist(win_text, As, Bs).
win_key(clause(I, _, _, K), clause(I, K)) :- !.
win_key(nohead(I, _, _, K), nohead(I, K)) :- !.
win_key(throw(I, D, _, B), throw(I, D, B1)) :- !, win_text(B, B1).
win_key(catch(I, D, _), catch(I, D)).

win_text(cut(T, L), cut(T1, L)) :- !, win_text(T, T1).
win_text(T, T1) :- re_replace_atom('_G[0-9]+', '_', T, T1).

win_first(N, L, H) :- length(H, N), append(H, _, L), !.
win_first(_, L, L).

%% the keys of a whole recording's events from FROM to TO that are about a
%% call made at FROM or after -- what a window opened at FROM can see
win_span(Es, From, To, Span) :-
    win_span(Es, From, To, [], Span).
win_span([], _, _, _, []).
win_span([E|Es], From, To, Calls, Span) :-
    arg(1, E, I),
    (   E = call(_, _, C, _, _, _) -> Calls1 = [C-I|Calls] ; Calls1 = Calls ),
    (   I >= From, I =< To, win_made_in(E, From, Calls1)
    ->  win_key(E, K), Span = [K|Span1]
    ;   Span = Span1
    ),
    win_span(Es, From, To, Calls1, Span1).

%% the event is about a call made at FROM or after: a call's own events by
%% its cell (the latest call of that cell), a throw or a catch always
win_made_in(E, _, _) :- functor(E, F, _), memberchk(F, [throw, catch]), !.
win_made_in(E, From, Calls) :-
    arg(3, E, C),
    memberchk(C-I, Calls),
    I >= From.

%% the collector's count at w_hc/1's two Exits: one number, or the two
win_hc(Es, R) :-
    findall(N, member(exit(_, _, _, w_hc, [N]), Es), Ns),
    (   Ns = [A, A] -> R = same ; R = Ns ).

win_kinds(Ks, Kind, Of) :-
    findall(K, ( member(K, Ks), functor(K, Kind, _) ), Of).

%% the Exits, Fails and Redos whose cell no Call before them named
win_paired(Es, Unpaired) :-
    win_paired(Es, [], Unpaired).
win_paired([], _, []).
win_paired([E|Es], Seen, Un) :-
    (   E = call(_, _, C, _, _, _) -> win_paired(Es, [C|Seen], Un)
    ;   ( E = exit(_, _, C, _, _) ; E = fail(_, _, C, _, _) ; E = redo(_, _, C, _, _) ),
        \+ memberchk(C, Seen)
    ->  Un = [E|Un1], win_paired(Es, Seen, Un1)
    ;   win_paired(Es, Seen, Un)
    ).

%% ---- a question asked where the run stopped (D4) ------------------------

asked :-
    section('ask(Cond, Holds): a question asked where the run stopped, over what it had bound there'),
    '$trace_window'(w_fill(_), [from(1)], Es0, _),
    ( member(call(I, _, _, _, =, [_, '2']), Es0) -> true ; I = none ),
    I0 is I - 1,
    '$trace_window'(w_fill(L1), [to(I), ask((nth1(2, L1, X1), X1 == 2), H1)], _, E1),
    '$trace_window'(w_fill(L2), [to(I0), ask((nth1(2, L2, X2), X2 == 2), H2)], _, _),
    check('the second element is 2 stopped at the inference of its X = 2, and not at the one before',
          H1-H2-E1, true-false-end(limit, I, [])),
    '$trace_window'(w_fill(L3), [ask(L3 == [1, 2, 3], H3)], _, E3),
    ( var(L3) -> V3 = unbound ; V3 = L3 ),
    check('at its answer, the answer''s bindings; and nothing kept after', H3-E3-V3,
          true-end(answer, 13, [13])-unbound),
    %% (25 through 1.12.1, when length(L, 3) was thirteen steps of clauses)
    '$trace_window'(w_pick(X4), [answers(5), ask(var(X4), H4)], _, end(How4, _, _)),
    check('at a failure, what the failure left: nothing bound', How4-H4, false-true),
    '$trace_window'(w_fill(_), [ask(w_nosuch, H5)], _, _),
    ( H5 = exception(error(existence_error(procedure, P5), _)) -> R5 = P5 ; R5 = H5 ),
    '$trace_window'(w_fill(_), [ask(w_loop, H6)], _, _),
    check('a question that raises hands back its ball; one that runs on is stopped', R5-H6, w_nosuch/0-limit),
    %% only w_junk's list below the question: a slide the run's last list
    %% outgrows
    garbage_collect,
    w_junk,
    w_asked_gc(H7),
    check('asked after collections that moved the question and the run''s terms', H7, true).

win_refused(Opts, R) :-
    answer('$trace_window'(w_go(_), Opts, _, _), x, G),
    (   G = error(error(domain_error(trace_window_option, _), _)) -> R = domain
    ;   R = G
    ).
