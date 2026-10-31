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
%% naming the ball in SWI's words, and then the Warning). None of the three
%% stops the load -- but for a ball that is no error(_, _), which ends it,
%% as swipl's does (3.1.0, a_ball/1).
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
    a_goal(D), does_not_prove(D), a_ball(D), loads_nothing(D), syntax_error(D), initialization(D),
    init_main(D), halted_load(D), in_a_module(D), exit_status(D), fresh_line(D), reader_level(D), the_program(D),
    taken_later(D),
    under_swipl(D),
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
    has('...and the Warning names the goal', 'Goal (directive) failed: user:fail', Out),
    sh_join(['--local run ', F, ' "(q(X), write(X))" 2>/dev/null'], Args),
    cocolog_run(Args, G, _),
    check('AND THE LOAD CARRIED ON', G, '2').
    %% The line numbers above are the point of the check: a message that says
    %% only "unknown procedure" in a file of two hundred clauses is a message
    %% you have to go looking for.

%% A DIRECTIVE'S BALL (3.1.0), as swipl's '$execute_directive_3' takes it.
%% AN ERROR is reported where it stands, and the directive is then counted
%% failed, its goal written as it was asked -- its bindings undone, as the
%% catch/3 swipl runs it under undoes them -- and the load goes on. ANY
%% OTHER BALL ENDS THE LOAD: consult/1 raises it to its caller, and `run'
%% and `-s' say `Prolog initialisation failed:' over its message and exit 1.
%% Through 3.0 every ball was an ERROR and the load went on, and a failed
%% directive was written with the bindings its goal had made.
a_ball(D) :-
    section('a directive''s ball: an error goes on, any other ends the load'),
    atom_concat(D, '/eball.pl', F),
    fixture(F, ['p(1).', ':- atom_length(_, _).', ':- throw(oh_no).', 'q(2).']),
    ran(F, '(q(X), write(X))', Out, Rc),
    sh_join(['ERROR: ', F, ':2:\nERROR:    atom_length/2: Arguments are not sufficiently instantiated\n'], E2),
    has('an error is reported where it stands', E2, Out),
    sh_join(['Warning: ', F, ':2:\nWarning:    Goal (directive) failed: user:atom_length(_G'], W2),
    has('...and the directive failed, its goal written as it was asked', W2, Out),
    has('any other ball ends the load', 'ERROR: Prolog initialisation failed:\nERROR: Unknown message: oh_no', Out),
    check('...and the run exits 1, its goal never asked', Rc, 1),
    ( sub_atom(Out, _, _, _, 'q/1') -> Q = asked ; Q = not_asked ),
    check('...so nothing names q/1', Q, not_asked),
    sh_join(['--local -s ', F, ' 2>&1'], A2), cocolog_run(A2, Out2, Rc2),
    has('-s says the same', 'ERROR: Prolog initialisation failed:\nERROR: Unknown message: oh_no', Out2),
    check('...and exits 1', Rc2, 1),
    atom_concat(D, '/eload.pl', F3),
    atomic_list_concat([ 'go :- catch(consult(''', F, '''), B, true), write(B), nl, ',
                         '( catch(q(_), _, fail) -> write(read) ; write(not_read) ).' ], Go3),
    fixture(F3, [Go3]),
    sh_join(['--local run ', F3, ' go 2>/dev/null'], A3), cocolog_run(A3, Out3, _),
    check('consult/1 raises it to its caller, and the clause after was not read', Out3, 'oh_no\nnot_read'),
    atom_concat(D, '/efail.pl', F4),
    fixture(F4, [ 'mk(0, []) :- !.', 'mk(N, [N|T]) :- N1 is N - 1, mk(N1, T).',
                  ':- mk(3, L), L == [3, 2, 9].' ]),
    ran(F4, true, Out4),
    has('a failed directive is written as it was asked, too',
        'Goal (directive) failed: user:(mk(3,_G', Out4).

loads_nothing(D) :-
    section('a load directive that loads nothing says so'),
    %% IT USED TO SAY NOTHING. A library the path could not find made
    %% `:- use_module(...)' succeed in silence -- the tolerance for files
    %% borrowed from SWI -- so a program on a machine without raylib loaded
    %% cleanly and failed at its first drawing call. Now it is SWI's two
    %% lines, the ERROR and then the failed directive, and the load goes on.
    atom_concat(D, '/missing.pl', F),
    fixture(F, ['p(1).', ':- use_module(library(nosuch)).', ':- ensure_loaded(nosuch_file).', 'q(2).']),
    ran(F, '(q(X), write(X))', Out),
    sh_join(['ERROR: ', F, ':2:'], E2), has('a library that is not there is an ERROR', E2, Out),
    has('...in SWI''s words', 'source_sink `library(nosuch)'' does not exist', Out),
    sh_join(['Warning: ', F, ':2:'], W2), has('...and then the directive failed, as SWI says it', W2, Out),
    has('...naming the directive', 'Goal (directive) failed: user:use_module(library(nosuch))', Out),
    has('a file that is not there, the same', 'source_sink `nosuch_file'' does not exist', Out),
    sh_join(['--local run ', F, ' "(q(X), write(X))" 2>/dev/null'], Args),
    cocolog_run(Args, G, _),
    check('AND THE LOAD CARRIED ON', G, '2'),
    %% WHAT THE OLD TOLERANCE WAS FOR, KEPT BY NAME: SWI's names for what
    %% cocolog carries under another arrangement say nothing -- and two of
    %% the SWI files read at every start-up name library(error), so an
    %% empty stderr here is also a start-up that stayed quiet.
    atom_concat(D, '/carried.pl', F2),
    fixture(F2, [ ':- use_module(library(error)).', ':- use_module(library(dcg/basics)).',
                  ':- use_module(library(dcg/high_order)).', 'ok(yes).' ]),
    ran(F2, '(ok(X), write(X))', Out2),
    check('SWI''s names for what cocolog carries stay quiet', Out2, yes).

syntax_error(D) :-
    section('a syntax error skips its clause, says where and why, and the load goes on'),
    %% AS SWIPL'S (3.1.0): swipl reads a clause's text whole, up to its
    %% full stop, before it parses it, so a clause that will not parse is
    %% reported and passed over and the rest of the file is read. The
    %% reader takes up where swipl's raw read would (`coco_reader_resync'):
    %% past the full stop that ends the clause it failed in -- so `s :- t u'
    %% runs on to the `.' after `v(1)', and v/1 is never defined, in both.
    %% Through 3.0.4 the first syntax error ended the consult, and nothing
    %% under a typo loaded. under_swipl/1 holds the program's answer here
    %% to swipl's.
    atom_concat(D, '/syn.pl', F),
    fixture(F, [ 'p(1).', 'q(x :- .', 'p(2).', 'r(''a\\qb'').', 'p(3).',
                 's :- t u', 'v(1).', 'p(4).' ]),
    ran(F, '(findall(X, p(X), L), ( catch(v(1), _, fail) -> V = v ; V = no_v ), write(L-V))', Out, Rc),
    check('a syntax error no longer ends the load', Rc, 0),
    has('the clauses either side of each bad one are read', '[1,2,3,4]-no_v', Out),
    %% WHERE AND WHY, IN SWI'S SHAPE (1.11.9): the file, the line, the
    %% column from 0 of the token it failed at, and the reason -- where
    %% 1.11.8 said `syntax error at offset 14', a byte offset. Here the
    %% reader stops at the `.', where swipl's does: an argument is read to
    %% 1200 (3.2.0), so `x :-' is the start of one, and its right side is
    %% missing (through 3.1.0 it stopped at the `:-', no argument then
    %% holding it); under_swipl/1 holds the place to swipl's in files where
    %% the two stop at one token.
    atomic_list_concat(['ERROR: ', F, ':2:7: Syntax error: expected a term'], W1),
    has('run names the file, the line, the column and the reason', W1, Out),
    atomic_list_concat(['ERROR: ', F, ':6:7: Syntax error: '], W1b),
    has('and so each later one, where swipl places it', W1b, Out),
    atom_concat(D, '/synat.pl', At),
    fixture(At, ['p(1).', 'q(2) :- .']),
    ran(At, true, OutAt, _),
    atomic_list_concat(['ERROR: ', At, ':2:8: Syntax error: expected a term'], WAt),
    has('the token it failed at, counted from 0', WAt, OutAt),
    %% THE CLAUSE BEFORE A BAD FIRST TOKEN IS KEPT: the reader is one token
    %% ahead, and through 3.0.4 a token that would not read straight after a
    %% full stop took the clause it closed with it (`coco_read_clause')
    atom_concat(D, '/synnext.pl', Nx),
    fixture(Nx, ['p(1).', '''a\\qb''.', 'p(2).']),
    ran(Nx, '(findall(X, p(X), L), write(L))', OutNx, _),
    has('the clause before a token that will not read is kept', '[1,2]', OutNx),
    %% A MODULE'S, named by ITS file, and its load goes on as a file's:
    %% through 1.11.8 `-s' said only that the top file's `clauses would not
    %% consult', and through 3.0.4 the module's load failed, its use_module
    %% with it
    atom_concat(D, '/synmod.pl', Mod),
    fixture(Mod, ['m(1).', 'm(2) :- .', 'm(3).']),
    atom_concat(D, '/syntop.pl', Top),
    %% named without its `.pl', as `use_module(bad)' is written: the module
    %% is registered under the spec, and the message names the file read
    atom_concat(D, '/synmod', ModSpec),
    atomic_list_concat([':- use_module(''', ModSpec, ''').'], UseMod),
    fixture(Top, [UseMod, 'main :- findall(X, m(X), L), write(L), nl.']),
    sh_join(['--local -s ', Top, ' 2>&1'], A2), cocolog_run(A2, Out2, Rc2),
    atomic_list_concat(['ERROR: ', Mod, ':2:8: Syntax error: expected a term'], W2),
    has('-s names the module''s file and where', W2, Out2),
    has('and the module''s other clauses load', '[1,3]', Out2),
    check('and main runs', Rc2, 0),
    %% THE COLUMN IS SWI'S, in bytes: two letters of two bytes before the
    %% token move it four, as swipl's moves (`z(''aa'', b c).'' fails at 10)
    atom_concat(D, '/synutf.pl', U),
    fixture(U, ['x(1).', 'z(''áá'', b c).']),
    ran(U, true, Out4, _),
    atomic_list_concat(['ERROR: ', U, ':2:12: Syntax error: '], W4),
    has('a column counts bytes, as swipl''s does', W4, Out4),
    %% THE CONSULT'S OTHER STOPS ARE REPORTS NOW TOO, each in swipl's words
    %% (under_swipl/1 holds the three files' stderr to swipl's, word for
    %% word): an endif, else or elif with no if open is passed over; an if
    %% the file never closes is named at the end; and a term that is no
    %% clause -- a number, or a body with one where a goal stands -- is
    %% refused and the load goes on. Through 3.0.4 the first two ended the
    %% consult, and the third ended it as `not a clause' or went in.
    atom_concat(D, '/synendif.pl', E),
    fixture(E, ['p(1).', ':- endif.', 'p(2).', ':- else.', 'p(3).']),
    ran(E, '(findall(X, p(X), L), write(L))', Out5, Rc5),
    atomic_list_concat(['ERROR: ', E, ':2:\nERROR:    :- endif without :- if'], W5),
    has('a stray endif names its line', W5, Out5),
    has('and the clauses after it are read', '[1,2,3]', Out5),
    check('and the goal runs', Rc5, 0),
    atom_concat(D, '/synnoend.pl', Ne),
    fixture(Ne, ['p(1).', ':- if(true).', 'p(2).']),
    ran(Ne, '(findall(X, p(X), L), write(L))', Out6, _),
    atomic_list_concat(['ERROR: ', Ne, ':4:\nERROR:    Unterminated conditional compilation from ',
                        Ne, ':2'], W6),
    has('an if never closed is named at the end, and where it opened', W6, Out6),
    has('and what it read is kept', '[1,2]', Out6),
    atom_concat(D, '/synnotcl.pl', Nc),
    fixture(Nc, ['p(1).', '3.', '1.5.', 'foo :- 3.', 'bar :- (a, 1).', '[].', 'p(2).']),
    atom_concat('(findall(X, p(X), L), ( catch(foo, _, fail) -> B = foo ; B = no_foo ), ',
                '( catch(clause([], _), _, fail) -> N = nil ; N = no_nil ), write(L-B-N))', G7),
    ran(Nc, G7, Out7, _),
    atomic_list_concat(['ERROR: ', Nc, ':2:\nERROR:    Type error: `callable'' expected, found `3'' (an integer)'], W7),
    has('a number is no clause', W7, Out7),
    atomic_list_concat(['ERROR: ', Nc, ':5:\nERROR:    Type error: `callable'' expected, found `a,1'' (a compound)'], W7b),
    has('nor a body with a number where a goal stands', W7b, Out7),
    has('and neither goes in, the clauses either side do', '[1,2]-no_foo', Out7),
    %% `[].' is passed over in silence, as swipl's: no fact `[]' stands
    has('and [] is passed over, no clause of it kept', 'no_foo-no_nil', Out7),
    %% A VARIABLE WHERE A CLAUSE STANDS is reported in swipl's words and
    %% passed over as the others are; swipl's load stops there instead
    %% (`Prolog initialisation failed', COMPAT.md)
    atom_concat(D, '/synvar.pl', Nv),
    fixture(Nv, ['p(1).', 'X.', 'p(2).']),
    ran(Nv, '(findall(X, p(X), L), write(L))', Out8, _),
    atomic_list_concat(['ERROR: ', Nv, ':2:\nERROR:    Arguments are not sufficiently instantiated'], W8),
    has('a variable is no clause either', W8, Out8),
    has('and the load goes on past it', '[1,2]', Out8).

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
    sh_join([F5, ':1:'], At5), has('...at the line it was written', At5, Out5),
    %% NOW, WHERE IT STANDS (3.1.0, swipl's): the place twice, once as the
    %% message's location and once inside it, and the load goes on
    %% whatever the ball -- its goal is run as an initialization's is
    atom_concat(D, '/now2.pl', F6),
    fixture(F6, [ ':- initialization(fail, now).', ':- initialization(throw(oh), now).',
                  ':- initialization(atom_length(_, _), now).', 'r(1).' ]),
    ran(F6, '(r(X), write(X))', Out6),
    sh_join(['Warning: ', F6, ':1:\nWarning:    ', F6, ':1: Initialization goal failed\n'], W6),
    has('now: one that fails says where twice, as swipl''s does', W6, Out6),
    sh_join(['ERROR: ', F6, ':2:\nERROR:    ', F6, ':2: Initialization goal raised exception:\nERROR:    Unknown message: oh\n'], E6),
    has('...one that raises, the message after', E6, Out6),
    ( atom_concat(_, '\n1', Out6) -> T6 = yes ; T6 = Out6 ),
    check('...and the load goes on, whatever the ball', T6, yes),
    %% A BUILTIN AS THE GOAL NAMES ITSELF (3.1.0), in a file of nothing else:
    %% the load winds its heap back clause by clause, so the goal would be
    %% built at heap cell 0 -- the goal in flight `kcall' 0, which reads as
    %% none -- and its error named no predicate
    atom_concat(D, '/ibuiltin.pl', F7),
    fixture(F7, [':- initialization(atom_length(_, _)).']),
    ran(F7, true, Out7),
    has('a builtin goal that raises names itself, on an empty heap too',
        'atom_length/2: Arguments are not sufficiently instantiated', Out7).

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
    sh_join([F1, ':1: user:main: false'], W1), has('...each on one line, as swipl''s', W1, Out1),
    %% UNDER `verbose' SILENT, swipl -q's (3.1.0): a main that fails says
    %% nothing and exits 1, as swipl's does
    atom_concat(D, '/m1v.pl', F4),
    fixture(F4, [':- set_prolog_flag(verbose, silent).', ':- initialization(main, main).', 'main :- fail.']),
    ran(F4, true, Out4, Rc4),
    check('under verbose silent a main that fails says nothing, and exits 1', Out4-Rc4, ''-1),
    atom_concat(D, '/when.pl', F3),
    fixture(F3, [':- initialization(true, restore_state).']),
    ran(F3, true, Out3),
    has('a when cocolog has not is refused BY NAME', restore_state, Out3).

%% ---- a halt during the load, under a store -------------------------------
%%
%% A HALT IS AN ANSWER, AND WHAT THE RUN WROTE IS KEPT, wherever it comes.
%% After the CLI's goal that has held since 1.2.4. During the LOAD -- a
%% `:- halt.', a halt in an initialization goal, `initialization(G, main)'
%% done -- the process exited from inside the consult, before the commit,
%% and kept nothing: exit 0, an empty stderr, and a second process found no
%% seen/1 at all, under --embed and over the wire alike. The claim is what a
%% SECOND process reads, so every check is two: the run, and a read-back
%% that consulted nothing. A main that threw is the one rolled back, as a
%% goal that threw is after the CLI's own.
%%
%% `-s' ADDS ONE THING: the file is a module there, and a module's load is
%% muted -- its directives write nothing through. The `main' goal is not
%% part of the load but the program, standing where `-s' would have called
%% main, so it writes through like that main does.
halted_load(D) :-
    section('a halt during the load keeps what the run wrote, under a store'),
    atom_concat(D, '/probe.kb', P),
    sh_join(['--embed ', P, ' query true >/dev/null 2>&1'], A0),
    (   cocolog_run(A0, _, 0)
    ->  halt_embed(D, h1, [':- dynamic(seen/1).', ':- assertz(seen(directive)).', ':- halt.'], run, Rc1, S1),
        check('a :- halt. directive keeps what the load wrote before it, and exits 0', Rc1-S1, 0-answer([directive])),
        halt_embed(D, h2, [':- dynamic(seen/1).', ':- assertz(seen(three)).', ':- halt(3).', 'seen(never).'], run, Rc2, S2),
        check(':- halt(3). exits 3, keeps the write, and stops the load where it stands', Rc2-S2, 3-answer([three])),
        halt_embed(D, h3, [':- dynamic(seen/1).', ':- initialization(main, main).', 'main :- assertz(seen(main)).'], run, Rc3, S3),
        check('initialization(main, main) under run: main''s write is kept', Rc3-S3, 0-answer([main])),
        halt_embed(D, h4, [':- dynamic(seen/1).', ':- initialization(main, main).', 'main :- assertz(seen(main)).'], s, Rc4, S4),
        check('...and under -s, where the file is a module whose load is muted', Rc4-S4, 0-answer([main])),
        halt_embed(D, h5, [':- dynamic(seen/1).', ':- initialization(main).', 'main :- assertz(seen(after_load)), halt.'], run, Rc5, S5),
        check('initialization(main) with a halt in main keeps its write', Rc5-S5, 0-answer([after_load])),
        halt_embed(D, h6, [':- dynamic(seen/1).', ':- initialization(main, main).', 'main :- assertz(seen(four)), halt(4).'], s, Rc6, S6),
        check('halt(4) inside the main goal exits 4 and keeps the write', Rc6-S6, 4-answer([four])),
        halt_embed(D, h7, [':- dynamic(seen/1).', ':- initialization(main, main).', 'main :- assertz(seen(failed)), fail.'], run, Rc7, S7),
        check('a main that fails exits 1 and is committed, as a failed goal is', Rc7-S7, 1-answer([failed])),
        halt_embed(D, h8, [':- dynamic(seen/1).', ':- initialization(main, main).', 'main :- assertz(seen(thrown)), throw(my_ball).'], run, Rc8, S8),
        check('a main that throws exits 2 and is rolled back, as a goal that threw is', Rc8-S8, 2-answer([]))
    ;   format("     (skipped: this build has no embedded store -- the --embed half not run)~n")
    ),
    halted_load_wire(D).

%% the same three kinds over the wire, when a server answers
halted_load_wire(D) :-
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    sh_join(['--host ', Host, ' --tcp ', Port, ' --timeout 60 --kb halt_case'], W),
    sh_join(['--host ', Host, ' --tcp ', Port, ' --timeout 10 --kb halt_case list >/dev/null 2>&1'], A0),
    (   cocolog_run(A0, _, 0)
    ->  halt_wire(D, W, w1, [':- dynamic(seen/1).', ':- assertz(seen(directive)).', ':- halt.'], run, Rc1, S1),
        check('wire: a :- halt. directive keeps what the load wrote', Rc1-S1, 0-answer([directive])),
        halt_wire(D, W, w2, [':- dynamic(seen/1).', ':- initialization(main, main).', 'main :- assertz(seen(main)).'], s, Rc2, S2),
        check('wire: initialization(main, main) under -s keeps main''s write', Rc2-S2, 0-answer([main])),
        halt_wire(D, W, w3, [':- dynamic(seen/1).', ':- initialization(main, main).', 'main :- assertz(seen(thrown)), throw(my_ball).'], run, Rc3, S3),
        check('wire: a main that throws is rolled back', Rc3-S3, 2-answer([]))
    ;   format("     (skipped: no Zigurat server at ~w:~w -- the wire half not run)~n", [Host, Port])
    ).

%% one run of a file under a fresh embedded store, then what a second
%% process reads back from that store: the run's exit status, and seen/1's
%% solutions -- [] when there are none, or no seen/1 at all
halt_embed(D, Name, Lines, How, Rc, Seen) :-
    atomic_list_concat([D, '/', Name, '.pl'], F), fixture(F, Lines),
    atomic_list_concat([D, '/', Name, '.kb'], S),
    sh_join(['--embed ', S], W),
    halt_go(W, F, How, Rc),
    halt_seen(W, Seen).

%% the same against the server's halt_case base, emptied before and after
halt_wire(D, W, Name, Lines, How, Rc, Seen) :-
    atomic_list_concat([D, '/', Name, '.pl'], F), fixture(F, Lines),
    sh_join([W, ' forget >/dev/null 2>&1'], Fg),
    cocolog_run(Fg, _, _),
    halt_go(W, F, How, Rc),
    halt_seen(W, Seen),
    cocolog_run(Fg, _, _).

halt_go(W, F, s, Rc) :- !,
    sh_join([W, ' -s ', F, ' >/dev/null 2>&1'], A), cocolog_run(A, _, Rc).
halt_go(W, F, run, Rc) :-
    sh_join([W, ' run ', F, ' true >/dev/null 2>&1'], A), cocolog_run(A, _, Rc).

halt_seen(W, Seen) :-
    sh_join([W, ' query "catch(findall(X, seen(X), L), _, L = []), write(answer(L)), nl"'], A),
    cocolog_answer(A, Seen).

in_a_module(D) :-
    section('a goal directive in a MODULE: the -s file, and a library .pl'),
    %% UNTIL 1.6.16 EVERY ONE OF THESE WAS A SEGFAULT, `:- true.' included.
    %% `-s FILE' is `use_module(FILE)', so the file is a MODULE, and a module
    %% was counted as loaded only AFTER its consult: the engine a goal
    %% directive runs in found it unloaded and consulted it again, whose
    %% directive opened another engine, until the C stack ran out. Every
    %% section above runs its file with `run', which consults the file
    %% itself, and so none of them could see it -- while a library .pl with
    %% a goal directive died under `run' as well, loaded by a goal or by a
    %% directive. `coco_module_load' claims a module before its consult now.
    atom_concat(D, '/s1.pl', F1),
    fixture(F1, [ ':- true.', ':- assert(seen(one)).', ':- fail.', ':- nosuch_goal.',
                  'main :- seen(X), format("~w~n", [X]).' ]),
    sh_join(['--local -s ', F1, ' 2>/dev/null'], A1), cocolog_run(A1, G1, Rc1),
    check('-s: a file with goal directives runs its main', G1, one),
    check('...and exits 0', Rc1, 0),
    sh_join(['--local -s ', F1, ' 2>&1'], A1e), cocolog_run(A1e, Out1, _),
    sh_join(['Warning: ', F1, ':3:'], W3), has('...a failing one is a Warning, as under run', W3, Out1),
    sh_join(['ERROR: ', F1, ':4:'], E4), has('...an unknown one an ERROR', E4, Out1),
    atom_concat(D, '/s2.pl', F2),
    fixture(F2, [':- initialization(main, main).', 'main :- format("main ran~n").']),
    sh_join(['--local -s ', F2, ' 2>&1'], A2), cocolog_run(A2, G2, Rc2),
    check('-s: initialization(main, main) runs main ONCE and halts', G2-Rc2, 'main ran'-0),
    atom_concat(D, '/lib1.pl', L1),
    fixture(L1, [':- assert(lib_seen(yes)).', 'lib_p(1).']),
    atom_concat(D, '/g3.pl', F3),
    format(atom(M3), 'main :- use_module(''~w''), lib_p(X), findall(Y, lib_seen(Y), Ys), format("~~w ~~w~~n", [X, Ys]).', [L1]),
    fixture(F3, [M3]),
    ran(F3, main, G3),
    check('a library .pl with a goal directive, loaded by a GOAL: its directive ran once', G3, '1 [yes]'),
    atom_concat(D, '/g4.pl', F4),
    format(atom(U4), ':- use_module(''~w'').', [L1]),
    fixture(F4, [U4, 'main :- lib_p(X), findall(Y, lib_seen(Y), Ys), format("~w ~w~n", [X, Ys]).']),
    ran(F4, main, G4),
    check('...and loaded by a DIRECTIVE', G4, '1 [yes]'),
    %% A MODULE REGISTERED ABOVE THE DIRECTIVE IS LOADED BY THE DIRECTIVE'S OWN
    %% ENGINE, and must not be consulted a second time when the -s file's
    %% load goes on: a walk on a local index would, and every answer the
    %% library gives would come back twice.
    atom_concat(D, '/lib2.pl', L2),
    fixture(L2, ['lib2_p(1).', 'lib2_p(2).']),
    atom_concat(D, '/s5.pl', F5),
    format(atom(U5), ':- use_module(''~w'').', [L2]),
    fixture(F5, [ U5, ':- findall(X, lib2_p(X), L), assert(during(L)).',
                  'main :- during(A), findall(X, lib2_p(X), B), format("~w ~w~n", [A, B]).' ]),
    sh_join(['--local -s ', F5, ' 2>&1'], A5), cocolog_run(A5, G5, _),
    check('-s: a library the directive''s engine loaded is loaded ONCE', G5, '[1,2] [1,2]').

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
    has('the message names the goal it was asked', '-g bad:', Out3),
    has('...and the ball, in SWI''s words', 'Unknown message: my_ball', Out3),
    ran(F, nosuch, Out4),
    has('an unknown procedure reads as SWI''s', 'Unknown procedure: nosuch/0', Out4),
    ran(F, 'X is foo + 1', Out5),
    has('arithmetic on an atom reads as SWI''s', 'is not a function', Out5),
    ran(F, 'atom_length(X, _)', Out6),
    has('an unbound argument reads as SWI''s', 'not sufficiently instantiated', Out6).

%% A REPORT BEGINS A LINE OF ITS OWN (2.16.0), as swipl's do, being
%% print_message/2's: after half a line on either stream -- user_output and
%% user_error share one column -- a newline first, and after a whole line
%% none. Through 2.15.2 `half' and the report's tag shared a line. Measured
%% against swipl 9.0.4; its words around them differ (the path, `user:',
%% the backtrace), which the swipl diff below keeps apart.
fresh_line(D) :-
    section('a report begins a line of its own'),
    atom_concat(D, '/fl.pl', F),
    fixture(F, [ ':- format(user_error, ''err_half'', []), fail.',
                 ':- write(out_half), fail.',
                 ':- format(user_error, ''raise_half'', []), atom_length(_, _).',
                 ':- format(user_error, ''whole~n'', []), fail.',
                 ':- initialization((format(user_error, ''init_half'', []), fail)).',
                 'main :- write(goal_half), atom_length(_, _).' ]),
    ran(F, main, Out),
    atomic_list_concat(['err_half\nWarning: ', F, ':1:'], W1),
    has('a failed directive''s Warning, after half a line on user_error', W1, Out),
    atomic_list_concat(['out_half\nWarning: ', F, ':2:'], W2),
    has('...and after half a line on user_output: the column is shared', W2, Out),
    atomic_list_concat(['raise_half\nERROR: ', F, ':3:'], W3),
    has('a raising directive''s ERROR', W3, Out),
    atomic_list_concat(['whole\nWarning: ', F, ':4:'], W4),
    has('after a whole line, the report straight after it', W4, Out),
    atomic_list_concat(['whole\n\nWarning: ', F, ':4:'], W4b),
    (   sub_atom(Out, _, _, _, W4b) -> Blank = yes ; Blank = no ),
    check('...and no blank line between them', Blank, no),
    atomic_list_concat(['init_half\nWarning: ', F, ':5: Initialization goal failed'], W5),
    has('an initialization goal''s Warning', W5, Out),
    has('the goal''s own ERROR, after half a line on user_output', 'goal_half\nERROR: -g main:', Out),
    atom_concat(D, '/fls.pl', S),
    fixture(S, [':- format(user_error, ''syn_half'', []).', 'p(1 :- .']),
    ran(S, true, OutS),
    atomic_list_concat(['syn_half\nERROR: ', S, ':2:'], W6),
    has('a syntax error''s ERROR, after half a line on user_error', W6, OutS).

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

%% A CLAUSE RUN BEFORE THE PROGRAM TOOK ITS NAME OVER IS COMPILED AGAIN
%% (3.1.0, `coco_code_forget_all'): the directives run early/1 and early2/0
%% while is/2 and not/1 are the engine's, so their bodies are compiled with
%% them in place -- a guard, a construct unit -- and the clauses that take
%% the names over come after; from then on the program's answer every
%% call, the clauses run before among them. And a builtin called before
%% its name is taken is the program's after: string_upper/2, a core one
%% whose functor kept its row, and msort/2, whose functor remembered the
%% module that owns it (`coco_pred_take_over'). swipl links a call at its
%% first run and keeps it (late(3)), and refuses not/1's, msort/2's and
%% string_upper/2's clauses after a use: a stated difference (COMPAT.md).
%% Kept, the stale code answers 3, the builtin's not/1, msort/2 and
%% string_upper/2.
taken_later(D) :-
    section('a clause run before the program took its name over is compiled again'),
    atom_concat(D, '/later.pl', F),
    fixture(F, [ 'early(Y) :- Y is 1 + 2.',
                 'early2 :- atom_length(x, _), not(fail).',
                 ':- early(Y), assert(seen(early(Y))).',
                 ':- ( early2 -> assert(seen(early2_ran)) ; true ).',
                 ':- msort([b, a], M), assert(seen(M)).',
                 ':- string_upper(abc, U), assert(seen(U)).',
                 ':- redefine_system_predicate(is(_, _)).',
                 'is(my_is, _).',
                 'not(_) :- assert(seen(my_not)).',
                 'msort(_, mine).',
                 'string_upper(_, mine).' ]),
    ran(F, '(early(Y), ( early2 -> E = e2_ran ; E = e2_no ), msort([b, a], M), string_upper(abc, S2), findall(S, seen(S), L), write(L-late(Y)-E-M-S2))', Got),
    %% string_upper/2 is a CORE builtin, whose functor kept its row when
    %% the directive called it (`bix'); msort/2 is library(lists)'s, asked
    %% through the module walk, which passes a taken name by
    check('the program''s is/2, not/1, msort/2 and string_upper/2 answer the clauses run before them',
          Got, '[early(3),early2_ran,[a,b],ABC,my_not]-late(my_is)-e2_ran-mine-mine').

under_swipl(D) :-
    section('the same files under swipl'),
    %% THE CLAIM IS COMPATIBILITY, so the check is a diff: first what the
    %% PROGRAM printed and the exit status, which is what a caller depends
    %% on, and then what each says about its load, to the letter.
    (   sh_exit('command -v swipl >/dev/null 2>&1', 0)
    ->  cocolog(C),
        forall(member(F-Goal, [run-'(answer(A), write(A))', init-true, order-true, m0-true,
                               typedef-'(names(Ns), write(Ns))',
                               syn-'(findall(X, p(X), L), ( catch(v(1), _, fail) -> V = v ; V = no_v ), write(L-V))',
                               synnext-'(findall(X, p(X), L), write(L))']),
               ( sh_join([D, '/', F, '.pl'], Pl),
                 sh_join([C, ' --local run ', Pl, ' "', Goal, '" 2>/dev/null; printf ''rc=%s'' $?'], Ca),
                 shell(Ca, A, _),
                 sh_join(['swipl -q -g "', Goal, '" -t halt ', Pl, ' 2>/dev/null; printf ''rc=%s'' $?'], Cb),
                 shell(Cb, B, _),
                 sh_join(['swipl agrees over ', F, '.pl'], Label),
                 check(Label, A, B) )),
        %% AND WHAT EACH SAYS, word for word (3.1.0): the whole of stderr
        %% and the exit status, with three things normalised away and
        %% nothing else -- the scratch directory (swipl prints a path
        %% absolute where cocolog prints it as the caller wrote it), SWI's
        %% `[Thread main]' tag, and a variable's name, `_G12' against
        %% `_2132', each a heap position. cocolog's backtrace is its own
        %% (1.10.17), which swipl writes only with library(prolog_stack)
        %% loaded (test/backtrace.pl), so cocolog runs with --no-backtrace.
        %% Through 3.0 only a directive's location line could be compared:
        %% swipl's `catch/3:' context and `user:' had no counterpart here,
        %% and an error was no failed directive. m1 and m1v run swipl
        %% without -q, whose `silent' is m1v's own flag.
        forall(member(W-Q, [ bad-'-q ', missing-'-q ', ithrow-'-q ', ifail-'-q ', now2-'-q ',
                             eball-'-q ', efail-'-q ', m1-'', m2-'-q ', m1v-'',
                             synendif-'-q ', synnoend-'-q ', synnotcl-'-q ' ]),
               ( sh_join([D, '/', W, '.pl'], WPl),
                 sh_join([C, ' --no-backtrace --local run ', WPl, ' true 2>&1 >/dev/null; printf ''rc=%s'' $?'], Ca6),
                 shell(Ca6, A6r, _), norm(D, A6r, A6n), vnorm(A6n, A6),
                 sh_join(['swipl ', Q, '-g true -t halt ', WPl, ' 2>&1 >/dev/null; printf ''rc=%s'' $?'], Cb6),
                 shell(Cb6, B6r, _), norm(D, B6r, B6n), vnorm(B6n, B6),
                 sh_join(['swipl says the same, word for word, of ', W, '.pl'], L6),
                 check(L6, A6, B6) )),
        %% A SYNTAX ERROR'S PLACE (1.11.9): the file, the line and the column
        %% before `Syntax error: '. The reasons are each system's own words
        %% (`expected a term' where swipl says `Unbalanced operator'). A bad
        %% escape is placed at its letter, as swipl's (3.1.0, synnext:
        %% `'a\qb'.' at 2:3; through 3.0.4 at the quote, 2:0)
        forall(member(S, [synat, synutf, synnext]),
               ( sh_join([D, '/', S, '.pl'], SPl),
                 sh_join([C, ' --local run ', SPl, ' true 2>&1 >/dev/null'], Ca5), shell(Ca5, A5r, _),
                 norm(D, A5r, A5n), first(A5n, A5l), syntax_place(A5l, A5),
                 sh_join(['LANG=C.UTF-8 swipl -q -g true -t halt ', SPl, ' 2>&1 >/dev/null'], Cb5),
                 shell(Cb5, B5r, _), norm(D, B5r, B5n), first(B5n, B5l), syntax_place(B5l, B5),
                 sh_join(['...and places a syntax error where swipl does in ', S, '.pl'], L5),
                 check(L5, A5, B5) ))
    ;   format("     (skipped: swipl is not here, so the diff did not run)~n", [])
    ).

%% `ERROR: FILE:LINE:COL: ' -- a syntax error's line up to its reason
syntax_place(Line, Place) :-
    (   sub_atom(Line, B, _, _, 'Syntax error: ')
    ->  sub_atom(Line, 0, B, _, Place)
    ;   Place = Line
    ).

%% a variable's name taken out: `_G12' and swipl's `_2132' are both `_'
vnorm(Text, Out) :-
    re_replace_atom('_G?[0-9]+', '_', Text, Out).

%% the .sh's norm(): the scratch prefix and SWI's thread tag taken out
norm(D, Text, Out) :-
    atom_concat(D, '/', Prefix),
    re_replace_atom(Prefix, '', Text, T1),
    re_replace_atom('\\[Thread main\\] ', '', T1, Out).

%% head -1
first(Text, Line) :-
    atom_codes(Text, Cs),
    ( first_line(Cs, L) -> atom_codes(Line, L) ; Line = '' ).

%% head -2
first_two(Text, Two) :-
    split_string(Text, '\n', '', Ls),
    ( Ls = [L1, L2|_] -> atomic_list_concat([L1, L2], '\n', Two) ; Two = Text ).
