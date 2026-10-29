%  A file read again, as SWI's load_files/2 reads it (2.14.0). Run by BOTH
%  SWI-Prolog and cocolog, output compared byte for byte; test/files.pl
%  writes each file's versions into the sandbox first, each at a time of
%  its own -- r.pl, r2.pl a second newer and r3.pl an hour older; c.pl and
%  c2.pl; g.pl and g2.pl -- and rename_file/2 puts the next one in place.
%  Every version's first line prints that it is being read.
%
%  Through 2.13 a file use_module/1 or ensure_loaded/1 had loaded stayed
%  that load whatever consult/1 or load_files/2 asked, its old clauses with
%  it (cicilang's report); a file read again kept the clauses of a
%  predicate its new text no longer defined; if(changed) read a file whose
%  time had only moved back; and if(exists) read it always.
%
%  WHAT IS LEFT OUT, because the two answer differently by design (STATUS.md,
%  2.14.0): a file with no clause in it, which swipl does not count as
%  loaded at all, so that even if(not_loaded) reads it again; and the order
%  of a predicate's clauses once the program asserted into it -- swipl puts
%  the file's new clause where its old one stood, cocolog after what the
%  program asserted -- so the last check sorts.

p(Name, G) :- catch((G -> R = yes ; R = no), error(F, _), R = raised(F)), format("~w: ~q~n", [Name, R]).
rs(L) :- findall(X, rp(X), L).

main :-
    %  loaded as ensure_loaded/1 loads it: nothing reads it again unasked
    p(ensure, ensure_loaded(r)),
    p(v1, rs([1])),
    p(ensure_again, ensure_loaded(r)),
    p(not_loaded, load_files(r, [if(not_loaded)])),
    p(changed_same, load_files(r, [if(changed)])),
    p(exists_same, load_files(r, [if(exists)])),
    %  the edited file, a second newer: if(changed) reads it, as the
    %  version it now is, and the predicate it no longer defines is unknown
    p(swap2, rename_file('r2.pl', 'r.pl')),
    p(ensure_edited, ensure_loaded(r)),
    p(not_loaded_edited, load_files(r, [if(not_loaded)])),
    p(still_v1, rs([1])),
    p(changed_newer, load_files(r, [if(changed)])),
    p(v2, rs([2])),
    p(dropped, rq(_)),
    p(changed_again, load_files(r, [if(changed)])),
    p(exists_again, load_files(r, [if(exists)])),
    %  an older file: if(changed) reads nothing, consult/1 reads it, and
    %  the predicate is back
    p(swap3, rename_file('r3.pl', 'r.pl')),
    p(changed_older, load_files(r, [if(changed)])),
    p(still_v2, rs([2])),
    p(consult, consult(r)),
    p(v3, rs([3])),
    p(back, (findall(Y, rq(Y), Q), Q == [3])),
    %  consult/1, [File] and if(true) read it each time, and hold it once
    p(consult_again, consult(r)),
    p(bracket, call([r])),
    p(lf_true, load_files(r, [if(true)])),
    p(v3_once, rs([3])),
    %  a file consulted, then consulted again without one of its predicates
    p(c_first, consult(c)),
    p(swap_c, rename_file('c2.pl', 'c.pl')),
    p(c_again, consult(c)),
    p(c_dropped, cq(_)),
    p(c_kept, (findall(Z, cp(Z), Cs), Cs == [2])),
    %  what the program asserted into the file's dynamic predicate stays
    p(g_first, ensure_loaded(g)),
    p(g_assert, assertz(gd(asserted))),
    p(swap_g, rename_file('g2.pl', 'g.pl')),
    p(g_consult, consult(g)),
    p(g_both, (findall(W, gd(W), Ws), msort(Ws, S), S == [asserted, file2])).
