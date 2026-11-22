%  A hook registered while the hooks run is not run, swipl 9.0.4's
%  '$run_at_halt' over the clauses that stood as it began, and the halt that
%  ran them ends the process, no other end running them again (cocolog
%  3.71.0: a host's end runs nothing after a halt that went on). Run by
%  BOTH SWI-Prolog and cocolog, output compared byte for byte; the rest of
%  at_halt/1 is test/files/at_halt.pl.

say(X) :- write(X), nl.

late :-
    at_halt(say(late_hook)),
    say(late_registered).

main :-
    set_prolog_flag(verbose, silent),
    at_halt(late),
    say(main),
    halt(3).
