%% test/flowchart/gate_half.pl -- a library the Prolog half of
%% gate_mod.cicili loads: it declares a table as it runs, which a chart
%% given modules(gate_mod.cicili) reads (test/flowchart.pl's gate section
%% puts test/flowchart/ on the library path for it).

gh_ready :- assertz(gh_row(1, 2)).
