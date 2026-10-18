%% LIBRARY 17 -- library(tcp): the socket seam
%%
%%     ./cocolog run tutorials/library/17-tcp.pl main
%%
%% TIER 2: `use_module(library(tcp))', a `.so' built from `modules/tcp'.
%% It needs nothing but libc: `sh modules/tcp/build.sh'.
%%
%% THE ONE THING TO UNDERSTAND: A HANDLE IS NOT A FILE DESCRIPTOR. tcp
%% keeps `coco_t_fd[256]' at file scope inside its own shared object, and
%% a handle is an INDEX into that table. Which has two consequences worth
%% knowing before you build anything on it:
%%
%%   * the table belongs to the PROCESS, so a handle can cross threads --
%%     which is exactly what library(httpd)'s worker pool does: one thread
%%     accepts and posts the handle down a channel, another reads it;
%%   * nothing guards the allocation, so only ONE thread may ever accept.
%%     That is not a limitation the pool works around, it is the reason
%%     the pool is shaped the way it is.
%%
%% THE SURFACE:
%%
%%     tcp_listen(+Port, -Socket)       tcp_listen(+unix(Path), -Socket)
%%     tcp_accept(+Socket, +TimeoutMs, -Conn, -Peer)
%%     tcp_connect(+Host, +Port, -Conn) tcp_connect(+unix(Path), -Conn)
%%                                      tcp_connect(+Host:Port, -Conn)
%%     tcp_read(+Conn, +MaxBytes, +TimeoutMs, -Codes)
%%     tcp_write(+Conn, +Text)
%%     tcp_close(+Conn)
%%     tcp_why(-Reason)                 why the last read, connect or listen failed
%%
%% IT READS AND WRITES CODES, for the reason library(http) gives: an atom
%% stops at the first NUL and a body is not text.
%%
%% A UNIX DOMAIN SOCKET IS AN ADDRESS (2.4.0): `unix(Path)' where a port
%% stands, and everything after it the same. The socket is a file, which
%% the listen makes and the listener's close removes.
%%
%% THIS FILE TALKS TO ITSELF over the loopback interface and over a socket
%% file in /tmp, which need no network and no other program.

:- use_module(library(tcp)).

main :-
    format("~n-- a listener, and what a handle is~n"),
    Port = 18871,
    tcp_listen(Port, Server),
    ( integer(Server) -> K = an_integer ; K = Server ),
    must('a handle is an index into tcp''s own table', K, an_integer),

    format("~n-- connect to ourselves, and accept the other end~n"),
    tcp_connect('127.0.0.1', Port, Client),
    tcp_accept(Server, 2000, Conn, Peer),
    %% THE PEER IS `address:port', not just the address -- the ephemeral
    %% port is different on every run, so a lesson can only check the
    %% half that is stable. Which is itself the useful fact: if you want
    %% the address, split it.
    ( sub_atom(Peer, 0, _, _, '127.0.0.1:') -> P = loopback ; P = Peer ),
    must('the peer is address:port', P, loopback),
    %% SPLIT INTO A PROPER LIST FIRST. `atomic_list_concat([A|_], ':', X)'
    %% with a PARTIAL list does not split -- the predicate needs to know
    %% how many pieces it is making. Split, then take the head.
    atomic_list_concat(Parts, ':', Peer),
    Parts = [Addr|_],
    must('...so the address is the part before the colon', Addr, '127.0.0.1'),

    format("~n-- write one way, read the other~n"),
    tcp_write(Client, 'hello over a socket'),
    tcp_read(Conn, 1024, 2000, Codes),
    atom_codes(Got, Codes),
    must('what arrived', Got, 'hello over a socket'),

    format("~n-- and back~n"),
    tcp_write(Conn, 'and back again'),
    tcp_read(Client, 1024, 2000, Codes2),
    atom_codes(Got2, Codes2),
    must('the reply', Got2, 'and back again'),

    format("~n-- a read that times out FAILS rather than hanging~n"),
    ( tcp_read(Conn, 1024, 200, _) -> R = read_something ; R = timed_out ),
    must('nothing to read, 200ms', R, timed_out),
    format("   An ordinary no. A server loop can decide what that means~n"),
    format("   -- a slow client, or a client that has gone -- instead of~n"),
    format("   being blocked forever by either.~n"),

    format("~n-- closing~n"),
    tcp_close(Client),
    tcp_close(Conn),
    tcp_close(Server),
    format("   A handle is a table slot, so closing frees the slot. A~n"),
    format("   program that leaks them runs out at 256, which is a~n"),
    format("   deliberate ceiling: the table is static, and a server that~n"),
    format("   needs more connections than that needs a design, not a~n"),
    format("   bigger array.~n"),

    format("~n-- accepting with no client waiting also just times out~n"),
    tcp_listen(18872, S2),
    ( tcp_accept(S2, 200, _, _) -> A = accepted ; A = timed_out ),
    must('tcp_accept with nobody there', A, timed_out),
    tcp_close(S2),

    unix_socket,

    format("~n-- WHAT TO BUILD ON THIS: library(http) parses what you~n"),
    format("   read, library(httpd) is the server loop, and~n"),
    format("   library(curl) is the client for when you want one that~n"),
    format("   already speaks TLS and redirects.~n~n"),
    format("done~n").

%% A SOCKET FILE, from its listen to its close -- its own predicate, for
%% the reason lesson 46 gives: a `main' longer than a page is one cocolint
%% asks to be split.
unix_socket :-
    format("~n-- a UNIX SOCKET: unix(Path) where the port stood~n"),
    tmp_file(lesson17, T0), atom_concat(T0, '.sock', Path),
    tcp_listen(unix(Path), Server),
    ( access_file(Path, exist) -> F1 = made ; F1 = none ),
    must('the listen makes a socket file', F1, made),
    tcp_connect(unix(Path), Client),
    tcp_accept(Server, 2000, Conn, Peer),
    %% NGINX'S WORD for a peer on a socket file: a client seldom binds a
    %% path of its own, and one that does has it after the colon
    must('a peer on a socket file', Peer, 'unix:'),
    tcp_write(Client, 'through a file'),
    tcp_read(Conn, 1024, 2000, Codes), atom_codes(Got, Codes),
    must('and the same bytes cross', Got, 'through a file'),
    format("   Same slots, same reads and writes, same close -- so~n"),
    format("   library(httpd) serves on one as httpd_serve(unix(Path), Opts).~n"),
    tcp_close(Client), tcp_close(Conn),

    format("~n-- a live server's file is not taken from it~n"),
    ( tcp_listen(unix(Path), _) -> L2 = bound ; tcp_why(L2) ),
    must('a second listen on the path', L2, 'Address already in use'),
    %% THE LISTEN ASKED BY CONNECTING, and the server saw it: a connection
    %% that closed at once. Nobody answering is what lets a listen replace
    %% the leftover file of a server that died without closing.
    ( tcp_accept(Server, 2000, Q, _) -> tcp_close(Q), Saw = a_connection ; Saw = nothing ),
    must('what the first server saw of the question', Saw, a_connection),

    format("~n-- the listener's close removes its file~n"),
    tcp_close(Server),
    ( access_file(Path, exist) -> F2 = left ; F2 = removed ),
    must('after the close', F2, removed),
    ( tcp_connect(unix(Path), _) -> W = connected ; tcp_why(W) ),
    must('and a connect to a file nobody made fails, saying why', W, 'No such file or directory').

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
