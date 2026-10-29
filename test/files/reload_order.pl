%  The clauses of a file read again, in the order SWI's reload puts them
%  (2.14.1). Run by BOTH SWI-Prolog and cocolog, output compared byte for
%  byte; test/files.pl writes each file's versions into the sandbox first
%  (s1.pl, s1.v2.pl, ...), and rename_file/2 puts the next one in place.
%
%  swipl 9.0.4's rule, which these probe: a pointer starts at the
%  predicate's first clause, and each clause the file says now looks from
%  it for one equal to it (a variant) that the file put there before or
%  that no file did (asserted). Found, that one stays where it stands -- an
%  asserted one becomes the file's -- and the pointer moves past it; not
%  found, the new clause goes in before the pointer. What the file put
%  there and does not say again goes; another file's clause is never a
%  candidate; and a file read for the first time appends. Through 2.14.0 a
%  file read again put its clauses after every clause the program had
%  asserted.

l(Name, G, X) :- findall(X, G, L0), maplist(vv, L0, L), format("~w: ~q~n", [Name, L]).
vv(X, Y) :- ( var(X) -> Y = '_' ; Y = X ).
swap(F, V) :- atomic_list_concat([F, '.', V, '.pl'], From), atomic_list_concat([F, '.pl'], To), rename_file(From, To).

main :- changed, kept, sides, adopted, firsts, files, open_call.

%  every clause changed, some kept, some new, with clauses asserted before
%  and after the file's
changed :-
    consult(s1), assertz(s1(a)), swap(s1, v2), consult(s1), l(s1_all_changed, s1(X1), X1),
    consult(s2), asserta(s2(z)), swap(s2, v2), consult(s2), l(s2_asserta, s2(X2), X2),
    consult(s10), assertz(s10(a)), asserta(s10(z)), swap(s10, v2), consult(s10),
    l(s10_both_sides, s10(X3), X3).

kept :-
    consult(s3), assertz(s3(a)), swap(s3, v2), consult(s3), l(s3_added_end, s3(X1), X1),
    consult(s4), assertz(s4(a)), swap(s4, v2), consult(s4), l(s4_added_front, s4(X2), X2),
    consult(s5), assertz(s5(a)), swap(s5, v2), consult(s5), l(s5_removed, s5(X3), X3),
    consult(s6), assertz(s6(a)), swap(s6, v2), consult(s6), l(s6_reordered, s6(X4), X4),
    consult(s9), assertz(s9(a)), swap(s9, v2), consult(s9), l(s9_middle, s9(X5), X5),
    %  the same clause twice in the file, and once more each time
    consult(d), assertz(d(a)), swap(d, v2), consult(d), l(d_duplicates, d(X6), X6),
    %  a variant: the same clause whatever its variables are called
    consult(v), assertz(v(a, b)), swap(v, v2), consult(v), l(v_variant, v(X7, _), X7),
    %  a predicate nobody declared dynamic
    consult(st), swap(st, v2), consult(st), l(st_static, st(X8), X8),
    %  a variant with a body, past a clause the program put in front
    consult(w), asserta(w(z)), swap(w, v2), consult(w), l(w_variant_kept, w(X9), X9),
    %  an atom spelled like a variable's name is no variable: no variant
    consult(wq), asserta(wq('_G5')), swap(wq, v2), consult(wq), l(wq_quoted, wq(X10), X10),
    %  nor is a name with one inside it
    consult(wb), asserta(wb(a_G5)), swap(wb, v2), consult(wb), l(wb_inside_name, wb(X11), X11),
    %  two variables where the program's clause has one twice: no variant
    consult(sh), asserta(sh(Z, Z)), swap(sh, v2), consult(sh),
    l(sh_shared, (sh(P, Q), ( P == Q -> R = same ; R = apart )), R).

%  the file's clauses split around what the program asserted, read again
%  three times
sides :-
    consult(s7), assertz(s7(a)), swap(s7, v2), consult(s7), l(s7_v2, s7(X1), X1),
    assertz(s7(b)), swap(s7, v3), consult(s7), l(s7_v3, s7(X2), X2),
    consult(s8), asserta(s8(z)), assertz(s8(a)), swap(s8, v2), consult(s8),
    l(s8_mixed, s8(X3), X3),
    consult(sp), assertz(sp(a)), asserta(sp(z)), swap(sp, v2), consult(sp), l(sp_v2, sp(X4), X4),
    swap(sp, v3), consult(sp), l(sp_v3_unchanged, sp(X5), X5),
    swap(sp, v4), consult(sp), l(sp_v4_swapped, sp(X6), X6),
    %  the pointer on a clause the program put in front, the file's own gone
    consult(k), asserta(k(z)), assertz(k(a)), retract(k(1)), l(k_before, k(X7), X7),
    swap(k, v2), consult(k), l(k_after, k(X8), X8),
    %  what a directive sees half way through the read: the old clauses
    %  out of sight, the new one and the asserted one there
    consult(m), assertz(m(a)), swap(m, v2), consult(m), l(m_end, m(X9), X9),
    %  what the pointer has passed is no candidate: the program's twin of a
    %  clause the file says after it stays, and the file's goes in again
    consult(bp), asserta(bp(z)), swap(bp, v2), consult(bp), l(bp_passed, bp(X10), X10),
    %  and one the file took for its own moves the pointer past it too
    consult(ba), asserta(ba(w)), assertz(ba(x)), swap(ba, v2), consult(ba),
    l(ba_taken_passed, ba(X11), X11).

%  a clause the file says that the program had asserted becomes the file's:
%  held once, and gone when the file stops saying it
adopted :-
    consult(e), assertz(e(3)), swap(e, v2), consult(e), l(e_adopted, e(X1), X1),
    swap(e, v3), consult(e), l(e_dropped, e(X2), X2),
    consult(e2), assertz(e2(3)), swap(e2, v2), consult(e2),
    retract(e2(3)), l(e2_held_once, e2(X3), X3),
    %  and in a file read again, a predicate it did not define before
    consult(n), assertz(nq(a)), assertz(nr(x)), swap(n, v2), consult(n),
    l(nq_new_to_file, nq(X4), X4), l(nr_new_to_file, nr(X5), X5).

%  a file read for the first time appends, beside what was asserted
firsts :-
    assertz(fq(a)), assertz(fr(x)), consult(fresh),
    l(fq_first_read, fq(X1), X1), l(fr_first_read, fr(X2), X2),
    assertz(q(1)), assertz(q(a)), consult(q), l(q_first_read, q(X3), X3),
    swap(q, v2), consult(q), l(q_read_again, q(X4), X4).

%  two files' clauses of one predicate: the other's are no candidates
files :-
    consult(f1), consult(f2), l(mf_both, mf(X1), X1),
    swap(f1, v2), consult(f1), l(mf_f1_v2, mf(X2), X2),
    swap(f1, v3), consult(f1), l(mf_f1_v3, mf(X3), X3),
    %  a clause equal to the other file's: the file says it again beside it
    consult(g1), consult(g2), l(mg_both, mg(X4), X4),
    swap(g1, v2), consult(g1), l(mg_other_no_candidate, mg(X5), X5).

%  a call open on the predicate while its file is read again sees the
%  clauses that stood when it began, and a call after it the new order
open_call :-
    consult(of), assertz(of(a)),
    findall(X, ( of(X), ( X == 1 -> swap(of, v2), consult(of) ; true ) ), L1),
    format("of_open: ~q~n", [L1]),
    l(of_after, of(X2), X2).
