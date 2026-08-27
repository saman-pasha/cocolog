%% BASICS 09 -- failure is not an error, and errors are terms
%%
%%     ./cocolog run tutorials/basics/09-exceptions.pl main
%%
%% THERE ARE THREE OUTCOMES, not two, and keeping them apart is most of
%% what makes a Prolog program readable:
%%
%%     SUCCESS   the goal held, and bindings came back
%%     FAILURE   the goal did not hold. This is an ANSWER -- "no" -- and
%%               it is how `member(x, [a,b])' says x is not there
%%     ERROR     the question could not be asked at all: a type is wrong,
%%               an argument is unbound, a predicate does not exist
%%
%% USING FAILURE FOR ERRORS is the commonest design mistake. If
%% `parse(Text, Term)' fails, the caller cannot tell "that is not valid
%% input" from "I have a bug". Throw for the second.
%%
%% AN ERROR IS AN ORDINARY TERM, and ISO fixes its shape:
%%
%%     error(Formal, Context)
%%
%% where `Formal' names what went wrong -- `type_error(integer, foo)',
%% `existence_error(procedure, p/1)', `instantiation_error' -- and
%% `Context' is implementation-defined. So a handler MATCHES on it, which
%% is why you should never catch a bare variable unless you mean to catch
%% absolutely everything, including the bugs.
%%
%% `catch/3' AND `throw/1' unwind to the nearest matching catcher and
%% undo every binding made in between.

:- dynamic touched/1.

%% Fails for a bad key -- an ordinary "no".
lookup(K, V) :- pair(K, V).

pair(a, 1).  pair(b, 2).

%% Throws for a bad ARGUMENT -- "this question is malformed".
double(N, D) :-
    (   integer(N)
    ->  D is N * 2
    ;   throw(error(type_error(integer, N), double/2))
    ).

main :-
    format("~n-- failure is an answer~n"),
    ( lookup(a, V1) -> R1 = V1 ; R1 = not_found ),
    must('lookup(a, V)', R1, 1),
    ( lookup(z, V2) -> R2 = V2 ; R2 = not_found ),
    must('lookup(z, V)', R2, not_found),

    format("~n-- an error is not~n"),
    catch(double(foo, _), error(E, _), true),
    must('double(foo, D) throws', E, type_error(integer, foo)),
    double(21, D),
    must('double(21, D)', D, 42),

    format("~n-- catch/3 matches on the ball, so be specific~n"),
    catch(throw(my_problem), my_problem, Caught = yes),
    must('a term of your own', Caught, yes),
    %% A BALL THAT DOES NOT MATCH GOES STRAIGHT PAST, which is the point
    %% of matching at all: the inner catch is looking for `my_problem' and
    %% this is not one, so the OUTER catch is the one that takes it.
    catch(catch(throw(other), my_problem, Inner = wrong),
          other, Outer = right),
    ( var(Inner) -> I = did_not_catch ; I = caught ),
    must('the inner catch, looking for my_problem', I, did_not_catch),
    must('the outer one, looking for other', Outer, right),

    format("~n-- bindings made before a throw are UNDONE~n"),
    catch(( assertz(touched(yes)), X = bound, throw(stop) ), stop, true),
    ( var(X) -> B = undone ; B = kept ),
    must('the binding', B, undone),
    format("   ...but an ASSERT is not a binding, and survives:~n"),
    ( touched(yes) -> T = still_there ; T = gone ),
    must('the asserted clause', T, still_there),
    retract(touched(yes)),

    format("~n-- the errors the system itself throws~n"),
    catch(atom_length(_, _), error(E1, _), true),
    must('an unbound argument', E1, instantiation_error),
    %% SWI NAMES THE CULPRIT `foo/0' -- an evaluable functor with its
    %% arity. cocolog names the atom. Both are `type_error(evaluable, _)',
    %% so a handler matching the FORMAL works either way, which is the
    %% argument for matching the formal and not the whole ball.
    catch(X2 is foo + 1, error(E2, _), true),
    must('arithmetic on an atom (SWI says foo/0 here)', E2,
         type_error(evaluable, foo)),
    ( var(X2) -> _ = ok ; true ),
    catch(no_such_predicate_here, error(E3, _), true),
    must('a predicate that does not exist', E3,
         existence_error(procedure, no_such_predicate_here/0)),

    format("~n-- and the shape a library should throw~n"),
    format("   error(type_error(Type, Culprit), Context) -- so a caller can~n"),
    format("   match the FORMAL and ignore the context. Never throw a bare~n"),
    format("   atom from a library: it collides with everybody else's.~n~n"),
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
