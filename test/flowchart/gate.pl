%% test/flowchart/gate.pl -- cicili-lang's flow gate, in small (1.11.4).
%%
%% That session charts each file of its library from a root that calls
%% every predicate the file defines, with what it is called with unknown,
%% and keeps the findings as a baseline. These are the places its report
%% said the chart was wrong or could do more, each as small as it goes:
%% test/flowchart.pl's gate section charts gt_all/2 with load(gate_lib.pl)
%% and modules(gate_mod.cicili) and reads the findings back.

%% a gate's root: everything called with its arguments unknown
gt_all(X, Y) :-
    (   gt_nan(X) ; gt_wo(X, Y) ; gt_fn(X, Y) ; gt_spell(X, Y)
    ;   gt_big(X, Y) ; gt_bad(X, Y)
    ;   gt_init ; gt_look(X, Y) ; gt_was(X) ; gt_count(X) ; gt_lib(X)
    ;   gt_nobody(X) ; gt_native(X, Y) ; gt_half(X, Y)
    ;   gt_alen(X) ; gt_slen(X) ; gt_astr(X) ; gt_sspl(X)
    ).

%% format/3's sink and with_output_to/2's hold the text written: A and S
%% are bound past them (item 3)
gt_nan(F) :- format(atom(A), '~w', [F]), sub_atom(A, 0, 1, _, '-').
gt_wo(X, P) :- with_output_to(string(S), write(X)), split_string(S, "", "", P).

%% text made from text binds every argument, whichever way it ran: W is
%% bound once the split succeeds, and so is each segment of the list a
%% split by length/2 and append/3 cuts (item 4)
gt_fn(Name, free(Op)) :- atomic_list_concat([op, W|_], '.', Name), !, gt_spell(W, Op).
gt_fn(Name, member(C, M)) :- atomic_list_concat(Segs, '.', Name), gt_prefix(Segs, C, Rest), !, gt_member(C, Rest, M).
gt_prefix(Segs, C, Rest) :- length(Segs, N), K is N - 1, K >= 1, gt_split(Segs, K, C, Rest).
gt_split(Segs, K, C, Rest) :- length(Pre, K), append(Pre, Rest, Segs), atomic_list_concat(Pre, '.', C), !.
gt_split(Segs, K, C, Rest) :- K > 1, K1 is K - 1, gt_split(Segs, K1, C, Rest).
gt_member(_, [op, W|_], M) :- !, gt_spell(W, M).
gt_member(_, [M|_], M).
gt_spell(W, S) :- atom_concat(conv_, K, W), !, atom_concat('operator ', K, S).
gt_spell(W, S) :- atom_concat('operator_', W, S).

%% and so does a text read from a list, as swipl's PL_get_text reads it: an
%% unbound element raises, so past atom_length/2, string_length/2,
%% atom_string/2 or split_string/4 the list's elements are bound and X is no
%% free argument of char_code/2 (3.0.0; through 2.16 they wrote any term out
%% and left its variables as they were)
gt_alen(N) :- atom_length([X], N), char_code(X, _).
gt_slen(N) :- string_length([X], N), char_code(X, _).
gt_astr(A) :- atom_string(A0, [X]), char_code(X, _), A = A0.
gt_sspl(P) :- split_string([X], [], [], P), char_code(X, _).

%% a table consulted at run time, asked for under a catch that takes its
%% absence: a warning; under one that does not, the error it was (item 5)
gt_big(F, T) :- catch(gt_sum_big(F, T), _, fail).
gt_bad(F, T) :- catch(gt_sum_bad(F, T), error(type_error(_, _), _), fail).

%% declared as the program runs: by a declarer of its own called with the
%% name written out, by dynamic/1, by an assert (item 6)
gt_reset(F/A) :- ( catch(abolish(F/A), _, true) -> true ; true ), dynamic(F/A).
gt_init :- gt_reset(gt_cache/2), dynamic(gt_seen/1), assertz(gt_hits(0)).
gt_look(K, V) :- gt_cache(K, V).
gt_was(X) :- gt_seen(X).
gt_count(N) :- gt_hits(N).
gt_lib(X) :- gl_table(X).
gt_nobody(X) :- gt_never(X).

%% a C predicate of the program's own module, and a table a library its
%% Prolog half loads declares (item 7)
gt_native(T, R) :- gm_lex(T, 0, R).
gt_half(X, Y) :- gh_row(X, Y).
