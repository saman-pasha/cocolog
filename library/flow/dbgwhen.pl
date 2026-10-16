%% library(flow/debug), part: questions over the clock -- the first
%% step at which something holds (DESIGN-flow.md 9.5, D4).
%%
%%     flow_when(+Goal, +Cond, +Options, -When)
%%
%% Cond is a goal over Goal's variables -- or over anything a goal can ask:
%% the knowledge base, a global -- asked of the run STOPPED at a step,
%% with what the run had bound there ('$trace_window'/4's ask(Cond, Holds)).
%% When is at(I): Cond does not hold at I - 1 and holds at I, where the
%% call made at step I is the goal that made it so; or never, when it
%% does not hold where the run ends (nor at any step(N) asked).
%%
%% Options: source(File) (required); until(end | answer(K)), where the run
%% ends; step(N), below; journal(Bool), true by default: the probe journals
%% every call that reaches the world and every later run is a replay of
%% it, so each reads what the probe read and none does again what it did
%% (journal(false) runs the program afresh each time); timeout(Ms) for each
%% run; embed(Dir) and kb(Name), the store each run opens, as flow_debug/4
%% takes them; and base(Base): Base.svg and Base.xml drawn for the window
%% of window(N) steps (2000) that ends at I, with flow_debug/4's
%% other options.
%%
%% THE SEARCH is over runs, never inside one: Cond is asked where the probe
%% ended, then bisected over [1, End] -- each step a run of its own, a child
%% process stopped at to(Mid) and asked there: about twenty runs for a
%% million steps. That finds THE FIRST step when Cond, once it
%% holds, holds to the end -- a binding made and kept, a fact asserted and
%% not retracted. One that backtracking undoes is not: it may not hold at
%% the end at all, and where it holds and stops holding the bisection finds
%% some step where it began to. step(N) asks every N-th step
%% first, from N, and bisects inside the first step where it holds: the
%% first step it holds at, whenever it holds for N steps running.
%%
%% A run that is not the same twice cannot be searched: a replay that
%% leaves its journal, or a run that ends elsewhere than the probe did, is
%% an error naming both ends, flow_when_diverged(Probe, Run).

:- use_module(library(process)).
:- use_module(library(stream)).

flow_when(Goal, Cond, Opts, When) :-
    flow_when_check(Goal, Cond, Opts, File),
    flow_option(timeout(Ms), Opts, 600000),
    (   memberchk(until(answer(K)), Opts) -> true ; K = 1 ),
    (   memberchk(journal(false), Opts) -> JFile = none, Keep = false
    ;   flow_dbg_journal_file([journal(true)|Opts], JFile, Keep)
    ),
    (   JFile == none -> JR = [], JP = []
    ;   JR = [journal(record(JFile))], JP = [journal(replay(JFile))]
    ),
    flow_dbg_src(File, Opts, Src),
    Ask = ask(Src, Goal, Cond, K, JP, Ms),
    (   catch(flow_when_search(Src, Goal, Cond, K, JR, Ms, Ask, Opts, When0),
              E, ( flow_dbg_journal_drop(JFile, Keep), throw(E) ))
    ->  true
    ;   flow_dbg_journal_drop(JFile, Keep), fail
    ),
    flow_dbg_journal_drop(JFile, Keep),
    When = When0,
    flow_when_draw(When, Goal, Opts).

flow_when_check(Goal, Cond, Opts, File) :-
    (   var(Goal) -> throw(error(instantiation_error, flow_when/4)) ; true ),
    (   callable(Goal) -> true ; throw(error(type_error(callable, Goal), flow_when/4)) ),
    (   var(Cond) -> throw(error(instantiation_error, flow_when/4)) ; true ),
    (   callable(Cond) -> true ; throw(error(type_error(callable, Cond), flow_when/4)) ),
    (   memberchk(source(File), Opts) -> true
    ;   throw(error(existence_error(flow_option, source), flow_when/4))
    ),
    (   memberchk(step(N), Opts), \+ ( integer(N), N >= 1 )
    ->  throw(error(domain_error(flow_when_option, step(N)), flow_when/4))
    ;   true
    ),
    (   memberchk(journal(J), Opts), \+ memberchk(J, [true, false])
    ->  throw(error(domain_error(flow_when_option, journal(J)), flow_when/4))
    ;   true
    ),
    flow_dbg_check_where(Opts, flow_when/4).

%% the probe, asked where it ends; then the steps, then the bisection
flow_when_search(Src, Goal, Cond, K, JR, Ms, Ask, Opts, When) :-
    flow_when_child(Src, Goal, Cond, [answers(K)|JR], Ms, Probe, H00),
    Probe = end(_, U, _),
    flow_when_end_ok(Probe, Probe),
    flow_when_holds(Cond, H00, H0),
    (   memberchk(step(N), Opts), N < U
    ->  flow_when_steps(N, N, 0, U, H0, Ask, Probe, Span)
    ;   ( H0 == true -> Span = 0-U ; Span = never )
    ),
    (   Span = Lo-At
    ->  flow_when_bisect(Lo, At, Ask, Probe, I),
        When = at(I)
    ;   When = never
    ).

%% the first N-th step where Cond holds, and the one before it where
%% it did not, as Lo-At; up to the run's end, where the probe asked
flow_when_steps(I, _, Lo, U, H0, _, _, Span) :-
    I >= U, !,
    ( H0 == true -> Span = Lo-U ; Span = never ).
flow_when_steps(I, N, Lo, U, H0, Ask, Probe, Span) :-
    flow_when_ask(Ask, I, Probe, H),
    (   H == true -> Span = Lo-I
    ;   I1 is I + N,
        flow_when_steps(I1, N, I, U, H0, Ask, Probe, Span)
    ).

%% Cond's answer: true or false, and anything else an error that names it
flow_when_holds(_, true, true) :- !.
flow_when_holds(_, false, false) :- !.
flow_when_holds(Cond, exception(B), _) :- !,
    throw(error(flow_when_cond(Cond, B), flow_when/4)).
flow_when_holds(Cond, H, _) :-
    throw(error(flow_when_cond(Cond, H), flow_when/4)).

%% Cond does not hold at Lo (0: before the run) and holds at Hi
flow_when_bisect(Lo, Hi, _, _, Hi) :-
    Hi - Lo =< 1, !.
flow_when_bisect(Lo, Hi, Ask, Probe, I) :-
    Mid is (Lo + Hi) // 2,
    flow_when_ask(Ask, Mid, Probe, H),
    (   H == true -> flow_when_bisect(Lo, Mid, Ask, Probe, I)
    ;   flow_when_bisect(Mid, Hi, Ask, Probe, I)
    ).

%% a run stopped at step I and asked: true when Cond held there
flow_when_ask(ask(Src, Goal, Cond, K, JP, Ms), I, Probe, H) :-
    flow_when_child(Src, Goal, Cond, [to(I), answers(K)|JP], Ms, End, H0),
    flow_when_stopped(End, I, Probe),
    flow_when_holds(Cond, H0, H).

%% a run stopped at I either stopped there (limit) or ended as the probe
%% did at or before it; anything else is not the probe's run
flow_when_stopped(end(limit, I, _), I, _) :- !.
flow_when_stopped(End, _, Probe) :-
    flow_when_end_ok(End, Probe).

flow_when_end_ok(end(diverged(At, W, G), U, A), Probe) :- !,
    throw(error(flow_when_diverged(Probe, end(diverged(At, W, G), U, A)), flow_when/4)).
flow_when_end_ok(end(How, U, A), Probe) :-
    Probe = end(PH, PU, PA),
    (   How = error(_) -> throw(error(flow_when_run(end(How, U, A)), flow_when/4)) ; true ),
    (   flow_dbg_how_word(How, W), flow_dbg_how_word(PH, PW), W == PW, U =:= PU, A == PA
    ->  true
    ;   throw(error(flow_when_diverged(Probe, end(How, U, A)), flow_when/4))
    ).

%% THE PROGRAM RUN IN A CHILD and asked where it stopped, as flow_dbg_child/6
%% runs one: the window and the question are one term, so Cond shares
%% Goal's variables in the child as here
flow_when_child(Src, Goal, Cond, WOpts0, Ms, End, H) :-
    tmp_file(flowwhen, Out),
    append(WOpts0, [ask(Cond, H1)], WOpts),
    Driver = ( use_module(library(stream)),
               '$trace_window'(Goal, WOpts, _, E),
               open(Out, write, S),
               format(S, '~q.~n~q.~n', [E, H1]),
               close(S) ),
    format(atom(GoalText), '~q', [Driver]),
    flow_dbg_cmd(Src, GoalText, Cmd),
    proc_run(Cmd, Ms, OutCodes, Exit),
    (   Exit =:= 0, exists_file(Out)
    ->  flow_dbg_read_terms(Out, [End0, H|_]),
        flow_dbg_norm_end(End0, End),
        catch(delete_file(Out), _, true)
    ;   catch(delete_file(Out), _, true),
        atom_codes(Said, OutCodes),
        flow_dbg_src_file(Src, File),
        throw(error(flow_debug_run(File, Exit, Said), flow_when/4))
    ).

%% base(Base): the window that ends where Cond began to hold, drawn
flow_when_draw(never, _, _) :- !.
flow_when_draw(at(I), Goal, Opts) :-
    (   memberchk(base(Base), Opts)
    ->  flow_option(window(W), Opts, 2000),
        From is max(1, I - W + 1),
        findall(O, ( member(O, Opts), \+ functor(O, base, 1), \+ functor(O, step, 1),
                     \+ functor(O, window, 1), \+ functor(O, from, 1), \+ functor(O, to, 1) ), Os),
        flow_debug(Goal, Base, [from(From), to(I)|Os])
    ;   true
    ).
