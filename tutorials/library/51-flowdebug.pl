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
%%     flow_why(+Run, -Why)                        why it failed, as a tree
%%     flow_why_furthest(+Why, -Path)              where a failed search got furthest
%%     flow_why_raised(+Run, -Raised)              why it raised: the calls the
%%                                                 exception ended, the failure
%%                                                 it answered
%%     flow_why_raised(+Run, -Raised, +Options)    and chose(C), the branch a
%%                                                 choice took to raise it and
%%                                                 the conditions it ran;
%%                                                 caught(K), the exception a
%%                                                 catch took when its
%%                                                 recovery raised
%%     flow_diff(+RunA, +RunB, -Diff)              two runs compared
%%
%% Options: source(File) (required), until(end | answer(K)), window(N) (the
%% last N steps, 2000), from(I) and to(J), discs(N), text(N),
%% view(flow | tree), names(['X'=X, ...]) for the goal's variables,
%% timeout(Ms), journal(true) and journal_file(F), txt(true) for Base.txt,
%% the run one line a call; cache(Dir), the chart built once for a program
%% and kept (library(sha)), and embed(Dir) with kb(Name), the program run
%% over a store; own(all) or own(Files), whose failed calls the why
%% explains (the chart's panels by default); svg(false) and xml(false),
%% leaving a document out; and answers: places(P), where each box is
%% written, profile(P), where the steps went, callers(C), who made the
%% calls, repeats(R), the goals asked more than once, and time(T), where the
%% TIME went -- the probe run under a clock read at every step.
%% flow_debug_windows/4 records windows(N) windows along one run, each by a
%% process of its own, and flow_profile_merge/4,5 adds their profiles up. The
%% same from a shell: `cocolog -s tools/flow/debug.pl -- GOAL FILE BASE
%% [OPTION ...]', with profile=all (or profile=time) and windows=N.
%%
%% NOTHING HERE SLOWS THE RUN IT EXPLAINS. The program runs twice, each
%% time in a child process that reads it afresh: a PROBE at full speed,
%% untraced, learns how the run ends and at which STEP -- the clock is
%% the untraced run's count of its goals, one a goal, a step; statistics/2
%% and call_metered/4 count INFERENCES, the steps less each `true' and
%% `=/2', which are no inference, and a profile says both -- and a REPLAY
%% goes untraced at full speed to the window's first step and records
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
%% +Options, -When) finds the first step at which Cond holds, by
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
    %% four calls, a step each: basket_total, price(apple), basket_total
    %% of the rest, price(banana) -- and there it fails
    must('how it ended, and at which step', How-At, false-4),
    must('the window: the whole run, recorded from its first step', From-To, 1-4),
    must('the replay ended where the probe did', Diverged, false),

    format("~n-- each call is a box of the chart~n"),
    %% query.g1 is the goal asked, p1 basket_total/2's panel, p1.c2.g1 the
    %% first goal of its second clause -- the same ids lesson 50 reads
    findall(P-B-F, member(call(_, P, _, _, B, _, _, _, _, F), Calls), Cs),
    must('the calls, the box each is, how each ended', Cs,
         [ basket_total/2-'query.g1'-fail, price/2-'p1.c2.g1'-exit,
           basket_total/2-'p1.c2.g2'-fail, price/2-'p1.c2.g1'-fail ]),
    %% the last call is price(banana, P): it tried no clause at all -- the
    %% index passed over price(apple, 3) and price(pear, 4), whose first
    %% argument is not banana -- and that is the bug, found without a
    %% breakpoint. A clause is recorded where a call TRIED it: c(K, At) for
    %% the one it entered, nohead(K, At) for one whose head did not unify
    last(Calls, call(_, _, _, _, _, _, Clauses, [Item, _], _, _)),
    must('price/2 was called with banana', Item, banana),
    must('and tried no clause: none has a head for a banana', Clauses, []),

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

    format("~n-- the run as text, one line a call~n"),
    %% txt(true) writes Base.txt beside the two -- the cheapest view of a
    %% run: each call's step, the goal at its Call, how it ended, the
    %% clauses it entered (c2) and the heads it tried that did not unify
    %% (h1) -- [] for price(banana, P), which tried none -- its box, and
    %% where that box is written: :LINE:COL in the file the second line
    %% names once
    flow_debug(G, Base, [source(Prog), names(['T'=T]), txt(true)], _),
    atom_concat(Base, '.txt', Txt),
    read_file_to_codes(Txt, TC),
    atom_codes(TA, TC),
    format("~w", [TA]),
    atomic_list_concat([Head, FileLine|TLs], '\n', TA),
    must('the first line says how the run ended', Head,
         '% basket_total([apple, banana, pear], T): false at step 4; recorded 1 to 4; diverged no; 4 calls'),
    atom_concat('% file: ', Dir, FL0), atom_concat(FL0, '/basket.pl', FL),
    must('the second names the file every place below is in', FileLine, FL),
    nth1(4, TLs, Fourth),
    atomic_list_concat(Fields, ' ', Fourth),
    append(_, [Fate, Cl4, Box4, Where], Fields),
    must('the fourth call: price/2 failed, no clause tried, the first goal of basket_total''s second clause, written at 3:28',
         [Fate, Cl4, Box4, Where], [fail, '[]', 'p1.c2.g1', ':3:28']),

    format("~n-- a long run, its last steps~n"),
    %% two hundred apples and then a banana: 402 steps, and a window
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
    must('one call a step', NL, 20),
    %% a call made inside one that began before the window has no clause to
    %% be matched in: it is placed in its predicate's panel, with no box
    LCalls = [call(_, FirstP, _, FirstParent, FirstBox, FirstPanel, _, _, _, _)|_],
    must('the window''s first call: basket_total/2, its caller unseen, no box, its panel',
         FirstP-FirstParent-FirstBox-FirstPanel, basket_total/2-0-none-p1),

    journalled(Dir),

    format("~n-- why it failed, read back~n"),
    %% the basket's run again: each failed call of the program's own, each
    %% clause it tried -- its head did not unify, or its body was entered
    %% and called what -- down to price(banana, P), which tried none: the
    %% price of a banana is nowhere. basket_total([], 0) is not tried
    %% either: a list of items is never [], and the index knows it
    flow_why(Run, Why),
    why_shape(Why, Shape),
    must('basket_total/2 failed in its second clause, at basket_total/2 again, at price/2, which tried no clause',
         Shape, [why(basket_total/2, [entered(2, [exited(price/2),
                     why(basket_total/2, [entered(2, [why(price/2, [])])])])])]),
    %% a search that fails has many failures; the one that matters is where
    %% it got FURTHEST -- the clause, at each failed call, whose body got
    %% the most calls done -- not where it failed last
    flow_why_furthest(Why, Path),
    findall(P-K, ( member(Step, Path), arg(2, Step, P), ( Step = step(_, _, _, K, _, _) -> true ; functor(Step, K, _) ) ), PKs),
    must('where it got furthest: clause 2 twice, then price/2 with no head that unified',
         PKs, [basket_total/2-2, basket_total/2-2, price/2-nohead]),
    two_ways(Dir),

    format("~n-- where the steps went~n"),
    %% profile(P), an answer: each predicate's calls and the steps
    %% spent inside them, a call charged up to its first Exit or Fail
    flow_debug(basket_total(Long, _), LongBase, [source(Prog), from(1), profile(Prof)], _),
    Prof = profile(_, _, Spent, [TopRow, NextRow|_]),
    must('the 402 steps, basket_total/2 spending all of them over its 201 calls, price/2 one each',
         Spent-TopRow-NextRow, 402-prof(basket_total/2, 402, 201, 402)-prof(price/2, 201, 201, 1)),
    %% who made the calls, and the goals asked more than once -- a goal's
    %% variables named in the order they come, so price(apple, P) asked with
    %% a fresh P each time is one goal (flow_callers_text/2 and
    %% flow_repeats_text/2 write them; flow_steps_text/2 the window's
    %% steps by what took them). svg(false) and xml(false): neither
    %% document is written, the cheap way to a profile
    flow_debug(basket_total(Long, _), LongBase,
               [source(Prog), from(1), callers(Callers), repeats(Repeats), svg(false), xml(false)], _),
    Callers = callers(_, _, [callers(CP, CN, CBy)|_]),
    must('basket_total/2''s 201 calls: 200 made by basket_total/2 itself, one by the query',
         CP-CN-CBy, basket_total/2-201-[basket_total/2-200, '(the query)'-1]),
    Repeats = repeats(_, _, RRows),
    must('price/2 asked price(apple, P) 200 times: 201 calls of 2 goals',
         RRows, [repeats(price/2, 201, 2, ['price(apple,_1)'-200])]),
    %% windows along one run, each recorded by a process of its own, and
    %% their profile rows added up: a long run sampled where it is slow
    atom_concat(Dir, '/sampled', SampledBase),
    flow_debug_windows(basket_total(Long, _), SampledBase,
                       [source(Prog), windows(2), window(10), svg(false), xml(false)], windows(_, Ws)),
    findall(F-T2, member(window(_, _, run(_, _, _, window(F, T2), _, _, _, _), _), Ws), Spans),
    must('two windows of 10, the second where the run fails', Spans, [192-201, 393-402]),
    findall(Rows, member(window(_, _, _, Rows), Ws), RowLists),
    flow_profile_merge(RowLists, profile(_, _, _, MRows), _, _),
    findall(MP-MN, member(prof(MP, _, MN, _), MRows), MPNs),
    must('their calls added up: ten of each predicate', MPNs, [basket_total/2-10, price/2-10]),
    timed(Dir),

    format("~n-- two runs compared~n"),
    %% the same basket over a program that knows what a banana costs: the
    %% inputs both runs called that answered differently, deepest first --
    %% the first is where the difference began
    atom_concat(Dir, '/basket2.pl', Prog2),
    read_file_to_codes(Prog, PC),
    atom_codes(PA, PC),
    atom_concat(PA, 'price(banana, 2).\n', PB),
    open(Prog2, write, W2), write(W2, PB), close(W2),
    atom_concat(Dir, '/basket2', Base2),
    flow_debug(G, Base, [source(Prog), names(['T'=T]), from(1)], RunA),
    flow_debug(G, Base2, [source(Prog2), names(['T'=T]), from(1)], RunB),
    flow_diff(RunA, RunB, diff(_, [differ(DP, DIn, c(_, _, _, _, DA), c(_, _, _, _, DB))|_], _, _)),
    must('the deepest input answered differently: price(banana, P), which a fails and b answers 2',
         DP-DIn-DA-DB, price/2-[banana, '_']-fail-exit([banana, '2'])),

    asked(Dir),
    raised(Dir),

    format("~ndone~n").

%% ONE CLAUSE, TWO WAYS THROUGH: a basket priced as it stands or, failing
%% that, as a coupon and the rest -- a disjunction in one clause. The
%% second way fails at once, no coupon, and it fails LAST; the first got
%% furthest, two items priced and the third a banana. Where a clause failed
%% is the call of it that spent the most steps without exiting: an explicit
%% fail/0 stands for the condition before it, and an exception a catch took
%% is no stall (1.13.7)
two_ways(Dir) :-
    format("~n-- one clause, two ways through~n"),
    atom_concat(Dir, '/basket.pl', Prog),
    atom_concat(Dir, '/coupon.pl', Prog3),
    read_file_to_codes(Prog, PC),
    atom_codes(PA, PC),
    atomic_list_concat([PA, 'total(Is, T) :- ( basket_total(Is, T) ; coupon(Is, Rest), basket_total(Rest, T) ).\n',
                        'coupon([coupon|Is], Is).\n'], P3),
    open(Prog3, write, W), write(W, P3), close(W),
    atom_concat(Dir, '/coupon', Base),
    flow_debug(total([apple, pear, banana], T), Base, [source(Prog3), names(['T'=T])], Run),
    flow_why(Run, Why),
    flow_why_furthest(Why, Path),
    findall(P-K, ( member(Step, Path), arg(2, Step, P), ( Step = step(_, _, _, K, _, _) -> true ; functor(Step, K, _) ) ), PKs),
    must('where it got furthest: into the first way, not the coupon that failed last',
         PKs, [total/2-1, basket_total/2-2, basket_total/2-2, basket_total/2-2, price/2-nohead]).

%% A RUN THAT RAISES: a checkout that gives up with an error when a basket
%% has no total. Its why is the calls the exception ended, the branch a
%% choice took to raise it and the conditions that choice ran, and the
%% failure the raise answered, with where that got furthest. The basket is
%% another file's, which the chart has no panel for: own(all) explains its
%% calls too
raised(Dir) :-
    format("~n-- a run that raises: why?~n"),
    atom_concat(Dir, '/basket.pl', Basket),
    atom_concat(Dir, '/checkout.pl', Prog),
    open(Prog, write, W),
    format(W, ":- use_module(~q).~n", [Basket]),
    format(W, "checkout(Items, T) :- ( basket_total(Items, T) -> true ; throw(error(unpriced(Items), checkout/2)) ).~n", []),
    format(W, "till(Items, T) :- catch(checkout(Items, T), error(unpriced(Is), _), refuse_sale(Is)).~n", []),
    format(W, "refuse_sale(Is) :- throw(error(sale_refused(Is), till/2)).~n", []),
    close(W),
    atom_concat(Dir, '/checkout', Base),
    flow_debug(checkout([apple, banana], T), Base, [source(Prog), names(['T'=T]), own(all)], Run),
    Run = run(How, _, _, _, _, _, _, _),
    must('the run raised', How, exception(error(unpriced([apple, banana]), checkout/2))),
    flow_why_raised(Run, raised(Chain, Answered), [own(all), chose(Chose)]),
    findall(P-F, member(ended(_, P, _, F), Chain), PF),
    must('the exception ended checkout/2, in whose body it was raised', PF, [checkout/2-unwound]),
    %% the throw/1 stands in the else of checkout/2's if-then-else: it ran
    %% because every condition failed -- basket_total/2, in its clauses
    ( Chose = chose(_, CP, _, _, Branch, Conds) -> true ; CP = none, Branch = none, Conds = [] ),
    findall(CN-CK, ( member(C, Conds), arg(2, C, CN), functor(C, CK, _) ), CNK),
    must('the branch it was raised in: checkout/2''s else, after basket_total/2 failed', CP-Branch-CNK,
         (checkout/2)-else-[(basket_total/2)-why]),
    flow_why_furthest([Answered], Path),
    findall(P-K, ( member(Step, Path), arg(2, Step, P), ( Step = step(_, _, _, K, _, _) -> true ; functor(Step, K, _) ) ), PKs),
    must('it answered basket_total/2''s failure, which got furthest down to price/2 with no head for a banana',
         PKs, [basket_total/2-2, basket_total/2-2, price/2-nohead]),
    %% A RECOVERY THAT RAISES: a till catches the checkout's error and
    %% refuses the sale with one of its own. The run raised in the catch's
    %% recovery, and the exception the catch took is explained as well
    atom_concat(Dir, '/till', TBase),
    flow_debug(till([apple, banana], T2), TBase, [source(Prog), names(['T'=T2]), own(all)], TRun),
    flow_why_raised(TRun, raised(TChain, _), [own(all), caught(Caught)]),
    findall(TP, member(ended(_, TP, _, _), TChain), TPs),
    must('the sale was refused: raised by refuse_sale/1, in till/2''s recovery', TPs, [till/2, refuse_sale/1]),
    (   Caught = caught(_, KP, _, _, raised(KChain, _), chose(_, KCP, _, _, KB, _), _)
    ->  findall(KQ, member(ended(_, KQ, _, _), KChain), KQs)
    ;   KP = none, KQs = [], KCP = none, KB = none
    ),
    must('...and the exception the catch took: checkout/2''s, raised in its else',
         KP-KQs-KCP-KB, (till/2)-[checkout/2]-(checkout/2)-else).

%% WHERE THE TIME WENT: time(T), an answer like profile(P). The probe runs
%% under a clock read at the top of every step of the window, untraced
%% -- the run as it is, not the replay, whose recorder writes every
%% argument -- and the replay says whose each step was: each
%% predicate's calls, the time inside them and the time of its calls' own
%% steps, in nanoseconds. A count says where the steps went; time
%% finds the ONE step that costs a thousand: a sort of 20 000 numbers
%% is one step among the window's eight hundred. A reading costs time
%% too, measured as the probe starts and taken off each one
timed(Dir) :-
    format("~n-- where the time went~n"),
    atom_concat(Dir, '/sorting.pl', Prog),
    open(Prog, write, W),
    forall(member(L, [ 'sorted_last(X) :- numlist(1, 20000, L0), reverse(L0, L), msort(L, S), last(S, X).',
                       'count(0) :- !.',
                       'count(N) :- N1 is N - 1, count(N1).',
                       'job(X) :- count(200), sorted_last(X), count(200).' ]),
           format(W, "~w~n", [L])),
    close(W),
    atom_concat(Dir, '/sorting', Base),
    flow_debug(job(_), Base, [source(Prog), from(1), profile(Prof), time(Time), svg(false), xml(false)], _),
    Prof = profile(_, _, _, PRows),
    ( memberchk(prof(msort/2, MI, MN, _), PRows) -> true ; MI = 0, MN = 0 ),
    must('msort/2 in the profile: one call, one step', MI-MN, 1-1),
    Time = time(_, _, _, TRows),
    findall(Own-P, member(t(P, _, _, Own, _), TRows), Owns),
    max_member(_-Top, Owns),
    must('in time, msort/2''s own is the most of any predicate''s', Top, msort/2),
    %% a GUARD -- the arithmetic and tests a clause begins with, run as the
    %% clause is entered -- is a step no reading separates from its
    %% call's: count/1's is/2 has no time of its own, it is count/1's
    ( memberchk(t(is/2, IN, _, IOwn, _), TRows) -> true ; IN = 0, IOwn = none ),
    must('is/2, count/1''s guard: 400 calls, no time of its own', IN-IOwn, 400-0),
    %% as text (flow_time_text/2; profile=time from the shell): the window's
    %% time and what the clock cost, then a row a predicate, the most
    %% inclusive first -- its numbers are this run's, and the next differs
    flow_time_text(Time, Text),
    atomic_list_concat([_, _, Cols|Rows], '\n', Text),
    format("~w~n", [Cols]),
    forall(( member(R, Rows), member(E, ['  job/1', '  sorted_last/1', '  msort/2', '  count/1']),
             atom_concat(_, E, R) ),
           format("~w~n", [R])).

%% a why tree without its arguments: what failed, and where
why_shape(L, S) :- is_list(L), !, findall(X, ( member(W, L), why_shape(W, X) ), S).
why_shape(why(_, P, _, Ts), why(P, Ss)) :- !, findall(X, ( member(T, Ts), why_shape(T, X) ), Ss).
why_shape(entered(K, Gs), entered(K, Ss)) :- !, why_shape(Gs, Ss).
why_shape(nohead(K), nohead(K)) :- !.
why_shape(exited(_, P, _, _), exited(P)) :- !.
why_shape(failed(_, P, _), failed(P)) :- !.
why_shape(ended(_, P, _, F), ended(P, F)).

%% WHEN DID IT HAPPEN? A list of squares built one at a time: the first
%% step at which its fourth is 16, found by asking runs stopped part
%% way (flow_when/4 bisects: a handful of runs, each at full speed), and
%% then the one call made there, seen through a window of one step
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
    must('the fourth square is 16 from step 12', When, at(12)),
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
    %% past the probe's end -- stopped there, at the window's last step
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
