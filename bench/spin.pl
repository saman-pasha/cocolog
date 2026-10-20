%% The work unit of bench/concurrency.sh, in one module so library(thread)'s
%% threads can see it: a thread's store starts empty, and the process-wide
%% module registry is what fills it on the first goal. The green threads
%% get it from their snapshot of the caller's store, which `use_module`
%% filled in the host. The same recursion, `M` edges, in every lane.

spin(0) :- !.
spin(N) :- N > 0, M is N - 1, spin(M).
