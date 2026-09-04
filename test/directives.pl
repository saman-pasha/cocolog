%% directives: `:- G' is a GOAL, `initialization' puts one off, and a bad one
%% is reported rather than fatal.
%%
%% WHAT CHANGED, AND WHY IT NEEDED A CASE OF ITS OWN. A directive used to be
%% matched against a list of fourteen names and refused if it was not one of
%% them -- and the refusal took the WHOLE CONSULT with it, so a file whose
%% first line was `:- initialization(main).' loaded nothing at all and the
%% error named a directive rather than the file. Now the fourteen are only
%% the ones that must act on the READER (op/3, set_prolog_flag,
%% dynamic/1, if/elif/else/endif: they change how the rest of the file
%% parses or what it means) and everything else is CALLED, in file order,
%% through a seam the library layer fills in with an engine.
%%
%% THE THREE ANSWERS A DIRECTIVE CAN GIVE are what most of this file is
%% about, because they are what a person sees when something is wrong:
%% proved (silence), failed (a Warning naming the goal), threw (an ERROR
%% naming the ball in SWI's words). None of the three stops the load.
%%
%% MEASURED AGAINST swipl, not remembered. Every message shape below was
%% read off a real `swipl -q -g main -t halt' run first and the code written
%% to match; where swipl is on the machine the last section runs the SAME
%% file under both and diffs what they say. That is the only kind of
%% compatibility claim that cannot be fooled by its author.
%%
%%     cocolog -s test/directives.pl        from the checkout root
%%
%% Every check IS a child: what is pinned is what a CONSULT reports, on the
%% loader's stderr, and how the process exits.

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    a_goal(D), does_not_prove(D), syntax_error(D), initialization(D), init_main(D),
    exit_status(D), reader_level(D), the_program(D), under_swipl(D),
    shl(['rm -rf ', D]),
    checks_done.

%% `cocolog --local run FILE GOAL', both streams and the exit
ran(File, Goal, Got, Rc) :-
    sh_join(['--local run ', File, ' "', Goal, '" 2>&1'], Args), cocolog_run(Args, Got, Rc).
ran(File, Goal, Got) :- ran(File, Goal, Got, _).

a_goal(D) :-
    section('a directive is a goal'),
    atom_concat(D, '/run.pl', F),
    fixture(F,
            [ ':- assert(seen(one)).',
              ':- ( seen(one) -> assert(order(kept)) ; assert(order(broken)) ).',
              ':- X is 2 + 3, assert(sum(X)).',
              'answer(A-B-C) :- seen(A), order(B), sum(C).' ]),
    ran(F, '(answer(A), write(A))', G),
    check('a directive RUNS', G, 'one-kept-5').
    %% THE ORDER IS THE FILE'S. `order(kept)' above is only kept if the second
    %% directive could see what the first one asserted -- which is the whole
    %% difference between running a directive where it stands and collecting
    %% them all up for later.

does_not_prove(D) :-
    section('a directive that does not prove'),
    atom_concat(D, '/bad.pl', F),
    fixture(F, ['p(1).', ':- nosuch_goal.', ':- fail.', 'q(2).']),
    ran(F, '(q(X), write(X))', Out),
    sh_join(['ERROR: ', F, ':2:'], E2), has('an unknown goal is an ERROR', E2, Out),
    has('...in SWI''s words', 'Unknown procedure: nosuch_goal/0', Out),
    sh_join(['Warning: ', F, ':3:'], W3), has('a failing goal is a Warning', W3, Out),
    has('...and the Warning names the goal', 'Goal (directive) failed: fail', Out),
    sh_join(['--local run ', F, ' "(q(X), write(X))" 2>/dev/null'], Args),
    cocolog_run(Args, G, _),
    check('AND THE LOAD CARRIED ON', G, '2').
    %% The line numbers above are the point of the check: a message that says
    %% only "unknown procedure" in a file of two hundred clauses is a message
    %% you have to go looking for.

syntax_error(D) :-
    section('a syntax error still ends the consult'),
    %% THE ONE THING THAT IS STILL FATAL, and it has to be: after a syntax
    %% error the reader does not know where the next clause begins, so
    %% carrying on would mean guessing.
    atom_concat(D, '/syn.pl', F),
    fixture(F, ['p(1).', 'q(x :- .']),
    ran(F, true, _, Rc),
    check('a syntax error is still fatal', Rc, 1).

initialization(D) :-
    section('initialization/1: after the file, not where it stands'),
    atom_concat(D, '/init.pl', F1),
    fixture(F1, [':- initialization(greet).', 'greet :- format("greeted~n").']),
    ran(F1, true, G1),
    check('initialization/1 runs AFTER the load', G1, greeted),
    %% ...which is the reason it exists: `greet' is defined BELOW the
    %% directive that calls it, and a directive that ran where it stood
    %% could not.
    atom_concat(D, '/now.pl', F2),
    fixture(F2, [':- initialization(greet, now).', 'greet :- format("greeted~n").']),
    ran(F2, true, Out2),
    has('now: runs it where it stands', 'Unknown procedure: greet/0', Out2),
    atom_concat(D, '/order.pl', F3),
    fixture(F3, [ ':- initialization(format("second~n")).',
                  ':- initialization(format("third~n")).',
                  ':- format("first~n").' ]),
    sh_join(['--local run ', F3, ' true 2>&1 | tr ''\\n'' '' '' | sed ''s/ *$//'''], Args3),
    cocolog_run(Args3, G3, _),
    check('and they run in the order they were written', G3, 'first second third'),
    atom_concat(D, '/ifail.pl', F4),
    fixture(F4, [':- initialization(fail).', ':- initialization(format("still ran~n")).']),
    ran(F4, true, Out4),
    has('one that fails is a Warning', 'Initialization goal failed', Out4),
    has('...and the next one still runs', 'still ran', Out4),
    %% AND ONE THAT THROWS IS AN ERROR NAMING THE BALL, which is what a real
    %% program does with a real failure: `typedef' throwing a term of its own
    %% from inside `:- initialization(...)'. The ball is not an error/2, so
    %% the message is SWI's `Unknown message:' -- word for word, measured.
    %% THE BALL'S TEXT IS A QUOTED ATOM, deliberately: cocolog's
    %% `double_quotes' default is ISO's `codes' and SWI's is `string', so a
    %% "..." here would make this check about the flag rather than about the
    %% message. `:- set_prolog_flag(double_quotes, string).' is how a file
    %% that wants SWI's reading asks for it -- test/string.pl covers that.
    atom_concat(D, '/ithrow.pl', F5),
    fixture(F5, [':- initialization(build).', 'build :- throw(my_error(''not a type'', nosuch_t)).']),
    ran(F5, true, Out5),
    has('one that throws is an ERROR', 'Initialization goal raised exception:', Out5),
    has('...and the ball is named', 'Unknown message: my_error', Out5),
    sh_join([F5, ':1:'], At5), has('...at the line it was written', At5, Out5).

init_main(D) :-
    section('initialization(main, main) IS the program'),
    atom_concat(D, '/m0.pl', F0),
    fixture(F0, [':- initialization(main, main).', 'main :- format("main ran~n").']),
    ran(F0, 'format(\\"cli goal ran~n\\")', Out0, Rc0),
    check('main: runs the goal', Out0, 'main ran'),
    check('...and HALTS, so the CLI''s own goal does not run', Rc0, 0),
    atom_concat(D, '/m1.pl', F1),
    fixture(F1, [':- initialization(main, main).', 'main :- fail.']),
    ran(F1, true, Out1, Rc1),
    check('a main that fails exits 1', Rc1, 1),
    has('...and says so', 'main: false', Out1),
    atom_concat(D, '/m2.pl', F2),
    fixture(F2, [':- initialization(main, main).', 'main :- throw(my_ball).']),
    ran(F2, true, Out2, Rc2),
    check('a main that throws exits 2', Rc2, 2),
    has('...naming the ball', 'Unknown message: my_ball', Out2),
    atom_concat(D, '/when.pl', F3),
    fixture(F3, [':- initialization(true, restore_state).']),
    ran(F3, true, Out3),
    has('a when cocolog has not is refused BY NAME', restore_state, Out3).

exit_status(D) :-
    section('the exit status of a goal, and what is said about it'),
    %% `swipl -q -g GOAL -t halt': 0 proved, 1 failed -- SILENTLY, measured
    %% -- and 2 threw. cocolog answers the same three.
    atom_concat(D, '/g.pl', F),
    fixture(F, ['ok.', 'bad :- throw(my_ball).', 'typed :- atom_length(1, _).']),
    ran(F, ok, _, Rc1),
    check('a proved goal exits 0', Rc1, 0),
    ran(F, fail, Out2, Rc2),
    check('a failed goal exits 1', Rc2, 1),
    check('...and says nothing about it', Out2, ''),
    ran(F, bad, Out3, Rc3),
    check('a goal that throws exits 2', Rc3, 2),
    has('the message names the goal it was asked', '-g main:', Out3),
    has('...and the ball, in SWI''s words', 'Unknown message: my_ball', Out3),
    ran(F, nosuch, Out4),
    has('an unknown procedure reads as SWI''s', 'Unknown procedure: nosuch/0', Out4),
    ran(F, 'X is foo + 1', Out5),
    has('arithmetic on an atom reads as SWI''s', 'is not a function', Out5),
    ran(F, 'atom_length(X, _)', Out6),
    has('an unbound argument reads as SWI''s', 'not sufficiently instantiated', Out6).

reader_level(D) :-
    section('the reader-level directives still act on the reader'),
    atom_concat(D, '/rd.pl', F),
    fixture(F, [':- op(700, xfx, ===>).', 'rule(a ===> b).', ':- dynamic counter/1.', 'counter(0).']),
    ran(F, '(rule(R), write(R))', G1),
    check('op/3 still takes effect for the rest of the file', G1, 'a===>b'),
    ran(F, '(counter(N), write(N))', G2),
    check('dynamic/1 still declares', G2, '0').

%% ---- THE PROGRAM THIS CASE WAS WRITTEN FOR --------------------------------
%%
%% A Cicili TYPE DESCRIPTOR table, trimmed from the real one but not
%% simplified: `nil' as a value with `null/1' to test for it, a `type/N'
%% family whose arities overlap, `describe/7' choosing among them, a
%% `typedef/1' that dispatches through `apply/2' BECAUSE THE ARITY IS ONLY
%% KNOWN AT RUN TIME, and a ball of its own when the answer is no.
%%
%% Every part of it was impossible here a day ago: the directive at the
%% foot of the file was REFUSED and took the whole consult with it, and
%% `apply/2' did not exist. Both halves of the failure path are checked
%% too, because a table that only ever succeeds proves nothing about the
%% reporting.
typedef_lines(
    [ 'nil.                                   % Cicili''s NIL, as a value',
      'null(A) :- A == nil.',
      '',
      ':- dynamic type/1.',
      'type(void).',
      'type(char).',
      'type(int).',
      'type(''unsigned int'').',
      'type(''FILE'').',
      '',
      'multi_pointer(M) :-',
      '    atom(M), atom_chars(M, Ps), length(Ps, L), L =< 3,',
      '    forall(member(P, Ps), P == *).',
      '',
      'describe(C, T, M, P, V, DESC) :-',
      '    ( null(C) ; C == const ),',
      '    atom(T), type(T),',
      '    ( ( null(M), null(P) ) ; ( multi_pointer(M), ( null(P) ; P == const ) ) ),',
      '    atom(V),',
      '    DESC = [C, T, M, P, V], !.',
      '',
      'type(T, V, DESC)            :- describe(nil, T, nil, nil, V, DESC).',
      'type(T, M, V, DESC)         :- describe(nil, T, M, nil, V, DESC).',
      'type(const, T, M, V, DESC)  :- describe(const, T, M, nil, V, DESC).',
      '',
      'typedef(Es) :-',
      '    reverse(Es, Rs),',
      '    reverse([DESC | Rs], FEs),',
      '    (   apply(type, FEs), !',
      '    ;   throw(ccl_type_error(''type does not exist'', typedef(Es)))   ),',
      '    nth0(4, DESC, V),',
      '    (   type(V), !, throw(ccl_type_error(''name exists'', typedef(Es)))',
      '    ;   assert(type(V)), !   ).',
      '',
      'names(Ns) :- findall(T, type(T), Ns).',
      ':- initialization(( typedef([const, char, *, cstr_t]),',
      '                    typedef([int, *, intptr_t]),',
      '                    typedef([int, size_t]) )).' ]).

the_program(D) :-
    section('the program this case was written for'),
    atom_concat(D, '/typedef.pl', F),
    typedef_lines(Lines), fixture(F, Lines),
    ran(F, '(names(Ns), write(Ns))', G1),
    check('apply/2 dispatches on an arity known at run time', G1,
          '[void,char,int,unsigned int,FILE,cstr_t,intptr_t,size_t]'),
    %% A NAME ALREADY TAKEN, and a type that was never there: the two ways
    %% the table says no, both of them a ball of the program's own shape
    %% reported at the line the directive was written on.
    read_file_to_codes(F, Src),
    re_replace('typedef\\(\\[int, size_t\\]\\)', 'typedef([int, *, cstr_t])', Src, Taken),
    atom_concat(D, '/taken.pl', FT), write_file_from_codes(FT, Taken),
    ran(FT, true, Out2),
    has('a typedef of a name already taken throws', 'Unknown message: ccl_type_error(''name exists''', Out2),
    re_replace_atom('taken', 'typedef', Out2, Out2n),
    has('...reported at the directive''s line', 'typedef.pl', Out2n),
    re_replace('typedef\\(\\[int, size_t\\]\\)', 'typedef([nosuch_t, x_t])', Src, Unknown),
    atom_concat(D, '/unknown.pl', FU), write_file_from_codes(FU, Unknown),
    ran(FU, true, Out3),
    has('and a typedef of a type that is not there throws', 'Unknown message: ccl_type_error(''type does not exist''', Out3).
    %% THE TEXT IS A QUOTED ATOM AND NOT A "STRING", which is the thing to
    %% copy out of this fixture: `double_quotes' is ISO's `codes' here and
    %% SWI's is `string', so a ball carrying "text" reports as a list of
    %% numbers under cocolog and reads back as text under swipl. The same
    %% throw with an atom in it reads the same under both -- which is what
    %% the diff below is able to check.

under_swipl(D) :-
    section('the same files under swipl'),
    %% THE CLAIM IS COMPATIBILITY, so the check is a diff. Only the files
    %% whose output is Prolog's own and not cocolog's are run here: a
    %% message's exact wording differs (`[Thread main]', `user:' and the
    %% `catch/3:' context are SWI's and cocolog has no equivalent), so what
    %% is compared is what the PROGRAM printed and the exit status -- which
    %% is what a caller depends on.
    (   sh_exit('command -v swipl >/dev/null 2>&1', 0)
    ->  cocolog(C),
        forall(member(F-Goal, [run-'(answer(A), write(A))', init-true, order-true, m0-true,
                               typedef-'(names(Ns), write(Ns))']),
               ( sh_join([D, '/', F, '.pl'], Pl),
                 sh_join([C, ' --local run ', Pl, ' "', Goal, '" 2>/dev/null; printf ''rc=%s'' $?'], Ca),
                 shell(Ca, A, _),
                 sh_join(['swipl -q -g "', Goal, '" -t halt ', Pl, ' 2>/dev/null; printf ''rc=%s'' $?'], Cb),
                 shell(Cb, B, _),
                 sh_join(['swipl agrees over ', F, '.pl'], Label),
                 check(Label, A, B) )),
        %% AND THE MESSAGE ITSELF, for the one case where both systems have
        %% something to say. Two SWI-isms are normalised away and nothing
        %% else is: `[Thread main]' names the thread that raised it, which
        %% the cocolog CLI has no equivalent for, and swipl prints the path
        %% absolute where cocolog prints it as the caller wrote it. What is
        %% left is compared line for line -- including the four-space indent
        %% on a directive's second line, which cocolog copies, and its
        %% ABSENCE on an initialization's, where swipl's slot holds the
        %% thread tag.
        sh_join([D, '/ithrow.pl'], Ithrow),
        sh_join([C, ' --local run ', Ithrow, ' true 2>&1 >/dev/null'], Ca2), shell(Ca2, A2r, _), norm(D, A2r, A2),
        sh_join(['swipl -q -g true -t halt ', Ithrow, ' 2>&1 >/dev/null'], Cb2), shell(Cb2, B2r, _), norm(D, B2r, B2),
        check('swipl says the same words about a thrown init goal', A2, B2),
        %% ONLY THE LOCATION LINE FOR A DIRECTIVE, and the reason is worth
        %% writing down rather than normalising away: swipl prefixes the
        %% message with the CONTEXT of the throw -- `catch/3: Unknown
        %% procedure: ...' -- and cocolog has nothing to put there, because
        %% a builtin leaves error/2's second argument unbound (card row C3).
        %% The line that says WHERE is identical, and that is the half a
        %% reader navigates by.
        sh_join([D, '/bad.pl'], Bad),
        sh_join([C, ' --local run ', Bad, ' true 2>&1 >/dev/null'], Ca3), shell(Ca3, A3r, _), norm(D, A3r, A3n), first(A3n, A3),
        sh_join(['swipl -q -g true -t halt ', Bad, ' 2>&1 >/dev/null'], Cb3), shell(Cb3, B3r, _), norm(D, B3r, B3n), first(B3n, B3),
        check('...and locates a directive that threw the same way', A3, B3)
    ;   format("     (skipped: swipl is not here, so the diff did not run)~n", [])
    ).

%% the .sh's norm(): the scratch prefix and SWI's thread tag taken out
norm(D, Text, Out) :-
    atom_concat(D, '/', Prefix),
    re_replace_atom(Prefix, '', Text, T1),
    re_replace_atom('\\[Thread main\\] ', '', T1, Out).

%% head -1
first(Text, Line) :-
    atom_codes(Text, Cs),
    ( first_line(Cs, L) -> atom_codes(Line, L) ; Line = '' ).
