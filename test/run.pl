%% The whole suite.
%%
%%     cocolog -s test/run.pl                 everything
%%     cocolog -s test/run.pl -- solve        one .cicili case
%%     cocolog -s test/run.pl -- groups       one .pl case
%%
%% `make test' is the first line. THE RUNNER IS A COCOLOG SCRIPT, like every
%% case it runs: it stands on library(process) for the children and prints
%% the same forty-eight lines test/run.sh printed, each with its seconds.
%%
%% Two kinds of case:
%%
%%   .cicili   seven test BINARIES -- term syntax solve module state zigurat
%%             shared -- each transpiled by Cicili from test/<c>.cicili and
%%             built through tools/cc, then run; the last line of what it
%%             prints is GREEN, SKIP, or the failure.
%%   .pl       every other case, `cocolog -s test/<c>.pl' from this checkout
%%             root: THE EXIT CODE IS THE VERDICT, 0 exactly when its main
%%             proved, which checks_done withholds on any red check; a line
%%             beginning SKIP at column 0 is a skip. test/prelude.pl says
%%             what a case is made of.
%%
%% The database cases SKIP when there is no server, because "no server here"
%% and "the backend is wrong" are different findings. To run them, raise a
%% ZiguratIP server and compile the schema into its home first:
%%
%%   export ZIGURATIP_HOME=/path/to/ZiguratIP/home
%%   make schema
%%   $ZIGURATIP_HOME/bin/ziguratip &
%%
%% COUNT THE SKIPs. `red: 0' is printed over a run where nothing happened as
%% happily as over a real one -- read the case lines, not the last one.
%%
%% THE ENVIRONMENT THE CASES NEED IS SET HERE, once: COCOLOG_LIBRARY with
%% this checkout's library/ FIRST and whatever the caller had behind it (a
%% suite must not go green about somebody else's httpd.pl, and a path
%% somebody exported on purpose must not be thrown away), and tools/cc on
%% PATH, because Cicili names `gcc' -- `clang' on Darwin -- outright and the
%% shims there are how that name reaches the wrappers that carry each
%% platform's flags. The .cicili binaries used to be built with whatever the
%% bare name resolved to, which is how they came to fail on a Mac beside a
%% `make' that succeeded.

:- use_module('test/prelude.pl').

main :-
    root(Root),
    environment(Root),
    ( getenv('CICILI', Cicili) -> true ; getenv('HOME', H), atom_concat(H, '/cicili', Cicili) ),
    atom_concat(Cicili, '/cicili.lisp', Lisp),
    (   exists_file(Lisp)
    ->  true
    ;   format("cocolog: set CICILI to a Cicili checkout (looked in ~w)~n", [Cicili]), halt(1)
    ),
    ( getenv('SBCL', Sbcl) -> true ; Sbcl = sbcl ),
    ( current_prolog_flag(argv, [_, Only|_]) -> true ; Only = all ),
    cicili_cases(Only, Cicili, Sbcl, Red0),
    pl_cases(Only, Red0, Red),
    format("~nred: ~w~n", [Red]),
    Red =:= 0.

environment(Root) :-
    atom_concat(Root, '/library', Lib),
    (   getenv('COCOLOG_LIBRARY', Old), Old \== ''
    ->  sh_join([Lib, ':', Old], Path)
    ;   Path = Lib
    ),
    setenv('COCOLOG_LIBRARY', Path),
    atom_concat(Root, '/tools/cc', CC),
    ( getenv('PATH', OldPath) -> sh_join([CC, ':', OldPath], NewPath) ; NewPath = CC ),
    setenv('PATH', NewPath).

%% ---- the .cicili cases -------------------------------------------------------

cicili_names([term, syntax, solve, module, state, zigurat, shared]).

%% NAMING ONE CASE runs only it; a name that is not a .cicili case belongs to
%% the .pl loop below, and this loop runs nothing at all.
cicili_cases(Only, Cicili, Sbcl, Red) :-
    cicili_names(All),
    ( Only == all -> Cases = All ; memberchk(Only, All) -> Cases = [Only] ; Cases = [] ),
    cicili_each(Cases, Cicili, Sbcl, 0, Red).

%% `printf '%-10s '': cocolog's format has no column directives
padded(Name, Width) :-
    atom_length(Name, L), Pad is max(1, Width - L),
    length(Spaces, Pad), maplist(=(0' ), Spaces), atom_codes(Blank, Spaces),
    format("~w~w", [Name, Blank]).

cicili_each([], _, _, Red, Red).
cicili_each([C|Cs], Cicili, Sbcl, Red0, Red) :-
    padded(C, 11),
    root(Root),
    %% Cicili takes the directory it starts in as where its own library
    %% lives, so it is run from its own checkout with the target named
    %% absolutely.
    sh_join(['cd ', Cicili, ' && ', Sbcl, ' --script cicili.lisp ', Root, '/test/', C, '.cicili 2>&1'], Build),
    shell(Build, BuildOut, BuildRc),
    (   BuildRc =:= 0
    ->  sh_join([Root, '/test/cocolog_', C, '_test 2>&1'], Run),
        shell(Run, Out, _),
        last_line(Out, Last),
        (   sub_atom(Last, 0, _, _, 'GREEN') -> format("GREEN~n", []), Red1 = Red0
        ;   sub_atom(Last, 0, _, _, 'SKIP') -> format("SKIP~n", []), Red1 = Red0
        ;   sub_atom(Out, 0, _, _, 'SKIP') -> format("SKIP~n", []), Red1 = Red0
        ;   format("~w~n", [Last]), fail_lines(Out), Red1 is Red0 + 1
        )
    ;   format("BUILD FAILED~n", []),
        atom_codes(BuildOut, BCs), codes_lines(BCs, BL), tail_lines(5, BL, Tail),
        forall(member(L, Tail), ( atom_codes(LA, L), format("~w~n", [LA]) )),
        Red1 is Red0 + 1
    ),
    cicili_each(Cs, Cicili, Sbcl, Red1, Red).

last_line(Text, Last) :-
    atom_codes(Text, Cs),
    ( codes_lines(Cs, Ls), Ls \== [], last(Ls, L) -> atom_codes(Last, L) ; Last = '' ).

fail_lines(Text) :-
    atom_codes(Text, Cs), re_lines('^FAIL', Cs, Ls), head_lines(5, Ls, Five),
    forall(member(L, Five), ( atom_codes(LA, L), format("~w~n", [LA]) )).

%% ---- the .pl cases -------------------------------------------------------------
%%
%% Each drives the built PROGRAM rather than a test binary. They run last
%% because they are the slowest and because everything above them has to be
%% right for them to mean anything.
%%
%%   files   the Files module, run against SWI-Prolog and compared line for line
%%   trace   the four-port tracer, run against SWI-Prolog's and compared
%%           port for port
%%   vacuum  the reclaim pass: the verb in both arrangements, and the gate
%%           on the vacuum_kb builtin
%%   repl    the toplevel, piped: SWI's answer shapes, one session one
%%           world, and a session's writes read by a second process
%%   script  `-s FILE': load a script, prove main, and say so in the
%%           EXIT CODE -- 0 exactly when main proved
%%   tunnel  the Zeytun reader behind a hostname-routing edge -- the local
%%           rehearsal of the Cloudflare tunnel in colab/COLAB.md
%%   tensors model parameters as Vector<Double> rows: the table on the
%%           wire, the paged tensor page over HTTP, the chunk fallback
%%   http    HTTP/1.1 as a grammar, held to written-out answers and to curl
%%   curl    the client half, over cicili's libcurl binding
%%   engine  the engine's COMPLEXITY: a timeout at a hundred-fold margin
%%   meter   `call_metered/4': a goal under a ceiling, and WHAT IT COST
%%   os      library(os), each answer held to the shell's own
%%   thread  threads that share nothing and channels that copy
%%   httpd   the server half: routing, the four ways a static file server
%%           leaks, keep-alive, the pool, pages that reach the knowledge base
%%   tcp     the socket seam, and one process reaching another
%%   colab   the notebook and the scripts beside it, without a VM
%%   crypto  ZiguratIP's cryptography and its CA as cocolog predicates
%%   tutorials  all the tutorial files, as tests -- every claim a must/3
%%   lint    cocolint over the calibration corpus
%%   groups  twelve interpreters sharing four machine STATES
%%   ruler   one interpreter writing the KNOWLEDGE BASE while eight read it
pl_names([files, trace, vacuum, repl, script, tunnel, reconsult, tensors,
          'torch-graph', 'torch-grad', 'torch-replay', tensorflow, library, bigint,
          'zigurat-lib', tcp, engine, meter, thread, process, text, os, kbs, http,
          curl, ray, numpy, opencv, hex, astar, serialize, httpd, 'httpd-tls', crypto,
          tls, 'zigurat-tls', tutorials, colab, lint, argv, string, directives,
          groups, ruler]).

pl_cases(Only, Red0, Red) :-
    pl_names(All),
    ( Only == all -> Cases = All ; memberchk(Only, All) -> Cases = [Only] ; Cases = [] ),
    ( exists_file(cocolog) -> Binary = yes ; Binary = no ),
    pl_each(Cases, Binary, Red0, Red).

pl_each([], _, Red, Red).
pl_each([C|Cs], Binary, Red0, Red) :-
    padded(C, 11),
    sh_join(['test/', C, '.pl'], File),
    get_time(T0),
    (   Binary == no, C \== colab
    ->  Verdict = 'SKIP (build cocolog first)', Out = ''
    ;   \+ exists_file(File)
    ->  Verdict = 'RED: no test/<case>.pl', Out = ''
    ;   cocolog(Bin),
        sh_join([Bin, ' -s ', File, ' 2>&1'], Cmd),
        proc_run(Cmd, 3600000, OutCs, Rc),
        chomp(OutCs, Body), atom_codes(Out, Body),
        (   re_match('(^|\n)SKIP', OutCs) -> Verdict = 'SKIP'
        ;   Rc =:= 0 -> Verdict = 'GREEN'
        ;   Verdict = 'RED'
        )
    ),
    get_time(T1), Secs is round(T1 - T0),
    %% and how long it took, because a suite that is slow in one case and
    %% says nothing about which is a suite nobody times twice
    (   Verdict == 'GREEN' -> format("GREEN  ~ws~n", [Secs]), Red1 = Red0
    ;   sub_atom(Verdict, 0, _, _, 'SKIP') -> format("SKIP   ~ws~n", [Secs]), Red1 = Red0
    ;   last_line(Out, Last), format("~w  ~ws~n", [Last, Secs]), fail_lines(Out), Red1 is Red0 + 1
    ),
    pl_each(Cs, Binary, Red1, Red).
