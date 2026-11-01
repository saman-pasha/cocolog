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
%% AND THREE THINGS THAT ARE COCOLOG'S, not ISO's, which the second half
%% of this lesson is about:
%%
%%   * a REFUSAL -- cocolog declining what no ISO formal fits: format's
%%     column directives, a library found and refused, a module's own
%%     failure -- is `error(cocolog_error(Text), _)', a sentence where
%%     ISO puts a formal, so a handler that names a formal walks straight
%%     past it. Card row C2; cocolint has a rule. (A file that is NOT
%%     THERE is no refusal: it is swipl's `existence_error(source_sink,
%%     Spec)' since 3.4.0, where through 3.3.0 it was the sentence too.)
%%   * the CONTEXT slot of a core builtin's error is swipl's,
%%     `context(system:atom_length/2, _)' (3.0.0), but the loader's
%%     ball leaves it an unbound variable, so writing
%%     `error(T, context(_,_))' does not fail to match THAT: it matches
%%     by BINDING, and everything the handler reads out of it is invented.
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
    %% THE CULPRIT IS NAMED WITH ITS ARITY, `foo/0' -- an evaluable functor
    %% is a name and an arity, and SWI says the same (through 1.10.5
    %% cocolog named the atom alone). A handler matching the FORMAL,
    %% `type_error(evaluable, _)', never cared about that spelling, which is
    %% the argument for matching the formal and not the whole ball.
    catch(X2 is foo + 1, error(E2, _), true),
    must('arithmetic on an atom', E2,
         type_error(evaluable, foo/0)),
    ( var(X2) -> _ = ok ; true ),
    catch(no_such_predicate_here, error(E3, _), true),
    must('a predicate that does not exist', E3,
         existence_error(procedure, no_such_predicate_here/0)),

    format("~n-- A REFUSAL'S BALL IS NOT ISO, and a handler can miss it~n"),
    %% A FILE THAT IS NOT THERE raises swipl's ball, the formal ISO names
    %% for a source that does not exist (3.4.0; through 3.3.0 it was the
    %% sentence below).
    catch(use_module('/no/such/library.pl'), error(E4, _), true),
    must('a file that is not there', E4,
         existence_error(source_sink, '/no/such/library.pl')),
    %% A REFUSAL is `error(cocolog_error(Text), _)': cocolog declining
    %% something no ISO formal fits -- here format's column directives,
    %% which cocolog does not have. The first argument is a SENTENCE and
    %% not one of ISO's formals. It is row C2 of the dialect card, and
    %% cocolint has a rule for it, because a handler written for SWI names
    %% a formal and walks past: `format(Message)' is the one swipl raises
    %% for a format string it cannot use, and cocolog raises it too, for
    %% `~a' with no argument left.
    catch(format(atom(_), "~t~20|x", []), error(E7, _), true),   % cocolint: F1 -- the refusal is the lesson
    ( E7 = cocolog_error(_) -> Shape = cocolog_error ; Shape = E7 ),
    must('a refusal is cocolog_error/1', Shape, cocolog_error),
    catch( catch(format(atom(_), "~t~20|x", []),   % cocolint: F1 -- the refusal is the lesson
                 error(format(_), _), Inner2 = caught),
           error(cocolog_error(_), _), Outer2 = caught),
    ( var(Inner2) -> Miss = missed ; Miss = caught ),
    must('a handler naming a FORMAL misses it', Miss, missed),
    must('...and one naming cocolog_error/1 takes it', Outer2, caught),
    format("   So `error(T, _)' is the catcher that takes both shapes, and~n"),
    format("   `cocolog_error(Text)' is how you read the message.~n"),

    format("~n-- the CONTEXT slot: a builtin's names it, the loader's is empty~n"),
    %% A CORE BUILTIN SAYS WHO RAISED, as swipl 9.0.4 does (3.0.0; through
    %% 2.16 every one left the slot a fresh variable): the predicate, its
    %% module, and a message where it has one. The toplevel prints the
    %% indicator before the message, `atom_length/2: Arguments are not
    %% sufficiently instantiated'.
    catch(atom_length(_, _), error(_, Ctx), true),
    ( Ctx = context(Who1, _) -> C1 = Who1 ; C1 = Ctx ),
    must('what a builtin leaves in the second argument', C1, system:atom_length/2),
    %% THE LOADER'S BALL STILL LEAVES IT UNBOUND, which makes
    %% `context(_,_)' WORSE THAN USELESS there, and is the half of C2 that
    %% surprises people: the pattern does not FAIL to match, it matches by
    %% BINDING an unbound slot -- so the handler runs and everything it
    %% reads out of the context is something it invented. (This line is
    %% what cocolint's C2 rule looks for. A lesson that teaches a trap trips
    %% it, which is the honest way round, and the comment at its end
    %% acknowledges the finding and says why.)
    catch(use_module('/no/such/library.pl'), error(_, context(Who, _)), true),   % cocolint: C2 -- the lesson: it matches by binding
    ( var(Who) -> C2 = matched_and_said_nothing ; C2 = Who ),
    must('`context(_,_)` matches the loader\'s anyway, by binding', C2, matched_and_said_nothing),

    format("~n-- rethrow: handle what you know, pass on what you do not~n"),
    catch(risky(9), B5, ( B5 = mine(N5) -> Got = N5 ; throw(B5) )),
    must('the ball you meant', Got, 9),
    catch( catch(strange, B6, ( B6 = mine(N6) -> Got2 = N6 ; throw(B6) )),
           not_mine(N7), Passed = N7),
    ( var(Got2) -> P = passed_on ; P = handled ),
    must('the ball you did not', P, passed_on),
    must('...caught by the outer handler instead', Passed, 1),

    format("~n-- cleanup: setup_call_cleanup/3~n"),
    %% `setup_call_cleanup(Setup, Goal, Cleanup)' (3.1.0, swipl's) runs
    %% Setup once, then Goal, and Cleanup once Goal is DONE WITH: it
    %% exited and left no choice, it failed, it threw, or its choices were
    %% cut. A ball goes on to whoever wanted it after the cleanup has run.
    %% The by-hand pattern, `catch(Goal, B, (Cleanup, throw(B)))', cleans
    %% up after a throw alone -- which is what you want when success is
    %% the one outcome that must KEEP what Setup made.
    catch(setup_call_cleanup(true, work, cleanup), oh_no, Done = ok),
    must('the ball still arrives', Done, ok),
    ( touched(cleaned) -> Cl = ran ; Cl = missed ),
    must('and the cleanup ran on the way', Cl, ran),
    retract(touched(cleaned)),
    ( setup_call_cleanup(true, fail, cleanup) -> F8 = held ; F8 = failed ),
    ( touched(cleaned) -> Cl8 = ran ; Cl8 = missed ),
    must('a goal that fails: no, and the cleanup', F8-Cl8, failed-ran),
    retract(touched(cleaned)),
    once(setup_call_cleanup(true, member(X9, [1, 2, 3]), cleanup)),
    ( touched(cleaned) -> Cl9 = ran ; Cl9 = missed ),
    must('a goal with choices left: the first answer, cleaned at the cut',
         X9-Cl9, 1-ran),
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
    format("     ERROR: -g main: catch/3: Unknown procedure: nosuch/0~n~n"),
    format("   0 proved, 1 failed, 2 threw. A script that reads exit codes~n"),
    format("   can tell the goal that said no from the goal that broke.~n"),
    format("   The second line names the FRAME the call was made in, as~n"),
    format("   swipl's does (3.1.0): `main :- nosuch.' calls nosuch last,~n"),
    format("   so main's clause is gone, and the goal runs under catch/3.~n"),
    format("   A call that is not the last names its clause's predicate:~n"),
    format("   `main/0: Unknown procedure: nosuch/0'.~n"),
    format("   After the message comes WHERE it was raised (1.10.17): the~n"),
    format("   goal that raised it and the goals left to run, or -- with~n"),
    format("   --backtrace -- every call it was made in, as SWI writes them.~n"),
    format("   `main :- risky(6), write(never).' under `run ... main':~n"),
    format("~n     ERROR: -g main: Unknown message: mine(6)~n"),
    format("     ERROR: In:~n"),
    format("     ERROR:   [3] throw(mine(6))~n"),
    format("     ERROR:   [2] risky(6)~n"),
    format("     ERROR:   [1] main~n~n"),
    format("   (TRACING.md; --no-backtrace keeps the message alone.)~n"),
    %% AND AT LOAD TIME. Thrown out of a directive, the report is
    %% swipl's, line for line, and test/directives.pl diffs the two to
    %% keep it so:
    %%
    %%     ERROR: p.pl:7:
    %%     ERROR:    atom_length/2: Arguments are not sufficiently instantiated
    %%     Warning: p.pl:7:
    %%     Warning:    Goal (directive) failed: user:atom_length(_G8,3)
    %%
    %% An ERROR TERM is reported and the load goes on, the directive
    %% counted as failed and written as it was asked (3.1.0). ANY OTHER
    %% BALL ENDS THE LOAD, as it does in swipl: consult/1 raises it to
    %% its caller, and `-s' says `Prolog initialisation failed:' and
    %% exits 1. An `initialization(G)' goal, run after the file is read,
    %% is reported and the next one runs, whatever its ball.
    format("   Thrown at LOAD time an error(_, _) is reported with its file~n"),
    format("   and line, and the load carries on; any other ball ends it:~n"),
    t09_fixture(':- throw(oh_no).', F10),
    catch(consult(F10), B10, true),
    delete_file(F10),
    must('consult/1 raises a directive\'s ball that is no error', B10, oh_no),
    ( catch(t09_after, _, fail) -> A10 = loaded ; A10 = not_loaded ),
    must('...and the clause after it was never read', A10, not_loaded),

    format("~n-- and the shape a library should throw~n"),
    format("   error(type_error(Type, Culprit), Context) -- so a caller can~n"),
    format("   match the FORMAL and ignore the context. Never throw a bare~n"),
    format("   atom from a library: it collides with everybody else's.~n~n"),
    format("done~n").

%% a file whose first line is LINE and whose second defines t09_after/0,
%% in the system's temporary directory
t09_fixture(Line, F) :-
    tmp_file(t09, F0), atom_concat(F0, '.pl', F),
    format(atom(Text), "~w~nt09_after.~n", [Line]),
    atom_codes(Text, Codes),
    write_file_from_codes(F, Codes).

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
