%  sleep/1, run by BOTH SWI-Prolog and cocolog and the output compared byte
%  for byte: any number is a time in seconds (an integer, a rational, a
%  float), a time below zero no sleep, a NaN or a time past 2^63 seconds a
%  return at once (swipl's time_t cast on Linux x86-64), and anything else
%  swipl's type_error(float, T), unbound instantiation_error, named
%  system:sleep/1 and printed with its `sleep/1: ' prefix. A time slept is
%  told by the clock, at least the time asked and less than a second more.

r(Label, Goal) :-
    catch(( Goal -> R = yes ; R = no ), E, R = ex(E)),
    copy_term(Label-R, C), term_variables(C, Vs), bindv(Vs), print(C), nl.
bindv([]).
bindv([v|Vs]) :- bindv(Vs).

slept(Label, T, Least) :-
    get_time(T0), sleep(T), get_time(T1), D is T1 - T0,
    ( D >= Least, D < Least + 1.0 -> R = ok ; R = off(D) ),
    print(Label-R), nl.

main :- taken, refused, slept, said.

taken :-
    r(zero, sleep(0)),
    r(zero_float, sleep(0.0)),
    r(negative, sleep(-1)),
    r(negative_float, sleep(-1.5)),
    r(negative_inf, sleep(-1.0Inf)),
    r(inf, sleep(1.0Inf)),
    r(nan, sleep(1.5NaN)),
    r(huge, sleep(1.0e300)),
    r(past_2_63, sleep(1.0e19)),
    r(small, sleep(0.001)),
    r(rational, sleep(1r1000)),
    r(bound_later, ( X = 0, sleep(X) )).

refused :-
    r(unbound, sleep(_)),
    r(atom, sleep(a)),
    r(compound, sleep(foo(1))),
    r(string, ( atom_string('1', S), sleep(S) )),
    r(list, sleep([1])),
    r(empty, sleep([])).

slept :-
    slept(tenth, 0.1, 0.099),
    slept(quarter, 1r4, 0.249),
    slept(integer, 1, 0.999).

said :-
    catch(sleep(a), E1, ( print_message(error, E1) )),
    catch(sleep(_), E2, ( print_message(error, E2) )),
    writeln(said).
