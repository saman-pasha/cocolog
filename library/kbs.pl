%% cocolog -- library(kbs): many knowledge bases from one script.
%%
%% A cocolog process proves against ONE knowledge base: the engine
%% runs here, the store rides one connection, and that is the
%% arrangement's honest shape (lib/zigurat-kb.cicili). What a test
%% SCRIPT wants is more than one base in one story -- seed vs_a,
%% grind vs_b, read both back -- and the .sh suites already had it,
%% by spawning one cocolog per touch. This library is that same
%% claim with the plumbing as clauses: EVERY kb_* GOAL IS ONE
%% PROCESS-PROOF over the wire, which is not a workaround but the
%% point -- a store half exists to show a SECOND process sees the
%% rows, and a library that proved everything in-process would
%% quietly stop making that claim.
%%
%% THE ERGONOMICS ARE THE REASON IT EXISTS: goals are TERMS, not
%% strings. kb_run(vs_x, enroll_unit(a, w, 'Warrior', 1, 5)) --
%% term_to_atom does the quoting, so the quote-doubling that eats a
%% shell suite's tokens (and this family's patience) is gone; and
%% kb_answer/3 extracts the answer(...) line with library(text)'s
%% own regex, so no grep is spawned to read a transcript.
%%
%% WHERE THE SERVER IS: kb_server(KB, Host, Port) facts name it per
%% base when asserted; otherwise $ZIGURAT_HOST/$ZIGURAT_PORT,
%% otherwise 127.0.0.1:2160 -- the family's defaults. WHICH COCOLOG
%% RUNS THE PROOF: $COCOLOG's checkout if set, otherwise THIS very
%% binary (the executable flag, the engine's own answer), so a script
%% needs no configuration to spawn what it already is.
%%
%% NOT HERE: an in-process multi-connection engine (that is a seam
%% in lib/module.cicili for a later piece of work, and it would be a
%% DIFFERENT claim), and transcript parsing beyond the answer line
%% (a page's whole output is the caller's to read with text's own
%% tools).
%%
%% THE SURFACE. KB names a base, a Goal is a term, Files are paths:
%%
%%   kb_run(+KB, +Goal)                one goal, one process, one transaction: succeeds iff it PROVED
%%   kb_answer(+KB, +Goal, -Answer)    the same, keeping the transcript's answer(...) line
%%   kb_consult(+KB, +Files)           load a program into the base
%%   kb_forget(+KB)                    empty it
%%   kb_vacuum(+KB)                    reclaim; never fails
%%   kb_fresh(+KB, +Files)             vacuum, forget, consult: a case's first word
%%   kb_up(+KB)                        is anybody there? -- the SKIP probe
%%   kb_at(+KB, -Host, -Port)          kb_server/3, else $ZIGURAT_HOST/$ZIGURAT_PORT, else 127.0.0.1:2160
%%   kb_cli(+KB, -Cmd)                 the cocolog command line every verb runs
%%   kb_binary(-Path)                  the cocolog that proves: $COCOLOG's checkout, else this very one
%%   kb_server(?KB, ?Host, ?Port)      dynamic; assert one to name a base's server

:- use_module(library(process)).
:- use_module(library(text)).

:- dynamic kb_server/3.

%% ---- where, and with what ---------------------------------------------

%% THE BINARY IS THE ONE RUNNING, asked of the engine rather than of
%% /proc: `current_prolog_flag(executable, P)' is resolved by cocolog
%% itself (readlink on Linux, _NSGetExecutablePath on Darwin), where a
%% `read_link('/proc/self/exe', ...)' silently failed on every machine
%% without a /proc -- and a kb_binary that fails makes every kb_* goal
%% fail with nothing printed, which cost a session on a Mac.
kb_binary(Bin) :-
    (   getenv('COCOLOG', D)
    ->  atom_concat(D, '/cocolog', Bin)
    ;   current_prolog_flag(executable, Bin)
    ).

kb_at(KB, Host, Port) :-
    (   kb_server(KB, Host, Port) -> true
    ;   ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
        ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 )
    ).

kb_cli(KB, Cli) :-
    kb_binary(Bin),
    kb_at(KB, Host, Port),
    sh_join([Bin, ' --host ', Host, ' --tcp ', Port,
             ' --timeout 240 --kb ', KB, ' '], Cli).

%% ---- the verbs ----------------------------------------------------------

%% is anybody there? -- the SKIP probe every store half opens with
kb_up(KB) :-
    kb_cli(KB, Cli),
    shl([Cli, 'list >/dev/null 2>&1']).

%% one goal, one transaction, one process -- succeeds iff it PROVED.
%% The goal is a TERM; term_to_atom quotes what needs quoting. The
%% verdict is read from the transcript, not the exit code, because
%% `query' exits 0 on a goal that merely FAILED (false. is an answer,
%% not an error) -- found by this library's own lesson: a separation
%% check read "leaked" from a base that was innocent. Wrapping in
%% if-then-else keeps the child's query succeeding either way, which
%% changes nothing the store commits (asserts commit on failure too,
%% the family's recorded rule; errors still roll back and print no
%% verdict at all, so they fail here like the refusals they are).
%% A REFUSAL NAMES ITSELF. A goal that is not proved used to fail this
%% predicate in silence -- the transcript thrown away, stderr to
%% /dev/null -- and a case then died at its section header having
%% printed nothing, which is the shape a whole suite's reds took for a
%% day (CivV, `match' and `ai' silent at their first store call). Now
%% the child's stderr rides with its stdout, and a miss prints the
%% transcript's tail under a `kb_run refused' line, so the case's own
%% output says whether the goal failed, threw, timed out or found no
%% server. The verdict is still the line, never a substring.
kb_run(KB, Goal) :-
    kb_cli(KB, Cli),
    term_to_atom(( Goal -> write(kbs_proved), nl ; write(kbs_refused), nl ), GA),
    %% `|| true': a child that THREW exits non-zero, and shl/2 fails on
    %% a non-zero exit -- which was the silent case, the transcript never
    %% read. Kept exiting 0, the transcript is what the report shows.
    shl([Cli, 'query "', GA, '" 2>&1 || true'], Out),
    (   re_lines('^kbs_proved$', Out, [_|_])
    ->  true
    ;   catch(kb_report_refusal(KB, Goal, Out), _, true),
        fail
    ).

kb_report_refusal(KB, Goal, Out) :-
    term_to_atom(Goal, GoalA),
    atom_length(GoalA, GL), Take is min(GL, 120),
    sub_atom(GoalA, 0, Take, _, Head),
    format("kb_run refused on ~w: ~w~n", [KB, Head]),
    kb_tail(Out, 6, Tail),
    forall(member(L, Tail), ( atom_codes(LA, L), format("     ~w~n", [LA]) )).

%% the last N lines of a transcript, as code lists
kb_tail(Out, N, Tail) :-
    kb_split_lines(Out, Ls0),
    findall(L, ( member(L, Ls0), L \== [] ), Ls),
    length(Ls, Len),
    Drop is max(0, Len - N),
    length(Pre, Drop), append(Pre, Tail, Ls).

kb_split_lines([], [[]]).
kb_split_lines([10|Cs], [[]|Ls]) :- !, kb_split_lines(Cs, Ls).
kb_split_lines([C|Cs], [[C|L]|Ls]) :- kb_split_lines(Cs, [L|Ls]).

%% the same proof, keeping the transcript's answer(...) line -- the
%% goal is expected to write(answer(...)), nl, the family's idiom
kb_answer(KB, Goal, Answer) :-
    kb_cli(KB, Cli),
    term_to_atom(Goal, GA),
    shl([Cli, 'query "', GA, '" 2>/dev/null'], Out),
    re_lines('^answer\\(', Out, [L|_]),
    atom_codes(Answer, L).

kb_consult(_, []) :- !.        % nothing to load is a loaded nothing
kb_consult(KB, Files) :-
    kb_cli(KB, Cli),
    kb_files_(Files, FA),
    shl([Cli, 'consult ', FA, ' >/dev/null 2>&1']).

kb_files_([], '').
kb_files_([F|Fs], A) :-
    kb_files_(Fs, R),
    atom_concat(F, ' ', F1),
    atom_concat(F1, R, A).

kb_forget(KB) :-
    kb_cli(KB, Cli),
    shl([Cli, 'forget >/dev/null 2>&1']).

kb_vacuum(KB) :-
    kb_cli(KB, Cli),
    ( shl([Cli, 'vacuum >/dev/null 2>&1']) -> true ; true ).

%% the setup every store half performs: reclaim, empty, load the
%% program -- one word at the top of a case
kb_fresh(KB, Files) :-
    kb_vacuum(KB),
    kb_forget(KB),
    kb_consult(KB, Files).
