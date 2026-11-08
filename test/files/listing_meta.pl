%  listing/1's declarations of a meta-predicate, as swipl 9.0.4's
%  library(listing) writes them (cocolog 3.48.2; through 3.48.1 it wrote
%  none): the `:- meta_predicate' line after the thread_local, dynamic,
%  volatile, multifile and public ones, the spec qualified with the
%  predicate's module where the listing is not that module's; no
%  `:- module_transparent' line where the spec says it already (an
%  argument 0..9, `:', `^' or `//'); a `*' kept as `?'; and the
%  transparency the declarations leave, which swipl's meta_declaration()
%  sets from the spec alone, so a module_transparent/1 after the spec
%  makes the predicate transparent and one before it is taken away, which
%  moves the module the predicate's own meta calls are made in, the
%  caller's for a transparent one. A predicate a meta_predicate/1 or a
%  module_transparent/1 alone declared is none to listing/1. Run by BOTH
%  SWI-Prolog and cocolog, output
%  compared byte for byte; lmq.pl, the module, is the runner's fixture
%  (test/files.pl). A clause's variables are named as listing/1 names
%  them, `A', `B', ..., so that swipl's, which restores the file's names,
%  writes the same (COMPAT.md).

:- use_module(lmq).

:- meta_predicate mp(0).
mp(A) :- call(A).
:- meta_predicate mq(1, ?, :).
mq(A, B, _) :- call(A, B).
:- dynamic md/2.
:- meta_predicate md(0, ?).
md(true, 1).
:- meta_predicate mz.
mz.
:- module_transparent mt/1.
mt(1).
:- meta_predicate mv(^, //).
mv(_, _).
:- meta_predicate mq2(+, -, *).
mq2(_, _, _).
:- dynamic mdm/1.
:- multifile mdm/1.
:- meta_predicate mdm(:).
:- dynamic dall/1.
:- multifile dall/1.
:- public dall/1.
:- meta_predicate dall(0).
dall(true).
:- thread_local tl/1.
:- meta_predicate tl(0).
:- volatile vo/1.
:- meta_predicate vo(1).
vo(_).
:- meta_predicate 'q z'(0).
'q z'(A) :- A.
:- meta_predicate mc(:, 0), md2(1).
mc(_, _).
md2(_).
:- meta_predicate nf(0).
:- module_transparent nt/1.

%% the transparency the declarations leave, in their order
:- module_transparent b1/1.
:- meta_predicate b1(0).
b1(A) :- call(A).
:- module_transparent b2/1.
:- meta_predicate b2(?).
b2(_).
:- meta_predicate a1(?).
:- module_transparent a1/1.
a1(_).
:- meta_predicate a2(0).
:- meta_predicate a2(?).
a2(_).
:- module_transparent a3/1.
:- meta_predicate a3(0).
:- meta_predicate a3(?).
a3(_).
:- module_transparent a5/1.
:- meta_predicate a5(+).
a5(_).
:- meta_predicate a6(0).
:- module_transparent a6/1.
a6(_).
:- meta_predicate mz2.
:- module_transparent mz2/0.
mz2.

t(G) :-
    catch(( G -> true ; writeln(no) ), E, ( print(caught(E)), nl )).

main :- lists, transparency, modules, guards.

%% each listing, and how it ended where it raised
lists :-
    forall(member(S, [mp/1, mq/3, md/2, mz/0, mt/1, mv/2, mq2/3, mdm/1, dall/1,
                      tl/1, vo/1, 'q z'/1, mc/2, md2/1, nf/1, nt/1]),
           ( format("=== ~q~n", [S]), t(listing(S)) )).

%% what predicate_property/2 says of each, and its listing
transparency :-
    forall(member(H, [b1(_), b2(_), a1(_), a2(_), a3(_), a5(_), a6(_), mz2, mt(_),
                      mq2(_, _, _), nf(_), nt(_)]),
           ( findall(P, ( predicate_property(H, P),
                          memberchk(P, [transparent, meta_predicate(_)]) ), Ps),
             print(Ps), nl )),
    forall(member(S, [b1/1, b2/1, a1/1, a2/1, a3/1, a5/1, a6/1, mz2/0]),
           ( format("=== ~q~n", [S]), t(listing(S)) )).

%% a module's: its spec qualified where the listing is user's; and the
%% module its predicates' own meta calls take: the caller's for a
%% predicate module_transparent/1 left transparent (lx_t, lx_d), lmq's for
%% any other, one whose spec names a module among them, a
%% module_transparent/1 after it notwithstanding (lx_e)
modules :-
    forall(member(S, [lmq_p/1, lmq_s/1, lmq:lmq_p/1, lmq:lmq_s/1]),
           ( format("=== ~q~n", [S]), t(listing(S)) )),
    forall(member(G, [lx_p(true), lx_t(true), lx_b(true), lx_c(true), lx_a(true), lx_d(true),
                      lx_e(true)]),
           t(G)).

%% a last call under `$/0' takes the guard on into the callee, and drops
%% it where the callee is transparent: by module_transparent/1, or by a
%% spec that names a module, before a module_transparent/1 too
:- meta_predicate dg_p(0).
dg_p(A) :- call(A).
dg_q(A) :- call(A).
:- module_transparent dg_t/1.
dg_t(A) :- call(A).
:- module_transparent dg_b/1.
:- meta_predicate dg_b(0).
dg_b(A) :- call(A).
:- meta_predicate dg_c(?).
dg_c(A) :- call(A).
:- module_transparent dg_a/1.
:- meta_predicate dg_a(?).
dg_a(A) :- call(A).
:- meta_predicate dg_d(?).
:- module_transparent dg_d/1.
dg_d(A) :- call(A).
g_p :- $, dg_p(member(_, [1, 2])).
g_q :- $, dg_q(member(_, [1, 2])).
g_t :- $, dg_t(member(_, [1, 2])).
g_b :- $, dg_b(member(_, [1, 2])).
g_c :- $, dg_c(member(_, [1, 2])).
g_a :- $, dg_a(member(_, [1, 2])).
g_d :- $, dg_d(member(_, [1, 2])).

guards :-
    forall(member(G, [g_p, g_q, g_t, g_b, g_c, g_a, g_d]),
           ( catch(( G -> print(G-yes) ; print(G-no) ), E,
                   \+ \+ ( numbervars(E, 0, _), print(G-E) )),
             nl )).
