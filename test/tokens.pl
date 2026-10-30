%% The token benchmark's harness still does what bench/tokens/README.md says.
%%
%% bench/tokens.pl asks a model to write each task's program, runs what it
%% wrote on the task's cases and sends the first failure back, round after
%% round, counting what every call costs. A live run needs a key and spends
%% money, so nothing here asks a model: what is held is the part a run
%% stands on, which goes wrong quietly if it goes wrong at all --
%%
%%   * every task's two references, Python's and cocolog's, pass every one of
%%     its cases: the cases are the yardstick, and a case that its own
%%     reference fails would score every model's right answer as wrong;
%%   * the loop, through the replay backend, which answers each round from a
%%     file: a wrong program is told its first failing case and passes in
%%     round 2, a reply with no closed code block is told so, a program that
%%     raises is shown its standard error, and the rounds stop at the limit;
%%   * the request it would send: the cache breakpoints, the thinking and
%%     effort it names, the assistant's reply echoed as it came, the card in
%%     the card arm's system prompt, and no fallback unless asked;
%%   * the echo rule after a fallback, and the code block a reply's text is
%%     read for, as the harness's own predicates answer them.
%%
%% It needs python3, as test/langs.pl does, and SKIPs without one.
%%
%%     cocolog -s test/tokens.pl        from the checkout root

:- use_module('test/prelude.pl').
:- use_module(library(json)).

main :-
    (   shell('command -v python3', _, 0) -> true
    ;   skip('no python3 -- the token benchmark runs both languages')
    ),
    scratch(D),
    references,
    replay(D),
    fallback(D),
    pieces(D),
    shl(['rm -rf ', D]),
    checks_done.

%% ---- every reference passes every case ----------------------------------

references :-
    section('the references'),
    cocolog_run('-s bench/tokens.pl -- check 2>&1', T1, E1),
    check('check exits 0', E1, 0),
    atomic_list_concat(Ls1, '\n', T1),
    length(Ls1, N1),
    check('check names the ten tasks', N1, 10),
    (   sub_atom(T1, _, _, _, 'FAIL') -> F1 = T1 ; F1 = none ),
    check('no reference fails a case', F1, none).

%% ---- the loop, from files -------------------------------------------------

%% Round 1 of each arm, and round 2 where there is one: python writes the
%% input back and is then given its reference; cocolog leaves its code block
%% open (a reply cut short) and is then given its reference; the card arm
%% raises in round 1 and has no round 2, so its reply is used again until
%% the rounds run out.
replay(D) :-
    section('the loop'),
    atom_concat(D, '/r', R),
    atom_concat(R, '/rle', RT),
    shl(['mkdir -p ', RT]),
    root(Root),
    atom_concat(Root, '/bench/tokens/tasks/rle/', Src),
    fence(python, [ 'import sys',
                    'for line in sys.stdin:',
                    '    print(line.split(" ", 1)[1].rstrip("\\n"))' ], RT, 'python.1.txt'),
    atom_concat(Src, 'ref.py', Py), read_lines(Py, PyLs),
    fence(python, PyLs, RT, 'python.2.txt'),
    atom_concat(RT, '/cocolog.1.txt', Open),
    fixture(Open, [ 'Here is the program:', '', '```prolog', 'main :- write(hello), nl.' ]),
    atom_concat(Src, 'ref.pl', Pl), read_lines(Pl, PlLs),
    fence(prolog, PlLs, RT, 'cocolog.2.txt'),
    fence(prolog, [ 'main :- X is foo + 1, write(X), nl.' ], RT, 'cocolog-card.1.txt'),
    sh_join(['-s bench/tokens.pl -- replay ', R, ' reps=1 rle 2>&1'], A2),
    cocolog_run(A2, T2, E2),
    check('a replay exits 0', E2, 0),
    has('the report says no model was asked', 'REPLAY: no model was asked', T2),
    has('the report sets each cocolog arm against python', 'against python, per task solved', T2),
    atom_concat(R, '/replay.jsonl', Log),
    log_kind(Log, episode, Eps),
    findall(Arm-Res-Ro, ( member(E, Eps), memberchk(arm-Arm, E), memberchk(result-Res, E),
                          memberchk(rounds-Ro, E) ), Got3),
    check('python passes in round 2, cocolog in round 2, the card arm fails all 4',
          Got3, [python-pass-2, cocolog-pass-2, 'cocolog-card'-fail-4]),
    log_kind(Log, call, Calls),
    findall(K-V, ( member(C, Calls), memberchk(round-K, C), memberchk(verdict-V, C),
                   memberchk(arm-python, C) ), Got4),
    check('python''s two calls: a failed case, then a pass', Got4, [1-fail, 2-pass]),
    findall(V, ( member(C, Calls), memberchk(arm-cocolog, C), memberchk(round-1, C),
                 memberchk(verdict-V, C) ), Got5),
    check('a code block never closed is no program', Got5, [nocode]),
    atom_concat(R, '/requests', Req),
    directory_files(Req, Fs6),
    include([F]>>sub_atom(F, _, _, 0, '.json'), Fs6, Js6),
    length(Js6, N6),
    check('a request is written for every round (2 + 2 + 4)', N6, 8),
    request(Req, 'rle.python.1.2.json', P7),
    shape(P7),
    memberchk(messages-Ms7, P7),
    findall(Role, ( member(json(M), Ms7), memberchk(role-Role, M) ), Roles7),
    check('round 2 is the task, the reply, the failure', Roles7, [user, assistant, user]),
    Ms7 = [_, json(A7), json(U7)],
    memberchk(content-Echo7, A7),
    atom_concat(RT, '/python.1.txt', P1),
    read_file_to_codes(P1, Want7c), atom_codes(Want7, Want7c),
    check('the reply goes back as the block it came as',
          Echo7, [json([type-text, text-Want7])]),
    memberchk(content-Fb7, U7),
    (   sub_atom(Fb7, 0, _, _, 'Test 1 of 5 failed.') -> S7 = yes ; S7 = Fb7 ),
    check('the failure names its case and the count', S7, yes),
    has('the failure shows the output wanted', 'Expected output:', Fb7),
    request(Req, 'rle.cocolog.1.2.json', P8),
    memberchk(messages-[_, _, json(U8)], P8),
    memberchk(content-Fb8, U8),
    has('a reply with no closed block is told so', 'no complete fenced code block', Fb8),
    request(Req, 'rle.cocolog-card.1.2.json', P9),
    memberchk(messages-[_, _, json(U9)], P9),
    memberchk(content-Fb9, U9),
    has('a program that raised is shown its standard error', 'Its standard error ended with:', Fb9),
    has('and that it wrote nothing', 'Your program wrote nothing to standard output.', Fb9),
    system_text(P8, Plain10), system_text(P9, Card10),
    atom_length(Plain10, L10a), atom_length(Card10, L10b),
    (   L10b - L10a > 5000, sub_atom(Card10, 0, _, _, Plain10) -> G10 = yes ; G10 = L10a/L10b ),
    check('the card arm''s system prompt is the plain one with the card after it', G10, yes),
    request(Req, 'rle.cocolog-card.1.4.json', P11),
    memberchk(messages-Ms11, P11),
    length(Ms11, N11),
    check('round 4 carries every turn before it', N11, 7).

%% A reply file: the lines in a fenced block of the language named.
fence(Lang, Lines, Dir, Name) :-
    atom_concat('```', Lang, Open),
    append([Open|Lines], ['```'], All),
    atomic_list_concat([Dir, '/', Name], Path),
    fixture(Path, All).

read_lines(Path, Lines) :-
    read_file_to_codes(Path, Cs),
    split_string(Cs, "\n", "", Ss0),
    (   append(Ss, [Last], Ss0), string_length(Last, 0) -> true ; Ss = Ss0 ),
    maplist([S, A]>>atom_string(A, S), Ss, Lines).

%% The log's lines of one kind, each the pairs of its object.
log_kind(Log, Kind, Pairs) :-
    read_file_to_codes(Log, Cs),
    split_string(Cs, "\n", "", Ls),
    findall(P, ( member(L, Ls), string_length(L, N), N > 0, string_codes(L, LCs),
                 json_parse(LCs, json(P)), memberchk(kind-Kind, P) ), Pairs).

request(Dir, Name, Pairs) :-
    atomic_list_concat([Dir, '/', Name], Path),
    read_file_to_codes(Path, Cs),
    json_parse(Cs, json(Pairs)).

system_text(Pairs, Text) :-
    memberchk(system-[json(B)], Pairs),
    memberchk(text-Text, B).

%% What every request asks for, whichever the round.
shape(P) :-
    findall(K, member(K-_, P), Ks),
    check('a request names exactly these fields', Ks,
          [model, max_tokens, system, messages, thinking, output_config, cache_control]),
    field(P, system, Sys),
    (   Sys = [json(B)], memberchk(cache_control-json([type-ephemeral]), B) -> Gs = yes ; Gs = Sys ),
    check('the system prompt is one block with a cache breakpoint', Gs, yes),
    field(P, cache_control, Top),
    check('a second breakpoint moves along the conversation', Top, json([type-ephemeral])),
    field(P, thinking, Th),
    check('thinking is asked for by name', Th, json([type-adaptive])),
    field(P, output_config, Oc),
    check('so is the effort', Oc, json([effort-high])),
    field(P, model, Mo),
    check('the default model', Mo, 'claude-opus-5-5').

%% a field of a request, or `missing', so that a field gone is a FAIL line
field(P, K, V) :- ( memberchk(K-V0, P) -> V = V0 ; V = missing ).

%% ---- a fallback only when asked -------------------------------------------

fallback(D) :-
    section('the fallback'),
    atom_concat(D, '/r', R),
    atom_concat(D, '/fallback.jsonl', Out),
    sh_join(['-s bench/tokens.pl -- replay ', R, ' reps=1 arms=python fallbacks=default out=',
             Out, ' rle 2>&1'], A1),
    cocolog_run(A1, _, E1),
    check('a replay with fallbacks=default exits 0', E1, 0),
    atom_concat(R, '/requests', Req),
    request(Req, 'rle.python.1.1.json', P2),
    (   memberchk(fallbacks-F2, P2) -> true ; F2 = none ),
    check('fallbacks=default asks for the API''s fallback', F2, default),
    log_kind(Out, run, [H3]),
    memberchk(fallbacks-F3, H3),
    check('and the run says so in its header', F3, default).

%% ---- the harness's own predicates -------------------------------------

%% Asked of a child that loads bench/tokens.pl as a module: its main/0 is
%% not this case's, and a child keeps the two apart. The probes are a file
%% of the child's own, not a goal on its command line, because a fence's
%% backquotes are command substitution to the shell (and no syntax at all to
%% cocolog, card E1: the probe makes them from their code, 96).
pieces(D) :-
    section('the pieces'),
    root(Root),
    atom_concat(Root, '/bench/tokens.pl', Bench),
    format(atom(Load), ':- use_module(''~w'').', [Bench]),
    atom_concat(D, '/probe.pl', Probe),
    fixture(Probe,
            [ Load,
              'fence(T) :- atom_codes(T, [96, 96, 96]).',
              'probe(echo, E) :- tk_echo([json([type-thinking, thinking-a]), json([type-text, text-b])], E).',
              'probe(fallback, E) :- tk_echo([json([type-thinking, thinking-a]), json([type-text, text-b]), json([type-fallback]), json([type-thinking, thinking-c]), json([type-text, text-d])], E).',
              'probe(first, E) :- fence(F), atomic_list_concat([''say\\n'', F, ''prolog\\nmain.\\n'', F, ''\\nmore\\n'', F, ''x\\n'', F], T), ( tk_code_block(T, C) -> atom_codes(E, C) ; E = none ).',
              'probe(open, E) :- fence(F), atom_concat(F, ''\\nmain.'', T), ( tk_code_block(T, C) -> E = C ; E = none ).',
              'probe(blanks, E) :- atom_codes(''a  \\nb\\n\\n'', A), atom_codes(''a\\nb'', B), ( tk_same(A, B) -> E = same ; E = differ ).',
              'probe(between, E) :- atom_codes(''a\\n\\nb\\n'', A), atom_codes(''a\\nb\\n'', B), ( tk_same(A, B) -> E = same ; E = differ ).',
              'probe(cost, E) :- tk_cost(''claude-opus-5-5'', u(1000000, 0, 0, 1000000), E).' ]),
    sh_join(['--local run ', Probe, ' "forall(probe(K, E), ( writeq(answer(K, E)), nl ))" 2>&1'], Args),
    cocolog_run(Args, Out, Exit),
    check('the probes run', Exit, 0),
    atomic_list_concat(Lines, '\n', Out),
    findall(K-E, ( member(L, Lines), catch(term_to_atom(T, L), _, fail), T = answer(K, E) ), Got),
    probe_is(Got, echo, [json([type-thinking, thinking-a]), json([type-text, text-b])],
             'with no fallback block the reply goes back whole'),
    probe_is(Got, fallback, [json([type-text, text-b]), json([type-fallback]),
                             json([type-thinking, thinking-c]), json([type-text, text-d])],
             'after a fallback, the thinking before it is left out and the text kept'),
    probe_is(Got, first, 'main.\n', 'the first fenced block is the program, a newline after it'),
    probe_is(Got, open, none, 'a block never closed is none'),
    probe_is(Got, blanks, same, 'blanks at a line''s end and empty lines at the end do not count'),
    probe_is(Got, between, differ, 'an empty line between two does'),
    probe_is(Got, cost, 24.0, 'a million in and a million out on Opus 5.5 is $24').

probe_is(Got, K, Want, Label) :-
    ( memberchk(K-V, Got) -> true ; V = missing ),
    check(Label, V, Want).
