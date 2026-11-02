%  A discontiguous declaration suppresses the not-together warning; a
%  singleton name that begins with `_' suppresses the singleton warning.
:- discontiguous p/1.
p(a).
q(a).
p(b).
under(_X) :- true.
main :- writeln(quiet).
