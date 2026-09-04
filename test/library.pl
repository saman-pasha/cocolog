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
    registered, from_the_path(D), errors(D), shared_object(D), across_processes(D),
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

errors(D) :-
    section('the errors'),
    written(catch(use_module(library(nosuch)), error(cocolog_error(_), _), C1 = caught), C1, G1),
    check('a missing library throws, catchably', G1, caught),
    atom_concat(D, '/warns.pl', Warns),
    fixture(Warns, [':- use_module(library(nosuch)).', 'still(here).']),
    sh_join(['run ', Warns, ' "still(X), write(answer(X)), nl"'], Args2),
    cocolog_answer(Args2, G2),
    check('as a directive it warns and the file still reads', G2, answer(here)).

shared_object(D) :-
    section('a .so library: the seam, reached later'),
    ( getenv('CICILI', Cicili) -> true ; getenv('HOME', Home), atom_concat(Home, '/cicili', Cicili) ),
    atom_concat(Cicili, '/cicili.lisp', Lisp),
    (   sh_exit('command -v sbcl >/dev/null 2>&1', 0), exists_file(Lisp)
    ->  atom_concat(D, '/plib', PLib),
        working_directory(Root, Root),
        %% Cicili takes the directory it starts in as where its own library
        %% lives, so it runs from its checkout with the target named absolutely
        shl(['cd ', Cicili, ' && sbcl --script cicili.lisp ', Root, '/test/hoot.cicili > ', D, '/transpile.log 2>&1 || true']),
        %% THE ONE COMPILER: tools/cc/cc is the wrapper every link here goes
        %% through, and on a Mac the one that knows a module may leave the
        %% interpreter's symbols undefined (-Wl,-undefined,dynamic_lookup)
        ( exists_file('tools/cc/cc') -> Compiler = 'tools/cc/cc' ; Compiler = gcc ),
        (   sh_join(['command -v ', Compiler, ' >/dev/null 2>&1 || test -x ', Compiler], HaveCc), sh_exit(HaveCc, 0)
        ->  sh_join([Compiler, ' -shared -fPIC -O2 -o ', PLib, '/hoot.so test/hoot.c > ', D, '/cc.log 2>&1'], Cc),
            (   sh_exit(Cc, 0)
            ->  written(( use_module(library(hoot)), hoot(X1), double_hoot(X1, X1) ), X1, G1),
                check('a compiled Cicili module loads, both halves', G1, hoot_from_c)
            ;   atom_concat(D, '/cc.log', Log), read_file_to_codes(Log, Cs), atom_codes(Why, Cs),
                check('the hoot fixture compiles', Why, compiled)
            )
        ;   format("     (skipped: no C compiler for the hoot fixture)~n", [])
        )
    ;   format("     (skipped: .so -- no sbcl or no CICILI checkout)~n", [])
    ).

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
