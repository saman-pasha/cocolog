%% reader.pl -- every shape that has ever fooled a clause reader here.
%%
%% NOT MEANT TO RUN. It is a FIXTURE: clauses.pl must read it into exactly the
%% clause list in reader.expected, and test/lint.pl checks that. Every case is
%% one that was got wrong at some point, by this reader or by the Python one it
%% replaced, and each is labelled with what went wrong.
%%
%% This is what replaced the differential check against clauses.py. A second
%% implementation catches a regression by disagreeing; a fixture catches it by
%% being specific, and does not go stale when an unrelated tutorial is edited.

%% ---- A DCG HEAD OCCUPIES ARITY+2. The whole reason a regex will not do:
%% a regex over heads answers digit/1 where the store holds digit/3.
rd_digit(D) --> [D].
rd_digits([D|T]) --> rd_digit(D), rd_digits(T).
rd_none --> [].

%% ---- A PUSHBACK HEAD IS STILL A DCG HEAD.
rd_push, [0'x] --> [0'y].

%% ---- A 0'c LITERAL IS NOT ALWAYS THREE CHARACTERS. 0'a and 0'' are three;
%% 0''' and 0'\n are four. Reading them all as three made the escaped quote
%% open a quote that swallowed the argument list, so this clause came out as
%% rd_esc/1 PLAIN where the store holds rd_esc/3 DCG. Found by the collision
%% oracle disagreeing with two readers at once.
rd_esc([0'\',0'\'|T]) --> [0'\', 0'\'], rd_esc(T).
rd_quote(0''') --> [].
rd_nl(0'\n) --> [].
rd_plain(0'a, 0'b) --> [].

%% ---- A PREFIX OPERATOR TAKES ITS ARGUMENT WITHOUT PARENTHESES.
%% `:- dynamic rd_seen/1.' is dynamic/1, not dynamic/0. Reading it as 0 made
%% the linter reject eight files of correct code.
:- dynamic rd_seen/1.
:- discontiguous rd_spread/2.

%% ---- A `.' AFTER A DIGIT STILL ENDS A CLAUSE. A guard meant to protect 3.14
%% made this directive swallow the clause after it.
:- multifile rd_multi/2.
rd_after_directive(1).
rd_pi(3.14).

%% ---- A Module:Head CLAUSE IS STORED UNDER HEAD. aggregate.pl writes
%% `sandbox:safe_meta_predicate(...)' and cocolog stores it under the head --
%% verified against the binary. Reading the qualifier as the name blocked a
%% free name and missed a taken one.
rd_mod:rd_qualified(X) :- rd_seen(X).

%% ---- A QUOTED HEAD, including one with a $ in it and a doubled quote.
'rd_$internal'(X) :- rd_seen(X).
'rd_it''s'(1).

%% ---- A `.' INSIDE A QUOTED ATOM DOES NOT END A CLAUSE.
rd_dotted('a. b', 'c.').

%% ---- NESTED ARGUMENT LISTS, and a comma inside a list and inside a quote.
rd_nested(f(g(1,2), [a,b,c]), 'x,y', "p,q").

%% ---- A COMMENT IS NOT CODE, and a /* */ can span clauses.
/* rd_commented(1).
   rd_commented(2). */
rd_real(1).   % rd_fake(2).

%% ---- A CLAUSE THAT ENDS AT END OF FILE WITH NO FINAL `.' is still a clause.
rd_last(ok)
