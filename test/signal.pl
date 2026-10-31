%% library(signal) -- POSIX signals as SWI's on_signal/3, current_signal/3
%% and raise_signal/1, with the ball raised at the engine's next step.
%%
%% WHAT IS CHECKED, and why each part needs its own shape:
%%
%%   THE TABLE is in the ENGINE (lib/solve.cicili), not the module, because
%%   the ball's name is made where the ball is made. signal_name/2 and
%%   signal_number/2 read it; current_signal/3 enumerates it.
%%
%%   A RAISED SIGNAL is an ordinary throw: raise_signal(usr1) with `throw'
%%   installed reaches catch/3 as error(signal(usr1, N), _), and the process
%%   goes on. `ignore' leaves the raise with nothing to do.
%%
%%   A DELIVERED SIGNAL is the point of the module, and the only way to test
%%   it is another process: a child loops, the shell sends it SIGUSR1, and
%%   its catch writes the answer. The child's exit status is checked too --
%%   0 when caught, 2 when the ball is uncaught (the `-s' host's SWI code).
%%
%%   THE REPL catches SIGINT: a child toplevel runs a long goal, gets
%%   SIGINT, prints the `Caught signal 2 (int)' error and reads the next
%%   line -- `halt.' -- so the session ends 0. Its empty input (Ctrl+D) is
%%   the same exit.
%%
%%     cocolog -s test/signal.pl        from the checkout root
%%
%% The signal numbers are the platform's (usr1 is 30 on Darwin, 10 on
%% Linux); every check takes the number from the library, never writes it.

:- use_module('test/prelude.pl').

main :-
    (   catch(use_module(library(signal)), _, fail)
    ->  true
    ;   skip('(no library/signal.so -- sh modules/signal/build.sh)')
    ),
    scratch(D),
    names,
    handler_table,
    raised,
    refused,
    delivered(D),
    repl_cases(D),
    checks_done.

%% ---- the names and numbers ---------------------------------------------
names :-
    section('the names and numbers'),
    answer(signal_number(int, N1), N1, G1),
    check('int is 2', G1, 2),
    answer(signal_name(2, N2), N2, G2),
    check('2 is int', G2, int),
    answer(signal_name(usr1, N3), N3, G3),
    check('usr1 names itself', G3, usr1),
    answer(( signal_number(usr1, N4), signal_name(N4, usr1) ), yes, G4),
    check('and its number names it back', G4, yes),
    answer(( signal_number(term, N5), signal_name(term, term), N5 > 0 ), yes, G5),
    check('term agrees with itself', G5, yes),
    answer(( findall(Name-N, current_signal(Name, N, _), L),
              length(L, Len), ( Len > 20 -> W = many ; W = Len ) ), W, G6),
    check('current_signal enumerates the named signals', G6, many).

%% ---- the handler table --------------------------------------------------
handler_table :-
    section('the handler table'),
    answer(( signal_number(usr1, _), current_signal(usr1, _, H0) ), H0, G0),
    check('a signal starts at default', G0, default),
    answer(( on_signal(usr1, Old1, throw), current_signal(usr1, _, H1) ),
           Old1-H1, G1),
    check('setting throw answers the old handler', G1, default-throw),
    answer(on_signal(usr1, Old2, default), Old2, G2),
    check('and restoring default answers throw', G2, throw),
    answer(( on_signal(usr1, Old3, V3), current_signal(usr1, _, H3) ),
           Old3-V3-H3, G3),
    check('a variable New asks only, and both answer the current',
          G3, default-default-default).

%% ---- a raised signal ----------------------------------------------------
raised :-
    section('a raised signal is a catchable error'),
    answer(( signal_number(usr1, N),
              on_signal(usr1, _, throw),
              (   catch(raise_signal(usr1), E, true),
                  E = error(signal(usr1, N2), _),
                  N2 =:= N
              ->  W = caught
              ;   W = not_caught
              ),
              on_signal(usr1, _, default) ), W, G1),
    check('raise_signal(usr1) reaches catch/3 with signal(usr1, N)', G1, caught),
    answer(( on_signal(usr1, _, ignore), raise_signal(usr1),
              on_signal(usr1, _, default) ), yes, G2),
    check('with ignore the raise has nothing to do', G2, yes).

%% ---- what is refused ----------------------------------------------------
refused :-
    section('a mistake is named, not ignored'),
    answer(catch(signal_number(nosuch, _), E1,
                 E1 = error(domain_error(signal, nosuch), _)), yes, G1),
    check('an unknown name is a domain error', G1, yes),
    answer(catch(signal_number(999, _), E2,
                 E2 = error(type_error(signal, 999), _)), yes, G2),
    check('a number out of range is a type error', G2, yes),
    answer(catch(signal_number(1.5, _), E3,
                 E3 = error(type_error(signal_name, 1.5), _)), yes, G3),
    check('a float is no signal name', G3, yes),
    answer(catch(on_signal(int, _, bogus), E4,
                 E4 = error(domain_error(signal_handler, bogus), _)), yes, G4),
    check('an unknown handler is refused before anything changes', G4, yes).

%% ---- a signal delivered to a child --------------------------------------
delivered(D) :-
    section('a signal delivered from outside a child'),
    atom_concat(D, '/sigcatch.pl', F1),
    fixture(F1, ['main :- use_module(library(signal)),',
                 '        on_signal(usr1, _, throw),',
                 '        catch((between(1, 1000000000, _), fail),',
                 '              error(signal(Nm, N), _),',
                 '              (write(answer(Nm, N)), nl)).']),
    atom_concat(D, '/sigcatch.out', O1),
    cocolog(C),
    format(atom(Cmd1),
           "~w --local -s ~w > ~w 2>&1 & P=$!; sleep 1; kill -USR1 $P; wait $P; echo rc=$?; cat ~w",
           [C, F1, O1, O1]),
    shell(Cmd1, T1, _, 120000),
    (   sub_atom(T1, _, _, _, 'answer(usr1,'),
        sub_atom(T1, _, _, _, 'rc=0')
    ->  check('the child caught the delivered usr1, and ended 0', yes, yes)
    ;   check('the child caught the delivered usr1, and ended 0', T1, caught)
    ),

    atom_concat(D, '/sigplain.pl', F2),
    fixture(F2, ['main :- use_module(library(signal)),',
                 '        on_signal(usr1, _, throw),',
                 '        raise_signal(usr1).']),
    format(atom(Cmd2), "~w --local -s ~w 2>&1; echo rc=$?", [C, F2]),
    shell(Cmd2, T2, _, 120000),
    (   sub_atom(T2, _, _, _, 'Caught signal'),
        sub_atom(T2, _, _, _, '(usr1)'),
        sub_atom(T2, _, _, _, 'rc=2')
    ->  check('an uncaught one is SWI\'s sentence, and the -s host ends 2', yes, yes)
    ;   check('an uncaught one is SWI\'s sentence, and the -s host ends 2', T2, uncaught)
    ),

    atom_concat(D, '/sigignore.pl', F3),
    fixture(F3, ['main :- use_module(library(signal)),',
                 '        on_signal(usr1, _, ignore),',
                 '        raise_signal(usr1),',
                 '        write(ignored), nl.']),
    format(atom(Cmd3), "~w --local -s ~w 2>&1; echo rc=$?", [C, F3]),
    shell(Cmd3, T3, _, 120000),
    (   sub_atom(T3, _, _, _, 'ignored'),
        sub_atom(T3, _, _, _, 'rc=0')
    ->  check('ignoring a delivered signal lets the goal go on', yes, yes)
    ;   check('ignoring a delivered signal lets the goal go on', T3, ignored)
    ).

%% ---- the REPL -----------------------------------------------------------
repl_cases(D) :-
    section('the toplevel catches Ctrl+C and still ends on Ctrl+D'),
    atom_concat(D, '/repl.in', In),
    fixture(In, ['between(1, 1000000000, _), fail.', 'halt.']),
    atom_concat(D, '/repl.out', Out),
    cocolog(C),
    format(atom(Cmd1),
           "~w --local < ~w > ~w 2>&1 & P=$!; sleep 1; kill -INT $P; wait $P; echo rc=$?; cat ~w",
           [C, In, Out, Out]),
    shell(Cmd1, T1, _, 120000),
    (   sub_atom(T1, _, _, _, 'Caught signal 2 (int)'),
        sub_atom(T1, _, _, _, 'rc=0')
    ->  check('SIGINT stops the goal, the error is printed, the prompt reads halt.', yes, yes)
    ;   check('SIGINT stops the goal, the error is printed, the prompt reads halt.', T1, repl)
    ),
    format(atom(Cmd2), "~w --local < /dev/null 2>&1; echo rc=$?", [C]),
    shell(Cmd2, T2, _, 120000),
    (   sub_atom(T2, _, _, _, 'rc=0')
    ->  check('an empty input (Ctrl+D) still leaves with 0', yes, yes)
    ;   check('an empty input (Ctrl+D) still leaves with 0', T2, eof)
    ).
