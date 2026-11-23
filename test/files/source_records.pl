%  source_file/1,2 and current_module/1, swipl 9.0.4's (cocolog 3.78.0, 3.78.1):
%  COMPAT.md's fifth group of small built-ins. The case holds:
%  - the source files in the order their first defining reads began, a
%    file a load reads inside another's read after it; a file while a read
%    of it is under way, before it has defined anything, and a file of
%    goals alone only then (swipl's '$start_consult'/2 makes the record as
%    the read begins), and after the files read since once a later read of
%    it defines something; an empty file and an included one no source
%    file, a module file with no predicates one; a file named by a relative
%    name, a name with `./', and names that are none;
%  - the predicates each file registered, the last first: a clause's; a
%    dynamic, discontiguous, multifile or meta_predicate declaration's --
%    a goal's as a directive's; an included file's in the file that
%    includes it; a module's under its module, the message hook's under
%    prolog (cocolog stores its clauses as '$prolog_message'/3) -- never public/1's,
%    module_transparent/1's, thread_local/1's or volatile/1's, nor what a
%    directive asserts;
%  - a predicate's file: the first that registered it, where it is
%    defined (a clause, or declared dynamic, discontiguous or multifile:
%    a meta_predicate/1 alone defines nothing), a multifile one's the
%    files its clauses came from, in their order, an asserted clause
%    none's; a module's predicate under its module, never user's name; a
%    qualifier that names no module user's own predicate (swipl's lookup
%    reads it as a new module whose default import is user, and makes
%    none), one that names a module that module's own alone;
%  - a file read again: what its new text registers, the predicates it
%    registered before where they stood and the new ones before them;
%  - a declaration of a predicate defined before it (a clause, or declared
%    dynamic, discontiguous or multifile) registers it only where the
%    file's list holds it already (3.78.1): one another file defined stays
%    that file's alone, where one only called is the file's;
%  - the errors: a number for a file, a number for a predicate's file and
%    one for its head, each in swipl's context;
%  - current_module/1: user, system and prolog, a module a file defined
%    (with no predicates too), a library the program loaded; anything else
%    fails.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte; the
%  files are test/files.pl's `srec/2', made in the sandbox, and a file of a
%  library swipl reads (lists.pl) is left out of the lists, cocolog
%  compiling the library in (COMPAT.md). Not here (COMPAT.md): swipl's own
%  modules and its bookkeeping predicates ('$load_context_module'/3, in a
%  file that loads another) and a module a qualified assert or call names;
%  the message hooks' declarations are test/files/message_hooks.pl's.

% cocolint: T1 -- swipl loads lists.pl here, the module current_module/1 names
:- use_module(library(lists)).

w(X) :- \+ \+ ( numbervars(X, 0, _), print(X), nl ).

t(G) :-
    catch(( G -> R = yes ; R = no ), E, R = caught(E)),
    w(G-R).

%% the sandbox's files and this one, by their base names
ours(F) :-
    file_base_name(F, B),
    ( sub_atom(B, 0, _, _, sr_) -> true ; B == 'source_records.pl' ).

files(L) :-
    findall(B, ( source_file(F), ours(F), file_base_name(F, B) ), Bs),
    w(L-Bs).

%% user's predicates of a file, and every module's of a file that loads none
preds(F) :-
    absolute_file_name(F, A),
    findall(H, source_file(H, A), Hs),
    w(F-Hs).

mpreds(F) :-
    absolute_file_name(F, A),
    findall(M-H, source_file(M:H, A), MHs),
    w(F-MHs).

where(H) :-
    findall(B, ( source_file(H, F), file_base_name(F, B) ), Bs),
    w(H-Bs).

%% ...of the sandbox's files alone, for a predicate swipl's own files give
%% clauses too
where_ours(H) :-
    findall(B, ( source_file(H, F), ours(F), file_base_name(F, B) ), Bs),
    w(H-Bs).

main :-
    files(before),
    ensure_loaded(sr_g2),
    ensure_loaded(sr_a),
    ensure_loaded(sr_outer),
    use_module(sr_emod),
    ensure_loaded(sr_q),
    files(after),
    %% read again, defining something now: after the files read since
    rename_file('sr_g2.v2.pl', 'sr_g2.pl'),
    ensure_loaded(sr_g2),
    ensure_loaded(sr_h),
    ensure_loaded(sr_h2),
    files(again),
    preds('sr_a.pl'), preds('sr_outer.pl'), preds('sr_q.pl'),
    forall(member(F, ['sr_b.pl', 'sr_mod.pl', 'sr_emod.pl', 'sr_inner.pl', 'sr_qg.pl',
                      'sr_g2.pl', 'sr_h.pl', 'sr_inc.pl', 'sr_goals.pl', 'sr_empty.pl']),
           mpreds(F)),
    forall(member(H, [ sa_dyn(_), sa_dis(_), sa_mf(_), sa_meta(_), sa_pub(_), sa_mt(_),
                       sa_tl(_), sa_vol(_), sa_c(_), sa_late(_), sa_asserted(_),
                       sa_cdyn(_), sa_cdis(_), sa_last(_), si_p(_), si_q(_), sb_p(_),
                       sb_none(_), so_p(_), sx_p(_), sm_a(_), sm_b(_), sr_mod:sm_a(_),
                       sr_mod:sm_b(_), sr_mod:sm_c(_), user:sa_c(_), sr_mod:sa_c(_),
                       system:sa_c(_), lists:sa_c(_), nosuch:sa_c(_), nosuch:sa_mf(_),
                       main, w(_), nosuch(_) ]),
           where(H)),
    where_ours(prolog:message(_, _, _)), where(sg2_p(_)),
    %% an asserted clause of a multifile predicate is no file's
    assertz(sa_mf(z)), where(sa_mf(_)),
    forall(member(G, [ source_file('sr_a.pl'), source_file('./sr_a.pl'), source_file(sr_a),
                       source_file('sr_b.pl'), source_file('sr_mod.pl'),
                       source_file('sr_emod.pl'), source_file('sr_inc.pl'),
                       source_file('sr_goals.pl'), source_file('sr_empty.pl'),
                       source_file('source_records.pl'), source_file(nosuch),
                       source_file(f(x)), source_file(library(lists)), source_file(3),
                       source_file(_, 3), source_file(3, _), source_file(_:3, _),
                       source_file(foo:bar, _), source_file(3:foo, _),
                       source_file(f(x):foo, _), source_file(sr_mod:3, _),
                       source_file(sa_c(_), 'sr_a.pl'), source_file(sa_mf(_), 'sr_b.pl'),
                       source_file(_, nosuch) ]),
           t(G)),
    %% a file read again
    consult(sr_rc), mpreds('sr_rc.pl'), where(rc_b(_)),
    rename_file('sr_rc.v2.pl', 'sr_rc.pl'),
    consult(sr_rc), mpreds('sr_rc.pl'), where(rc_b(_)), where(rc_c(_)),
    %% a declaration of a predicate defined before it registers it only
    %% where the file's list holds it: one another file defined, or that
    %% was only called, and a new one
    ensure_loaded(sr_d1), ensure_loaded(sr_d2), mpreds('sr_d1.pl'), mpreds('sr_d2.pl'),
    forall(member(H, [sd_m(_), sd_d(_), sd_c(_), sd_k, sd_only, sd_new(_)]), where(H)),
    %% a file read again keeps its list: what it registers again where it
    %% stood, what it registers first before it
    consult(sr_ro), mpreds('sr_ro.pl'),
    rename_file('sr_ro.v2.pl', 'sr_ro.pl'),
    consult(sr_ro), mpreds('sr_ro.pl'),
    files(reconsulted),
    forall(member(M, [user, system, prolog, sr_mod, sr_emod, lists, sr_a, nosuch, 3, f(x), []]),
           t(current_module(M))),
    findall(M, ( current_module(M),
                 memberchk(M, [user, system, prolog, sr_mod, sr_emod, lists, sr_a, nosuch]) ),
            Ms),
    msort(Ms, Sorted),
    w(modules-Sorted).
