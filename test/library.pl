%% use_module, like SWI's: libraries load at run time.
%%
%% WHAT IT IS CHECKING, and why each part is there:
%%
%%   A REGISTERED MODULE ANSWERS AT ONCE. `use_module(library(lists))'
%%   finds the linked-in module and succeeds without touching the disk.
%%
%%   A .pl LIBRARY LOADS FROM THE LIBRARY PATH -- as a goal and as a
%%   `:- use_module' directive in a consulted file -- and loading twice
%%   answers everything ONCE: the file registers as a clauses-only
%%   module, and a module's clauses never load twice into one store.
%%
%%   A .so LIBRARY IS THE WHOLE SEAM, REACHED LATER: a module written in
%%   Cicili against lib/sdk.cicili, compiled to a shared object, found on
%%   $COCOLOG_LIBRARY, dlopen'd, and both its halves answer -- the C
%%   predicate and the Coco clause on top of it. Skipped without sbcl and
%%   a Cicili checkout, because "no transpiler here" and "the loader is
%%   wrong" are different findings.
%%
%%   A LIBRARY IS PROCESS-LOCAL, exactly as in SWI: its clauses are muted
%%   and never written through, so a second process on the same knowledge
%%   base does not see them -- proven across processes, because that is
%%   the claim. Skipped without a server.
%%
%%   A MISSING LIBRARY THROWS A CATCHABLE ERROR as a goal, and as a
%%   directive warns and continues, so a borrowed file still reads.
%%
%%   THE VENDORED SWI LIBRARIES ARE ALWAYS PRESENT, and reachable from
%%   anywhere -- checked from a child with NO library path, run from
%%   /tmp, because from this checkout `./library' would find them by
%%   accident.
%%
%%     cocolog -s test/library.pl        from the checkout root
%%
%% ONE PROCESS FOR THE LOADER'S OWN CHECKS; the children that remain are
%% the ones whose claim is about another process -- a second process on
%% the wire, a process with no library path at all, a consult whose
%% directive warns on stderr.

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    registered, from_the_path(D), keeps_builtins(D), lends_ops(D), errors(D), includes(D), shared_object(D), across_processes(D),
    always_present, still_answers,
    shl(['rm -rf ', D]),
    checks_done.

registered :-
    section('a registered module'),
    written(( use_module(library(lists)), msort([b,a], [a,b]) ), ok, G1),
    check('a linked-in library answers at once', G1, ok).

%% the scratch directory goes on the library path -- read at every lookup,
%% so a setenv in this process is enough
from_the_path(D) :-
    section('a .pl library on the path'),
    atom_concat(D, '/plib', PLib), make_directory(PLib),
    atom_concat(PLib, '/greet.pl', Greet),
    fixture(Greet, ['greeting(hello_from_pl).']),
    ( getenv('COCOLOG_LIBRARY', Old) -> sh_join([PLib, ':', Old], New) ; New = PLib ),
    setenv('COCOLOG_LIBRARY', New),
    written(( use_module(library(greet)), greeting(G1v) ), G1v, G1),
    check('a .pl library loads as a goal', G1, hello_from_pl),
    written(( use_module(library(greet)), use_module(library(greet)),
              findall(G2v, greeting(G2v), L2), length(L2, N2) ), N2, G2),
    check('and loading twice answers once', G2, '1'),
    atom_concat(D, '/uses.pl', Uses),
    fixture(Uses, [':- use_module(library(greet)).', 'both(G) :- greeting(G).']),
    sh_join(['run ', Uses, ' "both(G), write(answer(G)), nl"'], Args3),
    cocolog_answer(Args3, G3),
    check('the :- use_module directive loads it too', G3, answer(hello_from_pl)).

%% A LIBRARY KEEPS THE BUILTIN A PROGRAM FILE TAKES OVER (3.1.0): the
%% program's garbage_collect/0, msort/2 and not/1 answer the program's own
%% goals, and a library's clause calling the name still has the engine's --
%% as a swipl library module calls system's -- whether the library was
%% loaded before the program's clauses (its bodies are rewritten then) or
%% after them (as it loads). A library on the path is a library here; swipl
%% takes a directory a user added as the user's (COMPAT.md).
keeps_builtins(D) :-
    section('a library keeps the builtin a program file takes over'),
    atom_concat(D, '/plib/keep.pl', Keep),
    fixture(Keep, [ 'keep_gc(done) :- garbage_collect.',
                    'keep_sort(S) :- msort([b, a], S).',
                    'keep_not(yes) :- not(fail).' ]),
    Own = [ 'garbage_collect :- fail.', 'msort(_, mine).', 'not(_) :- fail.',
            'go :- keep_gc(A), keep_sort(B), keep_not(C),',
            '      ( garbage_collect -> E = gc_yes ; E = gc_no ), msort([b, a], F),',
            '      write(answer(A, B, C, E, F)), nl.' ],
    atom_concat(D, '/takes1.pl', T1), fixture(T1, [':- use_module(library(keep)).'|Own]),
    sh_join(['run ', T1, ' go'], Args1), cocolog_answer(Args1, G1),
    check('loaded first, its calls keep the builtins; the program''s are the program''s',
          G1, answer(done, [a, b], yes, gc_no, mine)),
    append(Own, [':- use_module(library(keep)).'], Own2),
    atom_concat(D, '/takes2.pl', T2), fixture(T2, Own2),
    sh_join(['run ', T2, ' go'], Args2), cocolog_answer(Args2, G2),
    check('loaded after the program''s clauses, the same',
          G2, answer(done, [a, b], yes, gc_no, mine)),
    %% A DIRECTIVE use_module/1 LOADS AT THE FIRST GOAL, so the two above
    %% both load the library after the file is read; a goal directive runs
    %% one, and the library's clauses are in the store when the program's
    %% are read -- each call of a taken name made the system's then
    %% (`coco_sys_library'), not as the library is read
    atom_concat(D, '/takes3.pl', T3),
    fixture(T3, [':- use_module(library(keep)).', ':- keep_sort(_).'|Own]),
    sh_join(['run ', T3, ' go'], Args3), cocolog_answer(Args3, G3),
    check('loaded and run before the program''s clauses are read, the same',
          G3, answer(done, [a, b], yes, gc_no, mine)).

%% A LIBRARY LENDS ITS OPERATORS to the file that names it (`lb_lend_ops'):
%% its text is walked for `:- op' before the file reads on, so the file's
%% own clauses parse with them. A clause of the library that will not read
%% is passed over there as its consult passes it over (3.1.0); through
%% 3.0.4 the walk ended at it, and an op declared after it was not lent.
lends_ops(D) :-
    section('a library lends its operators, past a clause that will not read'),
    atom_concat(D, '/plib/opsyn.pl', Lib),
    fixture(Lib, ['bad(x y).', ':- op(700, xfx, ===>).', 'rule(a ===> b).']),
    atom_concat(D, '/lends.pl', F),
    fixture(F, [':- use_module(library(opsyn)).', 'mine(c ===> d).']),
    sh_join(['run ', F, ' "(mine(X), rule(Y), write_canonical(answer(X, Y)), nl)"'], Args), cocolog_answer(Args, G),
    check('the file reads with the operator declared after the bad clause', G,
          answer('===>'(c, d), '===>'(a, b))).

errors(D) :-
    section('the errors'),
    %% swipl's term since 3.4.0, where it was cocolog_error('use_module: ...')
    written(catch(use_module(library(nosuch)),
                  error(existence_error(source_sink, library(nosuch)), _), C1 = caught), C1, G1),
    check('a missing library throws, catchably', G1, caught),
    atom_concat(D, '/warns.pl', Warns),
    fixture(Warns, [':- use_module(library(nosuch)).', 'still(here).']),
    sh_join(['run ', Warns, ' "still(X), write(answer(X)), nl"'], Args2),
    cocolog_answer(Args2, G2),
    check('as a directive it warns and the file still reads', G2, answer(here)),
    %% A DIRECTIVE'S UNBOUND SPEC, AND A LIST WHOSE TAIL IS UNBOUND (3.4.0),
    %% are swipl's instantiation_error said at the directive's place, the
    %% file named by its absolute path though `run' and `consult' were given
    %% it from its own directory, as swipl names it. swipl's lines to the
    %% letter but for the variables' names, which no two systems share, so
    %% the ERROR lines are what is held; the directory as getcwd sees it
    %% (`pwd -P': on a Mac /tmp is a link to /private/tmp)
    atom_concat(D, '/vars.pl', Vars),
    fixture(Vars, [':- use_module(_).', ':- ensure_loaded([library(lists)|_]).', 'still(vars).']),
    sh_join(['cd ', D, ' && pwd -P'], Pwd3), shell(Pwd3, Real3, _),
    cocolog(C3),
    sh_join(['cd ', D, ' && ', C3, ' --local run vars.pl "still(X), write(answer(X)), nl" 2>&1'], Run3),
    shell(Run3, Out3, _),
    vars_said(Real3, Out3, R3),
    check('run: a directive''s unbound spec and tail, swipl''s errors at the file''s absolute path',
          R3, said),
    sh_join(['cd ', D, ' && ', C3, ' --local consult vars.pl 2>&1'], Run4),
    shell(Run4, Out4, _),
    vars_said(Real3, Out4, R4),
    check('consult: the same', R4, said).

%% WHAT include/1 DOES THAT NO swipl CAN BE ASKED (3.5.0): an include of a
%% file already open on the way down to it, or one sixty-four files deep,
%% is refused -- swipl reads it again for ever -- with
%% error(permission_error(include, source_sink, Spec), _), and the load
%% ends there, what it read before standing; and a script whose include
%% names nothing ends its load as swipl's script does, `Prolog
%% initialisation failed' and exit 1 (test/files/include.pl holds the rest
%% to swipl's text)
includes(D) :-
    section('include/1: the refusals, and a script it ends'),
    atom_concat(D, '/self.pl', Self),
    fixture(Self, ['s(1).', ':- include(self).', 's(2).']),
    written(catch(consult(Self), error(E1v, _), true), E1v, G1),
    check('an include of the file it stands in is refused', G1,
          'permission_error(include,source_sink,self)'),
    written(findall(X2, s(X2), L2), L2, G2),
    check('...and what the file read before it stands', G2, '[1]'),
    forall(between(0, 70, I3),
           ( atom_concat(D, '/c', P3), atom_concat(P3, I3, B3), atom_concat(B3, '.pl', F3),
             format(atom(C3), "d(~d).", [I3]), J3 is I3 + 1,
             format(atom(N3), ":- include(c~d).", [J3]),
             ( I3 < 70 -> fixture(F3, [C3, N3]) ; fixture(F3, [C3]) ) )),
    atom_concat(D, '/c0.pl', C0),
    written(catch(consult(C0), error(E3v, _), true), E3v, G3),
    check('a sixty-fifth file deep is refused', G3, 'permission_error(include,source_sink,c64)'),
    written(aggregate_all(count, d(_), N4), N4, G4),
    check('...the sixty-four above it read', G4, '64'),
    atom_concat(D, '/script.pl', Script),
    fixture(Script, ['s5(0).', ':- include(nope).', 'main :- writeln(main_ran).']),
    sh_join(['-s ', Script, ' 2>&1'], A5), cocolog_run(A5, T5, X5),
    check('-s: a script its include ends says swipl''s two lines', T5,
          'ERROR: Prolog initialisation failed:\nERROR: source_sink `nope\' does not exist'),
    check('...and exits 1, as swipl''s', X5, 1),
    %% the report's whole text, a name of six hundred characters in it
    %% (through 3.4.0 the message was cut at 512 bytes)
    length(Cs6, 600), maplist(=(0'n), Cs6), atom_codes(Long6, Cs6),
    atom_concat(D, '/script6.pl', Script6),
    format(atom(Inc6), ":- include(~w).", [Long6]),
    fixture(Script6, [Inc6, 'main :- true.']),
    sh_join(['-s ', Script6, ' 2>&1'], A6), cocolog_run(A6, T6, _),
    ( sub_atom(T6, _, _, _, Long6), sub_atom(T6, _, _, _, 'does not exist') -> R6 = whole ; R6 = T6 ),
    check('...and says it whole', R6, whole),
    %% library(Name) names a file on the library path, read where the
    %% directive stands as any other
    atom_concat(D, '/plib/incl_lib.pl', Lib7), fixture(Lib7, ['from_lib(yes).']),
    atom_concat(D, '/incl.pl', Incl7), fixture(Incl7, [':- include(library(incl_lib)).', 'mine7(1).']),
    written(( consult(Incl7), from_lib(V7) ), V7, G7),
    check('an include of library(Name) reads the library''s file', G7, yes).

vars_said(Dir, Out, R) :-
    atomic_list_concat(['ERROR: ', Dir, '/vars.pl:1:\nERROR:    Arguments are not sufficiently instantiated\n'], W1),
    atomic_list_concat(['ERROR: ', Dir, '/vars.pl:2:\nERROR:    Arguments are not sufficiently instantiated\n'], W2),
    ( sub_atom(Out, _, _, _, W1), sub_atom(Out, _, _, _, W2) -> R = said ; R = Out ).

shared_object(D) :-
    section('a .so library: the seam, reached later'),
    ( getenv('CICILI', Cicili) -> true ; getenv('HOME', Home), atom_concat(Home, '/cicili', Cicili) ),
    atom_concat(Cicili, '/cicili.lisp', Lisp),
    (   sh_exit('command -v sbcl >/dev/null 2>&1', 0), exists_file(Lisp)
    ->  atom_concat(D, '/plib', PLib),
        working_directory(Root, Root),
        %% Cicili takes the directory it starts in as where its own library
        %% lives, so it runs from its checkout with the target named
        %% absolutely; --release and -O3 below, as every module is built
        shl(['cd ', Cicili, ' && sbcl --script cicili.lisp --release ', Root, '/test/hoot.cicili > ', D, '/transpile.log 2>&1 || true']),
        %% THE ONE COMPILER: tools/cc/cc is the wrapper every link here goes
        %% through, and on a Mac the one that knows a module may leave the
        %% interpreter's symbols undefined (-Wl,-undefined,dynamic_lookup)
        ( exists_file('tools/cc/cc') -> Compiler = 'tools/cc/cc' ; Compiler = clang ),
        (   sh_join(['command -v ', Compiler, ' >/dev/null 2>&1 || test -x ', Compiler], HaveCc), sh_exit(HaveCc, 0)
        ->  sh_join([Compiler, ' -shared -fPIC -O3 -o ', PLib, '/hoot.so test/hoot.c > ', D, '/cc.log 2>&1'], Cc),
            (   sh_exit(Cc, 0)
            ->  written(( use_module(library(hoot)), hoot(X1), double_hoot(X1, X1) ), X1, G1),
                check('a compiled Cicili module loads, both halves', G1, hoot_from_c),
                module_context
            ;   atom_concat(D, '/cc.log', Log), read_file_to_codes(Log, Cs), atom_codes(Why, Cs),
                check('the hoot fixture compiles', Why, compiled)
            )
        ;   format("     (skipped: no C compiler for the hoot fixture)~n", [])
        )
    ;   format("     (skipped: .so -- no sbcl or no CICILI checkout)~n", [])
    ).

%% A LOADED MODULE'S ERRORS NAME IT (3.0.2), as swipl names a foreign
%% predicate's by the module that defines it: hoot_bad/1 raises through the
%% SDK, and its context is hoot:hoot_bad/1 -- caught, and as the message of
%% an error nothing caught, in a child (test/files/module_context.pl holds
%% the caught ones and print_message/2's text to swipl). A compiled-in
%% module's predicate that no row of *error-contexts* names keeps its
%% context unbound, as swipl's library predicates written over must_be/2
%% do (nth0/3).
module_context :-
    use_module(library(hoot)),
    % cocolint: C2 -- the check reads the context a loaded module's raise names
    answer(catch(hoot_bad(f(x)), error(F2, context(C2, _)), true), [F2, C2], A2),
    format(atom(G2), "~q", [A2]),
    check('a loaded module''s error names it', G2, '[type_error(hoot,f(x)),hoot:hoot_bad/1]'),
    % cocolint: C2 -- and an unbound culprit's
    answer(catch(hoot_bad(_), error(F3, context(C3, _)), true), [F3, C3], A3),
    format(atom(G3), "~q", [A3]),
    check('and an unbound culprit''s, an instantiation error', G3, '[instantiation_error,hoot:hoot_bad/1]'),
    % cocolint: C2 -- and an atom goal's
    answer(catch(hoot_none, error(F6, context(C6, _)), true), [F6, C6], A6),
    format(atom(G6), "~q", [A6]),
    check('an atom goal''s too, which the modules are asked in turn', G6,
          '[existence_error(hoot,none),hoot:hoot_none/0]'),
    cocolog_out('query "use_module(library(hoot)), hoot_bad(f(x))"', Out4),
    atom_codes(O4, Out4),
    (   sub_atom(O4, _, _, _, 'hoot:hoot_bad/1: Type error: `hoot'' expected, found `f(x)'' (a compound)')
    ->  G4 = prefixed
    ;   G4 = O4
    ),
    check('uncaught, its message begins Module:Name/Arity', G4, prefixed),
    answer(catch(nth0(a, [x], _), error(_, C5), true), C5, A5),
    ( var(A5) -> G5 = unbound ; format(atom(G5), "~q", [A5]) ),
    check('a compiled-in module''s predicate names nothing new', G5, unbound).

across_processes(D) :-
    section('process-local, proven across processes'),
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    sh_join(['--kb library_test --host ', Host, ' --tcp ', Port, ' --timeout 15'], W),
    cocolog(C),
    sh_join(['timeout 20 ', C, ' ', W, ' list >/dev/null 2>&1'], Probe),
    (   sh_exit(Probe, 0)
    ->  sh_join(['timeout 60 ', C, ' ', W, ' forget >/dev/null 2>&1'], Forget),
        sh_exit(Forget, _),
        sh_join([W, ' query "use_module(library(greet)), greeting(G), write(answer(G)), nl"'], A1),
        cocolog_answer(A1, G1),
        check('wire: the loading process sees the library', G1, answer(hello_from_pl)),
        sh_join([W, ' query "catch(greeting(_), error(existence_error(procedure, _), _), (write(answer(clean)), nl))"'], A2),
        cocolog_answer(A2, G2),
        check('wire: a second process does not -- nothing leaked', G2, answer(clean)),
        %% THE OTHER SIDE OF THE SAME COIN. A library is process-local and must
        %% not leak, which is what the two checks above prove. A `:- dynamic'
        %% DECLARATION is the opposite: README says a declaration is about the
        %% knowledge base, so it has to outlive the process -- and it did not.
        %% The row was written and read back, but ordinary resolution loads a
        %% predicate lazily, one at a time, and that path learns clauses and
        %% not declarations. A predicate declared in one process and never
        %% written to had no clauses to fetch, so the next process raised
        %% existence_error where SWI simply fails.
        sh_exit(Forget, _),
        atom_concat(D, '/dyn.pl', Dyn),
        fixture(Dyn, [':- dynamic ledger_mark/2.']),
        sh_join(['timeout 60 ', C, ' ', W, ' consult ', Dyn, ' >/dev/null 2>&1'], Consult),
        sh_exit(Consult, _),
        sh_join([W, ' query "catch((ledger_mark(_,_) -> write(answer(unexpected)) ; write(answer(fails_cleanly))), error(existence_error(_,_),_), write(answer(raised))), nl"'], A3),
        cocolog_answer(A3, G3),
        check('wire: a dynamic declaration DOES outlive the process', G3, answer(fails_cleanly)),
        sh_join([W, ' query "catch(never_declared_at_all(_), error(existence_error(procedure,_),_), (write(answer(raised)), nl))"'], A4),
        cocolog_answer(A4, G4),
        check('wire: and an undeclared predicate still raises', G4, answer(raised)),
        sh_exit(Forget, _)
    ;   format("     (skipped: wire -- no Zigurat server at ~w:~w)~n", [Host, Port])
    ).

%% a child with COCOLOG_LIBRARY unset, run from /tmp: `ok' or not
plain(Goal, Got) :-
    cocolog(C),
    sh_join(['cd /tmp && env -u COCOLOG_LIBRARY timeout 60 ', C, ' query "', Goal, '" 2>/dev/null'], Cmd),
    proc_run(Cmd, 60000, Out, _),
    ( re_match('(^|\n)ok\n', Out) -> Got = ok ; Got = no ).

always_present :-
    %% THE VENDORED SWI LIBRARIES ARE ALWAYS PRESENT, and reachable from
    %% anywhere. Two separate claims, and both were false a commit ago.
    %%
    %% They were shipped, documented and listed in CLAUDE.md while sitting on
    %% NO default path: `use_module(library(assoc))' on a plain checkout
    %% answered "not found on the library path". It survived because every
    %% test that used one set COCOLOG_LIBRARY for its own reasons, so nothing
    %% ever asked the question a new user asks first.
    %%
    %% COCOLOG_LIBRARY IS UNSET AND THE DIRECTORY IS ELSEWHERE, on purpose.
    %% Running this from the checkout with the variable set would check
    %% nothing at all: `./library' would find them by accident.
    section('always present: no use_module, no COCOLOG_LIBRARY, and not even here'),
    plain('empty_assoc(A), put_assoc(k,A,v,B), get_assoc(k,B,v), write(ok), nl', G1),
    check('assoc, without being asked for', G1, ok),
    plain('pairs_keys_values(P,[a],[1]), P == [a-1], write(ok), nl', G2),
    check('pairs, without being asked for', G2, ok),
    plain('ord_union([a,c],[b],[a,b,c]), write(ok), nl', G3),
    check('ordsets, without being asked for', G3, ok),
    plain('maplist([X,Y]>>(Y is X*2), [1,2], [2,4]), write(ok), nl', G4),
    check('yall, without being asked for', G4, ok),
    plain('aggregate_all(count, member(_,[a,b]), 2), write(ok), nl', G5),
    check('aggregate, without being asked for', G5, ok),
    plain('vertices_edges_to_ugraph([a,b],[a-b],G), G \\== [], write(ok), nl', G6),
    check('ugraphs, without being asked for', G6, ok),
    plain('phrase(integer(42), \\"42\\"), write(ok), nl', G7),
    check('dcg_basics, without being asked for', G7, ok).

still_answers :-
    %% use_module STILL WORKS, because a program that says so is not wrong --
    %% a registered module answers the call at once and costs nothing.
    section('and use_module(library(X)) still answers, at once'),
    forall(member(L, [assoc, pairs, ordsets, yall, aggregate, ugraphs, dcg_basics, dcg_high_order]),
           ( sh_join(['use_module(library(', L, ')), write(ok), nl'], Goal),
             plain(Goal, G),
             sh_join(['use_module(library(', L, ')) is a no-op that succeeds'], Label),
             check(Label, G, ok) )).
