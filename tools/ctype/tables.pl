%% tools/ctype/tables.pl -- swipl's character classes, as lib/swipl-ctype.cicili
%%
%%     swipl -q -g main -t halt tools/ctype/tables.pl > lib/swipl-ctype.cicili
%%
%% RUN BY THE REFERENCE swipl 9.0.4 ON LINUX, NOT BY cocolog: what it
%% writes is what code_type/2 answers there for every code point from 0 to
%% U+10FFFF, the classes swipl asks glibc for (iswalpha() and its kin, and
%% towupper() and towlower()) under LC_CTYPE C.UTF-8 -- set here, so the run
%% does not depend on the caller's LANG, under which the C locale has no
%% letter past ASCII -- and the ones swipl keeps itself (prolog_var_start,
%% prolog_atom_start, prolog_identifier_continue, prolog_symbol, decimal
%% and its weight, pl-umap.c's), which no locale moves.
%%
%% Each table is a list of runs (LO HI A B): the codes LO to HI hold A, B,
%% A, B ... from LO on, which takes a range of one value (A = B) and the
%% upper and lower case letters that alternate through Latin Extended alike;
%% a code no run covers holds 0. The flags are eleven bits a code: alpha 1,
%% upper 2, lower 4, print 8, space 16, cntrl 32, prolog_var_start 64,
%% prolog_atom_start 128, prolog_identifier_continue 256, prolog_symbol 512,
%% decimal 1024 -- every other class swipl names is one of these or ASCII's
%% (alnum is alpha or 0-9, csym alnum or `_', csymf alpha or `_', graph
%% print and not space, punct graph and not alnum: true of every code
%% point here, and checked as the table is made). The case tables hold
%% towupper(C) - C and towlower(C) - C; the decimal one (LO HI D) a digit's
%% weight, C + D. lib/term.cicili's macros make two-level tables of
%% them as cocolog is built (`coco-ct-emit-flags', `coco-ct-emit-case').

main :-
    setlocale(ctype, _, 'C.UTF-8'),
    numlist(0, 0x10FFFF, Cs),
    maplist(flags, Cs, Fs),
    forall(derived(T), check_derived(T, Cs)),
    maplist(delta(to_lower), Cs, Us),
    maplist(delta(to_upper), Cs, Ls),
    runs(Fs, 0, FRs), runs(Us, 0, URs), runs(Ls, 0, LRs),
    maplist(weight, Cs, Ws),
    maplist(decimal_agrees, Cs, Fs, Ws),
    wruns(Ws, 0, DRs),
    header([FRs, URs, LRs, DRs]),
    table('*swipl-ctype-flags*', FRs),
    table('*swipl-ctype-toupper*', URs),
    table('*swipl-ctype-tolower*', LRs),
    table('*swipl-ctype-decimal*', DRs).

bit(alpha, 1). bit(upper, 2). bit(lower, 4). bit(print, 8). bit(space, 16).
bit(cntrl, 32). bit(prolog_var_start, 64). bit(prolog_atom_start, 128).
bit(prolog_identifier_continue, 256). bit(prolog_symbol, 512). bit(decimal, 1024).

flags(C, F) :- aggregate_all(sum(B), ( bit(T, B), code_type(C, T) ), F).

delta(T, C, D) :- G =.. [T, X], ( code_type(C, G) -> D is X - C ; D = 0 ).

%% the classes made of others, as lib/solve-text.cicili makes them
derived(alnum). derived(csym). derived(csymf). derived(graph). derived(punct).

check_derived(T, Cs) :-
    (   member(C, Cs), \+ same(T, C)
    ->  format(user_error, "~w is not what it is made of at ~w~n", [T, C]), halt(1)
    ;   true
    ).

holds(T, C) :- code_type(C, T), !.
same(T, C) :- ( holds(T, C) -> made(T, C) ; \+ made(T, C) ).
made(alnum, C) :- ( holds(alpha, C) ; C >= 48, C =< 57 ), !.
made(csym, C) :- ( holds(alnum, C) ; C =:= 95 ), !.
made(csymf, C) :- ( holds(alpha, C) ; C =:= 95 ), !.
made(graph, C) :- holds(print, C), \+ holds(space, C).
made(punct, C) :- holds(graph, C), \+ holds(alnum, C).

%% the runs of a list of values from code C0 on
runs([], _, []).
runs([0|Vs], C, Rs) :- !, C1 is C + 1, runs(Vs, C1, Rs).
runs([A|Vs], C, [run(C, Hi, A, B)|Rs]) :-
    ( Vs = [B|_] -> true ; B = A ),
    C1 is C + 1,
    extend(Vs, C1, 1, A, B, Hi0, Rest0),
    trim(C, Hi0, A, B, Hi),
    Back is Hi0 - Hi,
    put_back(Back, A, B, Hi, C, Rest0, Rest),
    Hi1 is Hi + 1,
    runs(Rest, Hi1, Rs).

%% as far as the values go on as A, B, A, B ...: Hi is the last code that
%% does, Rest what comes after it
extend([V|Vs], C, Off, A, B, Hi, Rest) :-
    ( Off mod 2 =:= 0 -> W = A ; W = B ),
    V =:= W, !,
    C1 is C + 1, Off1 is Off + 1,
    extend(Vs, C1, Off1, A, B, Hi, Rest).
extend(Vs, C, _, _, _, Hi, Vs) :- Hi is C - 1.

%% a run does not end on a 0 (B 0, an odd offset last)
trim(Lo, Hi, A, B, T) :-
    ( Hi > Lo, B =:= 0, (Hi - Lo) mod 2 =:= 1 -> T is Hi - 1 ; T = Hi ),
    ( A =:= 0 -> throw(no_run) ; true ).

%% the values trimmed off go back in front of what comes after
put_back(0, _, _, _, _, Rest, Rest) :- !.
put_back(1, _, B, _, _, Rest, [B|Rest]).

weight(C, W) :- ( code_type(C, decimal(X)) -> W is X - C + 0x200000 ; W = 0 ).

%% decimal/0 holds where decimal/1 has a weight, and nowhere else
decimal_agrees(C, F, W) :-
    (   sign(F /\ 1024) =:= sign(W)
    ->  true
    ;   format(user_error, "decimal and its weight disagree at ~w~n", [C]), halt(1)
    ).

%% a decimal run is a range of one D (the weight less the code, offset so
%% that no D is 0)
wruns([], _, []).
wruns([0|Vs], C, Rs) :- !, C1 is C + 1, wruns(Vs, C1, Rs).
wruns([V|Vs], C, [run(C, Hi, D)|Rs]) :-
    D is V - 0x200000,
    C1 is C + 1,
    same_run(Vs, C1, V, Hi, Rest),
    Hi1 is Hi + 1,
    wruns(Rest, Hi1, Rs).

same_run([V|Vs], C, V0, Hi, Rest) :- V =:= V0, !, C1 is C + 1, same_run(Vs, C1, V0, Hi, Rest).
same_run(Vs, C, _, Hi, Vs) :- Hi is C - 1.

header([F, U, L, D]) :-
    maplist(length, [F, U, L, D], [NF, NU, NL, ND]),
    format(";;;; cocolog -- swipl 9.0.4's character classes, for code_type/2~n"),
    format(";;;~n"),
    format(";;; GENERATED by tools/ctype/tables.pl under the reference swipl 9.0.4~n"),
    format(";;; with LC_CTYPE C.UTF-8: ~w runs of the class flags, ~w and ~w of~n", [NF, NU, NL]),
    format(";;; towupper() and towlower(), ~w of the decimal weights. Do not edit;~n", [ND]),
    format(";;; run it again. lib/term.cicili's macros make the two-level~n"),
    format(";;; tables code_type/2, char_type/2 and the case of a text read.~n~n"),
    format("(DEFPACKAGE :cocolog~n"),
    format("  (:USE :COMMON-LISP)~n"),
    format("  (:IMPORT-FROM :COMMON-LISP-USER \"import\" \"generic\" \"cicili\"))~n~n"),
    format("(IN-PACKAGE :cocolog)~n").

table(Name, Runs) :-
    format("~n(DEFPARAMETER ~w~n  '(", [Name]),
    rows(Runs, 0),
    format("))~n").

rows([], _).
rows([R|Rs], N) :-
    ( N > 0, N mod 4 =:= 0 -> format("~n    ") ; N > 0 -> format(" ") ; true ),
    row(R),
    N1 is N + 1,
    rows(Rs, N1).

row(run(L, H, A, B)) :- format("(~d ~d ~d ~d)", [L, H, A, B]).
row(run(L, H, D)) :- format("(~d ~d ~d)", [L, H, D]).
