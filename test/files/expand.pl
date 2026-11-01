%% Term and goal expansion, as swipl 9.0.4 does it: a program's
%% term_expansion/2 asked of every term a load reads where the file is taken
%% (directives too, the conditional ones aside, before a grammar rule is
%% translated, and the file's own end), what it gives read in the term's
%% place; its goal_expansion/2 asked of every clause's body and every
%% directive's goal, to a fixed point, through the control constructs and
%% the system's meta-arguments; expand_term/2 and expand_goal/2;
%% prolog_load_context/2 and source_location/2 while a hook runs; an
%% `end_of_file' that ends the file where it stands; a ball that is no
%% error ending a load; non_terminal/1.
%%
%% Run by test/files.pl beside swipl, which makes the files it consults
%% (`xf/2' there). What is printed of a clause has its variables named by
%% `pv/1' (cocolog has no numbervars/3), and no body here nests a
%% conjunction or qualifies a goal, where clause/2's answers differ apart
%% from expansion.

:- dynamic seen/1.

%% before any hook: read as it stands
early(old(1)).
e1 :- old(1).

%% a hook a directive makes is asked from the next term on
:- assertz((goal_expansion(dg, new(dg)))).
d1 :- dg.

%% every term the hooks are asked of, in order, in this file and the ones it
%% consults (swipl autoloads a library inside consult/1, and its first
%% terms reach the hook too)
seen_term(T) :-
    (   prolog_load_context(file, F), file_base_name(F, B),
        memberchk(B, ['expand.pl', 'stop.pl', 'lit.pl', 'withinc.pl', 'inc.pl',
                      'toss.pl', 'gt1.pl', 'gt2.pl', 'withsub.pl', 'inc2.pl'])
    ->  functor(T, N, A), assertz(seen(N/A))
    ;   true
    ).
%% the first clause of a hook, a qualified rule, is one from the next term on
user:term_expansion(T, _) :- seen_term(T), fail.
after_first.
term_expansion(gen(N), Cs) :- findall(g(I), between(1, N, I), Cs).
term_expansion(skip, []).
term_expansion((h --> b), (h(X, X) :- true)).
term_expansion(t1, [(a5 --> [x]), b5, (c5 :- old(1))]).
term_expansion((:- hello), (:- (write(expanded_directive), nl))).
term_expansion(boom, _) :- atom_length(_, _).
term_expansion(stop_here, [s(1), end_of_file, s(2)]).
term_expansion(where, here(F, L, P)) :-
    source_location(F0, L), file_base_name(F0, F),
    prolog_load_context(term_position, P).
term_expansion(ctx, ctx(M, S, D, Di, Sc, Ks)) :-
    prolog_load_context(module, M),
    prolog_load_context(source, S0), file_base_name(S0, S),
    prolog_load_context(directory, D0), file_base_name(D0, D),
    prolog_load_context(dialect, Di),
    prolog_load_context(script, Sc),
    findall(K, ( prolog_load_context(K, _),
                 memberchk(K, [module, file, source, directory, dialect, term_position, script]) ),
            Ks).
term_expansion(ictx, ic(F, S, D)) :-
    prolog_load_context(file, F0), file_base_name(F0, F),
    prolog_load_context(source, S0), file_base_name(S0, S),
    prolog_load_context(directory, D0), file_base_name(D0, D).
term_expansion(toss, _) :- throw(tossed).
term_expansion(tv, [_]).
term_expansion(end_of_file, [last(1), last(2)]) :- \+ seen(last_done), assertz(seen(last_done)).


% cocolint: N1 -- the program's hook, which joins yall's clause of it as swipl's multifile user:goal_expansion/2 does
goal_expansion(old(X), new(X)).
goal_expansion(a1, a2).
goal_expansion(a2, a3).
goal_expansion(m(X), (X > 0, true)).
goal_expansion(nt(S0, S), nt2(S0, S)).
goal_expansion(gboom, _) :- atom_length(_, _).
goal_expansion(gb_ok, _) :- atom_length(_, _).
goal_expansion(skipped_goal, _) :- assertz(seen(skipped_goal_asked)), fail.
goal_expansion(gtoss, _) :- throw(gtossed).
goal_expansion(same, same).
goal_expansion(sw(X, Y), new2(Y, X)).

new(_). new2(_, _). a3. nt2(S, S). gb_ok. sw(_, _).
old2(_, _).

gen(3).
skip.
h --> b.
b --> [].
t1.
:- hello.
boom.
gb :- gboom.
where.
   where.
ctx.
:- if(true).
cd1.
:- endif.
:- if(false).
skipped_term.
:- skipped_goal.
:- endif.
:- gb_ok, write(directive_gb), nl.

p1 :- a1.
p2 :- ( a1 -> m(1) ; \+ a1 ).
p3(L) :- findall(x, a1, L).
p4(L) :- maplist([X]>>(X > 0), L).
p5 :- call(a1).
p7 :- call([X]>>(X > 0), 1).
q1(L) :- maplist(old, L).
q3 :- findall(X, old(X), _).
q4 :- forall(old(_), old(_)).
q5 :- catch(old(1), _, old(2)).
q6 :- setof(X, Y^old2(X, Y), _).
q7 :- aggregate_all(count, old(_), _).
q8 :- \+ old(1).
q9 :- setof(X, Y^(old(X), old2(X, Y)), _).
q11 :- call(old, 1).
q12 :- not(old(1)).
q13 :- once(old(1)).
q14 :- ignore(old(2)).
s1 :- with_output_to(string(_), old(1)).
s2 :- setup_call_cleanup(old(1), old(2), old(3)).
s5 :- call(old(1)).
s10 :- ( old(1) -> old(2) ).
s11 :- ( old(1) *-> old(2) ; old(3) ).
s12 :- findall(X, old(X), _, []).
s13 :- bagof(X, old(X), _).
s14 :- catch_with_backtrace(old(1), _, old(2)).
s15 :- setup_call_catcher_cleanup(old(1), old(2), _, old(3)).
s16 :- call_cleanup(old(1), old(2)).
%% a closure whose expansion moves the arguments call/N gives it: swipl
%% compiles a wrapper, cocolog leaves the closure, and either runs
s17 :- call(sw(1), 2).
s18(G) :- bagof(x, G, _).
s19(G) :- call(G, 1).
r6 --> nt, {old(1)}.
:- old(1), write(directive_ran), nl.

%% clause/2 of each, its variables named
show(H) :-
    findall(H-B, catch(clause(H, B), _, fail), L),
    pv(L), nl.

%% `'$VAR'(N)' for each variable, as numbervars/3 would, printed
pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

main :-
    forall(member(H, [early(_), e1, d1, after_first, g(_), skip, h(_, _), a5(_, _), b5, c5, gb,
                      here(_, _, _), ctx(_, _, _, _, _, _), cd1, skipped_term,
                      p1, p2, p3(_), p4(_), p5, p7, q1(_), q3, q4, q5, q6, q7, q8,
                      q9, q11, q12, q13, q14, s1, s2, s5, s10, s11, s12, s13, s14, s15, s16,
                      s18(_), s19(_), r6(_, _), last(_)]),
           show(H)),
    ( catch(s17, E17, ( print(E17), nl, fail )) -> print(s17_ran) ; print(s17_failed) ), nl,
    %% files the case reads in the sandbox (test/files.pl's fixtures): an
    %% end_of_file an expansion gives, one written in a file, an include
    consult(stop), consult(lit), consult(withinc),
    forall(member(H, [s(_), never_read, l(_), w(_), i(_)]), show(H)),
    %% a ball that is no error, from each hook, ends the load it is thrown in
    forall(member(F-Hs, [toss-[toss, after_toss], gt1-[gt1b], gt2-[g2, gt2b]]),
           ( catch(consult(F), E, ( print(caught(E)), nl )),
             forall(member(H, Hs), show(H)) )),
    %% an include from another directory: the file, the source, the directory
    consult(withsub), show(ic(_, _, _)),
    findall(T, seen(T), Seen), print(Seen), nl,
    expand_term(gen(2), T1), pv(T1), nl,
    expand_term((a --> [x]), T2), pv(T2), nl,
    expand_term(t1, T3), pv(T3), nl,
    expand_term(foo, T4), pv(T4), nl,
    expand_term(V, T5), pv(V-T5), nl,
    expand_term((p :- old(1)), T6), pv(T6), nl,
    expand_term((:- old(1)), T7), pv(T7), nl,
    catch(expand_term(boom, T8), E8, true), pv(t8(T8, E8)), nl,
    expand_term(tv, T9), pv(T9), nl,
    expand_term((user:qa --> [x]), T10), pv(T10), nl,
    expand_term((b --> []), T11), pv(T11), nl,
    %% a load's grammar rule makes its predicate a non-terminal, one an
    %% expansion gave among them, and expand_term/2 then gives a rule of it
    %% no declaration; non_terminal/1 makes one of a predicate not defined
    forall(member(H, [b(_, _), a5(_, _), r6(_, _), h(_, _), early(_)]),
           ( ( predicate_property(H, non_terminal) -> pv(H-nt) ; pv(H-no) ), nl )),
    non_terminal(q/2), expand_term((q --> [x]), T12), pv(T12), nl,
    ( predicate_property(q(_, _), non_terminal) -> print(q_nt) ; print(q_no) ), nl,
    expand_goal(old(z), G1), pv(G1), nl,
    expand_goal((old(z), old(w)), G2), pv(G2), nl,
    expand_goal(foo, G3), pv(G3), nl,
    expand_goal(maplist(old, x), G4), pv(G4), nl,
    expand_goal(call(old, 1), G5), pv(G5), nl,
    expand_goal(V6, G6), pv(V6-G6), nl,
    expand_goal(same, G7), pv(G7), nl,
    expand_goal(user:old(1), G8), pv(G8), nl,
    forall(member(K, [module, source, file, directory, dialect, term_position, script]),
           ( prolog_load_context(K, KV) -> pv(K=KV), nl ; print(K-none), nl )),
    forall(member(S, [a/2, user:a//0, [a/2, b/3], (a/2, b/3), foo, _, [a/2, _], [], a/b,
                      1/2, a/(-1), a//b, a//1.5, a// -1, a//(-3), _/2, _:a/2, []/1, 3]),
           ( catch(non_terminal(S), error(Fm, _), true), pv(nt(S, Fm)), nl )).
