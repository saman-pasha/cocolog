%  A file read again registers its `:- at_halt(G)' hooks afresh, swipl
%  9.0.4's reconsult of its '$at_halt'/2 clauses (cocolog 3.71.0): a hook
%  the new text repeats keeps its place, among another file's hooks too, a
%  new one goes beside the file's others, and one the text no longer says
%  is gone; a file read again as it was runs its hook once, and a goal's
%  hook stays. Run by BOTH SWI-Prolog and cocolog, output compared byte for
%  byte; the files it reads it writes into the sandbox it runs in. Through
%  3.70.0 cocolog had no at_halt/1; the rest of it is
%  test/files/at_halt.pl.

say(X) :- write(X), nl.

write_file(F, Lines) :-
    open(F, write, S),
    forall(member(L, Lines), format(S, "~w~n", [L])),
    close(S).

main :-
    set_prolog_flag(verbose, silent),
    at_halt(say(goal_hook)),
    write_file('ha.pl', [':- at_halt(say(ha_first)).', ':- at_halt(say(ha_kept)).']),
    consult(ha),
    write_file('hd.pl', [':- at_halt(say(hd_between)).']),
    consult(hd),
    write_file('ha.pl', ['', ':- at_halt(say(ha_kept)).', ':- at_halt(say(ha_second)).']),
    consult(ha),
    write_file('hb.pl', [':- at_halt(say(hb_gone)).']),
    consult(hb),
    write_file('hb.pl', ['hb_fact.']),
    consult(hb),
    write_file('hc.pl', [':- at_halt(say(hc_same)).']),
    consult(hc),
    consult(hc),
    say(main_done).
