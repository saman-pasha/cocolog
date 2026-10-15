%% test/flowchart/gate_lib.pl -- a file of gate.pl's program that declares a
%% table as it runs (test/flowchart.pl's gate section loads it).

gl_ready :- dynamic(gl_table/1).
