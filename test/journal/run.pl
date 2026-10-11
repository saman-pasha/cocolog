%% test/journal.pl's program: a run that reads the world and changes it at
%% every kind of portal -- the clock, the environment, files read, written
%% and appended to, a stream written and read back, a raise a portal makes,
%% portals inside findall/3, a process, a temporary name, the program's own
%% arguments, a thread and its channel -- and the small runs the
%% divergences are worked out on. Its directory is the global j_dir, set
%% by whoever runs it, so a record and its replay touch the same files.

:- use_module(library(stream)).
:- use_module(library(process)).
:- use_module(library(thread)).

j_path(N, P) :- nb_getval(j_dir, D), atomic_list_concat([D, '/', N], P).

%% the clock, the environment, a file read and appended to: what a replay
%% without a journal sees otherwise, and repeats
j_flip(Odd) :-
    j_path('flip.dat', F),
    ( exists_file(F) -> read_file_to_codes(F, C) ; C = [] ),
    append_file_from_codes(F, "x"),
    length(C, N0), N is N0 + 1,
    ( N mod 2 =:= 1 -> Odd = odd ; Odd = even ).
%% format/3 into an atom writes nowhere: no portal
j_world(r(T, H, A, Odd)) :- get_time(T), getenv('HOME', H), format(atom(A), "~w", [t]), j_flip(Odd).

%% a stream written -- format/3 into it, with_output_to/2 into it, and a
%% float only seventeen digits say -- then read back a term at a time
j_stream(Ts) :-
    j_path('s.txt', P),
    open(P, write, S),
    format(S, "~q.~n", [f(1, "two", 3.25)]),
    with_output_to(S, (write(g(x)), write('.'), nl)),
    format(S, "x(0.30000000000000004).~n", []),
    close(S),
    open(P, read, R),
    read_term(R, T1, []), read_term(R, T2, []), read_term(R, T3, []), read_term(R, T4, []),
    close(R),
    Ts = [T1, T2, T3, T4].

%% a raise a portal makes, caught; portals inside findall/3
j_raise(E, L) :-
    catch(open('/nonexistent/j', read, _), error(E, _), true),
    findall(N-V, ( member(N, ['HOME', 'J_NO_SUCH_VAR']), ( getenv(N, V) -> true ; V = none ) ), L).

%% a process, a temporary name, the program's arguments
j_proc(Out-X, T, A) :-
    proc_run('echo hello', 5000, Out, X), tmp_file(jt, T), current_prolog_flag(argv, A).

%% a thread that leaves a mark on disk, and what it sends
j_thread(M-St) :-
    j_path('thread.mark', F),
    channel_new(C),
    thread_create(( append_file_from_codes(F, "t"), channel_send(C, got(41)) ), Id),
    channel_recv(C, M),
    thread_join(Id, St).

j_all(R) :-
    j_world(W), j_stream(Ts), j_raise(E, L), j_proc(P, T, A), j_thread(Th),
    R = all(W, Ts, E, L, P, T, A, Th),
    nb_setval(j_result, R).

%% ---- the small runs the divergences are worked out on ---------------------
%% j_d0's journal: get_time/1 at inference 2, getenv/2 at 3,
%% exists_directory/1 at 4

j_d0 :- get_time(_), getenv('HOME', _), exists_directory('/').
j_d_other :- getenv('HOME', _), get_time(_), exists_directory('/').
j_d_args :- get_time(_), getenv('USER', _), exists_directory('/').
j_d_passed :- get_time(_), true, getenv('HOME', _), exists_directory('/').
%% passed by, and a module's call that is not a portal made next
j_d_passed2 :- get_time(_), true, msort([b, a], _), getenv('HOME', _).
j_d_more :- get_time(_), getenv('HOME', _), exists_directory('/'), get_time(_).
%% the journal's last two calls not made, and its answer where j_d0's was
j_d_skip :- get_time(_), true, true.
%% and its last call not made, the run answering where that call was due
j_d_fewer :- get_time(_), getenv('HOME', _).

%% j_d1's journal: get_time/1 at 2, then getenv/2 at 6
j_d1 :- get_time(_), X = 1, Y is X + 1, Y > 1, getenv('HOME', _).
j_d_early :- get_time(_), getenv('HOME', _), X = 1, Y is X + 1, Y > 1.

%% j_d2's journal: exists_directory/1 failing. A failure has no answer to
%% unify, so only the call's text tells another call from the journal's
j_d2 :- ( exists_directory('/nonexistent/j') -> X = 1 ; X = 2 ), X == 2.
j_d_fail :- ( exists_directory('/nonexistent/k') -> X = 1 ; X = 2 ), X == 2.

%% a portal that raises with nothing to catch it
j_uncaught :- open('/nonexistent/j', read, _).

%% ---- driven from a shell, for the checks that want another process ------
%%   cocolog run test/journal/run.pl "j_run(Dir, record)"   -> j_end(...) on stdout

j_run(Dir, Mode) :-
    nb_setval(j_dir, Dir),
    atom_concat(Dir, '/run.jrnl', J),
    Opt =.. [Mode, J],
    ( Mode == record -> W = [] ; W = [from(1)] ),
    append(W, [journal(Opt)], Opts),
    '$trace_window'(j_all(_), Opts, _, End),
    nb_getval(j_result, R),
    format("~q.~n", [j_end(End, R)]).
