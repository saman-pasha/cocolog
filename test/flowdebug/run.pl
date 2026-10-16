%% test/flowdebug.pl's program: each way control moves through a clause, to
%% be run, recorded and matched to its chart -- an if-then-else both ways,
%% a disjunction's second branch, \+, findall/3, a predicate called twice in
%% a clause, a redo, an exception caught, a failed run, a recursion seen
%% through a window, a run not the same twice, and the ways a run raises
%% (its line numbers are checked: keep this comment six lines long).

:- use_module(library(stream)).

top(X, Y) :- ( X > 0 -> pos(X, Y) ; neg(X, Y) ), \+ bad(Y), findall(Z, member(Z, [1,2]), _).
top(_, none).

pos(X, X).

neg(X, Y) :- ( X =:= 0, Y = zero ; Y is -X ).

bad(b).

twice(A, B) :- inc(1, A), inc(A, B).

inc(X, Y) :- Y is X + 1.

%% the then and the else call one predicate: a call made after the
%% condition failed is the else's, though the then's comes first
choose(X) :- ( X > 0 -> inc(X, _) ; inc(0, _) ), inc(X, _).

pick(X) :- member(X, [1,2,3]), X > 1.

safe(E) :- catch(oops(_), E, noted(E)).

oops(X) :- X is foo + 1.

noted(_).

find(K, V) :- lookup(K, V), V > 1.

lookup(K, V) :- pairs(Ps), member(K-V, Ps).

pairs([a-1, b-2, c-3]).

app([], L, L).
app([H|T], L, [H|R]) :- app(T, L, R).

nrev([], []).
nrev([H|T], R) :- nrev(T, RT), app(RT, [H], R).

go(N, R) :- numlist(1, N, L), nrev(L, R).

%% each run adds a byte to the file F, and answers only when the file then
%% holds an odd number of them: a probe on a fresh file answers, and the
%% replay that follows it fails
flip(F) :-
    open(F, append, S), write(S, x), close(S),
    read_file_to_codes(F, Cs), length(Cs, N),
    N mod 2 =:= 1.

%% two clauses whose heads both unify and whose bodies both fail: the calls
%% each made are its own
classify(X, big) :- X > 10.
classify(X, mid) :- X > 5, X < 10.

%% a list of five filled one element at a time: each element is bound once,
%% and stays bound -- what flow_when/4's bisection is for
fill(L) :- length(L, 5), fill_(L, 1).
fill_([], _).
fill_([X|Xs], I) :- X = I, I1 is I + 1, fill_(Xs, I1).

%% loads F -- what a load reads is the program's own clauses, read again by
%% every run, and no journal answers it -- and then adds a clause to F unless
%% F had one: the replay's load reads what the probe added, takes the other
%% way, and leaves the journal where the probe appended
grow(F) :-
    use_module(F),
    (   catch(grown(x), _, fail) -> true ; append_file_from_codes(F, "grown(x).\n") ),
    getenv('HOME', _).

%% a clause that cuts and then fails: the call fails, from the frame its
%% cut kept -- through 1.10.22 the cut took that frame and the call had no
%% end at all (its fate open)
refuse(X) :- cut_none(X).
cut_none(X) :- X > 0, !, fail.
cut_none(_).

%% a reader with a fallback: its first clause gets furthest -- word/2
%% exits, and check/1 has no head for what it read -- and its second, the
%% fallback, fails at once: the last failure is the fallback's, the cause
%% is the first clause's
parse(X) :- word(X, W), check(W).
parse(X) :- fallback(X).
word(a, aa).
check(bb).
fallback(zz).

%% a clause that fails by an explicit fail/0 after its condition failed:
%% where it got furthest goes into the condition, lowerable/1, not into the
%% fail (1.11.4, from cicili-lang's report)
lower(X, Y) :- ( lowerable(X) -> Y = low(X) ; note(X), fail ).
lowerable(X) :- atom(X), X \== bad.
note(_).

%% ONE clause holding a disjunction, as the translator's tr_read_ir/5 (1.13.7,
%% the reasoning session's report): the first branch's read gets furthest
%% -- three words read, the fourth no word -- and the second branch, the
%% fallback for a byline, fails at once and last
read_ir(Ws) :- ( into_ir(Ws) ; byline(Ws, Ws2), into_ir(Ws2) ).
into_ir(Ws) :- ir_words(Ws, 0).
ir_words([], _).
ir_words([W|Ws], N) :- ir_word(W), N1 is N + 1, ir_words(Ws, N1).
ir_word(the).
ir_word(dog).
ir_word(sleeps).
byline([by|Ws], Ws).

%% a call that exited and failed only when asked again is the trail of a
%% later failure: tally/0's count_up/0 exits, judge/0 fails, and count_up/0,
%% asked again, fails -- judge/0 is where its clause failed, though
%% count_up/0 spent more
tally :- count_up, judge.
count_up :- count_down(12), ( yes_once ; no_more ).
count_down(0) :- !.
count_down(N) :- N1 is N - 1, count_down(N1).
yes_once.
no_more :- fail.
judge :- verdict(guilty).
verdict(innocent).

%% an exception a catch took is no stall: the first branch's catch/3 runs
%% long and its goal raises, the second branch fails at its test -- where
%% the clause got furthest is the test
caught_far :- ( catch(long_raise(12), _, fail) ; far_test(1) ).
long_raise(0) :- throw(gave_up).
long_raise(N) :- N > 0, N1 is N - 1, long_raise(N1).
far_test(X) :- X > 5.

%% two branches that spent alike, a step each: the later is where it failed
tie_far(X) :- ( X > 5 ; X > 7 ).

%% nothing failed but an exception a catch took, and the recovery's fail:
%% the exception is where it got furthest
caught_only :- catch(long_raise(3), _, fail).

%% a driver that gives up with an error when a step fails: the run raises,
%% and the failure it answered is step/1's (1.11.4)
drive(X) :- ( step(X) -> true ; give_up(X) ).
step(X) :- X > 0, ok_step(X).
ok_step(1).
give_up(X) :- throw(error(gave_up(X), drive/1)).

%% a builder that gives up with an error in a branch a choice took (1.11.7,
%% from cicili-lang's report): shape_ok/1's fourth arm raises, its
%% condition having held after three failed -- the first by an exception
%% its catch took and the recovery's fail/0, the second with no head for
%% the shape, the third in its clause. build/1's own if-then-else failed
%% too, settled before the raise, and is no part of why
build(Ss) :- ( sized(Ss) -> true ; true ), shapes_ok(Ss).
sized(Ss) :- Ss = [_, _|_].
shapes_ok([]).
shapes_ok([S|Ss]) :- shape_ok(S), shapes_ok(Ss).
shape_ok(S) :-
    (   catch(nb_getval('$flow_test_shape', yes), _, fail) -> true
    ;   round_shape(S) -> true
    ;   sized_shape(S) -> true
    ;   abstract_shape(S) -> refuse_shape(S)
    ;   true
    ).
round_shape(circle).
sized_shape(S) :- shape_area(S, A), A > 0.
shape_area(solid, 0).
abstract_shape(solid).
refuse_shape(S) :- throw(error(abstract(S), shape_ok/1)).

%% drivers whose catch takes the builder's error: one says it and throws it
%% again, one only throws it again, one whose saying raises an error of its
%% own -- the run raises in the catch's recovery, and the exception the
%% catch took is explained too
build_again(Ss) :- catch(build(Ss), E, (say_error(E), throw(E))).
say_error(E) :- error_text(E, _).
error_text(error(E, _), E).
build_throw(Ss) :- catch(build(Ss), E, throw(E)).
build_stop(Ss) :- catch(build(Ss), E, say_stop(E)).
say_stop(E) :- error_text(E, T), stop_with(T).
stop_with(T) :- throw(stopped(T)).

%% a check whose else throws, written there: the else the choice took,
%% after up_step/1 failed in its clause
checked_up(X) :- ( up_step(X) -> true ; throw(error(not_up(X), checked_up/1)) ).

%% no choice made these raises. fallback_up/1's second clause raises
%% because its first failed -- at settled/1, the else of its if-then-else,
%% which tried a clause: that is the failure it answered, though the raise
%% is in no construct of the first clause. give_up_after/1 and noted_up/1
%% throw after an if-then-else that is over: its failed condition is no
%% part of why, and the throw is in neither of its branches -- after a
%% then whose last call exited, the first build of 1.11.7 read it as the
%% then's
fallback_up(X) :- ( up_step(X) -> true ; settled(X) ).
fallback_up(X) :- throw(error(no_step(X), fallback_up/1)).
settled(X) :- level_of(X, L), L > 9.
level_of(_, 1).
up_step(X) :- X > 0, ok_up(X).
ok_up(1).
give_up_after(X) :- ( settled(X) -> true ; true ), throw(error(gave_up(X), give_up_after/1)).
noted_up(X) :- ( up_step(X) -> note(X) ; true ), throw(error(noted(X), noted_up/1)).

%% a goal of each element, the goal handed in: test/flowdebug/top.pl hands
%% it one of its own (1.11.7)
each_hook(_, []).
each_hook(G, [S|Ss]) :- call(G, S), each_hook(G, Ss).
