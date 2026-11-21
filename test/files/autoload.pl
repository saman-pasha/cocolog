%% A call of a predicate one of cocolog's own modules holds, with no
%% use_module/1 before it (cocolog 3.66.0), held to swipl 9.0.4. Run by
%% test/files.pl beside swipl, the two outputs compared byte for byte.
%%
%% swipl has open/3, read_term/3, with_mutex/2 and on_signal/3 built in,
%% and library(readutil)'s read_line_to_string/2 it autoloads; cocolog keeps
%% them in library(stream), library(thread) and library(signal), which a
%% first call of one now loads (lib/library.cicili, `lb_autoload'), as
%% swipl's autoloader loads a library. Through 3.65.0 each call here was an
%% unknown procedure, and `:- use_module(library(readutil))' no such source.
%%
%% Each module is loaded by a path of its own, so the order of the checks is
%% the point: current_predicate/1 answers for open/3 before anything loaded
%% library(stream); a plain call loads it; a qualified call loads
%% library(thread); the last call of a guarded clause loads library(signal).

q(G) :- catch((G -> R = yes ; R = no), E, R = ex(E)), print(R), nl.

%% asked before anything is loaded: answered by what a call would load
t_cp :- q(current_predicate(open/3)), q(current_predicate(set_stream/2)),
        q(current_predicate(no_such_thing/3)).

%% a plain call: library(stream), and what it holds after
t_file :- open('a.txt', write, S), writeq(S, f(x, 'Y')), write(S, '.'), nl(S),
          write(S, 'second line'), nl(S), close(S),
          open('a.txt', read, R), read_term(R, T, []), close(R), print(T), nl.
t_pp :- q(predicate_property(read_term(_, _, _), iso)),
        q(predicate_property(open(_, _, _), defined)).
t_err :- catch(open(_, read, _), error(E, _), true), print(E), nl,
         catch(no_such_pred(1), error(E2, _), true), print(E2), nl.

%% a qualified call: library(thread)
t_colon :- q(foo:with_mutex(m, true)).

%% the last call of a guarded clause: library(signal)
t_det :- q((det_s(O), nonvar(O))).
det_s(O) :- $, on_signal(int, O, O).

%% library(readutil) by its name: the module that holds its predicates
t_readutil :- q(use_module(library(readutil))),
              open('a.txt', read, S), read_line_to_string(S, L1), read_line_to_string(S, L2),
              read_line_to_string(S, L3), close(S), print([L1, L2, L3]), nl.

main :- t_cp, t_file, t_pp, t_err, t_colon, t_det, t_readutil.
