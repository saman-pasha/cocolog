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
%%
%% AND FOUR THINGS THAT ARE COCOLOG'S, not ISO's, which the second half
%% of this lesson is about:
%%
%%   * a LIBRARY OR LOADER failure is `error(cocolog_error(Text), _)' --
%%     a sentence where ISO puts a formal -- so a handler that names a
%%     formal walks straight past it. Card row C2; cocolint has a rule.
%%   * the CONTEXT slot is left an unbound variable, so writing
%%     `error(T, context(_,_))' does not fail to match: it matches by
%%     BINDING, and everything the handler reads out of it is invented.
%%   * there is no `setup_call_cleanup/3'. Cleanup is
%%     `catch(G, B, (Cleanup, throw(B)))', by hand.
%%   * a ball carrying `"text"' reports as a LIST OF CODES, because
%%     `double_quotes' is ISO's `codes' here and SWI's is `string'.
%%     Quote the text as an atom, or set the flag for the file.
%%
%% An UNCAUGHT ball reaches the toplevel, prints in SWI's words, and the
%% process exits 2 -- where a goal that merely failed exits 1, silently.

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

    format("~n-- THE LOADER'S BALL IS NOT ISO, and a handler can miss it~n"),
    %% A library or a loader failure is `error(cocolog_error(Text), _)':
    %% the first argument is a SENTENCE and not one of ISO's formals. It
    %% is row C2 of the dialect card, and cocolint has a rule for it,
    %% because a handler written for SWI names a formal and walks past.
    catch(use_module('/no/such/library.pl'), error(E4, _), true),
    ( E4 = cocolog_error(_) -> Shape = cocolog_error ; Shape = E4 ),
    must('a loader failure is cocolog_error/1', Shape, cocolog_error),
    catch( catch(use_module('/no/such/library.pl'),
                 error(existence_error(_, _), _), Inner2 = caught),
           error(cocolog_error(_), _), Outer2 = caught),
    ( var(Inner2) -> Miss = missed ; Miss = caught ),
    must('a handler naming a FORMAL misses it', Miss, missed),
    must('...and one naming cocolog_error/1 takes it', Outer2, caught),
    format("   So `error(T, _)' is the catcher that takes both shapes, and~n"),
    format("   `cocolog_error(Text)' is how you read the message.~n"),

    format("~n-- and the CONTEXT slot is a fresh variable~n"),
    catch(atom_length(_, _), error(_, Ctx), true),
    ( var(Ctx) -> C1 = a_fresh_variable ; C1 = Ctx ),
    must('what a builtin leaves in the second argument', C1, a_fresh_variable),
    %% WHICH MAKES `context(_,_)' WORSE THAN USELESS, and is the half of
    %% C2 that surprises people: the pattern does not FAIL to match, it
    %% matches by BINDING an unbound slot -- so the handler runs and
    %% everything it reads out of the context is something it invented.
    %% (This line is what cocolint's C2 rule looks for. A lesson that
    %% teaches a trap trips it, which is the honest way round.)
    catch(atom_length(_, _), error(_, context(Who, _)), true),
    ( var(Who) -> C2 = matched_and_said_nothing ; C2 = Who ),
    must('`context(_,_)` matches anyway, by binding', C2, matched_and_said_nothing),

    format("~n-- rethrow: handle what you know, pass on what you do not~n"),
    catch(risky(9), B5, ( B5 = mine(N5) -> Got = N5 ; throw(B5) )),
    must('the ball you meant', Got, 9),
    catch( catch(strange, B6, ( B6 = mine(N6) -> Got2 = N6 ; throw(B6) )),
           not_mine(N7), Passed = N7),
    ( var(Got2) -> P = passed_on ; P = handled ),
    must('the ball you did not', P, passed_on),
    must('...caught by the outer handler instead', Passed, 1),

    format("~n-- cleanup by hand: there is no setup_call_cleanup/3~n"),
    %% The pattern is `catch(Goal, B, (Cleanup, throw(B)))' -- do the
    %% cleanup, then let the ball go on to whoever wanted it. Nothing here
    %% runs the cleanup on SUCCESS as well, so a goal that can both
    %% succeed and throw needs the call after the catch too.
    catch( catch(work, B7, (cleanup, throw(B7))), oh_no, Done = ok),
    must('the ball still arrives', Done, ok),
    ( touched(cleaned) -> Cl = ran ; Cl = missed ),
    must('and the cleanup ran on the way', Cl, ran),
    retract(touched(cleaned)),

    format("~n-- A BALL THAT CARRIES TEXT, and what the message shows~n"),
    %% THE COMMONEST SURPRISE IN A MESSAGE, and it is the reader's doing
    %% rather than the thrower's: `double_quotes' is `codes' here, ISO's
    %% default, where SWI's is `string'. So the same `throw' writes a list
    %% of numbers under cocolog and a quoted string under SWI, and the
    %% message is unreadable in exactly the case you most want to read it.
    E5 = my_error("not a type", nosuch_t),
    arg(1, E5, Arg5),
    ( is_list(Arg5) -> K5 = a_code_list ; K5 = Arg5 ),
    must('"..." inside a ball is a CODE LIST by default', K5, a_code_list),
    E6 = my_error('not a type', nosuch_t),
    arg(1, E6, Arg6),
    ( atom(Arg6) -> K6 = an_atom ; K6 = Arg6 ),
    must('...so quote the text as an ATOM', K6, an_atom),
    format("   `throw(my_error(\"no such type\", T))' reports as~n"),
    format("   my_error([110,111,...],T) -- true to the flag and no use to~n"),
    format("   anybody. Quote it, or put~n"),
    format("   `:- set_prolog_flag(double_quotes, string).' at the top of~n"),
    format("   the file and get SWI's reading for the whole of it.~n"),

    format("~n-- and what an UNCAUGHT ball costs~n"),
    format("   It reaches the toplevel, which prints it in SWI's words and~n"),
    format("   exits 2 -- not 1, which is what a goal that merely FAILED~n"),
    format("   exits with, silently:~n"),
    format("~n     ERROR: -g main: Unknown message: my_ball~n"),
    format("     ERROR: -g main: Unknown procedure: nosuch/0~n~n"),
    format("   0 proved, 1 failed, 2 threw. A script that reads exit codes~n"),
    format("   can tell the goal that said no from the goal that broke.~n"),
    %% AND ONE THING THE MESSAGE DOES NOT SAY. Thrown at LOAD time -- out
    %% of a directive or an `initialization' goal -- the report is SWI's,
    %% line for line, and test/directives.sh diffs the two to keep it so:
    %%
    %%     ERROR: p.pl:76: Initialization goal raised exception:
    %%     ERROR: Unknown message: my_error(...)
    %%
    %% What swipl has there and cocolog does not is a CONTEXT before the
    %% message -- `catch/3: Unknown procedure: p/0' -- because its
    %% builtins fill error/2's second argument in and cocolog leaves it
    %% unbound. Which is the same fact as the section above, seen from
    %% the other side: nothing is in the context, so nothing is printed
    %% from it.
    format("   Thrown at LOAD time the report names the file and the line,~n"),
    format("   and the load carries on -- see tutorials/basics/11.~n"),

    format("~n-- and the shape a library should throw~n"),
    format("   error(type_error(Type, Culprit), Context) -- so a caller can~n"),
    format("   match the FORMAL and ignore the context. Never throw a bare~n"),
    format("   atom from a library: it collides with everybody else's.~n~n"),
    format("done~n").

%% ---- what the sections above throw ------------------------------------
risky(N) :- N > 5, throw(mine(N)).
strange  :- throw(not_mine(1)).
work     :- throw(oh_no).
cleanup  :- assertz(touched(cleaned)).

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
