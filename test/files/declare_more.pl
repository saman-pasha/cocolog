%  swipl's other declarations, as swipl 9.0.4 has them (cocolog 3.2.0): run
%  by BOTH SWI-Prolog and cocolog, output (stdout and stderr) compared byte
%  for byte.
%
%  public/1, volatile/1, module_transparent/1 and thread_local/1 are prefix
%  operators at 1150 fx, as are table/1, thread_initialization/1 and the
%  rest, and directives and goals both: the first three record an attribute
%  predicate_property/2 tells and define nothing, so a predicate they named
%  and nothing else defined is an unknown procedure; thread_local/1 makes
%  the predicate dynamic as well (every thread has a store of its own here)
%  and refuses one that has clauses and is not thread_local already. A
%  directive's part that raises is reported where the directive stands, as
%  dynamic/1's is, module_transparent/1's under swipl's name for the
%  attribute, transparent/1. Through 3.1.0 none of these names was an
%  operator, so `:- public p/1.' did not parse.

:- public pu/1.
:- volatile vo/1.
:- module_transparent mt/1.
:- thread_local tl/1.
:- public np/1.
:- volatile nv/1.
:- module_transparent nm/1.
:- thread_local nt/1.
:- public 1.
:- volatile foo.
:- thread_local atom_length/2.
:- module_transparent (a1/1, 3).
:- public [p2/1, 4, p3/2].
:- module_transparent [mt2/1, 5, mt3/1].
:- dynamic d/1.
:- discontiguous dc/1.
:- multifile mf/1.
:- dynamic ti/1.
:- thread_initialization(assertz(ti(x))).

pu(1). vo(1). mt(1). dc(1). mf(1). hc(1). mt3(1).

%  an error with its variables left out, which the two systems name
%  differently
w(E) :-
    copy_term(E, error(F, C)),
    term_variables(F, Vs), maplist(=('_'), Vs),
    (   var(C) -> C1 = '_'
    ;   C = context(X, _) -> C1 = context(X)
    ;   C1 = C
    ),
    writeq(F-C1), nl.
t(G) :- catch(( G -> writeln(yes) ; writeln(no) ), E, w(E)).

pr(G) :-
    functor(G, N, A),
    findall(P, ( predicate_property(G, P),
                 \+ memberchk(P, [file(_), line_count(_), last_modified_generation(_),
                                  size(_)]) ), Ps),
    writeq(N/A-Ps), nl.

op(N) :- ( current_op(P, T, N) -> writeq(N-P-T) ; writeq(N-none) ), nl.

main :-
    %  ---- the operators ----
    forall(member(N, [dynamic, discontiguous, initialization, meta_predicate,
                      module_transparent, multifile, public, thread_local,
                      thread_initialization, volatile, table]), op(N)),
    %  ---- what each declaration says ----
    pr(d(_)), pr(tl(_)), pr(pu(_)), pr(vo(_)), pr(mt(_)), pr(dc(_)), pr(mf(_)),
    pr(nt(_)), pr(np(_)), pr(mt3(_)),
    %  ---- a call of what only an attribute named ----
    t(np(_)), t(nv(_)), t(nm(_)), t(nt(_)), t(pu(_)),
    t(current_predicate(np/1)), t(current_predicate(nt/1)), t(current_predicate(nv/1)),
    %  ---- thread_local/1 is dynamic ----
    t(assertz(nt(1))), t(nt(_)), t(retract(nt(1))), t(nt(_)),
    t(assertz(np(1))), t(np(_)),
    %  ---- as goals, and their refusals ----
    t(public(1)), t(public(foo/a)), t(public(_)), t(public(foo)), t(public([g1/1, g2/2])),
    t(volatile(1)), t(volatile(x/1)), t(module_transparent(m/2)), t(module_transparent(3)),
    t(thread_local(hc/1)), t(thread_local(tl/1)), t(thread_local(nt/1)),
    t(thread_local(atom_length/2)), t(public(atom_length/2)),
    t(volatile(atom_length/2)), t(module_transparent(atom_length/2)),
    t(thread_local(1)), t(thread_local(_)),
    t(thread_local(d2/1)), t(dynamic(d2/1)), t(predicate_property(d2(_), thread_local)),
    t(dynamic(nt/1)), t(public(np/1)),
    pr(g1(_)), pr(d2(_)),
    %  ---- thread_initialization/1 ran its goal here (whether any thread
    %  swipl makes later runs it again is not asked) ----
    t(ti(x)).
