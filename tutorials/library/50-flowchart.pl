%% LIBRARY 50 -- library(flow/chart): a predicate drawn from the query down to
%% the C it reaches, and back, as an SVG for a person and an XML for an agent
%%
%%     ./cocolog run tutorials/library/50-flowchart.pl main
%%
%% TIER 2: `use_module(library(flow/chart))', clauses in library/flow/chart.pl
%% and library/flow/, over library(stream) (`sh modules/stream/build.sh').
%% Its tables -- which C function answers each name, with what modes -- are
%% written by `make modules' (sh tools/flow/build.sh).
%%
%%     flow_chart(+Spec, +Base)             Base.svg and Base.xml
%%     flow_chart(+Spec, +Base, +Options)   source(File), title(T), libraries(none|reach|all),
%%                                          depth(D), only(Preds) -- these two for the picture,
%%                                          load(Files) -- a program's other files, loaded
%%                                          first -- modules(Files), the Cicili sources of
%%                                          its own modules, and progress(S): a line on
%%                                          stderr every S seconds of a long chart
%%     flow_graph(+Spec, -Graph, +Options)  the analysis as a term
%%     flow_findings(+Graph, -Findings)     what is wrong, and where
%%     flow_svg(+Graph, -Svg)   flow_xml(+Graph, -Xml)      the documents as terms
%%
%% Spec is a call pattern -- count(+, -) -- or Name/Arity, or Name//Arity for
%% a nonterminal called to parse. It is NOT A DEBUGGER: nothing is run. The
%% program is READ, with its variable names and where each goal stands, and
%% analysed for the call pattern: which variables each goal finds bound (the
%% MODES, + - ? on every argument), how each predicate can end (det, semidet,
%% nondet, or never succeeds), and where every failure goes. A predicate met
%% with two call patterns gets a panel for each. A grammar rule is drawn as
%% the predicate it stands for, through the engine's own translator. A C
%% function is the end of the chart -- a portal, named with its module, its C
%% function and its table row -- and never looked inside.
%%
%% THE XML SAYS WHAT THE PICTURE DOES, for a program: every goal with its
%% file, line and column, its modes, can_fail and choice, the panel it calls
%% and on_fail -- the id of the goal tried again, next_clause, or fail -- and
%% each one's id is the id of its box in the SVG. tools/flow/chart.pl is the
%% same from a shell: `cocolog -s tools/flow/chart.pl -- SPEC FILE BASE'.
%%
%% IT FINDS WHAT IS WRONG, AND WHERE: a call nothing answers, a call the
%% engine refuses with an argument unbound on every path to it, a predicate
%% that calls itself again first with nothing gained, a clause never tried,
%% a `%! p(...) is det' the code does not keep, a predicate's clauses apart
%% in the file or defined twice -- each a numbered red disc
%% on its box, a line under the chart, a <finding> at the head of the XML,
%% and a line from tools/flow/chart.pl as a compiler writes one.
%%
%% IT SHOWS WHERE THE CODE RUNS: a thread, a pool, an isolated proof, a
%% cowork crew (a job, or cowork_map/3's list of them) and an httpd pool
%% each start a LANE -- a band of the picture with its own panels -- while
%% an httpd server with no pool runs its pages here. What crosses between
%% lanes is drawn and listed: what a spawn copies and what comes back,
%% joins, a channel's sends and receives tied across the lanes, locks, child
%% processes and writes to the knowledge base. A channel or a handle is
%% followed wherever the program takes it -- into a call, back out of one,
%% inside a term, down another channel -- and the k-th send of a channel is
%% tied to the k-th receive where that order can be read. A thread never
%% joined, a lock with a way out that keeps it, and a lane reading what only
%% another lane writes are findings.
%%
%% EVERY GOAL IS DRAWN, builtins too: a test, a unification, a builtin and
%% a library call are each a box with its own text on its clause's line,
%% and the chart never goes inside one -- a builtin is C in the engine, and
%% a library predicate is opened into a panel only when libraries(reach)
%% or libraries(all) asks. A BIG PROGRAM IS DRAWN IN PART and analysed in
%% full: past 150 panels the picture stops at the depth that fits,
%% depth(D) and only(Preds) choose another part, and a panel left out is a
%% stub that says how much hangs from it. The XML always has everything.

:- use_module(library(flow/chart)).
:- use_module(library(stream)).
:- use_module(library(xml)).

main :-
    Dir = '/tmp/cocolog-flowchart-lesson',
    ( exists_directory(Dir) -> true ; make_directory(Dir) ),
    atom_concat(Dir, '/words.pl', Prog),
    atom_concat(Dir, '/count', Base),
    program(Lines),
    open(Prog, write, W),
    forall(member(L, Lines), format(W, "~w~n", [L])),
    close(W),

    format("~n-- one call, two files~n"),
    flow_chart(count('+', '-'), Base, [source(Prog)]),
    atom_concat(Base, '.svg', Svg), atom_concat(Base, '.xml', Xml),
    ( exists_file(Svg), exists_file(Xml) -> Both = yes ; Both = no ),
    must('the picture and the XML are both written', Both, yes),

    format("~n-- what each predicate is, as count(+, -) meets it~n"),
    flow_graph(count('+', '-'), Graph, [source(Prog)]),
    Graph = graph(Title, _, Panels, _, _),
    must('the title is the moded head, named as the comment names it', Title, 'count(+Text, -N)'),
    findall(K-CM-D, ( member(panel(I, K, _, CM, _, _, D, _), Panels), I > 0 ), Ps),
    must('each panel: what it is, its call pattern, how it can end', Ps,
         [count/2-['+', '-']-semidet,
          ws/3-['-', '+', '+']-semidet,
          blanks/2-['+', '-']-det,
          word/3-['-', '+', '-']-semidet,
          blanks/2-['+', '+']-semidet,
          word_rest/3-['-', '+', '-']-det]),
    %% blanks//0 has two panels: ws//1's first clause calls it to read
    %% what blanks there are (+, -: it cannot fail), its second to read the
    %% REST of the text as blanks (+, +: phrase/2 left [] for what is left).
    %% So count/2 is semidet, which its comment promises it is not -- `is
    %% det' -- and a character that is neither a letter nor a blank ends
    %% the parse with no answer. The chart said so before anything ran;
    %% running it agrees.
    use_module(Prog),
    ( count("two words", N1) -> true ; N1 = none ),
    must('count("two words", N)', N1, 2),
    ( count("a 1", _) -> F1 = yes ; F1 = no ),
    must('count("a 1", N) has an answer', F1, no),

    format("~n-- what the chart finds: a promise the code does not keep~n"),
    %% a finding names its kind, the place it is about (p1, count/2's
    %% panel) and what is wrong, in a sentence: here the `is det' of the
    %% comment against the analysis, and the goal that breaks it
    flow_findings(Graph, Fs),
    findall(K-At, member(finding(_, K, _, At, _, _, _, _), Fs), KAs),
    must('one finding: count/2 breaks the det its comment promises', KAs, [det_promise-p1]),
    Fs = [finding(_, _, _, _, _, _, FText, _)],
    must('and what breaks it', FText,
         'count/2 is documented as det (line 3) but can fail: when phrase(ws(Ws), Text) fails, so does the whole call'),

    format("~n-- the XML, which is what an agent reads~n"),
    read_file_to_codes(Xml, XC),
    xml_parse(XC, X),
    goal_attr(X, 'p1.c1.g1', text, T1),
    goal_attr(X, 'p1.c1.g1', line, L1),
    must('count/2''s first goal, and the line it is on', T1-L1, 'phrase(ws(Ws), Text)'-'5'),
    goal_attr(X, 'p4.c1.g1', on_fail, F2),
    must('when word//1''s { code_type } test fails, the call fails: nothing before it can redo', F2, fail),
    goal_attr(X, 'p2.c1.g2', on_fail, F3),
    must('when ws//1''s word fails, its next clause is tried: blanks//0 left no choice', F3, next_clause),
    goal_attr(X, 'p2.c1.g5', on_fail, F4),
    must('past the cut, a failure fails the whole call', F4, fail),
    goal_attr(X, 'p2.c1.g2', dcg, D3),
    must('a goal from a grammar body says what it was there', D3, 'nonterminal word//1'),

    format("~n-- and the SVG names the same goal the same way~n"),
    read_file_to_codes(Svg, SC),
    xml_parse(SC, S),
    ( has_id(S, 'p2.c1.g2') -> Boxed = yes ; Boxed = no ),
    must('the box for p2.c1.g2 is in the picture', Boxed, yes),

    format("~n-- the picture can be cut short; the XML cannot~n"),
    atom_concat(Dir, '/count1', Base1),
    flow_chart(count('+', '-'), Base1, [source(Prog), depth(1)]),
    atom_concat(Base1, '.xml', Xml1),
    read_file_to_codes(Xml1, XC1),
    ( XC1 == XC -> SameX = yes ; SameX = no ),
    must('depth(1) leaves the XML as it was', SameX, yes),
    atom_concat(Base1, '.svg', Svg1),
    read_file_to_codes(Svg1, SC1),
    xml_parse(SC1, S1),
    ( has_text(S1, 'not drawn: deeper than depth(1)') -> Stub = yes ; Stub = no ),
    must('ws//1, which count/2 calls, is a stub in the picture', Stub, yes),

    format("~n-- every goal is drawn, and the chart does not go inside a builtin~n"),
    %% word//1 is word([C|Cs]) --> [C], { code_type(C, alpha) }, word_rest(Cs):
    %% its body is the test, the list passed on (S1 = S0), and the call
    svg_title(S, 'p4.c1.g1', T5),
    must('word//1''s code_type/2 test is a box of its own', T5,
         'code_type(C, alpha)  --  builtin, C in the engine, semidet'),
    svg_title(S, 'p4.c1.g2', T6),
    must('and so is the list the grammar passes on', T6, 'S1 = S0  --  unification, det'),
    svg_title(S, 'p1.c1.g2', T7),
    %% (a C row of the compiled-in lists module since 1.12.2, where it was
    %% library(lists)'s clauses: a builtin to the chart)
    must('length/2 is a box in count/2''s clause, and no panel of its own', T7,
         'length(Ws, N)  --  builtin, C in the engine, det'),

    apart(Dir),
    twice(Dir),
    tables(Dir),
    threads(Dir),
    asking(Dir),

    format("~ndone~n").

%% WHAT A PROGRAM MAKES AS IT RUNS, AND ITS OWN C. A table declared in a
%% clause -- dynamic/1 with its name written out, an assert, or a declarer of
%% the program's own called with the name -- is a dynamic predicate's to the
%% chart, not an unknown procedure. A call nothing answers under a catch/3
%% that takes its existence error is a warning: the recovery runs in its
%% place. And modules(Files) reads a module's Cicili source: each row of its
%% table is a C predicate, with the modes its header gives.
tables(Dir) :-
    format("~n-- what the program makes as it runs, and its own C~n"),
    atom_concat(Dir, '/tables.pl', Prog),
    atom_concat(Dir, '/native.cicili', Mod),
    open(Prog, write, W),
    forall(member(L, [ 'reset(F/A) :- ( catch(abolish(F/A), _, true) -> true ; true ), dynamic(F/A).',
                       'start :- reset(seen/1), assertz(hits(0)).',
                       'go(X, T) :- start, \\+ seen(X), hits(_), catch(cached(X, T), _, fail).',
                       'go(X, T) :- lex(X, T).' ]),
           format(W, "~w~n", [L])),
    close(W),
    open(Mod, write, WM),
    forall(member(L, [ ';;;; native -- a module of the program''s own, as its Cicili source',
                       ';;;;   lex(+Text, -Tokens)',
                       '(DEFPARAMETER *native-predicates*',
                       '  ''(("lex" 2 native_p_lex)))' ]),
           format(WM, "~w~n", [L])),
    close(WM),
    flow_graph(go('+', '-'), G0, [source(Prog)]),
    flow_findings(G0, Fs0),
    findall(Sev-Text, ( member(finding(_, unknown_procedure, Sev, _, _, _, T0, _), Fs0),
                        once(sub_atom(T0, B0, _, _, ' is defined nowhere')),
                        sub_atom(T0, 0, B0, _, Text) ), Un0),
    must('seen/1 and hits/1 are declared as it runs; cached/2 is caught, a warning; lex/2 nobody''s',
         Un0, [warning-'cached/2', error-'lex/2']),
    flow_graph(go('+', '-'), G1, [source(Prog), modules([Mod])]),
    flow_findings(G1, Fs1),
    findall(Sev-K, member(finding(_, K, Sev, _, _, _, _, _), Fs1), Ks1),
    must('modules([native.cicili]): lex/2 is the module''s C', Ks1, [warning-unknown_procedure]),
    flow_t_portal(native, lex, 2, CF, _, _, Ms, Ns),
    must('...its C function, and the modes and names its header gives', CF-Ms-Ns,
         native_p_lex-['+', '-']-['Text', 'Tokens']).

%% DEFINED TWICE, AND A PROGRAM OF SEVERAL FILES. A later place that defines
%% a predicate again -- a clause repeating one of an earlier place's, or a
%% head an earlier fact covers -- is an error where clauses merely apart are
%% a warning: the second definition never answers first, and every answer it
%% gives comes again on backtracking. And a file of a program is charted
%% with the files the program loads beside it, load(Files): a call into a
%% sibling is then a library's box, not an unknown procedure.
twice(Dir) :-
    format("~n-- defined twice, and a program of several files~n"),
    atom_concat(Dir, '/twice.pl', Prog),
    open(Prog, write, W),
    forall(member(L, [ 'len([], 0).',
                       'len([_|T], N) :- len(T, M), N is M + 1.',
                       '',
                       'show(N) :- format("~w~n", [N]).',
                       'len([], 0).' ]),
           format(W, "~w~n", [L])),
    close(W),
    flow_graph(len('+', '-'), G, [source(Prog)]),
    flow_findings(G, Fs),
    findall(K-In, member(finding(_, K, _, _, In, _, _, _), Fs), KIs),
    must('len/2''s third clause repeats its first: defined twice, an error', KIs,
         [defined_twice-'len/2']),
    atom_concat(Dir, '/helper.pl', Helper),
    atom_concat(Dir, '/user.pl', User),
    open(Helper, write, WH), format(WH, "double(X, Y) :- Y is X * 2.~n", []), close(WH),
    open(User, write, WU), format(WU, "quad(X, Y) :- double(X, Z), Y is Z * 2.~n", []), close(WU),
    flow_graph(quad('+', '-'), G1, [source(User)]),
    flow_findings(G1, Fs1),
    findall(K1, member(finding(_, K1, _, _, _, _, _, _), Fs1), Ks1),
    must('user.pl read alone: double/2 is nobody''s', Ks1, [unknown_procedure]),
    flow_graph(quad('+', '-'), G2, [source(User), load([Helper])]),
    flow_findings(G2, Fs2),
    must('with load([Helper]): double/2 is defined, and nothing is wrong', Fs2, []).

%% CLAUSES NOT TOGETHER. cocolog joins the clauses of a predicate wherever
%% they stand in the file, without a word (SWI warns at load), so a clause
%% meant for something else that is given a name already taken joins that
%% predicate -- and is tried with it. The chart says so, at the first clause
%% that stands apart; `:- discontiguous(sum/3).' says it is meant.
apart(Dir) :-
    format("~n-- clauses not together~n"),
    atom_concat(Dir, '/apart.pl', Prog),
    open(Prog, write, W),
    forall(member(L, [ 'total(Xs, T) :- sum(Xs, 0, T).',
                       'sum([], T, T).',
                       'sum([X|Xs], A, T) :- A1 is A + X, sum(Xs, A1, T).',
                       '',
                       'show(T) :- format("~w~n", [T]).',
                       'sum(none, T, T).' ]),
           format(W, "~w~n", [L])),
    close(W),
    flow_graph(total('+', '-'), G, [source(Prog)]),
    flow_findings(G, Fs),
    findall(K-At-Wh, member(finding(_, K, _, At, _, Wh, _, _), Fs), KAs),
    must('one finding: sum/3''s third clause stands apart, after show/1''s', KAs,
         [(discontiguous)-'p2.c3'-where(Prog, 6, 1)]).

%% WHERE THE CODE RUNS. A spawn is a fork: its goal goes, a copy, to a LANE
%% of its own -- a band of the picture, a <lane> of the XML -- and nothing
%% it binds comes back but what the spawn itself hands back. What crosses
%% between lanes is a LINK, each with an id: a spawn and a join, a channel
%% followed from channel_new/1 into the thread it was copied to, a lock, a
%% child process, a write to the knowledge base. Nothing is run here either:
%% the threads are charted, never started.
threads(Dir) :-
    format("~n-- where the code runs: a lane for each place, a link for what crosses~n"),
    atom_concat(Dir, '/jobs.pl', Prog),
    jobs(Lines),
    open(Prog, write, W),
    forall(member(L, Lines), format(W, "~w~n", [L])),
    close(W),
    flow_graph(run('+'), G, [source(Prog)]),
    flow_xml(G, X),
    findall(L1-K1-G1-C1, ( element_attrs(X, lane, A1), memberchk(id=L1, A1), L1 \== l0,
                           memberchk(kind=K1, A1), memberchk(goal=G1, A1), memberchk(copies=C1, A1) ), Ls),
    must('two threads, two lanes: the goal each is sent, and what it copies from run/1''s clause', Ls,
         [l1-thread-'worker(Ch)'-'Ch', l2-thread-ticker-nothing]),
    %% send_all/2 is handed the channel as an argument, worker/1 by the copy
    %% thread_create/2 made of worker(Ch): the analysis follows it into both
    findall(Op-At, ( element_attrs(X, channel, A2), memberchk(id=ch1, A2), element_op(X, ch1, Op, At) ), Ops),
    must('one channel, ch1, closed in run/1, sent to in send_all/2, received from in the worker''s lane', Ops,
         [close-'p1.c1.g5', send-'p2.c2.g1', receive-'p4.c1.g1']),
    goal_attr(X, 'p1.c1.g6', joins, J3),
    must('thread_join/2 joins lane l1, and reads its status, never its bindings', J3, l1),
    flow_findings(G, Fs),
    findall(K4-At4, member(finding(_, K4, _, At4, _, _, _, _), Fs), KAs),
    must('the ticker is never joined nor detached: the one finding', KAs, [thread_unjoined-'p1.c1.g3']).

%% WHAT IS FOLLOWED. A channel or a thread's handle is followed wherever
%% the program takes it: down into what it is handed to, back up out of the
%% predicate that made it, inside a term, and down another channel. So a
%% join in another clause than its spawn's still knows its lane, and a
%% channel sent along with a question is followed into the thread that
%% answers on it. And where one lane sends on a channel and one receives,
%% each in an order the chart can read, the k-th send is the k-th
%% receive's: the chart says which (n=) and ties those two alone.
asking(Dir) :-
    format("~n-- what is followed: handles and channels through heads, terms and other channels~n"),
    atom_concat(Dir, '/ask.pl', Prog),
    ask(Lines),
    open(Prog, write, W),
    forall(member(L, Lines), format(W, "~w~n", [L])),
    close(W),
    flow_graph(ask('+', '-'), G, [source(Prog)]),
    flow_xml(G, X),
    goal_attr(X, 'p1.c1.g6', joins, J1),
    must('ask/2''s join waits for the thread start/2 made: the handle came back up out of start/2', J1, l1),
    findall(Op2-At2, element_op(X, ch2, Op2, At2), Ops2),
    must('Req, made in start/2 and handed back up too: ask/2 sends on it and closes it, the thread receives',
         Ops2, [send-'p1.c1.g3', close-'p1.c1.g5', receive-'p4.c1.g1']),
    findall(Op3-At3, element_op(X, ch1, Op3, At3), Ops3),
    find_id(X, ch1, element(_, A3, _)),
    (   memberchk(via=V3, A3) -> true ; V3 = none ),
    must('Back goes down Req inside q(Q, Back): the thread''s send is on it, and it says which channel carried it',
         V3-Ops3, ch2-[receive-'p1.c1.g4', send-'p4.c1.g3']),
    findall(C4-P4, ( element_attrs(X, channel, A4), memberchk(id=C4, A4),
                     ( memberchk(pairs=P4, A4) -> true ; P4 = false ) ), Ps4),
    must('one lane sends on each, one receives, each in its order: the first send is the first receive''s',
         Ps4, [ch1-true, ch2-true]).

%% the program the handles and channels are followed through
ask([
    '%% ask.pl -- a question down one channel, its answer down another',
    '',
    'ask(Q, A) :-',
    '    start(Req, Id),',
    '    channel_new(Back),',
    '    channel_send(Req, q(Q, Back)),',
    '    channel_recv(Back, A),',
    '    channel_close(Req),',
    '    thread_join(Id, _).',
    '',
    'start(Req, Id) :-',
    '    channel_new(Req),',
    '    thread_create(answer(Req), Id).',
    '',
    'answer(Req) :-',
    '    channel_recv(Req, q(Q, Back)),',
    '    atom_length(Q, N),',
    '    channel_send(Back, N).'
]).

%% the program the threads are charted in
jobs([
    '%% jobs.pl -- the threads lesson 50 charts',
    '',
    'run(Jobs) :-',
    '    channel_new(Ch),',
    '    thread_create(worker(Ch), Id),',
    '    thread_create(ticker, _),',
    '    send_all(Jobs, Ch),',
    '    channel_close(Ch),',
    '    thread_join(Id, _).',
    '',
    'send_all([], _).',
    'send_all([J|Js], Ch) :- channel_send(Ch, J), send_all(Js, Ch).',
    '',
    'worker(Ch) :-',
    '    channel_recv(Ch, J), !,',
    '    with_mutex(log, format("job ~w~n", [J])),',
    '    worker(Ch).',
    'worker(_).',
    '',
    'ticker :- format("tick~n").'
]).

%% the attributes of each element of that name, in document order
element_attrs(element(N, As, Cs), Name, A) :-
    (   N == Name, A = As
    ;   member(C, Cs), C = element(_, _, _), element_attrs(C, Name, A)
    ).

%% each end of a channel, in the order the XML lists them
element_op(X, Id, Op, At) :-
    find_id(X, Id, element(channel, _, Cs)),
    member(element(Op, OAs, _), Cs),
    memberchk(at=At, OAs).

%% the program this lesson charts: a word count, by a grammar
program([
    '%% words.pl -- what lesson 50 charts',
    '',
    '%! count(+Text, -N) is det: how many words Text has',
    'count(Text, N) :-',
    '    phrase(ws(Ws), Text),',
    '    length(Ws, N).',
    '',
    '%% ws(-Words)//',
    'ws([W|Ws]) --> blanks, word(W), !, ws(Ws).',
    'ws([]) --> blanks.',
    '',
    'blanks --> [C], { code_type(C, space) }, !, blanks.',
    'blanks --> [].',
    '',
    '%% word(-W)//',
    'word([C|Cs]) --> [C], { code_type(C, alpha) }, word_rest(Cs).',
    '',
    'word_rest([C|Cs]) --> [C], { code_type(C, alpha) }, !, word_rest(Cs).',
    'word_rest([]) --> [].'
]).

goal_attr(X, Id, Name, V) :-
    (   find_id(X, Id, element(_, As, _)), memberchk(Name=V0, As) -> V = V0 ; V = none ).

find_id(element(N, As, Cs), Id, E) :-
    (   memberchk(id=Id, As) -> E = element(N, As, Cs)
    ;   member(C, Cs), C = element(_, _, _), find_id(C, Id, E)
    ), !.

has_id(T, Id) :- find_id(T, Id, _).

svg_title(T, Id, Title) :-
    (   find_id(T, Id, element(_, _, Cs)), memberchk(element(title, _, [Title0]), Cs)
    ->  Title = Title0
    ;   Title = none
    ).

has_text(element(_, _, Cs), T) :-
    member(C, Cs),
    (   C == T -> true
    ;   C = element(_, _, _), has_text(C, T)
    ), !.

must(What, Got, Want) :-
    (   Got == Want
    ->  format("     ok: ~w -> ~q~n", [What, Got])
    ;   format("     ~w = ~q  BUT THIS LESSON SAYS ~q~n", [What, Got, Want]),
        fail
    ).
