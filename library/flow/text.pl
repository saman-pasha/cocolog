%% library(flow/chart), part: terms as text, and how wide text is drawn.

%% ======================================================================
%% Text: terms written with their own variable names
%% ======================================================================
%%
%% write_term/2's variable_names is not honoured by cocolog, and the chart
%% needs each argument on its own anyway, to colour it by its mode -- so
%% the terms are written here, by a grammar over the term.

flow_term_text(T, Names, Prec, A) :-
    flow_term_full(T, Names, Prec, A0),
    flow_clip(A0, 26, A).

flow_term_full(T, Names, Prec, A) :-
    phrase(flow_t(T, Names, Prec), Cs),
    atom_codes(A, Cs).

flow_t(V, Names, _) --> { var(V) }, !, flow_tv(V, Names).
flow_t(N, _, _) --> { number(N) }, !, { number_codes(N, Cs) }, flow_codes(Cs).
flow_t('…', _, _) --> !, { atom_codes('…', Cs) }, flow_codes(Cs).
%% anything atomic but a number is written as writeq/1 writes it: an atom,
%% the list's end `[]' -- no atom since cocolog 3.0.0, as in swipl 7 -- and a
%% string, which until then fell through to the compound clause and failed
flow_t(A, _, _) --> { atomic(A) }, !, flow_ta(A).
flow_t(T, _, _) --> { flow_is_text(T) }, !, "\"", flow_codes(T), "\"".
flow_t([H|T], Names, _) -->
    { flow_code_prefix([H|T], Cs, Tail), var(Tail) }, !,
    "[", flow_code_items(Cs), "|", flow_tv(Tail, Names), "]".
flow_t([H|T], Names, _) --> !, "[", flow_t(H, Names, 999), flow_tl(T, Names), "]".
flow_t({X}, Names, _) --> !, "{", flow_t(X, Names, 1200), "}".
flow_t(T, Names, P) --> { T =.. [F, L, R], flow_infix(F, OP, LP, RP) }, !,
    flow_open(OP, P),
    flow_t(L, Names, LP),
    { flow_infix_text(F, OT), atom_codes(OT, OCs) },
    flow_codes(OCs),
    flow_t(R, Names, RP),
    flow_close(OP, P).
flow_t(T, Names, P) --> { T =.. [F, X], flow_prefix(F, OP, XP) }, !,
    flow_open(OP, P),
    flow_ta(F),
    flow_prefix_gap(F),
    flow_t(X, Names, XP),
    flow_close(OP, P).
flow_t(T, Names, _) --> { T =.. [F|Args] }, flow_ta(F), "(", flow_targs(Args, Names), ")".

flow_tl(T, _) --> { T == [] }, !, [].
flow_tl(T, Names) --> { var(T) }, !, "|", flow_tv(T, Names).
flow_tl([H|T], Names) --> !, ", ", flow_t(H, Names, 999), flow_tl(T, Names).
flow_tl(T, Names) --> "|", flow_t(T, Names, 999).

flow_targs([A], Names) --> !, flow_t(A, Names, 999).
flow_targs([A|As], Names) --> flow_t(A, Names, 999), ", ", flow_targs(As, Names).

flow_open(OP, P) --> { OP > P }, !, "(".
flow_open(_, _) --> [].

flow_close(OP, P) --> { OP > P }, !, ")".
flow_close(_, _) --> [].

flow_tv(V, Names) --> { flow_var_name(V, Names, N), atom_codes(N, Cs) }, !, flow_codes(Cs).
flow_tv(_, _) --> "_".

flow_ta(A) --> { format(atom(Q), '~q', [A]), atom_codes(Q, Cs) }, flow_codes(Cs).

flow_codes([]) --> [].
flow_codes([C|Cs]) --> [C], flow_codes(Cs).

flow_prefix_gap(F) --> { atom_codes(F, [C|_]), C >= 0'a, C =< 0'z }, !, " ".
flow_prefix_gap('\\+') --> !, " ".
flow_prefix_gap(_) --> [].

%% A LIST OF CODES WITH AN OPEN TAIL is what a grammar's terminal becomes:
%% `[0'+|S0]' says what `[43|S0]' does not. Only codes a reader sees as
%% characters, and no quote or backslash, which would need escaping.
flow_code_prefix([C|T], [C|Cs], Tail) :-
    integer(C), C >= 33, C =< 126, C =\= 39, C =\= 92, C =\= 34,
    (   var(T) -> Cs = [], Tail = T
    ;   T = [_|_], flow_code_prefix(T, Cs, Tail)
    ).

flow_code_items([C]) --> !, "0'", [C].
flow_code_items([C|Cs]) --> "0'", [C], ", ", flow_code_items(Cs).

flow_is_text(T) :-
    is_list(T),
    T = [_|_],
    flow_printable(T).

flow_printable([]).
flow_printable([C|Cs]) :-
    integer(C), C >= 32, C =< 126, C =\= 34, C =\= 92,
    flow_printable(Cs).

flow_op(':-', xfx, 1200).
flow_op('-->', xfx, 1200).
flow_op(';', xfy, 1100).
flow_op('|', xfy, 1100).
flow_op('->', xfy, 1050).
flow_op('*->', xfy, 1050).
flow_op(',', xfy, 1000).
flow_op('=', xfx, 700).
flow_op('\\=', xfx, 700).
flow_op('==', xfx, 700).
flow_op('\\==', xfx, 700).
flow_op('@<', xfx, 700).
flow_op('@>', xfx, 700).
flow_op('@=<', xfx, 700).
flow_op('@>=', xfx, 700).
flow_op('=..', xfx, 700).
flow_op(is, xfx, 700).
flow_op('=:=', xfx, 700).
flow_op('=\\=', xfx, 700).
flow_op('<', xfx, 700).
flow_op('>', xfx, 700).
flow_op('=<', xfx, 700).
flow_op('>=', xfx, 700).
flow_op('+', yfx, 500).
flow_op('-', yfx, 500).
flow_op('/\\', yfx, 500).
flow_op('\\/', yfx, 500).
flow_op(xor, yfx, 500).
flow_op('*', yfx, 400).
flow_op('/', yfx, 400).
flow_op('//', yfx, 400).
flow_op(mod, yfx, 400).
flow_op(rem, yfx, 400).
flow_op(div, yfx, 400).
flow_op('<<', yfx, 400).
flow_op('>>', yfx, 400).
flow_op('**', xfx, 200).
flow_op('^', xfy, 200).
flow_op(':', xfy, 200).

flow_infix(F, P, LP, RP) :-
    flow_op(F, Type, P),
    flow_op_sides(Type, P, LP, RP).

flow_op_sides(xfx, P, L, R) :- L is P - 1, R is P - 1.
flow_op_sides(xfy, P, L, P) :- L is P - 1.
flow_op_sides(yfx, P, P, R) :- R is P - 1.

flow_infix_text(',', ', ') :- !.
flow_infix_text(':', ':') :- !.
flow_infix_text(F, T) :- atomic_list_concat([' ', F, ' '], T).

flow_prefix('\\+', 900, 900).
flow_prefix('-', 200, 200).
flow_prefix('\\', 200, 200).

%% ---- widths -----------------------------------------------------------
%%
%% Code is drawn in a monospace font at 12px, 7.2px a character, so a
%% width is a count. In characters, the default since 2.0.0, a code is a
%% character and atom_length/2 counts them; under `text_units = bytes'
%% atom_codes/2 answers UTF-8 BYTES, and a character is every byte that is
%% not a continuation byte (128..191, which in characters are characters of
%% their own: a no-break space, a `»', a `¿'). Each test of a code below
%% asks the flag only past 127.

flow_chars(A, N) :-
    (   current_prolog_flag(text_units, bytes)
    ->  atom_codes(A, Cs),
        flow_count_chars(Cs, 0, N)
    ;   atom_length(A, N)
    ).

flow_count_chars([], N, N).
flow_count_chars([C|Cs], N0, N) :-
    (   C >= 128, C < 192 -> N1 = N0 ; N1 is N0 + 1 ),
    flow_count_chars(Cs, N1, N).

flow_text_w(Chars, W) :- W is (Chars * 72 + 9) // 10.

flow_segs_chars([], 0).
flow_segs_chars([s(T, _)|Ss], N) :-
    flow_chars(T, N1),
    flow_segs_chars(Ss, N2),
    N is N1 + N2.

flow_segs_w(Ss, W) :-
    flow_segs_chars(Ss, N),
    flow_text_w(N, W).

flow_clip(A, Max, C) :-
    flow_chars(A, N),
    (   N =< Max -> C = A
    ;   atom_codes(A, Cs),
        K is Max - 1,
        flow_take_chars(Cs, K, T),
        atom_codes(T0, T),
        atom_concat(T0, '…', C)
    ).

flow_take_chars([], _, []).
flow_take_chars([C|Cs], K, Out) :-
    (   C >= 128, C < 192, current_prolog_flag(text_units, bytes)
    ->  Out = [C|R], flow_take_chars(Cs, K, R)
    ;   K =:= 0 -> Out = []
    ;   K1 is K - 1, Out = [C|R], flow_take_chars(Cs, K1, R)
    ).

%% a goal as coloured segments: each argument in the colour of its mode
flow_goal_segs(G, Ms, Names, Segs) :-
    G =.. [F|Args],
    (   Args = [L, R], flow_infix(F, P, LP, RP), P >= 700, Ms = [ML, MR]
    ->  flow_term_text(L, Names, LP, LT),
        flow_term_text(R, Names, RP, RT),
        flow_infix_text(F, OT),
        Segs = [s(LT, m(ML)), s(OT, ink), s(RT, m(MR))]
    ;   format(atom(FA), '~q', [F]),
        (   Args == [] -> Segs = [s(FA, ink)]
        ;   flow_args_segs(Args, Ms, Names, ASegs),
            append([s(FA, ink), s('(', ink)|ASegs], [s(')', ink)], Segs)
        )
    ).

flow_args_segs([A], [M], Names, [s(T, m(M))]) :- !,
    flow_term_text(A, Names, 999, T).
flow_args_segs([A|As], [M|Ms], Names, [s(T, m(M)), s(', ', ink)|R]) :-
    flow_term_text(A, Names, 999, T),
    flow_args_segs(As, Ms, Names, R).

%% a predicate as called: report(+Pat, +Text, +Nums)
flow_moded_head(G, CM, Names, Segs) :-
    G =.. [F|Args],
    format(atom(FA), '~q', [F]),
    (   Args == [] -> Segs = [s(FA, ink)]
    ;   flow_moded_args(Args, CM, Names, ASegs),
        append([s(FA, ink), s('(', ink)|ASegs], [s(')', ink)], Segs)
    ).

flow_moded_args([A], [M], Names, [s(T, m(M))]) :- !,
    flow_moded_arg(A, M, Names, T).
flow_moded_args([A|As], [M|Ms], Names, [s(T, m(M)), s(', ', ink)|R]) :-
    flow_moded_arg(A, M, Names, T),
    flow_moded_args(As, Ms, Names, R).

flow_moded_arg(A, M, Names, T) :-
    (   var(A), flow_var_name(A, Names, N) -> atom_concat(M, N, T)
    ;   flow_term_text(A, Names, 999, T0), atom_concat(M, T0, T)
    ).

flow_panel_head(Key, CM, Rows, Docs, Segs) :-
    flow_names_for(Key, Docs, Rows, G, Names),
    flow_moded_head(G, CM, Names, Segs).

flow_lib_name(F, N) :-
    atom_codes(F, Cs),
    (   append(_, [47|R], Cs), \+ memberchk(47, R) -> true ; R = Cs ),
    (   append(B, [46|_], R) -> true ; B = R ),
    atom_codes(N, B).

