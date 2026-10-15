%% test/flowchart/gate_clash.pl -- a helper that takes a name the chart's
%% library has (library/flow/read.pl's flow_trim/2): loaded beside a
%% program, its clause joins the library's. test/flowchart.pl's gate
%% section charts with it in a process of its own and expects the refusal.

flow_trim(Cs, Cs).
