%% The journal of a run (1.10.15) -- what a replay reads instead of the
%% world (DESIGN-flow.md 9.2): `'$trace_window'/4' given
%% journal(record(File)) writes an entry for each portal call of the run;
%% given journal(replay(File)) it answers each from its entry and runs
%% nothing, and a replay that reaches a portal another way stops there,
%% diverged.
%%
%% Every value is worked out by hand from test/journal/run.pl: the entries
%% a run makes and their order, what a replay answers and what it must not
%% do again -- append to a file, write a stream's file, start a thread --
%% where each kind of divergence is reported and with what, a raise
%% recorded and raised again, and the same run recorded in one process
%% and replayed in another, under collections every 2000 cells.
%%
%%     cocolog -s test/journal.pl       from the checkout root

:- use_module('test/prelude.pl').
:- use_module('test/journal/run.pl').
:- use_module(library(stream)).
%% a divergence's CallText is a string, as the journal writes it
:- set_prolog_flag(double_quotes, string).

main :-
    scratch(D), nb_setval(j_dir, D),
    record(D), replay(D), diverged(D), raised(D), processes(D), refusals(D), sized(D),
    checks_done.

%% the journal's entries as terms: j(I, Module, Name/Arity, CallText, Outcome)
entries(File, Es) :-
    open(File, read, S),
    read_term(S, T, []),
    entries_rest(T, S, Es),
    close(S).

entries_rest(end_of_file, _, []) :- !.
entries_rest(T, S, [T|Es]) :- read_term(S, T1, []), entries_rest(T1, S, Es).

rising([]).
rising([_]).
rising([j(A, _, _, _, _), j(B, M, P, C, O)|Es]) :- A < B, rising([j(B, M, P, C, O)|Es]).

text_of(File, A) :- read_file_to_codes(File, Cs), atom_codes(A, Cs).

%% ---- a record ------------------------------------------------------------

record(D) :-
    section('a record: every portal call of the run, in order'),
    atom_concat(D, '/run.jrnl', J1),
    '$trace_window'(j_all(_), [journal(record(J1))], _, E1),
    nb_getval(j_result, R1),
    nb_setval(j_e1, E1), nb_setval(j_r1, R1),
    ( E1 = end(answer, U1, [U1]) -> Shape1 = answer ; Shape1 = E1 ),
    check('the run ends with its answer, the inference it came at its last', Shape1, answer),
    entries(J1, Es1),
    nb_setval(j_entries, Es1),
    findall(M2-P2-O2, ( member(j(_, M2, P2, _, Out2), Es1), functor(Out2, O2, _) ), MPO2),
    ( append(First2, _, MPO2), length(First2, 4) -> true ; First2 = MPO2 ),
    check('its first four: the clock, the environment, the file asked about, and appended to',
          First2, [files-get_time/1-exit, builtins-getenv/2-exit,
                   files-exists_file/1-fail, files-append_file_from_codes/2-exit]),
    ( rising(Es1) -> Rise3 = yes ; Rise3 = no ),
    check('each entry at a later inference than the one before', Rise3, yes),
    ( member(j(_, stream, '$stream_open'/4, _, throw(error(B4, _))), Es1) -> true ; B4 = none ),
    check('the raise open/3 made, kept with its ball', B4, existence_error(source_sink, '/nonexistent/j')),
    findall(V5, ( member(j(_, builtins, getenv/2, C5, O5), Es1),
                  atom_codes(A5, C5), sub_atom(A5, _, _, _, 'J_NO_SUCH_VAR'), V5 = O5 ), Vs5),
    check('getenv/2 inside findall/3, journalled, and its failure with it', Vs5, [fail]),
    findall(P6, ( member(j(_, thread, P6, _, _), Es1) ), Ps6),
    check('the thread: made, its message received, joined -- the module''s every call',
          Ps6, [channel_new/1, thread_create/2, channel_recv/2, '$thread_join'/2]),
    findall(S7, ( member(j(_, builtins, format/3, C7, _), Es1), atom_codes(S7a, C7),
                  ( sub_atom(S7a, 0, _, _, 'format(atom(') -> S7 = term ; S7 = stream ) ), Ss7),
    sort(Ss7, Sorted7),
    check('format/3 into a stream journalled, into an atom not: it writes nowhere', Sorted7, [stream]),
    text_of(J1, T8),
    ( sub_atom(T8, _, _, _, '0.30000000000000004') -> F8 = kept ; F8 = rounded ),
    check('a float written to read back bit for bit: 0.30000000000000004, its seventeen digits', F8, kept).

%% ---- a replay --------------------------------------------------------------

replay(D) :-
    section('a replay: every portal answered from the journal, and nothing done twice'),
    atom_concat(D, '/run.jrnl', J1),
    nb_getval(j_e1, E1), nb_getval(j_r1, R1),
    atom_concat(D, '/s.txt', Txt), delete_file(Txt),
    text_of(J1, Before1),
    '$trace_window'(j_all(_), [from(1), journal(replay(J1))], _, E2),
    nb_getval(j_result, R2),
    check('the replay ends where the record did', E2, E1),
    ( R2 == R1 -> Same3 = same ; Same3 = R2 ),
    check('every portal answered as the record''s did: the clock to the bit, the file read back, the raise, the process, the temporary name, the thread''s message',
          Same3, same),
    atom_concat(D, '/flip.dat', Flip), text_of(Flip, F4),
    check('the file appended to once, by the record', F4, x),
    ( exists_file(Txt) -> W5 = written ; W5 = absent ),
    check('the stream''s file not written again: opened, written and closed from the journal', W5, absent),
    atom_concat(D, '/thread.mark', Mark), text_of(Mark, M6),
    check('the thread not started again', M6, t),
    text_of(J1, After7),
    ( Before1 == After7 -> J7 = unchanged ; J7 = changed ),
    check('the journal as the record left it', J7, unchanged).

%% ---- divergence --------------------------------------------------------------

diverged(D) :-
    section('divergence: where a replay leaves the run its journal recorded, and with what'),
    atom_concat(D, '/d0.jrnl', J0), atom_concat(D, '/d1.jrnl', J1),
    '$trace_window'(j_d0, [journal(record(J0))], _, E0),
    check('j_d0: get_time/1 at 2, getenv/2 at 3, exists_directory/1 at 4, its answer at 5',
          E0, end(answer, 5, [5])),
    '$trace_window'(j_d_other, [from(1), journal(replay(J0))], _, E1),
    check('another portal where the journal holds one: at 2, getenv/2 for get_time/1', E1,
          end(diverged(2, portal(2, files, get_time/1, "get_time(_0)"),
                          portal(2, builtins, getenv/2, "getenv('HOME',_0)")), 2, [])),
    '$trace_window'(j_d_args, [from(1), journal(replay(J0))], _, E2),
    check('the same portal given another argument: at 3, USER for HOME', E2,
          end(diverged(3, portal(3, builtins, getenv/2, "getenv('HOME',_0)"),
                          portal(3, builtins, getenv/2, "getenv('USER',_0)")), 3, [])),
    '$trace_window'(j_d_passed, [from(1), journal(replay(J0))], _, E3),
    check('the journal''s call passed by: due at 3, made at 4', E3,
          end(diverged(3, portal(3, builtins, getenv/2, "getenv('HOME',_0)"),
                          portal(4, builtins, getenv/2, "getenv('HOME',_0)")), 4, [])),
    '$trace_window'(j_d_passed2, [from(1), journal(replay(J0))], _, E3a),
    check('passed by, and noticed at the next call a module answers -- not a portal, stopped before it runs, so no module is known for it',
          E3a, end(diverged(3, portal(3, builtins, getenv/2, "getenv('HOME',_0)"),
                               portal(4, unknown, msort/2, "msort([b,a],_0)")), 4, [])),
    '$trace_window'(j_d_more, [from(1), journal(replay(J0))], _, E4),
    check('a portal call past the journal''s last: at 5, the journal holding none', E4,
          end(diverged(5, none, portal(5, files, get_time/1, "get_time(_0)")), 5, [])),
    '$trace_window'(j_d_skip, [from(1), journal(replay(J0))], _, E4a),
    check('the journal''s calls left out, and the answer where the record''s was: diverged where the first was due, the replay having made none',
          E4a, end(diverged(3, portal(3, builtins, getenv/2, "getenv('HOME',_0)"), none), 5, [5])),
    '$trace_window'(j_d_fewer, [from(1), journal(replay(J0))], _, E4b),
    check('the journal''s last call left out, the run answering where it was due', E4b,
          end(diverged(4, portal(4, files, exists_directory/1, "exists_directory(/)"), none), 4, [4])),
    '$trace_window'(j_d0, [from(1), to(3), journal(replay(J0))], _, E4c),
    check('a replay stopped at to(3) leaves the call due at 4: not a divergence', E4c, end(limit, 3, [])),
    '$trace_window'(j_d1, [journal(record(J1))], _, E5),
    check('j_d1: get_time/1 at 2, getenv/2 at 6, its answer at 7', E5, end(answer, 7, [7])),
    '$trace_window'(j_d_early, [from(1), journal(replay(J1))], _, E6),
    check('a portal the journal holds made early, at 3 where it is due at 6 -- stopped before it runs',
          E6, end(diverged(3, portal(6, builtins, getenv/2, "getenv('HOME',_0)"),
                              portal(3, builtins, getenv/2, "getenv('HOME',_0)")), 3, [])),
    '$trace_window'(j_d0, [from(1), journal(replay(J0))], _, E7),
    check('the run it recorded replays to its answer', E7, end(answer, 5, [5])),
    atom_concat(D, '/d2.jrnl', J2),
    '$trace_window'(j_d2, [journal(record(J2))], _, E8),
    check('j_d2: exists_directory/1 failing at 3, its answer at 6', E8, end(answer, 6, [6])),
    '$trace_window'(j_d_fail, [from(1), journal(replay(J2))], _, E9),
    check('another directory asked about where the journal''s call failed: a failure answers nothing to unify, and the text tells them apart',
          E9, end(diverged(3, portal(3, files, exists_directory/1, "exists_directory('/nonexistent/j')"),
                              portal(3, files, exists_directory/1, "exists_directory('/nonexistent/k')")), 3, [])).

%% ---- raised --------------------------------------------------------------------

raised(D) :-
    section('a raise nothing catches: recorded, and raised again by the replay'),
    atom_concat(D, '/u.jrnl', J),
    '$trace_window'(j_uncaught, [journal(record(J))], _, end(H1, U1, A1)),
    '$trace_window'(j_uncaught, [from(1), journal(replay(J))], _, end(H2, U2, A2)),
    ( H1 = exception(error(B1, _)) -> true ; B1 = H1 ),
    check('the record ends on the ball open/3 raised', B1, existence_error(source_sink, '/nonexistent/j')),
    ( H2 = exception(error(B2, _)) -> true ; B2 = H2 ),
    check('and the replay on the same ball, at the same inference, the call not made',
          B2-U2-A2, B1-U1-A1).

%% ---- another process ---------------------------------------------------------------

%% the run recorded by one cocolog and replayed by another, each a fresh
%% process: the journal is a file, and the replay's world is not the record's
processes(D) :-
    section('recorded by one process, replayed by another -- and both under collections every 2000 cells'),
    atom_concat(D, '/p', P1), make_directory(P1),
    atom_concat(D, '/q', Q1), make_directory(Q1),
    j_child(P1, record, '', Rec1),
    atom_concat(P1, '/s.txt', Txt1), delete_file(Txt1),
    j_child(P1, replay, '', Rep1),
    ( Rec1 = j_end(end(answer, _, _), _), Rep1 == Rec1 -> X1 = same ; X1 = Rec1-Rep1 ),
    check('the replay''s end and every answer are the record''s', X1, same),
    j_child(Q1, record, 'COCOLOG_GC_CELLS=2000 ', Rec2),
    atom_concat(Q1, '/s.txt', Txt2), delete_file(Txt2),
    j_child(Q1, replay, 'COCOLOG_GC_CELLS=2000 ', Rep2),
    ( Rec2 = j_end(end(answer, _, _), _), Rep2 == Rec2 -> X2 = same ; X2 = Rec2-Rep2 ),
    check('the same with the heap collected every 2000 cells, in both', X2, same),
    ( exists_file(Txt2) -> W3 = written ; W3 = absent ),
    check('and the replay wrote no stream''s file there either', W3, absent).

j_child(Dir, Mode, Env, End) :-
    cocolog(C),
    format(atom(Goal), "j_run(~q, ~q)", [Dir, Mode]),
    sh_join([Env, C, ' run test/journal/run.pl "', Goal, '" 2>&1'], Cmd),
    proc_run(Cmd, 120000, Out, _),
    atom_codes(A, Out),
    ( catch(term_to_atom(End, A), _, fail) -> true ; End = A ).

%% ---- refusals -------------------------------------------------------------------------

refusals(D) :-
    section('refusals, by name; and a window without a journal, as before'),
    atom_concat(D, '/none.jrnl', N1),
    catch(( '$trace_window'(j_d0, [journal(replay(N1))], _, _), R1 = ran ), error(R1, _), true),
    check('a journal that is not there', R1, existence_error(journal, journal(replay(N1)))),
    catch(( '$trace_window'(j_d0, [journal(record(1))], _, _), R2 = ran ), error(R2, _), true),
    check('a journal not named by an atom', R2, domain_error(trace_window_option, journal(record(1)))),
    atom_concat(D, '/bad.jrnl', B3),
    fixture(B3, ['j(1, x).']),
    catch(( '$trace_window'(j_d0, [journal(replay(B3))], _, _), R3 = ran ),
          error(cocolog_error(M3), _), true),
    ( atom(M3), sub_atom(M3, _, _, _, 'is not j(I, Module, Name/Arity, CallText, Outcome)') -> W3 = named ; W3 = M3-R3 ),
    check('an entry that is not one, named', W3, named),
    atom_concat(D, '/syntax.jrnl', B4),
    fixture(B4, ['j(1, x, y/1, "c", fail'] ),
    catch(( '$trace_window'(j_d0, [journal(replay(B4))], _, _), R4 = ran ),
          error(cocolog_error(M4), _), true),
    ( atom(M4), sub_atom(M4, _, _, _, 'would not read') -> W4 = named ; W4 = M4-R4 ),
    check('a journal that will not read, named', W4, named),
    catch(( '$trace_window'(j_d0, [journal(record(D))], _, _), R5 = ran ), error(R5, _), true),
    check('a record that cannot be written: the run is made, and the file refused', R5,
          permission_error(write, journal, D)),
    atom_concat(D, '/d0.jrnl', J6),
    text_of(J6, Before6),
    '$trace_window'(j_d0, [], _, E6),
    text_of(J6, After6),
    ( Before6 == After6 -> U6 = untouched ; U6 = changed ),
    check('then a window without a journal: its run as before, and no journal written',
          E6-U6, end(answer, 5, [5])-untouched).

%% ---- the green world's size -----------------------------------------------------------

%% async_workers/1 (2.15.0) reads COCOLOG_GREEN_WORKERS and the cores, as
%% getenv/2 and os_cpus/1 do, so it is a portal by name: recorded, and a
%% replay answers it from its entry whatever the environment says by then.
%% The window undoes its bindings, so the answer is kept in a global.
j_size :- async_workers(N), nb_setval(j_size, N).

sized(D) :-
    section('the green world''s size is a portal'),
    atom_concat(D, '/size.jrnl', J1),
    nb_setval(j_size, none),
    '$trace_window'(j_size, [journal(record(J1))], _, E1),
    nb_getval(j_size, N1),
    entries(J1, Es1),
    findall(M1-P1-O1, ( member(j(_, M1, P1, _, Out1), Es1), functor(Out1, O1, _) ), MPO1),
    ( E1 = end(answer, _, _) -> End1 = answer ; End1 = E1 ),
    check('recorded: the run''s answer, and one entry, the green module''s exit', End1-MPO1,
          answer-[green-'$async_workers'/1-exit]),
    ( getenv('COCOLOG_GREEN_WORKERS', Old2) -> true ; Old2 = none ),
    ( N1 =:= 1 -> K2 = 2 ; K2 = 1 ),
    setenv('COCOLOG_GREEN_WORKERS', K2),
    nb_setval(j_size, none),
    '$trace_window'(j_size, [journal(replay(J1))], _, E2),
    nb_getval(j_size, N2),
    ( Old2 == none -> unsetenv('COCOLOG_GREEN_WORKERS') ; setenv('COCOLOG_GREEN_WORKERS', Old2) ),
    ( E2 == E1 -> End2 = same ; End2 = E2 ),
    check('replayed with the variable changed: the run''s end, and the recorded count',
          End2-N2, same-N1).
