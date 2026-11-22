%  at_halt/1 and cancel_halt/1, swipl 9.0.4's (cocolog 3.71.0): COMPAT.md's
%  fourth group of small built-ins, the process's. The case holds:
%  - the order: the hooks a goal registers, the newest first, then a file's
%    `:- at_halt(G)' directives in the file's order (swipl's asserta/1 of
%    '$at_halt'/2, and the directive's clause of it after them); a directive
%    that is more than at_halt/1 registers as a goal does;
%  - each hook run once, under catch/3: a failure the warning
%    goal_failed(at_halt, G), an error said as print_message/2 says it --
%    an unknown goal, a number and an unbound one among them, at_halt/1
%    checking nothing as it registers;
%  - cancel_halt/1 thrown, caught and said (informational: the case's
%    verbose silent quiets it, as swipl -q does); a hook that cancels makes
%    halt/0,1 fail, the hooks before it erased, it and those after it run
%    again at the next halt;
%  - halt/1 inside a hook fails; a hook registered while they run is not
%    run then; the exit_status flag the halt's code while they run, and
%    after a cancel, and none before the first halt;
%  - the meta-argument qualified, `foo:G' run in a module of its own;
%  - at_halt/1 and cancel_halt/1 as predicate_property/2 sees them.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte; the
%  hooks left at main's end run at the toplevel's halt (swipl's -t halt,
%  cocolog's run FILE main). Through 3.70.0 cocolog had neither, and a call
%  raised existence_error. The tenth cancel is test/files/at_halt_limit.pl.
%  Not here, cocolog's own (test/script.pl, test/thread.pl): the ends of -s,
%  query and the REPL, a thread's halt, which runs none, cancel_halt/1
%  uncaught, and a directive read again into a second store, which
%  registers nothing twice.

:- dynamic cancels/1.
cancels(0).

:- at_halt(say(directive_one)).
:- at_halt(fail).
:- at_halt(say(directive_two)), true.
:- at_halt(say(directive_three)).

say(X) :- write(X), nl.

main :-
    set_prolog_flag(verbose, silent),
    catch(cancel_halt(why), E1, true), print(caught(E1)), nl,
    print_message(error, cancel_halt(printed)),
    status_now(before),
    props(at_halt(_)),
    props(cancel_halt(_)),
    at_halt(say(goal_one)),
    at_halt(say(goal_two)),
    at_halt(fail),
    at_halt(throw(oops)),
    at_halt(nope),
    at_halt(3),
    at_halt(_),
    at_halt(foo:say(qualified)),
    at_halt(status),
    at_halt(inner_halt),
    at_halt(late),
    at_halt(canceller),
    at_halt(say(before_first_cancel)),
    at_halt(status),
    say(registered),
    ( halt(5) -> say(halt_returned) ; say(halt_failed) ),
    status_now(after_first),
    at_halt(say(before_second_cancel)),
    ( halt -> say(halt_returned) ; say(halt_failed) ),
    status_now(after_second),
    say(main_done).

status_now(When) :-
    (   current_prolog_flag(exit_status, S)
    ->  print(When-S)
    ;   print(When-none)
    ),
    nl.

props(H) :-
    functor(H, N, A),
    forall(member(P, [built_in, transparent, meta_predicate(_), iso, dynamic,
                      foreign, imported_from(_)]),
           (   predicate_property(H, P)
           ->  print(N/A-P), nl
           ;   functor(P, PN, _), print(N/A-no(PN)), nl
           )).

canceller :-
    retract(cancels(N)),
    N1 is N + 1,
    assertz(cancels(N1)),
    N < 2,
    !,
    print(cancelling(N)), nl,
    cancel_halt(N).
canceller :-
    say(canceller_lets_it_go).

status :-
    current_prolog_flag(exit_status, S),
    print(status(S)), nl.

inner_halt :-
    (   halt(7)
    ->  say(inner_halt_returned)
    ;   say(inner_halt_failed)
    ).

late :-
    at_halt(say(late_hook)),
    say(late_registered).
