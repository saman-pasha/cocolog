%% tools/props/tables.pl -- swipl's predicate properties, as lib/swipl-props.cicili
%%
%%     swipl -q -g main -t halt tools/props/tables.pl > lib/swipl-props.cicili
%%
%% RUN BY THE REFERENCE swipl 9.0.4, NOT BY cocolog: what predicate_property/2
%% answers, seen from module user, of every system predicate (module
%% `system''s, as tools/dwim/system.pl lists them) and of every predicate the
%% libraries cocolog carries export. cocolog answers a row's flags for a
%% predicate its engine, a compiled-in module or a library defines, and never
%% for the program's own (lib/builtins-db.cicili, `coco_b_pred_props').
%%
%% A row is the name, the arity, the module it is imported from ("" for
%% none), its implementation module, its flags and its meta_predicate
%% arguments, a character an argument ("" for none): a digit, `:', `^', `?',
%% `+', `-', `*', and `/' for `//'. `$' names are left out, as the dwim
%% table leaves them. The rows are in standard order of Name-Arity.
:- use_module(library(lists)).   % cocolint: T1 -- swipl runs this file, and loads the library to read its predicates
:- use_module(library(apply)).   % cocolint: T1 -- swipl runs this file, and loads the library to read its predicates
:- use_module(library(aggregate)).   % cocolint: T1 -- swipl runs this file, and loads the library to read its predicates
:- use_module(library(assoc)).   % cocolint: T1 -- swipl runs this file, and loads the library to read its predicates
:- use_module(library(pairs)).   % cocolint: T1 -- swipl runs this file, and loads the library to read its predicates
:- use_module(library(ordsets)).   % cocolint: T1 -- swipl runs this file, and loads the library to read its predicates
:- use_module(library(yall)).   % cocolint: T1 -- swipl runs this file, and loads the library to read its predicates
:- use_module(library(ugraphs)).   % cocolint: T1 -- swipl runs this file, and loads the library to read its predicates
:- use_module(library(dcg/basics)).
:- use_module(library(dcg/high_order)).
:- use_module(library(error)).
:- use_module(library(listing)).

library_module(M) :-
    member(M, [lists, apply, aggregate, assoc, pairs, ordsets, yall, ugraphs,
               dcg_basics, dcg_high_order, error, prolog_listing]).

%% WHAT COCOLOG DEFINES THAT swipl's AUTOLOADER BRINGS FROM A LIBRARY
%% COCOLOG DOES NOT CARRY (3.48.0): their rows say where swipl's come from,
%% library(random), library(filesex) and library(backcomp).
also(random/1).
also(make_directory_path/1).
also(string_to_atom/2).
also(sumlist/2).

main :-
    findall(N-A, pred(N, A), L0),
    sort(L0, L),
    findall(N-A-M, ( hidden(N, A, M), \+ memberchk(N-A, L) ), H0),
    sort(H0, H1),
    one_module(H1, H),
    findall((N-A)-r(N, A), member(N-A, L), R1),
    findall((N-A)-h(N, A, M), member(N-A-M, H), R2),
    append(R1, R2, R0),
    keysort(R0, R),
    length(R, Count),
    length(H, NH),
    header(Count, NH),
    forall(member(_-Row, R), out_row(Row)),
    format("    ))~n").

out_row(r(N, A)) :- row(N, A).
out_row(h(N, A, M)) :- hidden_row(N, A, M).

pred(N, A) :-
    predicate_property(system:H, defined),
    functor(H, N, A),
    \+ sub_atom(N, 0, _, _, $).
pred(N, A) :-
    library_module(M),
    module_property(M, exports(Es)),
    member(N/A, Es),
    \+ sub_atom(N, 0, _, _, $).
pred(N, A) :-
    also(N/A).
%% USER'S OWN HOOKS (3.48.0): what swipl declares multifile in user at its
%% start, file_search_path/2, message_hook/3 and the rest
pred(N, A) :-
    current_predicate(user:N/A),
    \+ sub_atom(N, 0, _, _, $),
    functor(H, N, A),
    predicate_property(user:H, multifile),
    \+ predicate_property(user:H, imported_from(_)).

%% A CARRIED LIBRARY'S OWN PREDICATES THAT USER DOES NOT SEE (3.48.0): every
%% predicate a clause of the library's file defines, in its module or in
%% another (`sandbox:safe_meta/2', `prolog:called_by/4'), that is not
%% imported there -- a helper, an export of a library no autoloading
%% reaches -- and is no row above. predicate_property/2 answers nothing
%% for it, as swipl's of user's.
hidden(N, A, Mod) :-
    library_module(LM),
    module_property(LM, file(F)),
    current_module(Mod),
    Mod \== user, Mod \== system,
    current_predicate(Mod:N/A),
    \+ sub_atom(N, 0, _, _, $),
    functor(H, N, A),
    \+ predicate_property(Mod:H, imported_from(_)),
    \+ predicate_property(Mod:H, foreign),
    once(( catch(nth_clause(Mod:H, _, Ref), _, fail),
           clause_property(Ref, file(F)) )).

%% one row a name: its first module's
one_module([], []).
one_module([N-A-M|T], [N-A-M|Out]) :-
    drop_same(N, A, T, T1),
    one_module(T1, Out).

drop_same(N, A, [N-A-_|T], Out) :- !, drop_same(N, A, T, Out).
drop_same(_, _, L, L).

hidden_row(N, A, M) :-
    atom_codes(N, NCs), lisp_text(NCs, NEsc),
    atom_codes(M, MCs), lisp_text(MCs, MEsc),
    format("    (\"~s\" ~d \"\" \"~s\" 4096 \"\")~n", [NEsc, A, MEsc]).

%% the flags, a bit each
flag(built_in, 1).
flag(foreign, 2).
flag(transparent, 4).
flag(nodebug, 8).
flag(noprofile, 16).
flag(iso, 32).
flag(ssu, 64).
flag(notrace, 128).
flag(non_terminal, 256).
flag(public, 512).
flag((dynamic), 1024).
flag((multifile), 2048).
%% 4096 a hidden row's (hidden_row/3), and 8192 an export swipl's
%% autoloader does not reach: library(dcg/basics)'s and (dcg/high_order)'s,
%% user's only once the program loads the library

row(N, A) :-
    functor(H, N, A),
    (   predicate_property(user:H, defined)
    ->  findall(B, (flag(F, B), predicate_property(user:H, F)), Bs0),
        (   predicate_property(user:H, imported_from(Imp)) -> true ; Imp = '' ),
        (   Imp \== '', Imp \== system, \+ sub_atom(Imp, 0, _, _, $),
            \+ '$find_library'(user, N, A, _, _),
            \+ predicate_property(system:H, defined)
        ->  Bs = [8192|Bs0]
        ;   Bs = Bs0
        ),
        sum_list(Bs, Flags),
        (   predicate_property(user:H, implementation_module(IM)) -> true ; IM = user ),
        (   predicate_property(user:H, meta_predicate(S))
        ->  S =.. [_|As], maplist(arg_code, As, Cs), atom_codes(Spec, Cs)
        ;   Spec = ''
        ),
        atom_codes(N, NCs), lisp_text(NCs, NEsc),
        atom_codes(Imp, ICs), lisp_text(ICs, IEsc),
        atom_codes(IM, MCs), lisp_text(MCs, MEsc),
        atom_codes(Spec, SCs), lisp_text(SCs, SEsc),
        format("    (\"~s\" ~d \"~s\" \"~s\" ~d \"~s\")~n", [NEsc, A, IEsc, MEsc, Flags, SEsc])
    ;   true
    ).

arg_code(X, C) :- integer(X), !, C is 0'0 + X.
arg_code((//), 0'/) :- !.
arg_code(X, C) :- atom_codes(X, [C]).

header(Count, NH) :-
    format(";;;; cocolog -- swipl 9.0.4's predicate properties, for predicate_property/2~n"),
    format(";;;~n"),
    format(";;; GENERATED by tools/props/tables.pl under the reference swipl 9.0.4:~n"),
    format(";;; ~w rows: Name, Arity, the module it is imported from (\"\" none),~n", [Count]),
    format(";;; its implementation module, its flags and its meta_predicate~n"),
    format(";;; arguments, in standard order. Do not edit; run it again. A flag~n"),
    format(";;; a bit: 1 built_in, 2 foreign, 4 transparent, 8 nodebug, 16~n"),
    format(";;; noprofile, 32 iso, 64 ssu, 128 notrace, 256 non_terminal, 512~n"),
    format(";;; public, 1024 dynamic, 2048 multifile, 4096 hidden from user (~w~n", [NH]),
    format(";;; rows: a carried library's own predicate user does not see), 8192 an~n"),
    format(";;; export swipl's autoloader does not reach; a meta argument a~n"),
    format(";;; character: a digit, `:', `^', `?', `+', `-', `*', and `/' for `//'.~n"),
    format(";;; predicate_property/2 answers a row for a predicate cocolog's~n"),
    format(";;; engine, a compiled-in module or a library defines, never for the~n"),
    format(";;; program's own (lib/builtins-db.cicili, `coco_b_pred_props').~n~n"),
    format("(DEFPACKAGE :cocolog~n"),
    format("  (:USE :COMMON-LISP)~n"),
    format("  (:IMPORT-FROM :COMMON-LISP-USER \"import\" \"generic\" \"cicili\"))~n~n"),
    format("(IN-PACKAGE :cocolog)~n~n"),
    format("(DEFPARAMETER *swipl-props*~n"),
    format("  '(~n").

%% a Lisp string's body: a backslash and a double quote each escaped
lisp_text([], []).
lisp_text([C|Cs], Out) :-
    (   ( C =:= 0'\\ ; C =:= 0'" )
    ->  Out = [0'\\, C|Rest]
    ;   Out = [C|Rest]
    ),
    lisp_text(Cs, Rest).
