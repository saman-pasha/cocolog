%% LIBRARY 19 -- library(zigurat): the connection, steered from Prolog
%%
%%     ./cocolog run tutorials/library/19-zigurat.pl main
%%
%%     ...and to see the half that needs a server:
%%
%%     ./cocolog --kb demo --host 127.0.0.1 --port 2160 \
%%               run tutorials/library/19-zigurat.pl main
%%
%% TIER 1: compiled in, no import. Which surprises people -- it looks like
%% a database driver -- but the knowledge base IS this interpreter, so the
%% predicates that steer its connection belong beside `assertz/1'.
%%
%% ONE TRANSACTION PER TURN IS THE DEFAULT, and most programs never touch
%% any of this. A `run' or a `query' opens a transaction, does what it was
%% asked, and commits; a goal that raised rolls back. That is the rule the
%% whole project is built on and it is the right default.
%%
%% THIS LIBRARY IS FOR WHEN THE DEFAULT IS NOT ENOUGH:
%%
%%     zigurat_begin                  open one explicitly
%%     zigurat_commit                 make writes durable BEFORE the turn ends
%%     zigurat_rollback               take uncommitted writes back
%%     zigurat_auto_commit(+Bool)     one transaction per statement, or not
%%     zigurat_isolation(+Level)      read_uncommitted .. serializable
%%     zigurat_transaction_id(-Id)    which transaction am I in
%%     zigurat_call(+Proc, +Args, -Rows)   call a compiled Parsi procedure
%%     zigurat_compile(+Source)       ship Parsi source to the server
%%
%% `--local' HAS NO CONNECTION, and every one of them says so as a
%% CATCHABLE error rather than pretending a local store has a transaction
%% to steer. That is what this file checks when you run it without a
%% server, and it is a real property: a program that works both ways
%% should be able to ask.

main :-
    (   catch(zigurat_transaction_id(_), error(cocolog_error(_), _), fail)
    ->  connected
    ;   local
    ).

connected :-
    format("~n-- there IS a connection, so the whole surface works~n"),
    zigurat_transaction_id(Id),
    ( integer(Id) -> K = an_integer ; K = Id ),
    must('zigurat_transaction_id/1', K, an_integer),

    format("~n-- an explicit commit makes a write durable BEFORE the turn~n"),
    format("   ends -- which is the point: another process can see it~n"),
    format("   while this one is still running.~n"),
    ( catch(zigurat_commit, _, true) -> C = committed ; C = refused ),
    must('zigurat_commit', C, committed),

    format("~n-- isolation is a per-turn choice~n"),
    ( catch(zigurat_isolation(read_committed), _, fail) -> I = set ; I = no ),
    must('zigurat_isolation(read_committed)', I, set),
    format("   `read_uncommitted' is what lets a reader audit a chain a~n"),
    format("   writer has staged and not yet committed -- The Coco's~n"),
    format("   speculative lane is exactly that, and it is why this~n"),
    format("   knob exists at all.~n"),
    finish.

local :-
    format("~n-- NO CONNECTION HERE: this is a --local run~n"),
    format("   Every predicate below says so, catchably, rather than~n"),
    format("   pretending a local store has a transaction to steer.~n~n"),
    refuses(zigurat_begin, 'zigurat_begin'),
    refuses(zigurat_commit, 'zigurat_commit'),
    refuses(zigurat_rollback, 'zigurat_rollback'),
    refuses(zigurat_transaction_id(_), 'zigurat_transaction_id/1'),
    refuses(zigurat_isolation(serializable), 'zigurat_isolation/1'),
    refuses(zigurat_auto_commit(true), 'zigurat_auto_commit/1'),
    format("~n   The ball is `error(cocolog_error(Text), _)' and the text~n"),
    format("   names the arrangement -- so a program that runs both ways~n"),
    format("   can ASK, with a catch, instead of being told.~n"),
    format("~n-- run this file against a server to see the other half:~n"),
    format("~n"),
    format("     cocolog --kb demo --host 127.0.0.1 --port 2160 \\~n"),
    format("             run tutorials/library/19-zigurat.pl main~n"),
    finish.

finish :-
    format("~n-- AND THE DEFAULT IS STILL THE RIGHT ONE~n"),
    format("   One transaction per turn: a `run' or a `query' opens it,~n"),
    format("   does the work and commits; a goal that raised rolls back.~n"),
    format("   Most programs should never call anything in this file.~n"),
    format("   Reach for it when a write has to be visible before the~n"),
    format("   turn ends, when you want a different isolation level for~n"),
    format("   one proof, or when you are calling a Parsi procedure~n"),
    format("   directly with zigurat_call/3.~n~n"),
    format("done~n").

refuses(Goal, Label) :-
    (   catch(Goal, error(cocolog_error(_), _), true)
    ->  R = said_so
    ;   R = failed_silently
    ),
    must(Label, R, said_so).

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
