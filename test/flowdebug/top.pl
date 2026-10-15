%% test/flowdebug.pl's small top file (1.11.7): its goals call into run.pl,
%% which a chart of this file does not draw -- so the calls an exception
%% ended are placed in run.pl's clauses as library(flow/debug) reads them
%% from the file: shape_ok/1#c1.g1 the if-then-else of shape_ok/1's first
%% clause, as cicili-lang's cpp_not_abstract/1#c1.g1 is.

:- use_module('test/flowdebug/run.pl').

top_build(Ss) :- build(Ss).

top_stop(Ss) :- build_stop(Ss).

%% a predicate the chart draws, called again from run.pl's clauses, which it
%% does not: that call is walked in the predicate's own panel, and its throw
%% placed there (1.11.7)
top_hooked(Ss) :- top_hook(round), each_hook(top_hook, Ss).

top_hook(S) :- ( S == solid -> throw(error(hooked(S), top_hook/1)) ; true ).
