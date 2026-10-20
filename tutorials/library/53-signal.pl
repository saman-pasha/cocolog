%% LIBRARY 53 -- library(signal): POSIX signals as catchable errors at the
%% engine's next step
%%
%%     ./cocolog run tutorials/library/53-signal.pl main
%%
%% TIER 2: `use_module(library(signal))', a `.so' from `modules/signal'.
%% It needs nothing but a C compiler: `sh modules/signal/build.sh'.
%%
%%     on_signal(+Sig, -Old, +New)       New = default | ignore | throw
%%     on_signal(+Sig, -Old, -New)       query: both are the current handler
%%     current_signal(?Name, ?Id, ?H)    enumerate the named signals
%%     raise_signal(+Sig)                raise(2), through the OS
%%     signal_name(+Sig, -Name)
%%     signal_number(+Sig, -Number)
%%
%% A HANDLER MAY ASSIGN A `volatile sig_atomic_t' AND CALL NOTHING. That is
%% the whole constraint, and it is why this library is small: cocolog
%% already has the safe point every C program writes a flag for -- the
%% engine's `halted' cell, tested once at the top of every step. `throw'
%% installs a handler that writes 3 + SIGNO there; the next step raises
%% error(signal(Name, Num), _), SWI's ball, and catch/3 takes it. Nothing
%% is built in the handler, nothing is allocated, and no goal runs in it.
%%
%% AN UNCAUGHT ONE reads as SWI's sentence and is an error: under `-s' the
%% host prints `Caught signal 30 (usr1)' and ends 2. The REPL installs
%% SIGINT throw at start-up, so Ctrl+C during a goal stops the goal and the
%% prompt returns; at the prompt the line editor owns Ctrl+C (it drops the
%% line) and Ctrl+D (it leaves), as it always did.
%%
%% A DELIVERED SIGNAL WAITS FOR A STEP. A blocking foreign call -- read,
%% accept, sleep -- defers it until the call returns; `signal(2)' has BSD
%% semantics here, so interrupted calls restart. A signal delivered to
%% another thread stops the machine that installed the handler: install it
%% in the machine whose goals should hear it.
%%
%% THE NUMBERS ARE THE PLATFORM'S. Learn them with signal_number/2 and
%% write them down never: usr1 is 30 on Darwin and 10 on Linux.

:- use_module(library(signal)).

main :-
    lesson_names,
    lesson_table,
    lesson_raise,
    lesson_errors,
    lesson_repl,
    format("done~n").

%% ---- names and numbers --------------------------------------------------
lesson_names :-
    format("~n-- the names are SIG lowercased, as SWI spells them~n"),
    signal_number(int, N1),
    must('int is signal 2', N1, 2),
    signal_name(2, N2),
    must('and 2 names int', N2, int),
    signal_name(usr1, N3),
    must('usr1 names itself', N3, usr1),
    %% the number of usr1 is NOT written here: it is the platform's, and
    %% signal_number/2 is how a program learns it
    signal_number(usr1, U1),
    format("     (usr1 is ~w on this system)~n", [U1]),
    signal_name(U1, N4),
    must('the number names the name back', N4, usr1),
    findall(Name, current_signal(Name, _, _), Names),
    length(Names, Count),
    ( Count > 20 -> W5 = true ; W5 = false ),
    must('current_signal enumerates every named signal', W5, true).

%% ---- the table ----------------------------------------------------------
lesson_table :-
    format("~n-- a signal starts at default, and on_signal/3 answers the old~n"),
    current_signal(usr1, _, H0),
    must('nothing is installed yet', H0, default),
    on_signal(usr1, Old1, throw),
    must('setting throw answers the old handler', Old1, default),
    current_signal(usr1, _, H1),
    must('and the table says throw', H1, throw),
    on_signal(usr1, Old2, default),
    must('restoring default answers throw', Old2, throw),
    current_signal(usr1, _, H2),
    must('and the table is default again', H2, default),
    on_signal(usr1, Old3, New3),
    must('a variable New asks only, and both are the current', Old3-New3, default-default),
    current_signal(usr1, _, H3),
    must('which changed nothing', H3, default).

%% ---- a raised signal ----------------------------------------------------
lesson_raise :-
    format("~n-- throw makes the signal a catchable Prolog error~n"),
    signal_number(usr1, N),
    on_signal(usr1, _, throw),
    catch(raise_signal(usr1), error(signal(Nm, Nb), _), true),
    must('the ball names the signal', Nm, usr1),
    must('with the number the table gave', Nb, N),
    on_signal(usr1, _, default),
    on_signal(usr1, _, ignore),
    ( raise_signal(usr1) -> W4 = true ; W4 = false ),
    must('with ignore the raise has nothing to do', W4, true),
    on_signal(usr1, _, default),
    %% the engine went on after the caught throw, and so does this lesson
    must('the lesson is still running', yes, yes).

%% ---- mistakes -----------------------------------------------------------
lesson_errors :-
    format("~n-- a mistake is named, not ignored~n"),
    must_error('an unknown name is a domain error',
               signal_number(nosuch, _),
               domain_error(signal, nosuch)),
    must_error('a number out of range is a type error',
               signal_number(999, _),
               type_error(signal, 999)),
    must_error('a float is no signal name',
               signal_number(1.5, _),
               type_error(signal_name, 1.5)),
    must_error('an unknown handler is refused before anything changes',
               on_signal(int, _, bogus),
               domain_error(signal_handler, bogus)).

%% ---- the toplevel -------------------------------------------------------
lesson_repl :-
    format("~n-- the ball the toplevel catches for Ctrl+C~n"),
    on_signal(int, _, throw),
    catch(raise_signal(int), error(signal(Nm, Nb), _), true),
    must('Ctrl+C during a goal is signal(int, 2)', Nm-Nb, int-2),
    on_signal(int, _, default),
    format("     (the REPL installs this at start-up; at its prompt the line~n"),
    format("      editor reads Ctrl+C as a dropped line and Ctrl+D as leave)~n").

%% ---- the helpers every lesson here carries -----------------------------
%% REPEATED ON PURPOSE, in every file. A tutorial you can copy anywhere and
%% run is worth the few duplicated lines.

must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).

must_error(Label, Goal, Formal) :-
    copy_term(Formal, FC),
    (   catch(Goal, error(E, _), true)
    ->  ( var(E) -> Got = no_error ; Got = E )
    ;   Got = failed
    ),
    (   subsumes_term(FC, Got)
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Formal]),
        fail
    ).
