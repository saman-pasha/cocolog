%  A halt in a directive, swipl 9.0.4's: the load ends there and the hooks
%  registered so far run, a hook a hook registers is not run, and nothing
%  after the halt runs one again (cocolog 3.71.0: the load's end of the
%  process, `coco_halt_load', runs nothing after a halt that went on). Run
%  by BOTH SWI-Prolog and cocolog, output compared byte for byte; main is
%  never reached. The rest of at_halt/1 is test/files/at_halt.pl.

say(X) :- write(X), nl.

late :-
    at_halt(say(late_hook)),
    say(late_registered).

:- at_halt(late).
:- at_halt(say(directive_hook)).
:- halt(4).

main :-
    say(never).
