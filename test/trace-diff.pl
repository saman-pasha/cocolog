%% trace-diff.pl -- compare two four-port traces, SWI's and cocolog's.
%%
%%     cocolog --local run test/trace-diff.pl td_main -- QUERY SWI-TEXT COCO-TEXT
%%
%% THE COCOLOG REWRITE OF test/trace-diff.py. Reads the query and the two raw
%% outputs from argv, keeps only the port lines, and normalises what the two
%% writers are entitled to disagree on: the depth base (each trace's first
%% line becomes depth 1), unbound variable names (_438 there, _G34 here),
%% module qualifiers on SWI's side, and spacing inside terms. Exits 0 when
%% the traces say the same thing, 1 with the first difference printed when
%% they do not.
%%
%% NO REGEX, AND THE PORT LINE IS THE REASON. `^\s*[?^]?\s*(Call|Exit|Redo|
%% Fail):\s*\((\d+)\)\s*(.*?)\s*$' wants three capture groups, and
%% library(text)'s re_first/3 answers the whole match and no groups -- so
%% every one would need a re_replace trick to get its parts out. Written as
%% a scan it is a dozen lines that say what they look for. The three
%% NORMALISERS are substitutions and would fit re_replace/4 exactly; they
%% are written out too, so the file has one idiom rather than two.

%% ---- one port line ------------------------------------------------------

%% td_port(+Line, -Port, -Depth, -Goal) is semidet.
td_port(Line, Port, Depth, Goal) :-
    td_ws(Line, A),
    td_opt_mark(A, B),
    td_ws(B, C),
    td_port_name(C, Port, D),
    D = [0':|E],
    td_ws(E, [0'(|F]),
    td_digits1(F, Ds, G),
    G = [0')|H],
    number_codes(Depth, Ds),
    td_ws(H, I),
    td_rstrip(I, Goal).

td_opt_mark([0'?|T], T) :- !.
td_opt_mark([0'^|T], T) :- !.
td_opt_mark(L, L).

td_port_name(Cs, 'Call', R) :- append("Call", R, Cs).
td_port_name(Cs, 'Exit', R) :- append("Exit", R, Cs).
td_port_name(Cs, 'Redo', R) :- append("Redo", R, Cs).
td_port_name(Cs, 'Fail', R) :- append("Fail", R, Cs).

%% ---- the three normalisers ----------------------------------------------
%%
%% Applied in the Python's order, which matters: the module strip runs before
%% the variable strip, so `lists:_438' loses its qualifier and then its
%% number rather than becoming `lists:_' and staying that way.

td_normalise(Goal, Out) :-
    td_strip_module(Goal, A),
    td_strip_var(A, B),
    td_strip_space(B, Out).

%% `\b[a-z][a-zA-Z0-9_]*:' -> '' -- lists:member becomes member. The word
%% boundary is what stops it eating the tail of an atom that ends in a
%% lower-case run followed by a colon.
td_strip_module([], []) :- !.
td_strip_module(Cs, Out) :-
    td_module_here(Cs, Rest),
    !,
    td_strip_module(Rest, Out).
td_strip_module([C|T], [C|R]) :- td_strip_module(T, R).

td_module_here(Cs, Rest) :-
    Cs = [C|T],
    td_lower(C),
    td_wordrun(T, T1),
    T1 = [0':|Rest].

td_wordrun([C|T], R) :- td_word(C), !, td_wordrun(T, R).
td_wordrun(L, L).

%% `_G?\d+' -> `_' -- _438 there, _G34 here.
td_strip_var([], []) :- !.
td_strip_var([0'_|T], [0'_|R]) :-
    td_var_tail(T, T1),
    !,
    td_strip_var(T1, R).
td_strip_var([C|T], [C|R]) :- td_strip_var(T, R).

td_var_tail([0'G|T], R) :- !, td_digits1(T, _, R).
td_var_tail(T, R) :- td_digits1(T, _, R).

%% `\s+' -> ''
td_strip_space([], []) :- !.
td_strip_space([C|T], R) :- td_space(C), !, td_strip_space(T, R).
td_strip_space([C|T], [C|R]) :- td_strip_space(T, R).

%% ---- a whole trace -------------------------------------------------------

%% td_ports(+Codes, -Rows) is det.
%% p(Port, Depth, Goal), with each trace's first line rebased to depth 1.
td_ports(Codes, Rows) :-
    td_lines(Codes, Lines),
    findall(p(P, D, G),
            ( member(L, Lines),
              td_port(L, P, D, G0),
              td_normalise(G0, G1),
              atom_codes(G, G1)
            ),
            Raw),
    (   Raw = [p(_, D0, _)|_]
    ->  Base is D0 - 1
    ;   Base = 0
    ),
    findall(p(P, D2, G),
            ( member(p(P, D1, G), Raw), D2 is D1 - Base ),
            Rows).

%% ---- the comparison -------------------------------------------------------

td_main :-
    current_prolog_flag(argv, [_, QueryA, SwiA, CocoA|_]),
    atom_codes(SwiA, Swi0),  td_ports(Swi0, Swi),
    atom_codes(CocoA, Coco0), td_ports(Coco0, Coco),
    td_compare(Swi, Coco, 1, QueryA).

td_compare([], [], _, _) :- !.
td_compare(Swi, Coco, N, Query) :-
    td_nth(Swi, A),
    td_nth(Coco, B),
    (   A == B
    ->  td_tail(Swi, S1), td_tail(Coco, C1),
        N1 is N + 1,
        td_compare(S1, C1, N1, Query)
    ;   format("  ?- ~w.   line ~w differs~n", [Query, N]),
        td_show('    swipl  : ', A),
        td_show('    cocolog: ', B),
        fail
    ).

td_nth([X|_], X) :- !.
td_nth([], none).

td_tail([_|T], T) :- !.
td_tail([], []).

td_show(Label, none) :- !, format("~w<nothing>~n", [Label]).
td_show(Label, p(P, D, G)) :- format("~w~w: (~w) ~w~n", [Label, P, D, G]).

%% ---- text helpers ---------------------------------------------------------

td_lines([], []) :- !.
td_lines(Cs, [L|Ls]) :-
    ( append(L, [0'\n|R], Cs) -> true ; L = Cs, R = [] ),
    !,
    ( R == [], L == [] -> Ls = [] ; td_lines(R, Ls) ).

td_space(0' ).  td_space(0'\t). td_space(0'\r).
td_space(0'\n). td_space(11).   td_space(12).

td_ws([C|T], R) :- td_space(C), !, td_ws(T, R).
td_ws(L, L).

td_rstrip(Cs, Out) :- reverse(Cs, R0), td_ws(R0, R1), reverse(R1, Out).

td_digits1([C|T], [C|Ds], R) :- td_digit(C), td_digits(T, Ds, R).
td_digits([C|T], [C|Ds], R) :- td_digit(C), !, td_digits(T, Ds, R).
td_digits(L, [], L).

td_digit(C) :- C >= 0'0, C =< 0'9.
td_lower(C) :- C >= 0'a, C =< 0'z.

td_word(C) :- C >= 0'a, C =< 0'z.
td_word(C) :- C >= 0'A, C =< 0'Z.
td_word(C) :- C >= 0'0, C =< 0'9.
td_word(0'_).
