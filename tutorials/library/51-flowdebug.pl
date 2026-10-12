%% LIBRARY 51 -- library(flow/debug): what a query DID, drawn over the
%% flowchart of what it can do -- the path it took, where it failed, the
%% values that crossed -- as an SVG for a person and an XML for an agent
%%
%%     ./cocolog run tutorials/library/51-flowdebug.pl main
%%
%% TIER 2: `use_module(library(flow/debug))', clauses in library/flow/debug.pl
%% and library/flow/dbg*.pl, over library(flow/chart) (lesson 50) and
%% library(stream).
%%
%%     flow_debug(+Goal, +Base, +Options)          Base.svg and Base.xml
%%     flow_debug(+Goal, +Base, +Options, -Run)    and the run as a term
%%
%% Options: source(File) (required), until(end | answer(K)), window(N) (the
%% last N inferences, 2000), from(I) and to(J), discs(N), text(N),
%% view(flow | tree), names(['X'=X, ...]) for the goal's variables,
%% timeout(Ms), journal(true) and journal_file(F). The same from a shell:
%% `cocolog -s tools/flow/debug.pl -- GOAL FILE BASE [OPTION ...]'.
%%
%% NOTHING HERE SLOWS THE RUN IT EXPLAINS. The program runs twice, each
%% time in a child process that reads it afresh: a PROBE at full speed,
%% untraced, learns how the run ends and at which inference -- the clock is
%% the untraced run's count, the one call_metered/4 reads -- and a REPLAY
%% goes untraced at full speed to the window's first inference and records
%% from there ('$trace_window'/4). A replay that does not end where the
%% probe did -- the program read the time, a file, the knowledge base -- is
%% said to have DIVERGED, on the picture and in the XML.
%%
%% journal(true) takes that away: the probe JOURNALS every call that
%% reaches the world -- the clock, the environment, a file, a stream, a
%% process, a thread -- and the replay is answered from the journal and
%% runs none of them. So it sees what the probe saw, and does not do
%% again what the probe did.
%%
%% QUESTIONS OVER THE CLOCK: flow_why(+Run, -Why) reads why a run failed
%% back from what flow_debug/4 recorded -- each failed call of the
%% program's own and each clause it tried -- and flow_when(+Goal, +Cond,
%% +Options, -When) finds the first inference at which Cond holds, by
%% asking runs stopped part way: at(I), or never.
%%
%% WHAT IS DRAWN: the chart, every box the window reached heavy, red where
%% its last call failed, purple where it raised an exception; a head red
%% where its last try did not unify; whatever the run never reached faded;
%% and a numbered disc wherever a value crossed into a variable the source
%% names -- given at a call, bound at an exit, undone by backtracking -- with
%% a line for each under the chart. THE XML is the chart's, with a <run>
%% after it: how the run ended, every call with its box and its arguments,
%% every event, every binding. view(tree) draws the calls themselves.

:- use_module(library(flow/debug)).
:- use_module(library(stream)).
:- use_module(library(xml)).

main :-
    Dir = '/tmp/cocolog-flowdebug-lesson',
    ( exists_directory(Dir) -> true ; make_directory(Dir) ),
    atom_concat(Dir, '/basket.pl', Prog),
    atom_concat(Dir, '/basket', Base),
    open(Prog, write, W),
    forall(member(L, [ '%% basket_total(+Items, -Total): what a basket costs',
                       'basket_total([], 0).',
                       'basket_total([I|Is], T) :- price(I, P), basket_total(Is, T0), T is T0 + P.',
                       '',
                       'price(apple, 3).',
                       'price(pear, 4).' ]),
           format(W, "~w~n", [L])),
    close(W),

    format("~n-- a run that fails: why?~n"),
    %% the basket holds a banana, and nothing says what a banana costs
    G = basket_total([apple, banana, pear], T),
    flow_debug(G, Base, [source(Prog), names(['T'=T])], Run),
    atom_concat(Base, '.svg', Svg), atom_concat(Base, '.xml', Xml),
    ( exists_file(Svg), exists_file(Xml) -> Both = yes ; Both = no ),
    must('the picture and the XML are both written', Both, yes),
    Run = run(How, At, _, window(From, To), Calls, Bindings, Diverged, _),
    %% four calls, an inference each: basket_total, price(apple), basket_total
    %% of the rest, price(banana) -- and there it fails
    must('how it ended, and at which inference', How-At, false-4),
    must('the window: the whole run, recorded from its first inference', From-To, 1-4),
    must('the replay ended where the probe did', Diverged, false),

    format("~n-- each call is a box of the chart~n"),
    %% query.g1 is the goal asked, p1 basket_total/2's panel, p1.c2.g1 the
    %% first goal of its second clause -- the same ids lesson 50 reads
    findall(P-B-F, member(call(_, P, _, _, B, _, _, _, _, F), Calls), Cs),
    must('the calls, the box each is, how each ended', Cs,
         [ basket_total/2-'query.g1'-fail, price/2-'p1.c2.g1'-exit,
           basket_total/2-'p1.c2.g2'-fail, price/2-'p1.c2.g1'-fail ]),
    %% the last call is price(banana, P): it tried both clauses' heads, and
    %% neither unified -- that is the bug, found without a breakpoint
    last(Calls, call(_, _, _, _, _, _, Clauses, [Item, _], _, _)),
    must('price/2 was called with banana', Item, banana),
    findall(K, member(nohead(K, _), Clauses), NoHeads),
    must('and neither of its heads unified', NoHeads, [1, 2]),

    format("~n-- the values that crossed~n"),
    findall(Port-Name-Value, member(x(_, Port, _, Name, Value, _), Bindings), Xs),
    must('each, by the name the source gives it', Xs,
         [ call-'I'-apple, exit-'P'-'3', call-'Is'-'[banana,pear]', call-'I'-banana ]),

    format("~n-- what an agent reads~n"),
    read_file_to_codes(Xml, XC),
    xml_parse(XC, element(flow, _, Kids)),
    findall(E, ( member(E, Kids), nonvar(E), E = element(_, _, _) ), Els),
    last(Els, element(run, RA, _)),
    memberchk(ended=Ended, RA),
    memberchk(failed_from_call=FC, RA),
    must('the <run> says it failed, and the call its failure began at', Ended-FC, false-'4'),

    format("~n-- a long run, its last inferences~n"),
    %% two hundred apples and then a banana: 402 inferences, and a window
    %% of the last 20 is all that is recorded -- the program runs to it at
    %% full speed
    length(Apples, 200),
    maplist(=(apple), Apples),
    append(Apples, [banana], Long),
    atom_concat(Dir, '/long', LongBase),
    flow_debug(basket_total(Long, _), LongBase, [source(Prog), window(20)], LongRun),
    LongRun = run(LHow, LAt, _, LWindow, LCalls, _, _, _),
    must('it fails where the untraced run does, the window its last 20', LHow-LAt-LWindow,
         false-402-window(383, 402)),
    length(LCalls, NL),
    must('one call an inference', NL, 20),
    %% a call made inside one that began before the window has no clause to
    %% be matched in: it is placed in its predicate's panel, with no box
    LCalls = [call(_, FirstP, _, FirstParent, FirstBox, FirstPanel, _, _, _, _)|_],
    must('the window''s first call: basket_total/2, its caller unseen, no box, its panel',
         FirstP-FirstParent-FirstBox-FirstPanel, basket_total/2-0-none-p1),

    journalled(Dir),

    format("~n-- why it failed, read back~n"),
    %% the basket's run again: each failed call of the program's own, each
    %% clause it tried -- its head did not unify, or its body was entered
    %% and called what -- down to price(banana, P), whose heads both
    %% failed to unify: the price of a banana is nowhere
    flow_why(Run, Why),
    why_shape(Why, Shape),
    must('basket_total/2 failed in its second clause, at basket_total/2 again, at price/2, with no head that unified',
         Shape, [why(basket_total/2, [nohead(1), entered(2, [exited(price/2),
                     why(basket_total/2, [nohead(1), entered(2, [why(price/2, [nohead(1), nohead(2)])])])])])]),

    asked(Dir),

    format("~ndone~n").

%% a why tree without its arguments: what failed, and where
why_shape(L, S) :- is_list(L), !, findall(X, ( member(W, L), why_shape(W, X) ), S).
why_shape(why(_, P, _, Ts), why(P, Ss)) :- !, findall(X, ( member(T, Ts), why_shape(T, X) ), Ss).
why_shape(entered(K, Gs), entered(K, Ss)) :- !, why_shape(Gs, Ss).
why_shape(nohead(K), nohead(K)) :- !.
why_shape(exited(_, P, _, _), exited(P)) :- !.
why_shape(failed(_, P, _), failed(P)) :- !.
why_shape(ended(_, P, _, F), ended(P, F)).

%% WHEN DID IT HAPPEN? A list of squares built one at a time: the first
%% inference at which its fourth is 16, found by asking runs stopped part
%% way (flow_when/4 bisects: a handful of runs, each at full speed), and
%% then the one call made there, seen through a window of one inference
asked(Dir) :-
    format("~n-- when did it happen?~n"),
    atom_concat(Dir, '/squares.pl', Prog),
    open(Prog, write, W),
    forall(member(L, [ 'squares(N, L) :- numlist(1, N, Ns), squares_(Ns, L).',
                       'squares_([], []).',
                       'squares_([X|Xs], [Y|Ys]) :- Y is X * X, squares_(Xs, Ys).' ]),
           format(W, "~w~n", [L])),
    close(W),
    flow_when(squares(6, Sq), (nth1(4, Sq, S4), S4 == 16), [source(Prog)], When),
    must('the fourth square is 16 from inference 12', When, at(12)),
    atom_concat(Dir, '/squares', Base),
    flow_debug(squares(6, _), Base, [source(Prog), from(12), to(12)], R),
    R = run(_, _, _, _, [call(12, P, _, _, _, _, _, _, Out, _)|_], _, _, _),
    must('the call made there: is/2, which made 16 of 4*4', P-Out, (is)/2-['16', '4*4']),
    flow_when(squares(6, Sq2), (nth1(4, Sq2, S42), S42 == 17), [source(Prog)], Never),
    must('and a question that never holds where the run ends', Never, never).

%% A VISIT COUNTER: each run reads a file and writes it back one more. The
%% probe is the first visit; a replay without a journal is the second, and
%% says so by diverging -- and with one it is the probe's visit again.
journalled(Dir) :-
    format("~n-- what the program reads, journalled~n"),
    atom_concat(Dir, '/count', CF),
    atom_concat(Dir, '/visits.pl', Prog),
    format(atom(Cl), 'visit(N) :- ( exists_file(~q) -> read_file_to_codes(~q, Cs), number_codes(N0, Cs) ; N0 = 0 ), N is N0 + 1, number_codes(N, C1), write_file_from_codes(~q, C1).',
           [CF, CF, CF]),
    open(Prog, write, W), format(W, "~w~n", [Cl]), close(W),
    ( exists_file(CF) -> delete_file(CF) ; true ),
    atom_concat(Dir, '/visits', B1),
    flow_debug(visit(N1), B1, [source(Prog), names(['N'=N1])], R1),
    R1 = run(_, _, _, _, _, X1, D1, _),
    %% the probe wrote 1; the replay read it, took the other way and ran
    %% past the probe's end -- stopped there, at the window's last inference
    must('without a journal the replay is a second visit, and diverged',
         D1, diverged(end(answer, 8, [8]), end(limit, 8, []))),
    findall(V, member(x(_, exit, _, 'N', V, _), X1), NV1),
    must('...the N it shows is 2', NV1, ['2']),
    delete_file(CF),
    atom_concat(Dir, '/visits-j', B2),
    flow_debug(visit(N2), B2, [source(Prog), names(['N'=N2]), journal(true)], R2),
    R2 = run(How2, _, _, _, _, X2, D2, journal(Es)),
    must('with a journal the replay is the probe''s visit, and did not diverge', How2-D2, answer-false),
    findall(V, member(x(_, exit, _, 'N', V, _), X2), NV2),
    must('...the N it shows is 1, at is/2''s exit and the query''s', NV2, ['1', '1']),
    findall(M-P-O, ( member(j(_, M, P, _, Out), Es), functor(Out, O, _) ), MPO),
    must('the journal: the file asked about (it was not there), then written',
         MPO, [files-exists_file/1-fail, files-write_file_from_codes/2-exit]),
    read_file_to_codes(CF, Cs), atom_codes(Count, Cs),
    must('...and the file holds the probe''s 1: the replay wrote nothing', Count, '1').

must(What, Got, Want) :-
    (   Got == Want
    ->  format("     ok: ~w -> ~q~n", [What, Got])
    ;   format("     ~w = ~q  BUT THIS LESSON SAYS ~q~n", [What, Got, Want]),
        fail
    ).
