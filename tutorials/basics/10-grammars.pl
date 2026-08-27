%% BASICS 10 -- grammars: `-->' and phrase/2
%%
%%     ./cocolog run tutorials/basics/10-grammars.pl main
%%
%% A DEFINITE CLAUSE GRAMMAR IS SUGAR, and knowing what it desugars TO is
%% the whole lesson. This rule:
%%
%%     greeting --> [hello], [world].
%%
%% is translated, at the moment it is read, into an ordinary predicate of
%% two extra arguments:
%%
%%     greeting(S0, S) :- S0 = [hello|S1], S1 = [world|S].
%%
%% The two arguments are a DIFFERENCE LIST: "here is the input, and here
%% is what is left". Every nonterminal takes what it needs off the front
%% and hands the rest on. There is no parser generator, no separate
%% language, and no magic -- just two arguments you did not have to type.
%%
%% `phrase(Rule, List)' STARTS IT with `S = []': parse this list, and
%% leave nothing over. `phrase(Rule, List, Rest)' leaves `Rest'.
%%
%% `{ Goal }' IS AN ESCAPE back to ordinary Prolog, for anything that is
%% not consuming input -- arithmetic, a test, building a result.
%%
%% GRAMMARS PARSE CODES HERE, because that is what text is in cocolog:
%% `"12"' is `[49, 50]'. A DCG over an atom would have to take it apart
%% first, and taking things apart one element at a time is exactly what a
%% list is for.
%%
%% AND A GRAMMAR RUNS BACKWARDS TOO, like everything else -- the same
%% rules that recognise a list can generate one.

%% Terminals in [ ] are literal; a string literal is a list of codes, so
%% "abc" in a DCG body consumes three bytes.
greeting --> "hello", " ", "world".

%% Recursion, and a nonterminal that can match nothing.
digits([D|T]) --> digit(D), digits(T).
digits([D])   --> digit(D).

digit(D) --> [D], { D >= 0'0, D =< 0'9 }.

%% `{ }' to turn what was collected into a number.
number_from(N) --> digits(Ds), { number_codes(N, Ds) }.

%% A tiny expression grammar: sums of numbers, left to right.
sum(N)      --> number_from(A), sum_rest(A, N).
sum_rest(A, N) --> "+", number_from(B), { C is A + B }, sum_rest(C, N).
sum_rest(N, N) --> [].

%% GENERATING. The same two extra arguments, used the other way round:
%% nothing here inspects the input, so with an unbound list it BUILDS one.
csv([X])    --> item(X).
csv([X|Xs]) --> item(X), ",", csv(Xs).

%% `{ atom_codes(X, Cs) }' BEFORE the terminals is what makes this
%% generate-only, and it is worth seeing why. Generating, X is bound and
%% the goal makes the codes; PARSING, X is unbound and there is nothing to
%% take apart -- the escape runs before a single byte has been read. A
%% rule that consumes first and converts after would go both ways, and
%% `number_from//1' above is exactly that shape. Purity is not automatic:
%% it is a property of where you put the `{ }'.
item(X) --> { atom_codes(X, Cs) }, string_of(Cs).

string_of([]) --> [].
string_of([C|Cs]) --> [C], string_of(Cs).

main :-
    format("~n-- a grammar rule is a predicate with two extra arguments~n"),
    ( phrase(greeting, "hello world") -> R = parsed ; R = refused ),
    must('phrase(greeting, "hello world")', R, parsed),
    ( phrase(greeting, "hello there") -> R2 = parsed ; R2 = refused ),
    must('phrase(greeting, "hello there")', R2, refused),

    format("~n-- and you can call the desugared form directly~n"),
    ( greeting("hello world", []) -> D = same_thing ; D = different ),
    must('greeting(S0, S) by hand', D, same_thing),

    format("~n-- phrase/3 hands back what was NOT consumed~n"),
    phrase(greeting, "hello world, and more", Rest),
    atom_codes(RestAtom, Rest),
    must('the rest', RestAtom, ', and more'),

    format("~n-- { } escapes to ordinary Prolog for anything not consuming~n"),
    phrase(number_from(N), "1234"),
    must('a number out of its digits', N, 1234),

    format("~n-- recursion gives you a real little parser~n"),
    phrase(sum(S1), "1+2+3"),
    must('1+2+3', S1, 6),
    phrase(sum(S2), "10+20"),
    must('10+20', S2, 30),
    ( phrase(sum(_), "1+") -> Bad = parsed ; Bad = refused ),
    must('an incomplete sum', Bad, refused),

    format("~n-- a PURE grammar runs backwards, and generates~n"),
    phrase(greeting, Made),
    atom_codes(MadeAtom, Made),
    must('phrase(greeting, L) with L unbound', MadeAtom, 'hello world'),
    format("   ...because greeting//0 only ever names terminals: nothing~n"),
    format("   in it inspects a byte, so with an unbound list unification~n"),
    format("   fills the list in instead of matching against it.~n"),
    catch(phrase(number_from(7), _), error(NumErr, _), true),
    must('number_from//1 asked to generate', NumErr, instantiation_error),
    format("   number_from//1 cannot: `{ D >= 0'0 }' has to LOOK at a byte,~n"),
    format("   and generating there is nothing to look at yet.~n"),

    format("~n-- ...and one that is not, does not. csv//1 only generates~n"),
    phrase(csv([a, bb, ccc]), Out),
    atom_codes(OutAtom, Out),
    must('csv([a, bb, ccc]) written out', OutAtom, 'a,bb,ccc'),
    ( catch(phrase(csv(_), "x,yy"), _, fail) -> P = parsed ; P = refused ),
    must('and asked to PARSE the same thing', P, refused),
    format("   Because its `{ atom_codes(X, Cs) }' runs before anything is~n"),
    format("   consumed, and parsing has no X yet. Move the escape after~n"),
    format("   the terminals and the rule works in both directions.~n"),

    format("~n-- the vendored SWI grammar helpers are always there~n"),
    format("   library(dcg/basics) needs no use_module here: see~n"),
    format("   tutorials/library/05-dcg. `library(http)' is a DCG over~n"),
    format("   bytes from a socket, and the three document libraries are~n"),
    format("   DCGs in both directions. This is the shape they all use.~n~n"),
    format("done~n").

%% ---- the two helpers every lesson here carries ------------------------
%% REPEATED ON PURPOSE, in every file. A tutorial you can copy anywhere and
%% run is worth six duplicated lines; a tutorial that needs a support
%% library beside it is a tutorial that stops working the moment it is
%% moved.
show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

%% `must/3' IS WHY THESE FILES ARE TESTS. Every claim a lesson makes is a
%% goal that has to hold: get it wrong and `main' FAILS, loudly, naming
%% both answers. A tutorial that prints whatever it computed is a tutorial
%% that goes quietly wrong the day the language changes underneath it.
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
