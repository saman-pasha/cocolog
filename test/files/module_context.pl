%% A loadable module's errors name the module (cocolog 3.0.2), held to swipl
%% 9.0.4.
%%
%% swipl raises a FOREIGN predicate's error with the module that defines it
%% in the context -- error(type_error(text, f(x)), context(md5:md5_hash/3,
%% _)) -- and print_message/2 writes `md5:md5_hash/3: ' before the message,
%% the module shown because it is not user, system or a `$' one. Through
%% 3.0.1 a loadable module of cocolog raised with the context unbound, and
%% its messages named nothing. Here swipl runs its own library(md5), whose
%% md5_hash/3 is foreign, and cocolog the fixture test/files.pl builds from
%% test/md5.cicili into the sandbox's library/: a module named md5 whose
%% md5_hash/3 raises what swipl's raises, through the SDK's helpers -- a
%% type error of a compound, of an atom and of an unbound culprit (an
%% instantiation error since 3.0.0), an instantiation error and a domain
%% error, the options before the data.
%%
%% A predicate swipl has as a builtin of its own is named as swipl names
%% it, whichever module carries it here: library(thread)'s mutexes are
%% system:mutex_lock/1 and their kin, a row of *error-contexts* each, where
%% the module would name itself (thread:mutex_lock/1). Only what both
%% systems raise alike is here: mutex_unlock(nosuch), mutex_destroy(nosuch),
%% mutex_create(f(x)) and thread_detach(f(x)) raise another error here, or
%% none (STATUS.md, 3.0.2).
%%
%% A line is the goal and its ball, every variable written `_', then the
%% message print_message/2 makes of it. Every line goes to user_error, so
%% that the two streams cannot interleave differently in the two systems.

:- use_module(library(md5)).
:- use_module(library(thread)).

e(G) :-
    (   catch(( G -> R = yes ; R = no ), E, R = E) -> true ; R = failed ),
    copy_term(G-R, G2-R2),
    term_variables(G2-R2, Vs), maplist(=('$VAR'('_')), Vs),
    format(user_error, '~p  ==>  ~p~n', [G2, R2]),
    ( R = error(_, _) -> print_message(error, R) ; true ).

main :- forall(p(G), e(G)).

p(md5_hash(f(x), _, [])).
p(md5_hash(_, _, [])).
p(md5_hash(abc, _, foo)).
p(md5_hash(abc, _, _)).
p(md5_hash(abc, _, [foo])).
p(md5_hash(abc, _, [encoding(foo)])).
p(md5_hash(abc, _, [encoding(_)])).
p(md5_hash(abc, _, [encoding(f(x))])).
p(md5_hash(f(x), _, foo)).
p(md5_hash(f(x), _, [encoding(foo)])).
p(mutex_lock(_)).
p(mutex_lock(f(x))).
p(mutex_lock(1.5)).
p(mutex_unlock(_)).
p(mutex_unlock(f(x))).
p(mutex_trylock(_)).
p(mutex_trylock(f(x))).
p(mutex_destroy(_)).
p(mutex_destroy(f(x))).
p(thread_detach(_)).
