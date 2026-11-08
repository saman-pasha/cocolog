%  What user sees of the system's and the libraries' predicates, as swipl
%  9.0.4's predicate_property/2 and current_predicate/1 answer it (cocolog
%  3.48.0): the list's own predicate, '[|]'/2, with its two clauses and its
%  meta_predicate; a predicate swipl's autoloader brings from a library
%  cocolog does not carry (random/1, string_to_atom/2); an export no
%  autoloading reaches (library(dcg/basics)'s, (dcg/high_order)'s) until the
%  program loads its library; a library's own predicate user does not see
%  (a helper, a hook it defines in another module), and a helper of
%  cocolog's own, a `$' name since 3.48.1; and the hooks swipl declares in
%  user, dynamic and multifile. Not here (COMPAT.md): where the
%  two write a predicate differently (`foreign', the counts of
%  file_search_path/2), the files of a library compiled into cocolog, and
%  library(yall)'s `system:goal_expansion/2' clause, which cocolog's one
%  namespace holds in user's.

out(T) :-
    \+ \+ ( numbervars(T, 0, _), print(T) ), nl.

t(G) :-
    catch(( G -> out(yes) ; out(no) ), E, out(caught(E))).

%% what both write alike of a predicate: none of how it is stored, nor
%% where a library's file is, nor the counts where the two differ
ours(size(_)). ours(last_modified_generation(_)). ours(indexed(_)).
ours(file(_)). ours(line_count(_)).

props(H) :-
    findall(P, ( predicate_property(H, P), \+ ours(P) ), Ps),
    out(Ps).

%% the counts too, where the two libraries hold other clauses
props_uncounted(H) :-
    findall(P, ( predicate_property(H, P), \+ ours(P),
                 P \= number_of_clauses(_), P \= number_of_rules(_) ), Ps),
    out(Ps).

main :-
    lists, libraries, unseen, hooks, consults.

%% the list's predicate: swipl's system one, its clauses consult/1's
lists :-
    props([_|_]), props(user:[_|_]),
    t(predicate_property([a], meta_predicate(S1))), out(S1),
    t(predicate_property([a], implementation_module(M1))), out(M1),
    findall([X|Y]-B, clause([X|Y], B), Cs), out(Cs),
    findall(B2, clause([x], B2), Cs2), out(Cs2),
    findall(B3, clause([m:f, g], B3), Cs3), out(Cs3),
    %% a list is a head to meta_predicate/1, the list's own predicate's
    t(meta_predicate([uvm(0)])), t(meta_predicate([uvm(0), uvn(:)])).

%% what the autoloader brings from a library cocolog does not carry: none
%% of user's until predicate_property/2 named it, and then the library's
libraries :-
    t(current_predicate(sumlist/2)), t(current_predicate(string_to_atom/2)),
    t(current_predicate(random/1)), t(current_predicate(make_directory_path/1)),
    forall(member(H, [sumlist(_, _), string_to_atom(_, _), random(_), make_directory_path(_)]),
           ( findall(M, predicate_property(H, imported_from(M)), Ms), out(Ms) )),
    t(current_predicate(sumlist/2)), t(current_predicate(string_to_atom/2)),
    t(current_predicate(random/1)), t(current_predicate(make_directory_path/1)).

%% a library's own predicate user does not see, and an export no
%% autoloading reaches until its library is loaded
unseen :-
    forall(member(H, [gen_assoc_(_, _, _), add_existential_vars(_, _, _), has_type(_, _),
                      safe_meta_predicate(_), goal_colours(_, _), called_by(_, _, _, _),
                      digits(_, _, _), string_without(_, _, _, _), sequence(_, _, _, _),
                      optional(_, _, _, _), sub_string_same(_, _), atom_chars_list(_, _)]),
           ( functor(H, N, A), props(H),
             ( current_predicate(N/A) -> out(N/A-current) ; out(N/A-none) ),
             predicate_property(H, implementation_module(M)), out(M) )),
    use_module(library(dcg/basics)),
    use_module(library(dcg/high_order)),
    use_module(library(assoc)),
    forall(member(H, [digits(_, _, _), string_without(_, _, _, _), sequence(_, _, _, _),
                      optional(_, _, _, _), gen_assoc_(_, _, _)]),
           ( functor(H, N, A), props(H),
             ( current_predicate(N/A) -> out(N/A-current) ; out(N/A-none) ) )),
    %% one the program defines itself is the program's
    props_uncounted(before(_, _)),
    ( current_predicate(before/2) -> out(before/2-current) ; out(before/2-none) ).

%% library(ugraphs)'s helper's name, the program's own
before(uv, x).   % cocolint: N1 -- a library's own name the program defines, which the case asks of

%% the hooks swipl declares in user: dynamic, multifile, current from the
%% start, their clauses the program's
hooks :-
    %% current from the start: asked before predicate_property/2 named them
    t(current_predicate(file_search_path/2)), t(current_predicate(prolog_file_type/2)),
    forall(member(H, [term_expansion(_, _), message_hook(_, _, _), library_directory(_), portray(_)]),
           ( functor(H, N, A), props(H),
             ( current_predicate(N/A) -> out(N/A-current) ; out(N/A-none) ) )),
    %% one with no clause fails, as print/1's asks find it (3.54.0)
    t(portray(uvp)),
    forall(member(H, [file_search_path(_, _), prolog_file_type(_, _)]),
           ( functor(H, N, A), props_uncounted(H),
             ( current_predicate(N/A) -> out(N/A-current) ; out(N/A-none) ) )),
    t(assertz(file_search_path(uvx, '/nowhere'))),
    t(file_search_path(uvx, D)), out(D),
    t(retract(file_search_path(uvx, _))),
    t(file_search_path(uvx, _)),
    t(assertz(prolog_file_type(uvt, prolog))),
    t(retract(prolog_file_type(uvt, prolog))),
    t(prolog_file_type(uvt, _)).

%% consult/1 of a module's file, as the list's second clause calls it
consults :-
    t(consult(user:uv1)), t(uv1(X1)), out(X1),
    t([uv2, uv3]), t(uv2(X2)), out(X2), t(uv3(X3)), out(X3),
    t([user:uv4]), t(uv4(X4)), out(X4),
    t(load_files(user:uv5, [])), t(uv5(X5)), out(X5),
    catch([uvnone], error(E6, _), true), out(E6),
    catch(consult(user:uvnone2), error(E7, _), true), out(E7).
