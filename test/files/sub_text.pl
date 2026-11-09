%  sub_atom/5 and sub_string/5, swipl 9.0.4's sub_text() (cocolog 3.58.2).
%  What is given chooses the walk:
%  - two of Before, Length and After given are the third worked out: one
%    answer and no choice point;
%  - one of them given walks the other two, and its last answer leaves no
%    choice point;
%  - a bound Sub is a test where Before or After is given, and else a search
%    that keeps a choice point after a place only where another place would
%    fit (`ab' in `abcab' ends at 3 with none, `a' at 3 with one).
%  The case holds every mode of every answer of five texts -- each of
%  Before, Length, After and Sub given or not, given as an answer gives it --
%  with whether each answer left a choice point, then the failures and the
%  errors, then arguments that are one variable, for both predicates: a Sub
%  that a walk binds through Before or Length is an integer then, which no
%  substring unifies with, never a Sub given (sub_atom('1', 0, L, _, L)
%  fails; 3.58.2's first cut compared its text and said L = 1).
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%  Through 3.58.1 a bound Sub left no choice point at its last place, an
%  unbound one walked every Before and every Length, its last answer leaving
%  one, and sub_atom(A, B, 3, 0, S) asked every place of A.

:- set_prolog_flag(double_quotes, codes).

%% each answer of G, and whether it left a choice point
answers(G, Vs, L) :-
    findall(Vs-D, ( call_cleanup(G, Det = true), ( Det == true -> D = det ; D = more ) ), L).

%% the goal as it was asked, its variables written `_'
shown(G, S) :-
    copy_term(G, S), term_variables(S, Vs), maplist(=('$VAR'('_')), Vs).

%% one goal: what it answered, or what it raised
q(P, T, Ms) :-
    args(Ms, As),
    G =.. [P, T|As],
    shown(G, S),
    catch(( answers(G, As, R), Out = (S => R) ), error(E, _), Out = (S => raised(E))),
    plain(Out, Plain), print(Plain), nl.

%% text past ASCII written as its codes: swipl escapes it on a stream its
%% locale cannot encode, where cocolog writes UTF-8 (COMPAT.md)
plain(X, Y) :-
    ( atom(X) ; string(X) ), atom_codes(X, Cs), member(C, Cs), C > 127, !,
    ( atom(X) -> Y = atom_codes(Cs) ; Y = string_codes(Cs) ).
plain(X, Y) :- compound(X), !, X =.. [F|As], maplist(plain, As, Bs), Y =.. [F|Bs].
plain(X, X).

args([], []).
args([u|Ms], [_|As]) :- args(Ms, As).
args([v(X)|Ms], [X|As]) :- args(Ms, As).

given(X, v(X)).
given(_, u).

%% every mode of every answer of P over T, each asked once
modes(P, T) :-
    findall(B-L-A-S, call(P, T, B, L, A, S), Sols),
    findall([GB, GL, GA, GS],
            ( member(B-L-A-S, Sols), given(B, GB), given(L, GL), given(A, GA), given(S, GS) ),
            Ms0),
    sort(Ms0, Mss),
    forall(member(Ms, Mss), q(P, T, Ms)).

%% what fails, and what raises
fails(P) :-
    forall(member(Ms, [ [v(9), u, u, u], [u, v(9), u, u], [u, u, v(9), u], [u, u, u, v(zz)],
                        [v(1), v(1), v(1), u], [v(1), u, v(1), v(x)], [u, v(2), u, v(abc)],
                        [v(0), v(0), u, v('')], [u, v(0), u, v('')], [u, u, v(0), v('')],
                        [v(4), v(2), u, u], [u, v(2), v(4), u], [v(3), u, v(3), u],
                        [v(-1), u, u, u], [u, v(-1), u, u], [u, u, v(-1), u],
                        [v(a), u, u, u], [u, v(a), u, u], [u, u, v(a), u],
                        [u, u, u, v(f(x))], [u, u, u, v("ab")],
                        [v(0), v(1), u, v(ab)], [u, v(1), v(3), v(ab)], [v(0), v(2), v(2), v(ab)] ]),
           q(P, abcab, Ms)),
    q(P, _, [u, u, u, u]), q(P, f(x), [u, u, u, u]), q(P, "ab", [u, u, u, u]),
    q(P, 12, [u, v(1), u, u]), q(P, a12b, [u, u, u, v(12)]), q(P, a12b, [u, u, u, v(2)]),
    %% a bound Sub is text whatever its type, where Before or After is given
    atom_string(ab, Ab),
    q(P, a12b, [v(1), u, u, v(12)]), q(P, a12b, [u, u, v(1), v(12)]),
    q(P, abcab, [v(3), u, u, v(ab)]), q(P, abcab, [u, u, v(0), v(Ab)]).

%% arguments that are one variable: the goal shown with them named
qa(G) :-
    term_variables(G, Vs),
    copy_term(G, S), numbervars(S, 0, _),
    catch(( answers(G, Vs, R), Out = (S => R) ), error(E, _), Out = (S => raised(E))),
    print(Out), nl.

alias('1', [0, L, _, L]).
alias('01', [_, B, _, B]).
alias('10', [B, _, _, B]).
alias(a0, [B, _, _, B]).
alias(a0, [1, 1, X, X]).
alias(a00, [_, L, L, _]).
alias(ab1, [B, 1, _, B]).
alias(a01, [_, _, A, A]).
alias(abcde, [1, L, L, _]).
alias(abc, [B, 1, B, _]).
alias(abcd, [1, X, X, bc]).
alias(abcd, [X, X, _, b]).
%% not abab: swipl 9.0.4's search succeeds at the last place that fits
%% whether or not its unifications did (pl-prims.c's SUB_SEARCH goes to
%% exit_succeed without asking `match'), so sub_atom(abab, X, X, _, b)
%% answers X = 3, its After unbound, where cocolog fails (COMPAT.md)
alias(abc, [B, L, B, b]).
alias('0x', [0, 1, _, 0]).
alias(a1, [X, _, _, X]) :- X = 1.

aliases(P) :-
    forall(alias(T, As),
           ( ( P == sub_string -> atom_string(T, Tx) ; Tx = T ), G =.. [P, Tx|As], qa(G) )).

main :-
    atom_codes(Wide, [0'a, 233, 0'a]),
    forall(member(T, [abcab, a, '', aaa, Wide]), modes(sub_atom, T)),
    fails(sub_atom),
    forall(member(T, [abcab, '', Wide]), ( atom_string(T, S), modes(sub_string, S) )),
    atom_string(ab, Ab), modes(sub_string, ab), modes(sub_atom, Ab),
    fails(sub_string),
    aliases(sub_atom), aliases(sub_string).
