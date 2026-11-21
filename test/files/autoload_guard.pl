%% The last call of a $/0-guarded clause that is the FIRST call of a
%% predicate one of cocolog's own modules holds (cocolog 3.66.0), held to
%% swipl 9.0.4. Run by test/files.pl beside swipl, the two outputs compared
%% byte for byte.
%%
%% is_stream/1 is library(stream)'s, which no goal here loads: g_fail's last
%% call loads it. The guard is the loaded predicate's to take on, as it is a
%% predicate's the module defined before: its failure is
%% determinism_error(is_stream/1, det, fail, guard_in_caller) at the first
%% call as at the second, and a call that succeeds is no error. The load is
%% asked where the step is about to raise the unknown procedure
%% (`coco_autoload_step', lib/solve-control.cicili), after the guard's last
%% call was taken on (`coco_det_pcall'): the call taken again after the load
%% is the last call it was, and takes the guard on again.

q(G) :- catch((G -> R = yes ; R = no), error(F, Ctx), ( arg(1, Ctx, C), R = ex(F, C) )), print(R), nl.

g_fail :- $, is_stream(foo).
g_ok :- $, is_stream(user_input).

main :- q(g_fail), q(g_fail), q(g_ok).
