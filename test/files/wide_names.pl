%  Names past ASCII (cocolog 3.35.0), as swipl 9.0.4's reader and writer
%  take them. A letter begins or continues a name -- a capital begins a
%  variable --, a symbol a run of symbols, a digit of another script a
%  number, a space is layout and a code no class names is refused, by
%  pl-read.c's classes ('$code_class'/2: its Latin-1 table up to U+00FF and
%  pl-umap.c past it); the writer leaves bare what reads back as itself
%  (pl-write.c's atomType() for an atom of codes up to U+00FF,
%  unquoted_atomW() for any other), escapes in a quoted atom what
%  unicode_quoted_escape() names, and puts a space between two tokens that
%  would read as one (needSpace()). Through 3.34.1 cocolog took no byte past
%  ASCII outside quotes and quoted every atom that held one. Run by BOTH
%  SWI-Prolog and cocolog, output compared byte for byte.
%
%  Every text is made of codes and every line printed is ASCII: a term read
%  is shown with its names as their codes, and a write as the codes it
%  wrote into a string, which holds any character (swipl's console is the
%  locale's). A syntax error is its reason and its place.
%
%  NOT HELD HERE, as swipl's own reader does not hold them: a code whose
%  UTF-8 ends in the byte 0xA0 right before a full stop, which swipl's raw
%  read takes for its Latin-1 no-break space; a full stop before a space
%  past ASCII that iswspace() does not call one (U+202F), where swipl's
%  raw read and its tokeniser disagree; and swipl 7's dicts.

:- G = setlocale(ctype, _, 'C.UTF-8'), catch(G, _, true).

%  SWI has open/4 built in, cocolog from library(stream)
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

%  `_' and a digit is a name no warning names (swipl's atom_is_named_var())
w(_1).

main :- reading, digits, writing, spacing, ops, names, raw_text, clauses.

%  a term read, with its names as codes (a list cell as itself: swipl 7's
%  is '[|]'/2)
shape(T, var) :- var(T), !.
shape(T, atom(Cs)) :- atom(T), !, atom_codes(T, Cs).
shape(T, T) :- number(T), !.
shape([H|T], l(H1, T1)) :- !, shape(H, H1), shape(T, T1).
shape(T, f(Cs, Args)) :- T =.. [F|As], atom_codes(F, Cs), maplist(shape, As, Args).

%  what the text of codes Cs reads as, or its syntax error and its place
r(Label, Cs) :-
    atom_codes(A, Cs),
    catch(( term_to_atom(T, A), shape(T, S) ),
          error(syntax_error(E), C),
          ( C = string(_, P) -> S = syntax_error(E, P) ; S = syntax_error(E) )),
    print(Label-S), nl.

%  the codes writeq/1 writes of the atom of codes Cs
q(Label, Cs) :- atom_codes(A, Cs), qw(Label, A).

%  the codes writeq/1 and write/1 write of T
qw(Label, T) :- with_output_to(codes(O), writeq(T)), print(Label-O), nl.
wr(Label, T) :- with_output_to(codes(O), write(T)), print(Label-O), nl.

%  the codes print/1 writes of '$VAR'(Name), Name of codes Cs
v(Label, Cs) :- atom_codes(A, Cs), with_output_to(codes(O), print('$VAR'(A))), print(Label-O), nl.

reading :-
    r(lat_lower, [0'a, 233]),
    r(lat_start, [233, 0'a]),
    r(lat_upper, [201, 0'a]),
    r(lat_ordinal, [170, 0'b]),
    r(lat_sharp_s, [223]),
    r(lat_solo, [178]),
    r(lat_solo_pair, [178, 178]),
    r(lat_symbols, [172, 0'+, 177]),
    r(lat_c1, [0'a, 0x85]),
    r(lat_nbsp, [0'a, 160, 0'+, 160, 0'b]),
    r(greek, [0x3B1, 0x3B2]),
    r(greek_var, [0x391, 0x3B1]),
    r(cyrillic_var, [0x416, 0x443, 0x43A]),
    r(mixed, [233, 0x3B1]),
    r(cjk, [0x4E2D, 0x6587]),
    r(symbol, [0x2200]),
    r(symbol_run, [0'+, 0x2200, 0'-]),
    r(symbol_then_letter, [0x2200, 0'a]),
    r(symbol_capital, [0x24B6]),
    r(emoji, [0x1F600]),
    r(mark_continues, [0'a, 0x301]),
    r(mark_alone, [0x301]),
    r(mark_first, [0x301, 0'a]),
    r(unassigned, [0x378]),
    r(private_first, [0xE000]),
    r(private_inner, [0xE001]),
    r(zero_width, [0'a, 0x200B]),
    r(layout, [0'f, 0'(, 0'a, 0x3000, 0',, 0x2028, 0'b, 0')]),
    r(layout_ascii, [0'a, 11, 0'+, 12, 0'b]),
    r(stop_wide, [0'a, 0'., 0x3000]),
    r(name_arg, [0'f, 0'(, 0x3B1, 0',, 0x391, 0')]),
    r(name_list, [0'[, 233, 0'|, 0x416, 0']]).

digits :-
    Z = 0x660, O is Z + 1, T is Z + 2, Th is Z + 3, F is Z + 5,
    r(d_int, [O, T]),
    r(d_float, [O, 0'., F]),
    r(d_rational, [O, 0'r, T]),
    r(d_exp, [O, 0'e, T]),
    r(d_exp_sign, [O, 0'e, 0'+, T]),
    r(d_group, [O, 0'_, T, Th]),
    r(d_space, [O, 0' , T]),
    r(d_mixed, [O, 0'2]),
    r(d_mixed_ascii_first, [0'1, O]),
    r(d_minus, [0'-, O, T]),
    r(d_minus_ascii, [0'-, 0'1, 0'2]),
    r(d_inf, [O, 0'., Z, 0'I, 0'n, 0'f]),
    r(d_nan, [O, 0'., F, 0'N, 0'a, 0'N]),
    r(d_zero_x, [Z, 0'x, 0'1]),
    r(d_quote, [T, 0'', O]),
    r(d_in_name, [0'a, O]),
    r(d_arg, [0'f, 0'(, O, 0')]),
    r(d_devanagari, [0x967, 0x966]),
    r(d_fullwidth, [0xFF11, 0xFF12]),
    r(d_two_scripts, [O, 0x967]),
    atom_codes(A, [O, T]),
    ( catch(atom_number(A, N1), _, fail) -> true ; N1 = no ),
    print(d_atom_number-N1), nl,
    ( catch(number_codes(N2, [O, T]), error(E2, _), N2 = E2) -> true ; N2 = no ),
    print(d_number_codes-N2), nl.

writing :-
    q(w_lat_lower, [233]),
    q(w_lat_word, [0'a, 233, 0'b]),
    q(w_lat_upper, [201]),
    q(w_lat_symbol, [172]),
    q(w_lat_symbols, [0'+, 172]),
    q(w_lat_solo, [178]),
    q(w_lat_solo_pair, [178, 178]),
    q(w_lat_shy, [173]),
    q(w_lat_nbsp, [0'a, 160, 0'b]),
    q(w_lat_c1, [0'a, 0x85]),
    q(w_lat_slash_star, [0'/, 0'*, 172]),
    q(w_greek, [0x3B1, 0x3B2]),
    q(w_greek_upper, [0x391]),
    q(w_mixed, [233, 0x3B1]),
    q(w_mixed_upper, [201, 0x3B1]),
    q(w_symbol, [0x2200]),
    q(w_symbols, [0'+, 0x2200]),
    q(w_lat_and_wide_symbols, [172, 0x2200]),
    q(w_dot_symbol, [0'., 0x2200]),
    q(w_slash_star, [0'/, 0'*, 0x2200]),
    q(w_digit, [0x661]),
    q(w_name_digit, [0'a, 0x661]),
    q(w_mark, [0'a, 0x301]),
    q(w_mark_alone, [0x301]),
    q(w_underscore, [0'_, 0x3B1]),
    q(w_line_sep, [0'a, 0x2028, 0'b]),
    q(w_zero_width, [0'a, 0x200B]),
    q(w_private, [0xE000]),
    q(w_cjk, [0x4E2D, 0x6587]),
    q(w_emoji, [0x1F600]),
    string_codes(S, [0'a, 160, 0'b]),
    qw(w_string, S),
    atom_codes(E, [233]),
    with_output_to(codes(O), write_canonical(f(E))), print(w_canonical-O), nl,
    v(v_lat_upper, [201, 0'b]),
    v(v_greek_lower, [0x3B1]),
    v(v_greek_upper, [0x391, 0x3B1]),
    v(v_circled, [0x24B6]),
    v(v_mark, [0'X, 0x301]).

spacing :-
    atom_codes(Ea, [233, 0'a]), atom_codes(Fa, [0x2200]), atom_codes(Up, [201]),
    wr(s_minus_name, 1-Ea),
    wr(s_name_minus, Ea-1),
    wr(s_prefix_symbol, -(Fa)),
    wr(s_prefix_name, -(Ea)),
    wr(s_eq_symbol, a = Fa),
    wr(s_symbol_eq, Fa = a),
    wr(s_list, [Ea, Fa]),
    wr(s_arg, f(Ea, Fa)),
    qw(s_quoted_name, f(Up, Ea)),
    wr(s_digit_name, 1+Ea),
    qw(s_name_digit, Ea+1).

ops :-
    atom_codes(Approx, [0x2248]), op(700, xfx, Approx),
    r(op_symbol, [0'1, 0x2248, 0'2]),
    T1 =.. [Approx, 1, 2], wr(op_symbol_w, T1),
    T1b =.. [Approx, a, -1], wr(op_symbol_neg, T1b),
    atom_codes(Ea, [233, 0'a]), op(200, xfy, Ea),
    r(op_name, [0'1, 0' , 233, 0'a, 0' , 0'2]),
    T2 =.. [Ea, 1, 2], wr(op_name_w, T2),
    T2b =.. [Ea, x, y], qw(op_name_q, T2b),
    atom_codes(Root, [0x221A]), op(200, fy, Root),
    r(op_prefix, [0x221A, 0'x]),
    T3 =.. [Root, x], wr(op_prefix_w, T3),
    T4 =.. [Root, T3], wr(op_prefix_twice, T4),
    T5 =.. [Root, -1], wr(op_prefix_neg, T5).

%  the raw text a syntax error carries, as codes: what the raw read took for
%  the clause -- a run of symbols, `0'c' after a name or after none,
%  layout and comments past ASCII
e(Label, Cs) :-
    atom_codes(A, Cs),
    catch(( term_to_atom(_, A), S = read ),
          error(syntax_error(E), C),
          ( C = string(R, P) -> string_codes(R, RC), S = syntax_error(E, P, RC) ; S = syntax_error(E) )),
    print(Label-S), nl.

raw_text :-
    e(raw_c1, [0'a, 0x85]),
    e(raw_symbol_dot, [0'a, 0x2200, 0'., 0' , 0'b]),
    e(raw_symbol_dot_wide, [0'a, 0x2200, 0'., 0x3000, 0'b]),
    e(raw_layout, [0'f, 0'(, 0x3000, 0'a, 0x3000, 0'b, 0')]),
    e(raw_code_after_symbol, [0'x, 0' , 0x2200, 0'0, 0'', 0'a]),
    e(raw_quote_after_name, [0'x, 0' , 233, 0'0, 0'', 0'a, 0'']),
    e(raw_inf_then_letter, [0'1, 0'., 0'0, 0'I, 0'n, 0'f, 233]),
    e(raw_block_comment, [0'a, 0' , 0'/, 0'*, 0x3B1, 0'*, 0'/, 0' , 0'b]),
    e(raw_line_comment, [0'a, 0' , 0'%, 0x3B1, 0'\n, 0'b]),
    e(raw_leading_layout, [0x3000, 0'a, 0' , 0'b]).

%  clauses read from a file of UTF-8, one after another: each term, or its
%  error and its place (the line, the line position and the characters
%  before it), where a full stop before a space past ASCII ends a clause
%  and a run of symbols past ASCII swallows the `.' after it
clauses :-
    F = 'wide_clauses.pl',
    Lines = [ [0'p, 0'(, 233, 0'), 0'.],
              [0'p, 0'(, 0x3B1, 0'), 0'., 0x3000, 0'p, 0'(, 0x2200, 0'), 0'.],
              [0'q, 0'(, 0'1, 0' , 0x2200, 0' , 0'2, 0'), 0'.],
              [0'p, 0'(, 0x661, 0x662, 0'), 0'.],
              [0'p, 0'(, 0'x, 0x2200, 0'., 0' , 0'y, 0'), 0'.],
              [0'p, 0'(, 0x2200, 0'0, 0'', 0'a, 0'), 0'.],
              [0'p, 0'(, 0x3B1, 0'0, 0'', 0'a, 0'', 0'), 0'.],
              [0'p, 0'(, 201, 0't, 233, 0',, 0'_, 0x391, 0'), 0'.],
              [0'p, 0'(, 0'x, 0'), 0'., 160, 0'p, 0'(, 0'y, 0'), 0'.],
              [0'p, 0'(, 0'a, 0x85, 0'), 0'.],
              [0'p, 0'(, 0'v, 0'), 0'., 11, 0'p, 0'(, 0'w, 0'), 0'.],
              [0'p, 0'(, 0x3B1, 0',, 0'\n, 0' , 0x3B2, 0' , 0'y, 0'), 0'.],
              [0'p, 0'(, 0x3B1, 0'), 0'., 0x3000, 0'q, 0'(, 0'x, 0' , 0'y, 0'), 0'.],
              [0'e, 0'n, 0'd, 0'.] ],
    open(F, write, W, [encoding(utf8)]),
    forall(member(L, Lines), format(W, "~s~n", [L])),
    %  and a clause the file's end cuts short after a letter past ASCII
    format(W, "~s", [[0'q, 0'(, 0x3B1]]),
    close(W),
    open(F, read, S, [encoding(utf8)]),
    read_all(S),
    close(S).

read_all(S) :-
    catch(read_term(S, T, []), error(E, C), true),
    (   nonvar(E)
    ->  ( C = file(_, L, LP, CN) -> print(clause-err(E, L, LP, CN)) ; print(clause-err(E)) ),
        nl, read_all(S)
    ;   T == end_of_file
    ->  true
    ;   shape(T, Sh), print(clause-Sh), nl, read_all(S)
    ).

%  a variable's name past ASCII, as atom_to_term/3 names it
names :-
    atom_codes(A, [201, 0't, 233, 0' , 0'=, 0' , 0'f, 0'(, 201, 0't, 233, 0',,
                   0'_, 0x3B1, 0',, 0x416, 0')]),
    atom_to_term(A, _, Bindings),
    forall(member(N=_, Bindings), ( atom_codes(N, Cs), print(name-Cs), nl )).
