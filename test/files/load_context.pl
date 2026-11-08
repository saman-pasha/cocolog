%  prolog_load_context/2 as swipl 9.0.4's boot/syspred.pl answers it while
%  a load reads, and after. Run by BOTH systems, output compared byte for
%  byte. The case writes the files it loads into the sandbox.
%
%  `module' is the read's module/2 module and `user' outside one, in an
%  initialization/1 goal run after its file too; `file' the file read (an
%  included one itself), `source' the file the load reads (the includer),
%  `directory' the file's; `term_position' the term's first character;
%  `variable_names' the term in hand's bindings, `[Name = Var, ...]' in
%  the reader's order (`_X' among them, `_' none), sharing the term's
%  variables while a hook runs and a directive's goal -- bound as the goal
%  bound them -- and `[]' outside a load; `term' the term as read while
%  term_expansion/2 and goal_expansion/2 run, `[]' while a directive's
%  goal runs, failing outside a load; `reloading' true through a read of a
%  file the load read before, a nested load's its own. At a file's end the
%  bindings are `[]'; at its start, and in a directive its start expands
%  to, they are those of the read around the load -- a nested load's are
%  its directive's -- as swipl's begin_of_file sets no '$variable_names'.
%
%  swipl's goal expansion gives a clause's variables attributes there,
%  which numbervars/3 refuses, so inside goal_expansion/2 the names and the
%  term's shape are written. `stream' is left out: a cocolog load reads
%  text, not a stream (COMPAT.md).
%
%  Through cocolog 3.50.0 `module' was always `user', and
%  `variable_names', `term' and `reloading' answered nothing.

:- set_prolog_flag(double_quotes, codes).
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

lc_key(module).
lc_key(file).
lc_key(source).
lc_key(directory).
lc_key(dialect).
lc_key(term_position).
lc_key(script).
lc_key(variable_names).
lc_key(term).
lc_key(reloading).

lc_report(N) :- forall(lc_key(K), lc_show(N, K)).

lc_show(N, K) :-
    (   prolog_load_context(K, V)
    ->  lc_value(K, V, W),
        \+ \+ ( numbervars(N-W, 0, _), print(N-K-W) )
    ;   \+ \+ ( numbervars(N, 0, _), print(N-K-none) )
    ),
    nl.

lc_value(K, F, W) :- memberchk(K, [file, source, directory]), !, file_base_name(F, W).
lc_value(_, V, V).

lc_report_g(N) :-
    forall(( lc_key(K), K \== variable_names, K \== term ), lc_show(N, K)),
    prolog_load_context(variable_names, B),
    findall(Nm, member(Nm = _, B), Ns),
    print(N-variable_names-Ns), nl,
    (   prolog_load_context(term, T)
    ->  lc_shape(T, Sh), print(N-term-Sh)
    ;   print(N-term-none)
    ),
    nl.

lc_shape(T, S) :-
    (   var(T) -> S = var
    ;   T = (H :- _) -> functor(H, F, A), S = clause(F/A)
    ;   T = (:- _) -> S = directive
    ;   functor(T, F, A), S = F/A
    ).

term_expansion(probe(N, X, Y), [probed(N)]) :- lc_report(N), X = Y.
term_expansion(begin_of_file, _) :- lc_ours, lc_eo(bof), fail.
term_expansion(begin_of_file, [(:- lc_eo(bof_dir))]) :- lc_file(lc_d).
term_expansion(end_of_file, _) :- lc_ours, lc_eo(eof), fail.

%  A file's start and end, of this case's files alone: a hook there that
%  called member/2 would load library(lists) in swipl, and be asked of its
%  start, which calls member/2 again (swipl's autoload loop).
lc_ours :- prolog_load_context(file, F), file_base_name(F, B), sub_atom(B, 0, _, _, lc_).
lc_file(N) :- prolog_load_context(file, F), file_base_name(F, B), atom_concat(N, '.pl', B).

lc_eo(Tag) :-
    prolog_load_context(variable_names, Bs), lc_names(Bs, Ns),
    ( prolog_load_context(term, T) -> true ; T = none ),
    prolog_load_context(file, F), file_base_name(F, Fb),
    print(Tag-Fb-Ns-T), nl.

lc_names([], []).
lc_names([N = _|Bs], [N|Ns]) :- lc_names(Bs, Ns).

% cocolint: N1 -- the program's hook, which joins yall's clause of it as swipl's multifile user:goal_expansion/2 does
goal_expansion(gprobe(N), true) :- lc_report_g(N).

lines(lc_a, [ ":- include(lc_i).",
              "probe(t1, Abc-Abc, _Def).",
              "p(A, B) :- gprobe(g1), A = B.",
              ":- lc_report(d1).",
              ":- X = f(Y), lc_report(d2(X, Y)).",
              ":- gprobe(d3).",
              ":- Z = 1, consult(lc_n), lc_report(after_nested(Z)).",
              ":- initialization(lc_report(init(_I)))." ]).
lines(lc_i, [ ":- lc_report(i1)." ]).
lines(lc_n, [ ":- lc_report(n1).", "q(W, W)." ]).
lines(lc_b, [ ":- V = 2, consult(lc_d), consult(lc_n), lc_report(b_after(V))." ]).
lines(lc_d, [ "d(1)." ]).
lines(lc_m, [ ":- module(lc_m, []).",
              ":- user:lc_report(m1).",
              "probe(m2, Q, Q).",
              "qq(R) :- gprobe(m3), R = 1.",
              ":- initialization(user:lc_report(m_init))." ]).

write_file(N) :-
    lines(N, Ls), atom_concat(N, '.pl', F),
    open(F, write, S),
    forall(member(L, Ls), format(S, "~s~n", [L])),
    close(S).

main :-
    forall(lines(N, _), write_file(N)),
    consult(lc_a),
    format("-- again~n"),
    consult(lc_a),
    format("-- a first read that reads a file again~n"),
    consult(lc_b),
    format("-- a module~n"),
    use_module(lc_m),
    format("-- the module again~n"),
    consult(lc_m),
    format("-- expand_goal/2 at a goal~n"),
    expand_goal(gprobe(rg), E2), print(E2), nl,
    format("-- after the loads~n"),
    lc_report(main),
    findall(K, prolog_load_context(K, _), Ks), print(Ks), nl,
    ( prolog_load_context(foo, _) -> writeln(foo) ; writeln(foo_fails) ),
    ( prolog_load_context(1, _) -> writeln(one) ; writeln(int_fails) ).
