%  library(sort), swipl 9.0.4's own file (lib/swipl/sort.pl, cocolog
%  3.76.0): predsort/3 and locale_sort/2, and the collation_key/2 the second
%  keys its atoms with. Run by BOTH SWI-Prolog and cocolog, output compared
%  byte for byte.
%
%  No use_module/1 of the library: the first call of predsort/3 loads it,
%  as swipl's autoloader does (cocolog's lib/autoload.cicili rows it beside
%  library(stream)'s names). Through 3.75.0 cocolog had neither predicate,
%  and every call here was an unknown procedure. The order matters:
%  predicate_property/2 imports what it names, in both systems, before
%  current_predicate/1 is asked of it; and the properties are asked
%  before anything calls locale_sort/2, because swipl's call of an export
%  imports it into user and cocolog's call imports nothing (COMPAT.md):
%  asked after `answers', p5 is yes in swipl and no here.
%
%  The helpers carry the library's module in an error's context
%  (sort:predsort/5), as the file's module/2 gives them; must_be(L, list),
%  with its arguments the other way round, is swipl's own and answers
%  existence_error(type, L) for a list that is no proper list. A
%  comparator that answers twice gives predsort/3 two answers.
%
%  collation_key/2 is cocolog's C, the text as a string, which is swipl's
%  under LC_COLLATE C and C.UTF-8 (COMPAT.md): no text here goes past
%  ASCII, and no string is written as "...", whose reading the
%  double_quotes flag of each system decides. swipl's key follows the
%  process's locale, so main sets its collation to C first, where the
%  system has setlocale/3 (swipl; cocolog has none, and its key is C's
%  whatever the locale): on a box whose LANG collates otherwise
%  (en_US.UTF-8 sorts a before 'B') the case holds all the same.

pv(T) :- \+ \+ ( numbervars(T, 0, _), print(T) ).
t(L, G) :-
    catch(( G -> R = yes(G) ; R = no ), E, R = caught(E)),
    ( R = caught(error(F, C)) -> pv(L-caught(F, C)) ; pv(L-R) ),
    nl.
all(L, G) :- catch(( G, pv(L-G), nl, fail ; true ), E, ( pv(L-caught(E)), nl )).

%% the comparators
by_len(O, A, B) :- atom_length(A, LA), atom_length(B, LB), compare(O, LA, LB).
rev(O, A, B) :- compare(O, B, A).
bad(x, _, _).
nd(<, _, _).
nd(>, _, _).
eq(=, _, _).
keyc(O, K1-_, K2-_) :- compare(O, K1, K2).

%% a guarded clause whose last call is the library's: predsort/3 is
%% transparent (its meta_predicate spec), so the guard is taken off with
%% the frame, as swipl's I_DEPART takes it; locale_sort/2 is not, and a
%% choice point it leaves is its own frame's, named by its module
gd(L) :- $, predsort(nd, [a, b], L).
ge(L) :- $, predsort(compare, [b, a], L).
gf(L) :- $, locale_sort([b, a], L).
gg(L) :- $, locale_sort([a|_], L).
gh(L) :- $, predsort(nd, [a, b], L), true.

%% a goal under each limit from 0 to N, and how it ended
r(G, Lim, R) :-
    copy_term(G, G1),
    catch(( call_with_depth_limit(G1, Lim, R0) -> R = R0 ; R = failed ), E, R = caught(E)).
short(caught(error(F, _)), caught(F)) :- !.
short(X, X).
d(L, G, N) :-
    findall(Lim-S, ( between(0, N, Lim), r(G, Lim, R), short(R, S) ), Rs),
    pv(L-G-Rs), nl.

main :-
    t(p0, current_predicate(predsort/3)),
    ( current_predicate(setlocale/3) -> setlocale(collate, _, 'C') ; true ),
    sorts,
    errors,
    props,
    answers,
    keys,
    depths.

%% what predsort/3 answers: sort/2's order under compare/3, each
%% comparator's own, the duplicates dropped where it says =
sorts :-
    t(s1, predsort(compare, [c, a, b, a], _)),
    t(s2, predsort(rev, [c, a, b, a], _)),
    t(s3, predsort(by_len, [abc, a, ab, b], _)),
    t(s4, predsort(compare, [], _)),
    t(s5, predsort(compare, [x], _)),
    t(s6, predsort(compare, [b, a], _)),
    t(s7, predsort(keyc, [2-a, 1-b, 2-c, 1-d], _)),
    t(s8, predsort(eq, [a, b, c], _)),
    t(s9, predsort(bad, [a, b], _)),
    t(s10, predsort(bad, [a], _)),
    t(s11, predsort(compare, [b, a], [a, b])),
    t(s12, predsort(compare, [b, a], [b, a])),
    t(s13, predsort(compare, [c, b, a], [a|T13])), pv(T13), nl,
    t(s14, predsort(lists:compare, [b, a], _)),
    t(s15, predsort(user:rev, [a, b], _)),
    t(s16, predsort([O16, A16, B16]>>compare(O16, A16, B16), [b, a, c], _)),
    t(s17, predsort(compare, [1, 1.0, a, f(x), Z17], _)), pv(Z17), nl,
    t(s18, predsort(compare, [b, a, c, a, b], [_, _, _])),
    t(s19, predsort(rev, [1, 2, 3, 4, 5, 6, 7, 8, 9], _)),
    t(s20, predsort(compare, [f(Y20), f(X20)], _)), pv(X20-Y20), nl.

%% a comparator that is none, and a list that is none
errors :-
    t(e1, predsort(nosuch, [a, b], _)),
    t(e2, predsort(compare, [a|_], _)),
    t(e3, predsort(compare, foo, _)),
    t(e4, predsort(compare, [a|b], _)),
    t(e5, predsort(compare, _, _)),
    t(e6, predsort(_, [a, b], _)),
    t(e7, predsort(3, [a, b], _)),
    t(e8, predsort(compare(<), [b, a], _)),
    t(e9, predsort(compare, L9, [a])), pv(L9), nl,
    t(e10, predsort(compare, [a, b|T10], _)), pv(T10), nl,
    t(e11, predsort(nosuch, [a], _)),
    t(e12, predsort(nosuch, [], _)).

%% a comparator's second answer is predsort/3's second, and a guard sees
%% the choice point it leaves; a guarded clause's last call of each export
%% (the library is loaded by now: a first call that loads it is no last
%% call in swipl, COMPAT.md)
answers :-
    all(a1, predsort(nd, [a, b, c], _)),
    all(a2, predsort(nd, [a, b], _)),
    t(a3, $(predsort(compare, [b, a], _))),
    t(a4, $(predsort(nd, [a, b], _))),
    t(a5, findall(L5, predsort(nd, [x, y, z], L5), _)),
    t(a6, gd(_)),
    t(a7, ge(_)),
    t(a8, gf(_)),
    t(a9, gg(_)),
    t(a10, gh(_)),
    t(a11, findall(L11, gd(L11), _)).

%% the predicates as predicate_property/2 and current_predicate/1 see them;
%% the library's helpers are no predicates of user's in either (cocolog's
%% props rows of flag 4096: one namespace holds their clauses)
props :-
    t(p1, predicate_property(predsort(_, _, _), imported_from(M1))), pv(M1), nl,
    t(p2, predicate_property(predsort(_, _, _), meta_predicate(S2))), pv(S2), nl,
    t(p3, predicate_property(predsort(_, _, _), transparent)),
    t(p4, current_predicate(predsort/3)),
    t(p5, current_predicate(locale_sort/2)),
    t(p6, current_predicate(predmerge/4)),
    t(p7, predicate_property(collation_key(_, _), built_in)),
    t(p8, current_predicate(collation_key/2)),
    t(p9, predicate_property(predmerge(_, _, _, _), _)),
    t(p10, predicate_property(collation_keys(_, _), number_of_clauses(_))).

%% collation_key/2 and locale_sort/2: the key is the text, a string
keys :-
    atom_string(str, Str),
    atom_string(s, S),
    t(k1, collation_key(b, _)),
    t(k2, collation_key('', _)),
    t(k3, collation_key(_, _)),
    t(k4, collation_key(1, _)),
    t(k5, collation_key(f(x), _)),
    t(k6, collation_key(Str, _)),
    t(k7, collation_key([a], _)),
    t(k8, collation_key(b, b)),
    t(k9, collation_key(b, x)),
    t(k10, collation_key(1.5, _)),
    t(k11, collation_key([], _)),
    t(k12, (collation_key(b, K12), string(K12))),
    t(k13, (collation_key(b, K13), atom_string(A13, K13), A13 == b)),
    t(k14, locale_sort([b, a, 'B', c, 'E'], _)),
    t(k15, locale_sort([], _)),
    t(k16, locale_sort([x, 1], _)),
    t(k17, locale_sort(foo, _)),
    t(k18, locale_sort([a|_], _)),
    t(k19, locale_sort([S, a], _)),
    t(k20, locale_sort([b, a, b], _)),
    t(k21, locale_sort([b, a], [a, b])),
    t(k22, locale_sort(_, _)).

%% the library's frames under a depth limit, swipl's own clauses counted
%% as swipl's are: loaded already, so no load is counted
depths :-
    forall(member(G, [predsort(compare, [], _), predsort(compare, [a], _),
                      predsort(compare, [b, a], _), predsort(compare, [c, b, a], _),
                      predsort(rev, [a, b, c, d], _), predsort(nd, [a, b], _),
                      predsort(nosuch, [a, b], _), predsort(compare, foo, _),
                      locale_sort([b, a], _), collation_key(b, _)]),
           d(d, G, 9)).
