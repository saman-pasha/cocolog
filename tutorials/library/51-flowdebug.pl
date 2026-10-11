%% LIBRARY 51 -- library(flowdebug): what a query DID, drawn over the
%% flowchart of what it can do -- the path it took, where it failed, the
%% values that crossed -- as an SVG for a person and an XML for an agent
%%
%%     ./cocolog run tutorials/library/51-flowdebug.pl main
%%
%% TIER 2: `use_module(library(flowdebug))', clauses in library/flowdebug.pl
%% and library/flow/dbg*.pl, over library(flowchart) (lesson 50) and
%% library(stream).
%%
%%     flow_debug(+Goal, +Base, +Options)          Base.svg and Base.xml
%%     flow_debug(+Goal, +Base, +Options, -Run)    and the run as a term
%%
%% Options: source(File) (required), until(end | answer(K)), window(N) (the
%% last N inferences, 2000), from(I) and to(J), discs(N), text(N),
%% view(flow | tree), names(['X'=X, ...]) for the goal's variables, and
%% timeout(Ms). The same from a shell: `cocolog -s tools/flow/debug.pl --
%% GOAL FILE BASE [OPTION ...]'.
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
%% WHAT IS DRAWN: the chart, every box the window reached heavy, red where
%% its last call failed, purple where it raised an exception; a head red
%% where its last try did not unify; whatever the run never reached faded;
%% and a numbered disc wherever a value crossed into a variable the source
%% names -- given at a call, bound at an exit, undone by backtracking -- with
%% a line for each under the chart. THE XML is the chart's, with a <run>
%% after it: how the run ended, every call with its box and its arguments,
%% every event, every binding. view(tree) draws the calls themselves.

:- use_module(library(flowdebug)).
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
    Run = run(How, At, _, window(From, To), Calls, Bindings, Diverged),
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
    LongRun = run(LHow, LAt, _, LWindow, LCalls, _, _),
    must('it fails where the untraced run does, the window its last 20', LHow-LAt-LWindow,
         false-402-window(383, 402)),
    length(LCalls, NL),
    must('one call an inference', NL, 20),
    %% a call made inside one that began before the window has no clause to
    %% be matched in: it is placed in its predicate's panel, with no box
    LCalls = [call(_, FirstP, _, FirstParent, FirstBox, FirstPanel, _, _, _, _)|_],
    must('the window''s first call: basket_total/2, its caller unseen, no box, its panel',
         FirstP-FirstParent-FirstBox-FirstPanel, basket_total/2-0-none-p1),

    format("~ndone~n").

must(What, Got, Want) :-
    (   Got == Want
    ->  format("     ok: ~w -> ~q~n", [What, Got])
    ;   format("     ~w = ~q  BUT THIS LESSON SAYS ~q~n", [What, Got, Want]),
        fail
    ).
