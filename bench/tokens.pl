%% bench/tokens.pl -- the tokens an agent spends writing the same program in
%% cocolog and in Python.
%%
%%     cocolog -s bench/tokens.pl -- check  [TASK...]
%%     cocolog -s bench/tokens.pl -- size   [model=M] [TASK...]
%%     cocolog -s bench/tokens.pl -- replay DIR [OPTION...] [TASK...]
%%     cocolog -s bench/tokens.pl -- run    [OPTION...] [TASK...]
%%     cocolog -s bench/tokens.pl -- report FILE.jsonl
%%
%% from the checkout root; bench/tokens/README.md is the long version.
%%
%% THE QUESTION is what a model burns, in tokens and in dollars, to get a
%% program right in each language: not how short the program is, but what
%% the loop that writes it costs -- the guide it has to be given, the
%% replies it writes (thinking included, which is billed as output), the
%% failures it reads back and the rounds it takes. So the unit is an
%% EPISODE: one task, one arm, one repetition, run until every test passes
%% or the rounds run out.
%%
%% THE ARMS. `python' is Python 3 with a short system prompt. `cocolog' is
%% the same prompt for cocolog, saying only how a program is run and how it
%% reads its input. `cocolog-card' adds the dialect card cocolint keeps
%% (tools/cocolint/traps.jsonl, rendered by `tool.sh card --card'): what
%% the project gives an agent so that it does not write SWI-Prolog. The
%% card is a fixed cost every request carries, cached, and whether it pays
%% for itself in rounds is one of the things a run measures.
%%
%% THE LOOP. Round 1 sends the task. A reply's first fenced code block is
%% the program; every test case runs it, and the first that fails comes
%% back as the next user turn -- its input, the output wanted, the output
%% got, the exit status and the end of stderr -- until a round passes them
%% all. A reply with no code block is told so, and that is a round too.
%% Everything the model sent back is echoed as it came, thinking blocks
%% included: the conversation is APPEND-ONLY, which is what the API's
%% preserved thinking asks of a harness, and what keeps the cache warm.
%%
%% WHAT IS COUNTED is what the API reports per call: `input_tokens',
%% `cache_creation_input_tokens', `cache_read_input_tokens' and
%% `output_tokens'. A token is never estimated here, with one exception
%% that says so: the replay backend has no model to ask, and writes a
%% length / 4 in its log so that the report has something to add up.
%%
%% NO FALLBACK MODEL BY DEFAULT. The API can re-run a declined request on
%% another model (`fallbacks', server-side), and once a conversation falls
%% back it stays there for about an hour. A benchmark that did that would
%% be measuring two models under one name, so a refusal is recorded as a
%% refusal; `fallbacks=default' turns the API's fallback on, and then
%% every call's log line names the model that served it.
%%
%% IT RUNS WHAT THE MODEL WROTE, on this machine, as this user: each test
%% in a scratch directory of its own, under a timeout. Run it in a
%% container or a VM you would let a stranger's program run in.

:- use_module(library(process)).
:- use_module(library(json)).

%% ---- the command line ---------------------------------------------------

main :-
    current_prolog_flag(argv, [_|Args]),
    tk_root(Root),
    (   Args = [Cmd|Rest], tk_command(Cmd, Root, Rest, Status)
    ->  halt(Status)
    ;   tk_usage,
        halt(2)
    ).

tk_usage :-
    format(user_error, "usage: cocolog -s bench/tokens.pl -- check|size|replay DIR|run|report FILE [OPTION...] [TASK...]~n", []).

tk_command(check, Root, Names, Status) :-
    tk_tasks(Root, Names, Tasks),
    tk_check(Root, Tasks, Failed),
    ( Failed =:= 0 -> Status = 0 ; Status = 1 ).
tk_command(size, Root, Args, 0) :-
    tk_options(Args, Opts, Names),
    tk_tasks(Root, Names, Tasks),
    tk_size(Root, Opts, Tasks).
tk_command(replay, Root, [Dir|Args], 0) :-
    tk_options(Args, Opts0, Names),
    tk_tasks(Root, Names, Tasks),
    atom_concat(Dir, '/replay.jsonl', Out0),
    tk_default_out(Opts0, Out0, Opts),
    tk_bench(Root, replay(Dir), Opts, Tasks).
tk_command(run, Root, Args, 0) :-
    tk_options(Args, Opts0, Names),
    tk_tasks(Root, Names, Tasks),
    tk_key(_),
    get_time(T), Stamp is truncate(T),
    format(atom(Out0), '~w/bench/tokens/runs/run-~d.jsonl', [Root, Stamp]),
    tk_default_out(Opts0, Out0, Opts),
    tk_bench(Root, api, Opts, Tasks).
tk_command(report, _, [File], 0) :-
    tk_report(File).

%% Options are NAME=VALUE, everything else a task. A value that reads as a
%% number is the number.
tk_options([], [], []).
tk_options([A|As], Opts, Names) :-
    (   atomic_list_concat([K, V0], '=', A)
    ->  ( atom_number(V0, V) -> true ; V = V0 ),
        Opts = [K-V|Opts1], Names = Names1
    ;   Opts = Opts1, Names = [A|Names1]
    ),
    tk_options(As, Opts1, Names1).

tk_default_out(Opts, _, Opts) :- memberchk(out-_, Opts), !.
tk_default_out(Opts, Out, [out-Out|Opts]).

%% Every default in one place.
tk_opt(Opts, K, V) :- memberchk(K-V0, Opts), !, V = V0.
tk_opt(_, K, V) :- tk_default(K, V).

tk_default(model, 'claude-opus-5-5').
tk_default(effort, high).
tk_default(max_tokens, 16000).
tk_default(rounds, 4).
tk_default(reps, 3).
tk_default(arms, 'python,cocolog,cocolog-card').
tk_default(timeout, 10).
tk_default(fallbacks, off).
tk_default(retries, 5).

%% ---- where things are -------------------------------------------------

tk_root(Root) :-
    working_directory(Raw, Raw),
    ( atom_concat(Root, '/', Raw), Root \== '' -> true ; Root = Raw ),
    atom_concat(Root, '/bench/tokens/tasks', Tasks),
    (   exists_directory(Tasks)
    ->  true
    ;   throw(error(existence_error(directory, Tasks), tk_root/1))
    ).

tk_path(Root, Rel, Path) :- atomic_list_concat([Root, '/bench/tokens/', Rel], Path).

tk_task_path(Root, Task, File, Path) :-
    atomic_list_concat([Root, '/bench/tokens/tasks/', Task, '/', File], Path).

tk_tasks(Root, [], Tasks) :- !,
    tk_path(Root, tasks, Dir),
    directory_files(Dir, Fs),
    exclude(tk_dot, Fs, Ts),
    msort(Ts, Tasks).
tk_tasks(Root, Names, Names) :-
    forall(member(T, Names),
           (   tk_task_path(Root, T, 'task.md', P), exists_file(P)
           ->  true
           ;   throw(error(existence_error(task, T), tk_tasks/3))
           )).

tk_dot(F) :- sub_atom(F, 0, 1, _, '.').

%% The case names, `01', `02', ..., in order.
tk_cases(Root, Task, Cases) :-
    tk_task_path(Root, Task, cases, Dir),
    directory_files(Dir, Fs),
    findall(C, ( member(F, Fs), atom_concat(C, '.in', F) ), Cs),
    msort(Cs, Cases).

%% arm -> the language its programs are written in
tk_arm(python, python).
tk_arm(cocolog, cocolog).
tk_arm('cocolog-card', cocolog).

tk_ref(python, 'ref.py').
tk_ref(cocolog, 'ref.pl').

tk_arms(Opts, Arms) :-
    tk_opt(Opts, arms, A),
    atomic_list_concat(Arms, ',', A),
    forall(member(X, Arms),
           ( tk_arm(X, _) -> true ; throw(error(domain_error(arm, X), tk_arms/2)) )).

%% ---- running a program against a task's cases ---------------------------

%% tk_test(+Root, +Lang, +Program, +Task, +TimeoutS, -Verdict): pass(N), or
%% fail(K, N, Why) for the first case K of N that did not pass, Why being
%% wrong(In, Want, Got, Exit, Err).
tk_test(Root, Lang, Program, Task, Timeout, Verdict) :-
    tk_cases(Root, Task, Cases),
    length(Cases, N),
    tmp_file(tokens, Dir),
    make_directory(Dir),
    tk_prog_file(Lang, ProgName),
    atomic_list_concat([Dir, '/', ProgName], Prog),
    write_file_from_codes(Prog, Program),
    tk_run_cases(Cases, 1, N, Root, Lang, Dir, Task, Timeout, Verdict),
    sh_join(['rm -rf ''', Dir, ''''], Rm),
    proc_run(Rm, 60000, _, _).

tk_prog_file(python, 'prog.py').
tk_prog_file(cocolog, 'prog.pl').

tk_run_cases([], _, N, _, _, _, _, _, pass(N)).
tk_run_cases([C|Cs], K, N, Root, Lang, Dir, Task, Timeout, Verdict) :-
    tk_task_path(Root, Task, cases, CaseDir),
    atomic_list_concat([CaseDir, '/', C, '.in'], In),
    atomic_list_concat([CaseDir, '/', C, '.out'], Want),
    tk_command_line(Lang, Root, Cmd0),
    sh_join(['cd ''', Dir, ''' && ', Cmd0, ' < ''', In, ''' > out.txt 2> err.txt'], Cmd),
    Ms is Timeout * 1000,
    proc_run(Cmd, Ms, _, Exit),
    atom_concat(Dir, '/out.txt', OutF),
    atom_concat(Dir, '/err.txt', ErrF),
    tk_read(OutF, Got),
    tk_read(ErrF, Err),
    read_file_to_codes(Want, WantCs),
    (   Exit =:= 0, tk_same(Got, WantCs)
    ->  K1 is K + 1,
        tk_run_cases(Cs, K1, N, Root, Lang, Dir, Task, Timeout, Verdict)
    ;   read_file_to_codes(In, InCs),
        Verdict = fail(K, N, wrong(InCs, WantCs, Got, Exit, Err))
    ).

%% A file the shell had no time to make reads as empty.
tk_read(F, Cs) :- ( exists_file(F) -> read_file_to_codes(F, Cs) ; Cs = [] ).

tk_command_line(python, _, Cmd) :-
    ( getenv('PYTHON', Py), Py \== '' -> true ; Py = python3 ),
    sh_join(['''', Py, ''' prog.py'], Cmd).
tk_command_line(cocolog, _, Cmd) :-
    current_prolog_flag(executable, Exe),
    sh_join(['''', Exe, ''' -s prog.pl'], Cmd).

%% Two outputs are the same when their lines are, trailing blanks at the
%% end of a line and blank lines at the end of the output aside: a fair
%% rule, and the same one for both languages.
tk_same(A, B) :- tk_lines(A, La), tk_lines(B, Lb), La == Lb.

tk_lines(Codes, Lines) :-
    split_string(Codes, "\n", "", Parts),
    maplist(tk_rstrip, Parts, Stripped),
    reverse(Stripped, R0),
    tk_drop_empty(R0, R1),
    reverse(R1, Lines).

tk_rstrip(S, T) :-
    string_codes(S, Cs),
    reverse(Cs, R),
    tk_skip_blank(R, R1),
    reverse(R1, Ts),
    string_codes(T, Ts).

tk_skip_blank([C|Cs], Rest) :- memberchk(C, [32, 9, 13]), !, tk_skip_blank(Cs, Rest).
tk_skip_blank(Cs, Cs).

tk_drop_empty([S|Ss], Out) :- string_length(S, 0), !, tk_drop_empty(Ss, Out).
tk_drop_empty(Ss, Ss).

%% ---- check: every reference passes every case ---------------------------

tk_check(Root, Tasks, Failed) :-
    foldl(tk_check_task(Root), Tasks, 0, Failed).

tk_check_task(Root, Task, F0, F) :-
    tk_check_lang(Root, Task, python, Vp),
    tk_check_lang(Root, Task, cocolog, Vc),
    tk_verdict_text(Vp, Tp),
    tk_verdict_text(Vc, Tc),
    tk_pad(Task, 10, P),
    format("~w python ~w   cocolog ~w~n", [P, Tp, Tc]),
    ( Vp = pass(_) -> F1 = F0 ; F1 is F0 + 1 ),
    ( Vc = pass(_) -> F = F1 ; F is F1 + 1 ).

tk_check_lang(Root, Task, Lang, Verdict) :-
    tk_ref(Lang, Ref),
    tk_task_path(Root, Task, Ref, Path),
    read_file_to_codes(Path, Program),
    tk_test(Root, Lang, Program, Task, 30, Verdict).

tk_verdict_text(pass(N), T) :- format(atom(T), '~d/~d', [N, N]).
tk_verdict_text(fail(K, N, _), T) :- format(atom(T), 'FAIL at case ~d of ~d', [K, N]).

%% ---- size: what the shortest right answer costs -------------------------

%% The references' bytes and lines, and -- with a key -- their tokens, by
%% the API's own count (`count_tokens', which is free): the least a model
%% must write, before any thinking, guide or retry. A program's count is
%% the count of a one-message request holding it, less that of one holding
%% `x', so both languages carry the same framing.
tk_size(Root, Opts, Tasks) :-
    (   getenv('ANTHROPIC_API_KEY', K), K \== ''
    ->  Count = yes, use_module(library(curl))
    ;   Count = no,
        format("no ANTHROPIC_API_KEY: bytes and lines only (count_tokens needs a key)~n")
    ),
    tk_opt(Opts, model, Model),
    (   Count == yes -> tk_count(Model, x, Base) ; Base = 0 ),
    format("~w~w~w~n", ['task      ', 'python: bytes lines tokens   ', 'cocolog: bytes lines tokens']),
    foldl(tk_size_task(Root, Count, Model, Base), Tasks, t(0,0,0,0,0,0), t(B1, L1, T1, B2, L2, T2)),
    tk_size_row(total, B1, L1, T1, B2, L2, T2, Count),
    tk_size_systems(Root, Count, Model, Base).

tk_size_task(Root, Count, Model, Base, Task, t(B1, L1, T1, B2, L2, T2), t(B1n, L1n, T1n, B2n, L2n, T2n)) :-
    tk_ref_size(Root, Task, python, Count, Model, Base, Bp, Lp, Tp),
    tk_ref_size(Root, Task, cocolog, Count, Model, Base, Bc, Lc, Tc),
    tk_size_row(Task, Bp, Lp, Tp, Bc, Lc, Tc, Count),
    B1n is B1 + Bp, L1n is L1 + Lp, T1n is T1 + Tp,
    B2n is B2 + Bc, L2n is L2 + Lc, T2n is T2 + Tc.

tk_ref_size(Root, Task, Lang, Count, Model, Base, Bytes, Lines, Tokens) :-
    tk_ref(Lang, Ref),
    tk_task_path(Root, Task, Ref, Path),
    read_file_to_codes(Path, Cs),
    string_codes(S, Cs), string_bytes(S, Utf8, utf8), length(Utf8, Bytes),
    tk_lines(Cs, Ls), length(Ls, Lines),
    (   Count == yes
    ->  atom_codes(Text, Cs), tk_count(Model, Text, N), Tokens is N - Base
    ;   Tokens = 0
    ).

tk_size_row(Name, Bp, Lp, Tp, Bc, Lc, Tc, Count) :-
    tk_pad(Name, 10, N),
    tk_cols(Bp, Lp, Tp, Count, P),
    tk_cols(Bc, Lc, Tc, Count, C),
    format("~w~w   ~w~n", [N, P, C]).

tk_cols(B, L, T, Count, Text) :-
    tk_lpad(B, 13, Bs), tk_lpad(L, 6, Ls),
    ( Count == yes -> tk_lpad(T, 7, Ts) ; Ts = '      -' ),
    atomic_list_concat([Bs, Ls, Ts], Text).

%% What each arm's system prompt costs, every request.
tk_size_systems(Root, Count, Model, Base) :-
    format("~nsystem prompt, every request:~n"),
    forall(tk_arm(Arm, _),
           (   tk_system(Root, Arm, Sys),
               atom_length(Sys, Chars),
               (   Count == yes
               ->  tk_count(Model, Sys, N), T is N - Base,
                   format("  ~w ~d characters, ~d tokens~n", [Arm, Chars, T])
               ;   format("  ~w ~d characters~n", [Arm, Chars])
               )
           )).

%% ---- the prompts ------------------------------------------------------

tk_read_atom(Path, A) :- read_file_to_codes(Path, Cs), atom_codes(A, Cs).

%% The system prompt of an arm, made once a process: the card is a child
%% process's output.
tk_system(Root, Arm, Sys) :-
    atom_concat(tk_system_, Arm, Key),
    (   catch(nb_getval(Key, Sys0), _, fail)
    ->  Sys = Sys0
    ;   tk_make_system(Root, Arm, Sys),
        nb_setval(Key, Sys)
    ).

tk_make_system(Root, python, Sys) :-
    tk_path(Root, 'prompts/python.md', P), tk_read_atom(P, Sys).
tk_make_system(Root, cocolog, Sys) :-
    tk_path(Root, 'prompts/cocolog.md', P), tk_read_atom(P, Sys).
tk_make_system(Root, 'cocolog-card', Sys) :-
    tk_make_system(Root, cocolog, Base),
    tk_path(Root, 'prompts/card.md', P), tk_read_atom(P, Intro),
    sh_join(['sh ''', Root, '/tools/cocolint/tool.sh'' card --card 2>/dev/null'], Cmd),
    proc_run(Cmd, 300000, CardCs, Exit),
    (   Exit =:= 0, CardCs \== []
    ->  atom_codes(Card, CardCs)
    ;   throw(error(tk_card(Exit), tk_make_system/3))
    ),
    atomic_list_concat([Base, '\n', Intro, '\n', Card], Sys).

tk_task_prompt(Root, Task, Prompt) :-
    tk_task_path(Root, Task, 'task.md', P), tk_read_atom(P, Spec),
    tk_path(Root, 'prompts/contract.md', C), tk_read_atom(C, Contract),
    atomic_list_concat([Spec, '\n', Contract], Prompt).

%% ---- the benchmark ------------------------------------------------------

tk_bench(Root, Backend, Opts, Tasks) :-
    tk_arms(Opts, Arms),
    tk_opt(Opts, reps, Reps),
    tk_opt(Opts, out, Out),
    (   exists_file(Out) -> delete_file(Out) ; true ),
    tk_header(Root, Backend, Opts, Arms, Tasks, Header),
    tk_log(Out, Header),
    numlist(1, Reps, Rs),
    forall(( member(Rep, Rs), member(Task, Tasks), member(Arm, Arms) ),
           tk_episode(Root, Backend, Opts, Task, Arm, Rep)),
    format("log: ~w~n", [Out]),
    tk_report(Out).

tk_header(Root, Backend, Opts, Arms, Tasks, json(Pairs)) :-
    ( Backend = replay(_) -> B = replay ; B = api ),
    tk_opt(Opts, model, Model), tk_opt(Opts, effort, Effort),
    tk_opt(Opts, rounds, Rounds), tk_opt(Opts, reps, Reps),
    tk_opt(Opts, fallbacks, Fb),
    findall(A-N, ( member(A, Arms), tk_system(Root, A, S), atom_length(S, N) ), Sizes),
    sh_join(['git -C ''', Root, ''' rev-parse --short HEAD 2>/dev/null'], Git),
    proc_run(Git, 30000, GitCs, _),
    ( append(H, [10], GitCs) -> atom_codes(Commit, H) ; atom_codes(Commit, GitCs) ),
    current_prolog_flag(executable, Exe),
    sh_join(['''', Exe, ''' --version'], VerCmd),
    proc_run(VerCmd, 30000, VerCs, _),
    ( append(V, [10], VerCs) -> atom_codes(Version, V) ; atom_codes(Version, VerCs) ),
    get_time(T),
    Pairs = [kind-run, backend-B, model-Model, effort-Effort, rounds-Rounds, reps-Reps,
             fallbacks-Fb, arms-Arms, tasks-Tasks, system_chars-json(Sizes),
             commit-Commit, cocolog-Version, started-T].

%% One episode: rounds until a pass, a refusal or the last round.
tk_episode(Root, Backend, Opts, Task, Arm, Rep) :-
    tk_arm(Arm, Lang),
    tk_system(Root, Arm, System),
    tk_task_prompt(Root, Task, Prompt),
    tk_opt(Opts, rounds, Max),
    tk_opt(Opts, out, Out),
    Ctx = ctx(Root, Backend, Opts, Task, Arm, Rep, Lang, System, Out),
    tk_round(1, Max, Ctx, [json([role-user, content-Prompt])], u(0, 0, 0, 0), Result, Rounds, U),
    U = u(I, CW, CR, O),
    tk_opt(Opts, model, Model),
    tk_cost(Model, U, Cost),
    tk_log(Out, json([kind-episode, task-Task, arm-Arm, rep-Rep, result-Result, rounds-Rounds,
                      input-I, cache_write-CW, cache_read-CR, output-O, cost-Cost])),
    Total is I + CW + CR + O,
    format("~w ~w rep ~d: ~w after ~d round(s), ~d tokens~n", [Task, Arm, Rep, Result, Rounds, Total]),
    flush_output.

tk_round(K, Max, Ctx, Messages, U0, Result, Rounds, U) :-
    Ctx = ctx(Root, Backend, Opts, Task, Arm, Rep, Lang, System, Out),
    get_time(T0),
    tk_ask(Backend, Opts, System, Messages, Task-Arm-Rep-K, Reply),
    get_time(T1),
    Reply = reply(Served, Stop, Content, u(I, CW, CR, O)),
    tk_text(Content, Text),
    (   Stop == refusal
    ->  Verdict = refused
    ;   tk_code_block(Text, Code)
    ->  tk_opt(Opts, timeout, Timeout),
        tk_test(Root, Lang, Code, Task, Timeout, Verdict)
    ;   Verdict = nocode
    ),
    tk_verdict_word(Verdict, Word, Case),
    Secs is T1 - T0,
    tk_opt(Opts, model, Model),
    tk_log(Out, json([kind-call, task-Task, arm-Arm, rep-Rep, round-K, model-Model,
                      served-Served, stop-Stop, input-I, cache_write-CW, cache_read-CR,
                      output-O, verdict-Word, case-Case, secs-Secs])),
    U0 = u(I0, CW0, CR0, O0),
    I1 is I0 + I, CW1 is CW0 + CW, CR1 is CR0 + CR, O1 is O0 + O,
    U1 = u(I1, CW1, CR1, O1),
    (   Verdict = pass(_)
    ->  Result = pass, Rounds = K, U = U1
    ;   Verdict == refused
    ->  Result = refused, Rounds = K, U = U1
    ;   K >= Max
    ->  Result = fail, Rounds = K, U = U1
    ;   tk_feedback(Verdict, Stop, Feedback),
        tk_echo(Content, Echo),
        append(Messages, [json([role-assistant, content-Echo]),
                          json([role-user, content-Feedback])], Messages1),
        K1 is K + 1,
        tk_round(K1, Max, Ctx, Messages1, U1, Result, Rounds, U)
    ).

tk_verdict_word(pass(_), pass, 0).
tk_verdict_word(fail(K, _, _), fail, K).
tk_verdict_word(nocode, nocode, 0).
tk_verdict_word(refused, refused, 0).

%% The reply's text: its text blocks, in order, joined.
tk_text(Content, Text) :-
    findall(T, ( member(json(B), Content), memberchk(type-text, B), memberchk(text-T, B) ), Ts),
    atomic_list_concat(Ts, '\n', Text).

%% The first fenced block of a reply, as codes with a newline at the end.
%% A block that is never closed is a reply cut short, and no program.
tk_code_block(Text, Code) :-
    atom_codes(Text, Cs),
    split_string(Cs, "\n", "", Lines),
    append(_, [Open|After], Lines),
    string_codes(Open, [96, 96, 96|_]), !,
    append(Body, [Close|_], After),
    tk_rstrip(Close, C), string_codes(C, [96, 96, 96]), !,
    atomic_list_concat(Body, '\n', A),
    atom_codes(A, Code0),
    append(Code0, [10], Code).

%% What the model is told when a round did not pass.
tk_feedback(nocode, Stop, Feedback) :-
    (   Stop == max_tokens
    ->  Why = 'Your reply was cut off at the output limit before its code block closed.'
    ;   Why = 'Your reply had no complete fenced code block.'
    ),
    atomic_list_concat([Why, ' Reply with the whole program in one fenced code block.'], Feedback).
tk_feedback(fail(K, N, wrong(In, Want, Got, Exit, Err)), _, Feedback) :-
    tk_clip_head(In, 40, 3000, InT),
    tk_clip_head(Want, 40, 3000, WantT),
    (   Got == []
    ->  GotPart = 'Your program wrote nothing to standard output.'
    ;   tk_clip_head(Got, 40, 3000, GotT),
        format(atom(GotPart), 'Your program''s output:~n~n```text~n~w~n```', [GotT])
    ),
    (   Exit =:= 124
    ->  format(atom(How), 'It was stopped after the time limit (exit status ~d).', [Exit])
    ;   format(atom(How), 'It exited with status ~d.', [Exit])
    ),
    (   Err == []
    ->  ErrPart = ''
    ;   tk_clip_tail(Err, 30, 3000, ErrT),
        format(atom(ErrPart), 'Its standard error ended with:~n~n```text~n~w~n```~n~n', [ErrT])
    ),
    format(atom(Feedback),
           'Test ~d of ~d failed.~n~nInput:~n~n```text~n~w~n```~n~nExpected output:~n~n```text~n~w~n```~n~n~w~n~n~w~n~n~wReply with the whole corrected program.',
           [K, N, InT, WantT, GotPart, How, ErrPart]).

%% The first lines of a text, or its last, at most Chars characters, with a
%% line saying what was left out.
tk_clip_head(Cs, MaxLines, MaxChars, Text) :-
    split_string(Cs, "\n", "", Ls0),
    ( append(Ls1, [Last], Ls0), string_length(Last, 0) -> true ; Ls1 = Ls0 ),
    length(Ls1, N),
    (   N > MaxLines
    ->  length(Keep, MaxLines), append(Keep, _, Ls1),
        Dropped is N - MaxLines,
        format(atom(More), '... (~d more lines)', [Dropped]),
        append(Keep, [More], Ls2)
    ;   Ls2 = Ls1
    ),
    atomic_list_concat(Ls2, '\n', T0),
    tk_clip_chars(T0, MaxChars, Text).

tk_clip_tail(Cs, MaxLines, MaxChars, Text) :-
    reverse(Cs, R0),
    ( R0 = [10|R1] -> true ; R1 = R0 ),
    reverse(R1, Cs1),
    split_string(Cs1, "\n", "", Ls),
    length(Ls, N),
    (   N > MaxLines
    ->  Skip is N - MaxLines, length(Front, Skip), append(Front, Keep, Ls),
        format(atom(More), '... (~d lines before)', [Skip]),
        Ls2 = [More|Keep]
    ;   Ls2 = Ls
    ),
    atomic_list_concat(Ls2, '\n', T0),
    tk_clip_chars(T0, MaxChars, Text).

tk_clip_chars(T, Max, T) :- atom_length(T, L), L =< Max, !.
tk_clip_chars(T, Max, Text) :-
    sub_atom(T, 0, Max, _, Head),
    atom_concat(Head, '... (cut)', Text).

%% What goes back as the assistant's turn: the content as it came. After a
%% mid-output fallback the API's rule is to leave out the thinking and
%% tool_use blocks before the last `fallback' block; with no fallback
%% (the default) nothing is left out.
%% NOTE: library(json) reads the string "[]" as the empty list, so a text
%% block that is nothing but `[]' would come back as an array. A reply
%% asked to be a fenced code block is never that.
tk_echo(Content, Echo) :-
    (   append(Before, [json(F)|After], Content),
        memberchk(type-fallback, F),
        \+ ( member(json(G), After), memberchk(type-fallback, G) )
    ->  exclude(tk_pre_fallback, Before, Kept),
        append(Kept, [json(F)|After], Echo)
    ;   Echo = Content
    ).

tk_pre_fallback(json(B)) :-
    memberchk(type-T, B),
    memberchk(T, [thinking, redacted_thinking, tool_use]).

%% ---- the two backends ---------------------------------------------------

%% tk_ask(+Backend, +Opts, +System, +Messages, +Where, -Reply)
%% Reply = reply(ServedModel, StopReason, Content, u(In, CacheWrite, CacheRead, Out)).
tk_ask(api, Opts, System, Messages, _, Reply) :-
    tk_request(Opts, System, Messages, Body, Betas),
    json_codes(Body, BodyCs),
    tk_post(Opts, 'https://api.anthropic.com/v1/messages', Betas, BodyCs, Json),
    tk_reply(Json, Reply).
tk_ask(replay(Dir), Opts, System, Messages, Task-Arm-Rep-K, Reply) :-
    tk_request(Opts, System, Messages, Body, _),
    format(atom(ReqDir), '~w/requests', [Dir]),
    ( exists_directory(ReqDir) -> true ; make_directory(ReqDir) ),
    format(atom(ReqFile), '~w/~w.~w.~d.~d.json', [ReqDir, Task, Arm, Rep, K]),
    json_codes(Body, BodyCs),
    write_file_from_codes(ReqFile, BodyCs),
    tk_replay_text(Dir, Task, Arm, K, Text),
    tk_opt(Opts, model, Model),
    length(BodyCs, InChars), atom_length(Text, OutChars),
    I is (InChars + 3) // 4, O is (OutChars + 3) // 4,
    Reply = reply(Model, end_turn, [json([type-text, text-Text])], u(I, 0, 0, O)).

%% The reply of round K is DIR/TASK/ARM.K.txt, or the last one there is.
tk_replay_text(Dir, Task, Arm, K, Text) :-
    format(atom(F), '~w/~w/~w.~d.txt', [Dir, Task, Arm, K]),
    (   exists_file(F)
    ->  tk_read_atom(F, Text)
    ;   K > 1
    ->  K1 is K - 1, tk_replay_text(Dir, Task, Arm, K1, Text)
    ;   throw(error(existence_error(replay_reply, F), tk_replay_text/5))
    ).

%% The request body. The system prompt is one block with an explicit cache
%% breakpoint, and the top-level `cache_control' moves a second one along
%% the growing conversation: the static prefix always has a read point,
%% and so does every turn before the last. Thinking is asked for by name
%% (adaptive, the only kind the current models take) rather than left to
%% a model's default, which is not the same on every model; the effort is
%% named too (Haiku's default is lower than Opus's).
tk_request(Opts, System, Messages, json(Pairs), Betas) :-
    tk_opt(Opts, model, Model),
    tk_opt(Opts, max_tokens, MaxTokens),
    tk_opt(Opts, effort, Effort),
    Pairs0 = [model-Model, max_tokens-MaxTokens,
              system-[json([type-text, text-System, cache_control-json([type-ephemeral])])],
              messages-Messages,
              thinking-json([type-adaptive]),
              output_config-json([effort-Effort]),
              cache_control-json([type-ephemeral])],
    (   tk_opt(Opts, fallbacks, default)
    ->  append(Pairs0, [fallbacks-default], Pairs),
        Betas = ['server-side-fallback-2026-07-01']
    ;   Pairs = Pairs0,
        Betas = []
    ).

tk_key(Key) :-
    (   getenv('ANTHROPIC_API_KEY', Key), Key \== ''
    ->  true
    ;   throw(error(existence_error(environment_variable, 'ANTHROPIC_API_KEY'), tk_key/1))
    ).

%% POST with the key read at the call, never logged. A 429 or a 5xx, or a
%% transport error, is tried again after 2, 4, 8, ... seconds; any other
%% status stops the run with the body it came with, because a 400 asked
%% again is a 400 again.
tk_post(Opts, Url, Betas, BodyCs, Json) :-
    use_module(library(curl)),
    tk_key(Key),
    atom_concat('x-api-key: ', Key, KeyH),
    findall(header(H), ( member(B, Betas), atom_concat('anthropic-beta: ', B, H) ), BetaHs),
    append([header(KeyH), header('anthropic-version: 2026-10-21')|BetaHs],
           [timeout(600), max_size(16777216)], CurlOpts),
    tk_opt(Opts, retries, Retries),
    tk_post_try(0, Retries, Url, BodyCs, CurlOpts, Status, Resp),
    (   Status =:= 200
    ->  json_parse(Resp, Json)
    ;   atom_codes(A, Resp),
        throw(error(tk_api(Status, A), tk_post/5))
    ).

tk_post_try(N, Max, Url, Body, Opts, Status, Resp) :-
    (   catch(curl_post(Url, 'application/json', Body, Opts, S0, R0), E,
              ( format(user_error, "curl: ~q~n", [E]), fail ))
    ->  true
    ;   S0 = transport, R0 = []
    ),
    (   tk_retryable(S0), N < Max
    ->  Wait is 2000 << N,
        format(user_error, "status ~w, trying again in ~d ms~n", [S0, Wait]),
        proc_sleep(Wait),
        N1 is N + 1,
        tk_post_try(N1, Max, Url, Body, Opts, Status, Resp)
    ;   S0 == transport
    ->  throw(error(tk_api(transport, 'no response'), tk_post/5))
    ;   Status = S0, Resp = R0
    ).

tk_retryable(transport) :- !.
tk_retryable(S) :- integer(S), ( S =:= 429 -> true ; S >= 500 ).

tk_reply(json(Pairs), reply(Model, Stop, Content, u(I, CW, CR, O))) :-
    ( memberchk(model-Model, Pairs) -> true ; Model = unknown ),
    ( memberchk(stop_reason-Stop, Pairs) -> true ; Stop = unknown ),
    ( memberchk(content-Content, Pairs), is_list(Content) -> true ; Content = [] ),
    ( memberchk(usage-json(U), Pairs) -> true ; U = [] ),
    tk_usage(U, input_tokens, I),
    tk_usage(U, cache_creation_input_tokens, CW),
    tk_usage(U, cache_read_input_tokens, CR),
    tk_usage(U, output_tokens, O).

tk_usage(U, K, N) :- ( memberchk(K-N0, U), integer(N0) -> N = N0 ; N = 0 ).

%% count_tokens: the input tokens of a one-message request holding Text.
tk_count(Model, Text, N) :-
    json_codes(json([model-Model, messages-[json([role-user, content-Text])]]), Body),
    tk_post([], 'https://api.anthropic.com/v1/messages/count_tokens', [], Body, json(Pairs)),
    memberchk(input_tokens-N, Pairs).

%% ---- prices: dollars per million tokens ---------------------------------
%%
%% The Claude API's list prices as the claude-api skill's model table gave
%% them on 2026-10-06: input, output, a 5-minute cache write (1.25x input)
%% and a cache read. A model not here is reported in tokens only.
tk_price('claude-opus-5-5',   4.0,  20.0,  5.0,   0.20).
tk_price('claude-sonnet-5-5', 2.0,  10.0,  2.5,   0.20).
tk_price('claude-haiku-5-5',  0.10, 0.50,  0.125, 0.01).
tk_price('claude-fable-5-1',  10.0, 50.0,  12.5,  0.25).

tk_cost(Model, u(I, CW, CR, O), Cost) :-
    (   tk_price(Model, Pi, Po, Pw, Pr)
    ->  Cost is (I * Pi + O * Po + CW * Pw + CR * Pr) / 1000000
    ;   Cost = @(null)
    ).

%% ---- the log and the report ---------------------------------------------

tk_log(File, Term) :-
    json_codes(Term, Cs),
    append(Cs, [10], Line),
    append_file_from_codes(File, Line).

tk_report(File) :-
    read_file_to_codes(File, Cs),
    split_string(Cs, "\n", "", Lines),
    findall(J, ( member(L, Lines), string_length(L, N), N > 0, string_codes(L, LCs), json_parse(LCs, J) ), Js),
    (   member(json(H), Js), memberchk(kind-run, H)
    ->  tk_report_header(H)
    ;   true
    ),
    findall(e(T, A, R, Ro, I, CW, CR, O, C),
            ( member(json(P), Js), memberchk(kind-episode, P),
              memberchk(task-T, P), memberchk(arm-A, P), memberchk(result-R, P),
              memberchk(rounds-Ro, P), memberchk(input-I, P), memberchk(cache_write-CW, P),
              memberchk(cache_read-CR, P), memberchk(output-O, P), memberchk(cost-C, P) ),
            Es),
    findall(A, member(e(_, A, _, _, _, _, _, _, _), Es), As0), tk_uniq(As0, Arms),
    findall(T, member(e(T, _, _, _, _, _, _, _, _), Es), Ts0), tk_uniq(Ts0, Tasks),
    format("~ntask       arm            solved  rounds    input  cache_w   cache_r   output     total      cost$~n"),
    forall(( member(T, Tasks), member(A, Arms) ), tk_report_row(Es, T, A)),
    format("~nevery task, summed over its episodes:~n"),
    forall(member(A, Arms), tk_report_total(Es, A)),
    tk_report_ratio(Es, Arms).

tk_report_header(H) :-
    ( memberchk(backend-B, H) -> true ; B = '?' ),
    ( memberchk(model-M, H) -> true ; M = '?' ),
    ( memberchk(effort-E, H) -> true ; E = '?' ),
    ( memberchk(reps-R, H) -> true ; R = '?' ),
    ( memberchk(rounds-Ro, H) -> true ; Ro = '?' ),
    ( memberchk(cocolog-V, H) -> true ; V = '?' ),
    ( memberchk(commit-C, H) -> true ; C = '?' ),
    format("~w backend, model ~w, effort ~w, ~w rep(s), at most ~w round(s); ~w at ~w~n",
           [B, M, E, R, Ro, V, C]),
    (   B == replay
    ->  format("REPLAY: no model was asked, and every token below is a length / 4~n")
    ;   true
    ).

%% A task and arm's episodes: how many passed, and per episode the mean
%% rounds, tokens and dollars.
tk_report_row(Es, T, A) :-
    findall(x(R, Ro, I, CW, CR, O, C), member(e(T, A, R, Ro, I, CW, CR, O, C), Es), Xs),
    (   Xs == []
    ->  true
    ;   length(Xs, N),
        aggregate_all(count, member(x(pass, _, _, _, _, _, _), Xs), Passed),
        tk_means(Xs, N, MRo, MI, MCW, MCR, MO, MC),
        MT is MI + MCW + MCR + MO,
        format(atom(Solved), '~d/~d', [Passed, N]),
        tk_pad(T, 11, Tp), tk_pad(A, 14, Ap), tk_lpad(Solved, 7, Sp),
        format(atom(Rs), '~1f', [MRo]), tk_lpad(Rs, 8, Rp),
        tk_lpad_int(MI, 9, Ip), tk_lpad_int(MCW, 9, Wp), tk_lpad_int(MCR, 10, Cp),
        tk_lpad_int(MO, 9, Op), tk_lpad_int(MT, 10, Totp), tk_money(MC, Mp),
        format("~w~w~w~w~w~w~w~w~w~w~n", [Tp, Ap, Sp, Rp, Ip, Wp, Cp, Op, Totp, Mp])
    ).

tk_means(Xs, N, MRo, MI, MCW, MCR, MO, MC) :-
    aggregate_all(sum(Ro), member(x(_, Ro, _, _, _, _, _), Xs), SRo),
    aggregate_all(sum(I), member(x(_, _, I, _, _, _, _), Xs), SI),
    aggregate_all(sum(W), member(x(_, _, _, W, _, _, _), Xs), SW),
    aggregate_all(sum(R), member(x(_, _, _, _, R, _, _), Xs), SR),
    aggregate_all(sum(O), member(x(_, _, _, _, _, O, _), Xs), SO),
    (   forall(member(x(_, _, _, _, _, _, C), Xs), number(C))
    ->  aggregate_all(sum(C), member(x(_, _, _, _, _, _, C), Xs), SC), MC is SC / N
    ;   MC = none
    ),
    MRo is SRo / N, MI is SI / N, MCW is SW / N, MCR is SR / N, MO is SO / N.

%% The whole run for one arm: what every episode spent, and what that
%% comes to per task solved -- the number the question asks for.
tk_report_total(Es, A) :-
    findall(x(R, Ro, I, CW, CR, O, C), member(e(_, A, R, Ro, I, CW, CR, O, C), Es), Xs),
    length(Xs, N),
    aggregate_all(count, member(x(pass, _, _, _, _, _, _), Xs), Passed),
    aggregate_all(sum(T), ( member(x(_, _, I, W, R, O, _), Xs), T is I + W + R + O ), Tokens),
    aggregate_all(sum(O), member(x(_, _, _, _, _, O, _), Xs), Out),
    aggregate_all(sum(Ro), member(x(_, Ro, _, _, _, _, _), Xs), Rounds),
    (   forall(member(x(_, _, _, _, _, _, C), Xs), number(C))
    ->  aggregate_all(sum(C), member(x(_, _, _, _, _, _, C), Xs), Cost),
        format(atom(CostT), '$~4f', [Cost])
    ;   Cost = none, CostT = 'no price'
    ),
    (   Passed > 0
    ->  PerTok is Tokens // Passed,
        (   number(Cost) -> PerCost is Cost / Passed, format(atom(PerC), '$~4f', [PerCost])
        ;   PerC = 'no price'
        ),
        format(atom(Per), '~d tokens and ~w per task solved', [PerTok, PerC])
    ;   Per = 'nothing solved'
    ),
    tk_pad(A, 14, Ap),
    format("  ~w solved ~d of ~d in ~d rounds: ~d tokens (~d output), ~w; ~w~n",
           [Ap, Passed, N, Rounds, Tokens, Out, CostT, Per]).

%% Each cocolog arm against python: tokens per task solved, and dollars.
tk_report_ratio(Es, Arms) :-
    (   memberchk(python, Arms), tk_per_solved(Es, python, Tp, Cp), Tp > 0
    ->  format("~nagainst python, per task solved:~n"),
        forall(( member(A, Arms), A \== python ),
               (   tk_per_solved(Es, A, Ta, Ca), Ta > 0
               ->  Rt is Ta / Tp,
                   (   number(Ca), number(Cp), Cp > 0
                   ->  Rc is Ca / Cp, format(atom(RcT), '~2fx the dollars', [Rc])
                   ;   RcT = 'no price'
                   ),
                   format("  ~w ~2fx the tokens, ~w~n", [A, Rt, RcT])
               ;   format("  ~w solved nothing~n", [A])
               ))
    ;   true
    ).

tk_per_solved(Es, A, PerTok, PerCost) :-
    findall(x(R, I, W, Ca, O, C), member(e(_, A, R, _, I, W, Ca, O, C), Es), Xs),
    aggregate_all(count, member(x(pass, _, _, _, _, _), Xs), Passed),
    Passed > 0,
    aggregate_all(sum(T), ( member(x(_, I, W, Ca, O, _), Xs), T is I + W + Ca + O ), Tokens),
    PerTok is Tokens / Passed,
    (   forall(member(x(_, _, _, _, _, C), Xs), number(C))
    ->  aggregate_all(sum(C), member(x(_, _, _, _, _, C), Xs), Cost), PerCost is Cost / Passed
    ;   PerCost = none
    ).

tk_uniq(Xs, Ys) :- tk_uniq(Xs, [], Ys).
tk_uniq([], Acc, Ys) :- reverse(Acc, Ys).
tk_uniq([X|Xs], Acc, Ys) :- ( memberchk(X, Acc) -> tk_uniq(Xs, Acc, Ys) ; tk_uniq(Xs, [X|Acc], Ys) ).

%% ---- columns: format/2 has no ~t or ~| here (cocolint F1) ---------------

tk_pad(X, W, Out) :-
    format(atom(A), '~w', [X]), atom_length(A, L),
    ( L >= W -> atom_concat(A, ' ', Out) ; N is W - L, tk_spaces(N, S), atom_concat(A, S, Out) ).

tk_lpad(X, W, Out) :-
    format(atom(A), '~w', [X]), atom_length(A, L),
    ( L >= W -> atom_concat(' ', A, Out) ; N is W - L, tk_spaces(N, S), atom_concat(S, A, Out) ).

tk_lpad_int(X, W, Out) :- I is round(X), tk_lpad(I, W, Out).

tk_money(none, '      none') :- !.
tk_money(C, Out) :- format(atom(A), '~4f', [C]), tk_lpad(A, 11, Out).

tk_spaces(N, S) :- length(L, N), maplist(=(32), L), atom_codes(S, L).
