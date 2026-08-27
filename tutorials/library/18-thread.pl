%% LIBRARY 18 -- library(thread): share nothing, copy the term
%%
%%     ./cocolog run tutorials/library/18-thread.pl main
%%
%% TIER 2: `use_module(library(thread))', a `.so' from `modules/thread'.
%% Needs nothing but pthreads: `sh modules/thread/build.sh'.
%%
%% A THREAD GETS ITS OWN MACHINE, STORE AND ENGINE. That is not a
%% conservative choice, it is the only correct one: a cocolog machine is
%% an unguarded heap, a trail and an atom table, and two threads proving
%% goals on one would corrupt it in a millisecond. Locking at that level
%% would be neither correct nor fast.
%%
%% SO A CHANNEL COPIES, in canonical text -- the same form the database
%% stores clauses in, quoted and with operators ignored, so a term reads
%% back on a machine that never ran the same `op/3'. Two machines cannot
%% share a heap cell, so a term crossing between them is copied whatever
%% the mechanism; text is the copy this interpreter already trusts.
%%
%% WHAT A THREAD CAN SEE, in one line each:
%%
%%   * EVERY REGISTERED MODULE -- linked-in ones, and anything
%%     `use_module' loaded BEFORE it started. The registry is
%%     process-wide and a fresh store consults all of it on the first
%%     goal.
%%   * NOTHING THE PARENT ASSERTED. A thread's store starts empty.
%%
%% REGISTER YOUR MODULES BEFORE YOU SPAWN. `use_module' writes that
%% registry, and a thread reading it while another writes is the one
%% unguarded thing here -- unguarded because loading libraries at start-up
%% is what every program does, and a lock would sit on the first goal of
%% every proof in the process.

:- use_module(library(thread)).

main :-
    format("~n-- a thread is a goal on a machine of its own~n"),
    thread_create((X is 2 + 2, X =:= 4), Id1),
    thread_join(Id1, S1),
    must('it ran and joined', S1, true),

    format("~n-- and the three outcomes are kept apart~n"),
    thread_create(fail, Id2), thread_join(Id2, S2),
    must('a goal that FAILED', S2, false),
    thread_create((Y is 1/0, write(Y)), Id3), thread_join(Id3, S3),
    ( S3 = error(_) -> E = tagged ; E = S3 ),
    must('a goal that RAISED', E, tagged),
    format("   `false' and `error(_)' are different answers. Failing the~n"),
    format("   join instead would make `it did not prove it' and `it~n"),
    format("   never started' the same thing.~n"),

    format("~n-- a channel carries a TERM between two machines~n"),
    channel_new(Ch1),
    thread_create(channel_send(Ch1, hello(world)), Id4),
    channel_recv(Ch1, Msg),
    thread_join(Id4, _),
    must('what crossed', Msg, hello(world)),

    format("~n-- ...and its STRUCTURE survives, operators and all~n"),
    channel_new(Ch2),
    thread_create(channel_send(Ch2, f(1+2, 'an atom', [a, b])), Id5),
    channel_recv(Ch2, F),
    thread_join(Id5, _),
    must('a compound with an operator in it', F, f(1+2, 'an atom', [a, b])),
    format("   Canonical text is what buys that: quoted atoms, operators~n"),
    format("   written as compounds, so the far machine reads the same~n"),
    format("   term having run no op/3 of its own.~n"),

    format("~n-- what a closed channel does~n"),
    channel_new(Ch3), channel_close(Ch3),
    ( channel_recv(Ch3, _) -> C1 = got ; C1 = failed ),
    must('recv on a closed empty channel', C1, failed),
    channel_new(Ch4),
    channel_send(Ch4, a), channel_send(Ch4, b), channel_close(Ch4),
    channel_recv(Ch4, A1), channel_recv(Ch4, A2),
    ( channel_recv(Ch4, _) -> C2 = more ; C2 = done ),
    must('but what was queued still comes out', [A1, A2, C2], [a, b, done]),
    format("   Closing does not discard. Otherwise a close would~n"),
    format("   silently drop whatever was in flight.~n"),
    channel_new(Ch5), channel_close(Ch5),
    ( channel_send(Ch5, x) -> C3 = sent ; C3 = refused ),
    must('sending to a closed one fails rather than raising', C3, refused),

    format("~n-- a timeout, so a receiver is never stuck~n"),
    channel_new(Ch6),
    ( channel_recv(Ch6, 300, _) -> C4 = got ; C4 = timed_out ),
    must('channel_recv/3 with 300ms', C4, timed_out),
    channel_new(Ch7), channel_send(Ch7, only),
    channel_recv(Ch7, 0, V7),
    must('...and 0 means take only what is already there', V7, only),

    format("~n-- backpressure: a bounded channel makes the SENDER wait~n"),
    channel_new(2, Ch8),
    thread_create(( channel_send(Ch8, 1), channel_send(Ch8, 2),
                    channel_send(Ch8, 3), channel_send(Ch8, 4) ), Id6),
    channel_recv(Ch8, _), channel_recv(Ch8, _),
    channel_recv(Ch8, _), channel_recv(Ch8, _),
    thread_join(Id6, S6),
    must('four through a channel of two', S6, true),

    format("~n-- a pool, and the helpers~n"),
    channel_new(Ch9),
    thread_pool(3, channel_send(Ch9, tick), Ids),
    length(Ids, PoolSize),
    must('thread_pool/3', PoolSize, 3),
    channel_recv(Ch9, _), channel_recv(Ch9, _), channel_recv(Ch9, _),
    thread_join_all(Ids),
    channel_new(ChA),
    channel_send(ChA, 1), channel_send(ChA, 2), channel_close(ChA),
    channel_drain(ChA, Drained),
    must('channel_drain/2 takes what is queued', Drained, [1, 2]),

    format("~n-- and a thread's store is ITS OWN~n"),
    assertz(only_here(1)),
    thread_create(only_here(_), IdX), thread_join(IdX, SX),
    ( SX = error(_) -> Seen = unseen ; Seen = SX ),
    must('a clause the PARENT asserted', Seen, unseen),
    retractall(only_here(_)),
    format("   Share-nothing, holding. Clauses are shared through the~n"),
    format("   DATABASE in this project, not through memory -- see~n"),
    format("   tutorials/basics/11.~n~n"),
    format("done~n").

:- dynamic only_here/1.

%% ---- the two helpers every lesson here carries ------------------------
%% REPEATED ON PURPOSE, in every file. A tutorial you can copy anywhere and
%% run is worth six duplicated lines; a tutorial that needs a support
%% library beside it is a tutorial that stops working the moment it is
%% moved.
show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

%% `must/3' IS WHY THESE FILES ARE TESTS. Every claim a lesson makes is a
%% goal that has to hold: get it wrong and `main' FAILS, loudly, naming
%% both answers. A tutorial that prints whatever it computed is a tutorial
%% that goes quietly wrong the day the language changes underneath it.
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
