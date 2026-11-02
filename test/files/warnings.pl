%  Load-time warnings: singleton variables and clauses that are not together.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte; the
%  paths in the warning are the same absolute sandbox path in both runs.
p(X) :- q(X).
q(a).
r(Y, Y) :- true.
p(Z) :- true.
under(_H) :- true.
main :- writeln(loaded).
