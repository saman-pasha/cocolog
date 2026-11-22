%  The tenth cancel of a halt, swipl 9.0.4's MAX_HALT_CANCELLED (cocolog
%  3.71.0): a hook that cancels makes halt/1 fail nine times, and the tenth
%  halt ends the process all the same, the hooks behind the canceller never
%  run. Run by BOTH SWI-Prolog and cocolog, output compared byte for byte
%  (the exit status, 10 in both, is test/script.pl's). The rest of
%  at_halt/1 and cancel_halt/1 is test/files/at_halt.pl.

say(X) :- write(X), nl.

main :-
    set_prolog_flag(verbose, silent),
    at_halt(say(never)),
    at_halt(cancel_halt(always)),
    at_halt(say(only_once)),
    halts(1).

halts(K) :-
    (   halt(K)
    ->  say(halt_returned)
    ;   print(cancelled(K)), nl
    ),
    K1 is K + 1,
    halts(K1).
