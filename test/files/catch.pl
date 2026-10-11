%  catch/3 and throw/1, and the ISO errors the libraries now raise.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  ONLY THE FORMAL PART OF AN ERROR IS COMPARED. SWI puts a module-qualified
%  predicate indicator and a message in the second argument of error/2, and no
%  two systems agree on its contents -- matching on `error(Formal, _)' is what
%  portable code does and is all that can be compared.

s(L,V) :- write(L), write(=), write(V), nl.
yn(G,L) :- ( call(G) -> s(L,yes) ; s(L,no) ).
p(1). p(2). p(3).
%  What the goal did: the error's formal part, or `succeeded', or `failed'.
%  It must never print F unbound -- a goal that raises nothing leaves it free,
%  and an unbound variable's name is numbered differently by every Prolog.
f(G) :- catch((call(G) -> R = succeeded ; R = failed), error(F, _), R = F),
        !, write(R), nl.

main :-
    ( catch(throw(hello), E1, true) -> s(caught, E1) ; s(caught, no) ),
    ( catch(true, _, fail) -> s(no_throw, ok) ; s(no_throw, no) ),
    yn(catch(fail, _, true), goal_fails),
    ( catch(throw(f(1,2)), f(A,B), true) -> s(unify_a, A), s(unify_b, B) ; true ),
    yn(catch(catch(throw(a), b, true), a, fail), catcher_mismatch_propagates),
    ( catch(catch(throw(x), b, true), x, true) -> s(nested_outer, ok) ; s(nested_outer, no) ),
    ( catch(catch(throw(x), x, true), y, true) -> s(nested_inner, ok) ; s(nested_inner, no) ),
    ( catch((p(X), X > 2, throw(found(X))), found(Y), true) -> s(after_backtracking, Y) ; true ),
    ( catch(throw(z), Z, (Z == z -> R = yes ; R = no)) -> s(recovery_runs, R) ; true ),
    ( findall(N, catch(p(N), _, fail), L1) -> s(inside_findall, L1) ; true ),
    ( catch(findall(N2, (p(N2), N2 > 1), L2), _, fail) -> s(findall_inside, L2) ; true ),

    %  ---- the errors the libraries raise, which used to be plain failures ----
    f(msort(notalist, _)),
    f(atom_length(_, _)),
    f(succ(_, _)),
    f(plus(_, _, _)),
    f(char_code(_, _)),
    f(atom_chars(_, _)),
    f(nb_getval(nosuch, _)),
    f(sort(0, bad, [], _)),
    f(exists_file(_)),
    f(atom_number(_, _)),
    f(_X0 is _ + 1),
    f(1 is 1 // 0),
    f(atom_length(1, _)),

    %  ---- =.., functor/3, arg/3 and is/2: SWI's errors, and catchable. Through
    %  1.10.5 =.. and an unknown function of an argument or more ended the
    %  query where no catch/3 could see it, and arg/3 failed ----
    f(_ =.. _),
    f(_ =.. foo),
    f(_ =.. []),
    f(_ =.. [_, a]),
    f(_ =.. [f(a), b]),
    f(_ =.. [f(a)]),
    f(_ =.. [1, a]),
    f(_ =.. [a|_]),
    f(_ =.. [a|b]),
    f(functor(_, foo, -1)),
    f(functor(_, _, 1)),
    f(functor(_, foo(a), 1)),
    f(functor(_, foo, a)),
    f(functor(_, 1, 1)),
    f(_ is foo + 1),
    f(_ is foo(1, 2)),
    f(arg(1, _, _)),
    f(arg(1, foo, _)),
    f(arg(a, f(x), _)),
    f(arg(0, f(x), _)),
    f(arg(-1, f(x), _)),

    %  ---- assert and retract refuse as SWI does. Through 1.10.5 they failed,
    %  and `assertz((foo :- 3))' stored the clause ----
    f(assertz(_)),
    f(asserta(_)),
    f(retract(_)),
    f(assertz(3)),
    f(assertz((foo :- 3))),
    f(assertz((foo :- a, 3))),
    f(assertz((_ :- true))),
    f(retract(3)),
    %  a clause for a control construct; SWI refuses a builtin's name too,
    %  and cocolog keeps data under one (test/errors.pl says why)
    f(assertz(call(x))),
    f(assertz(true)),
    f(assertz((a, b))),
    true.
