%  format/2's column directives: ~t (a fill point), ~N| (a column stop at
%  column N) and ~N+ (a column stop N past the last one), and the fill
%  characters a backquote, a number or `*' give ~t.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
:- set_prolog_flag(double_quotes, codes).
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

%  each case's name on a line of its own, then the format from column 0
%  and a bar after it, so that a fill at the end is seen
f(N, F, A) :- writeln(N), format(F, A), write('|'), nl.
%  into an atom, the codes written, so that no character past ASCII
%  reaches the console
s(N, F, A) :- format(atom(X), F, A), atom_codes(X, Cs), print(N-Cs), nl.
e(N, F, A) :- catch(( format(atom(X), F, A), R = X ), error(E, _), R = E), print(N-R), nl.

main :-
    stops, fills, overflow, colon, lines, writers, sinks, errors.

stops :-
    f(left, "~w~t~10|", [abc]),
    f(right, "~t~w~10|", [abc]),
    f(center, "~t~w~t~11|", [abc]),
    f(center_even, "~t~w~t~10|", [abc]),
    f(no_fill_point, "~w~10|", [abc]),
    f(two_cols, "~w~t~10|~w~t~10+", [abc, def]),
    f(three_plus, "~w~t~6+~w~t~6+~w~t~6+", [a, bb, ccc]),
    f(plus_default, "~w~t~+~w~t~+", [a, b]),
    f(plus_right, "~t~w~6+~t~w~6+", [a, bb]),
    f(bar_nothing, "~w~|~w", [a, b]),
    f(bar_then_plus, "~w~|~w~t~3+x", [a, b]),
    f(bar_then_bar, "~w~|~w~t~4|x", [a, b]),
    f(bar_zero, "~w~0|~w", [a, b]),
    f(stop_then_text, "~10|~w", [x]),
    f(fill_then_stop, "~t~10|~w", [x]),
    f(empty_seg, "~t~5|~t~5+x", []),
    f(table_row, "~w~t~10|~t~d~6+~t~2f~10+", [kiwi, 100, 12.0]).

fills :-
    f(dashes, "~`-t~30|", []),
    f(dots, "~w~`.t~20|~w", [name, value]),
    f(stars_code, "~42t~10|", []),
    f(star_arg, "~*t~10|", [0'=]),
    f(fill_two, "~`<t~w~`>t~11|", [mid]),
    f(fills_three, "~t~w~t~w~t~12|", [a, b]),
    f(fills_uneven, "~t~w~t~w~t~13|", [a, b]),
    f(fills_four, "~`at~w~`bt~w~`ct~w~`dt~15|", [x, y, z]),
    f(fills_five, "~`at~w~`bt~w~`ct~w~`dt~w~`et~13|", [p, q, r, s]),
    f(fills_six, "~`at~w~`bt~w~`ct~w~`dt~w~`et~w~`ft~16|", [p, q, r, s, t]),
    f(fills_seven, "~`at~w~`bt~w~`ct~w~`dt~w~`et~w~`ft~w~`gt~19|", [p, q, r, s, t, u]),
    f(bar_backquote, "~`-|x", []),
    f(digits_bar, "~w~`-t~3|~w~`=t~3+", [ab, cd]).

overflow :-
    f(over_bar, "~w~t~3|~w", [abcdef, x]),
    f(over_plus, "~w~t~3+~w", [abcdef, x]),
    f(over_right, "~t~w~3|~w", [abcdef, x]),
    f(exact, "~w~t~6|~w", [abcdef, x]),
    f(over_then_plus_w, "~w~t~3|~w~t~4+~w", [abcdef, x, y]),
    f(over_then_plus_a, "~w~t~3|~a~t~4+~w", [abcdef, x, y]),
    f(back_stop, "~w~10|~w~5|~w", [a, b, c]),
    f(over_n, "~w~0|~Nx", [abc]),
    f(over_text_n, "~w~t~2|~w~Nx", [abc, d]).

colon :-
    f(colon_bar, "~w~t~3:|~w", [abcdef, x]),
    f(colon_fill, "~w~`-t~3:|~w", [abcdef, x]),
    f(colon_none, "~w~3:|~w", [abcdef, x]),
    f(colon_fits, "~w~t~10:|~w", [abc, x]),
    f(colon_plus, "~w~t~4:+~w~t~4:+~w", [abcdef, x, y]),
    f(colon_two, "~w~`*t~w~`+t~3:|~w", [ab, cd, x]).

lines :-
    f(after_newline, "ab~ncd~t~6|x", []),
    f(nl_resets, "abc~t~6|~nde~t~6|x", []),
    f(tab_text, "a\tb~t~12|c", []),
    f(tab_w, "~w~t~12|c", ['a\tb']),
    f(tab_a, "~a~t~12|c", ['a\tb']),
    f(tab_w_pending, "~t~w~12|c", ['a\tb']),
    f(tab_text_w, "xy\t~w~t~20|c", [ab]),
    %  writers before the first fill point or stop, each walked by its own
    %  rule when the column is first asked
    f(two_w_tab, "~w~w~t~20|x", ['a\tb', cd]),
    f(text_then_tab_w, "ab~w~t~12|x", ['c\td']),
    f(tab_then_tab_w, "\t~w~t~20|c", ['x\ty']),
    f(nine_writers, "~w~w~w~w~w~w~w~w~w~t~40|x", [a, b, c, d, e, f, g, 'h\ti', j]),
    f(newline_w, "~w~t~8|x", ['ab\ncd']),
    f(newline_w_pending, "~t~w~8|x", ['ab\ncd']),
    f(newline_w_after, "xy~t~w~8|x", ['ab\ncd']),
    f(newline_a_after, "xy~t~a~8|x", ['ab\ncd']),
    f(cr_n, "abc\r~Nx", []),
    f(bs_n, "a\b~Nx", []),
    f(bs_col, "ab\b~t~6|x", []),
    f(n_mid, "~w~Nx~Ny", [abc]),
    f(pending_end, "~w~t", [abc]),
    f(pending_plus_end, "~w~t~w", [a, b]).

writers :-
    s(utf8, "~w~t~6|x", ['d\xE1\r']),
    s(utf8_a, "~a~t~6|x", ['d\xE1\r']),
    s(utf8_fill, "~`\xE9\t~w~6|", [ab]),
    f(quoted, "~q~t~10|x", ['a b']),
    f(number, "~t~d~8|~t~2f~10+", [42, 3.14159]),
    f(grouped, "~t~D~12|", [1234567]),
    f(print, "~p~t~10|x", [f('A', b)]),
    f(code_list, "~s~t~6|x", ["abc"]),
    f(c_char, "~c~t~5|x", [0'a]),
    f(c_count, "~3c~t~6|x", [0'a]),
    f(e_float, "~t~e~15|", [1.5]),
    f(radix, "~t~8r~6|", [64]),
    f(ignore, "~i~w~t~4|x", [skipped, ab]),
    f(tilde, "~~~t~4|x", []),
    f(canonical, "~k~t~10|x", ['A'+b]),
    f(write_term_opts, "~W~t~10|x", [f('A'), [quoted(true)]]).

sinks :-
    format(atom(A1), "~w~t~8|~w", [ab, cd]), print(A1), nl,
    format(atom(A2), "~t~w~8|", [ab]), print(A2), nl,
    format(string(S1), "~w~t~6|~w~t~6+~w", [x, y, z]), print(S1), nl,
    format(codes(C1), "~t~w~5|", [ab]), atom_codes(A3, C1), print(A3), nl,
    format(codes(C2, T2), "~w~t~4|", [ab]), T2 = [], atom_codes(A4, C2), print(A4), nl,
    with_output_to(string(S2), (write(abc), format("~t~w~10|", [x]))), print(S2), nl,
    with_output_to(string(S3), (write(abc), format("~w~t~10+", [x]))), print(S3), nl,
    with_output_to(string(S4), (write(abc), format("~Nx", []))), print(S4), nl,
    with_output_to(string(S5), (write(ab), nl, format("~Nx", []))), print(S5), nl,
    %  a capture inside a capture: its own column from 0, the outer one's
    %  back after it
    with_output_to(string(S6), ( write(abc),
                                 with_output_to(string(T6), format("~t~w~5|", [x])),
                                 write(T6), format("~t~w~12|", [y]) )),
    print(S6), nl,
    %  a table of rows
    forall(member(Name-Qty-Price, [apple-3-1.5, banana-12-0.25, kiwi-100-12.0]),
           format("~w~t~10|~t~d~6+~t~2f~10+~n", [Name, Qty, Price])),
    %  the console's column: text written before the format
    write(xyz), format("~t~w~10|]~n", [a]),
    write(xyz), format("~w~t~10|]~n", [a]),
    write(xyz), format("~w~t~10+]~n", [a]),
    write(xyz), format("~t~w~2|]~n", [a]),
    write(xyz), format("~Nx~n", []),
    write(xy), format(user_output, "~t~w~6|]~n", [a]),
    %  the console named by a stream term, its column library(stream)'s
    %  sink hook answers
    current_output(S7), write(xy), format(S7, "~t~w~6|]~n", [a]),
    %  a stream's column
    open('fc.txt', write, W),
    write(W, abc), format(W, "~t~w~10|]~n", [x]),
    write(W, ab), format(W, "~w~t~6+]~n", [y]),
    write(W, a), format(W, "~Nb~n", []),
    format(W, "~Nc~n", []),
    close(W),
    open('fc.txt', read, R), read_chars(R, Cs), close(R),
    atom_chars(Back, Cs), print(Back), nl.

read_chars(R, Cs) :-
    get_char(R, C),
    (   C == end_of_file
    ->  Cs = []
    ;   Cs = [C|T], read_chars(R, T)
    ).

errors :-
    e(t_alone, "~t", []),
    e(bar_alone, "~|", []),
    e(plus_alone, "~+", []),
    e(star_neg, "~*t~5|", [-1]),
    e(star_atom, "~*t~5|", [a]),
    e(star_none, "~*t~5|", []),
    e(bar_star, "~*|x", [4]),
    e(bar_star_text, "ab~*|x", [4]),
    e(bar_backquote_text, "ab~`-|x", []),
    e(plus_star, "~*+x", [4]),
    e(bar_star_neg, "~*|x", [-4]),
    e(star_past_int, "~*t~3|", [3000000000]),
    findall(0'~-0't, between(1, 100, _), T100), t_format(T100, F100),
    e(tab_stops_100, F100, []),
    findall(0'~-0't, between(1, 101, _), T101), t_format(T101, F101),
    e(tab_stops_101, F101, []),
    e(not_enough, "~w~t~10|~w", [a]),
    e(too_many, "~w~t~10|", [a, b]),
    %  to the console: a segment held at the end is put out before an
    %  argument left over is refused, and one an error ends is not
    catch(format("~w~t", [a, b]), error(E1, _), true), write('|'), print(E1), nl,
    catch(format("~w~t~w", [a, b, c]), error(E3, _), true), write('|'), print(E3), nl,
    catch(format("~t~w~w", [a]), error(E2, _), true), write('|'), print(E2), nl.

t_format([], []).
t_format([A-B|T], [A, B|F]) :- t_format(T, F).
