%% predicate_property/2 of a name one of cocolog's own modules holds, asked
%% before anything loaded the module (cocolog 3.66.0), held to swipl 9.0.4.
%% Run by test/files.pl beside swipl, the two outputs compared byte for
%% byte.
%%
%% swipl's predicate_property/2 autoloads what it is asked of
%% (define_or_generate/1); cocolog's loads the module of its own that holds
%% the name first, as a call would (lib/builtins-db.cicili, before the
%% properties are read), and through 3.65.0 answered nothing for any of
%% these: with_mutex/2 is library(thread)'s, stream_property/2
%% library(stream)'s, each a clause of the module's Prolog half -- swipl
%% defines the first in C, whose clauses it does not count.

q(G) :- catch((G -> R = yes ; R = no), error(F, _), R = ex(F)), print(R), nl.

main :- q(predicate_property(with_mutex(_, _), defined)),
        q(predicate_property(with_mutex(_, _), number_of_clauses(_))),
        q(predicate_property(stream_property(_, _), defined)),
        q(predicate_property(stream_property(_, _), number_of_clauses(_))).
