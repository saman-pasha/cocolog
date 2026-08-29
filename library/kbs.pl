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
%% binary (/proc/self/exe, the kernel's own answer), so a script
%% needs no configuration to spawn what it already is.
%%
%% NOT HERE: an in-process multi-connection engine (that is a seam
%% in lib/module.cicili for a later piece of work, and it would be a
%% DIFFERENT claim), and transcript parsing beyond the answer line
%% (a page's whole output is the caller's to read with text's own
%% tools).

:- use_module(library(process)).
:- use_module(library(text)).

:- dynamic kb_server/3.

%% ---- where, and with what ---------------------------------------------

kb_binary(Bin) :-
    (   getenv('COCOLOG', D)
    ->  atom_concat(D, '/cocolog', Bin)
    ;   read_link('/proc/self/exe', _, Bin)
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
kb_run(KB, Goal) :-
    kb_cli(KB, Cli),
    term_to_atom(( Goal -> write(kbs_proved), nl ; write(kbs_refused), nl ), GA),
    shl([Cli, 'query "', GA, '" 2>/dev/null'], Out),
    %% the toplevel ECHOES the goal, verdict atoms included, so the
    %% verdict is matched as ITS OWN LINE, never as a substring
    re_lines('^kbs_proved$', Out, [_|_]).

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
