%% cocolog tutorial 49 -- library(websocket): RFC 6455, a client and a server.
%%
%% TIER 2, clauses only: `use_module(library(websocket))'. It sits on
%% library(tcp) -- and library(tls) for wss:// -- reads its opening
%% handshake with library(http)'s grammar, and serves through
%% library(httpd): a page that answers `websocket(Goal)' is handed the
%% connection, and Goal runs for as long as the session lasts.
%%
%%     ws_open(+URL, -WS)  ws_open(+URL, -WS, +Options)     a client
%%     ws_send(+WS, +Message)                               text(T) binary(B) ping(D) pong(D) close(C, Why)
%%     ws_receive(+WS, -Message)  ws_receive(+WS, -M, +Opts) the next message; pings answered on the way
%%     ws_close(+WS)  ws_close(+WS, +Code, +Why)             the closing handshake
%%     httpd_page(Path, Request, websocket(Goal))           a server
%%
%% EVERY CONVERSATION ENDS WITH close(Code, Why), whoever ended it -- the
%% peer, this side failing it (1002, 1007, 1009), or a connection lost
%% (1006) -- so a session loop has one way out to test for. A timeout is a
%% plain failure, as it is in library(tcp).
%%
%% THIS FILE TALKS TO ITSELF over the loopback interface, both ends of one
%% connection in one process -- which is why it does the handshake by hand
%% with the library's pieces: ws_open/3 would wait for an answer this
%% process has not written yet. A real client is one line, section 5.
%%
%% WHAT THIS LESSON CLAIMS:
%%
%%     1  the handshake is arithmetic: SHA-1 and base64 of the client's key
%%     2  a frame, byte by byte, exactly as RFC 6455 writes one
%%     3  masking is XOR with four bytes, and its own inverse
%%     4  a session: the handshake, messages both ways, a ping, the close
%%     5  a server is an httpd page; a client is ws_open

:- use_module(library(tcp)).
:- use_module(library(http)).
:- use_module(library(websocket)).

main :-
    t49_key,
    t49_frame,
    t49_mask,
    t49_session,
    t49_shapes,
    format("done~n").

t49_key :-
    format("~n-- 1. THE HANDSHAKE IS ARITHMETIC~n"),
    format("   The client sends sixteen random bytes as base64; the server~n"),
    format("   answers with base64(SHA-1(key ++ a GUID fixed by the RFC)).~n"),
    format("   Proof the server read THIS request, not that it is a friend.~n"),
    ws_accept_key('dGhlIHNhbXBsZSBub25jZQ==', Accept),
    must('the key RFC 6455 section 1.3 works through', Accept, 's3pPLMBiTxaQ9kYGzzhZRbK+xOo='),
    atom_codes(abc, ABC), ws_sha1(ABC, D), length(D, N),
    must('SHA-1 is twenty bytes', N, 20),
    ws_base64([1, 2, 3, 4], B64),
    must('and base64 pads to four characters a group', B64, 'AQIDBA==').

t49_frame :-
    format("~n-- 2. A FRAME, BYTE BY BYTE~n"),
    format("   FIN and the opcode in the first byte, MASK and a length in the~n"),
    format("   second, then the mask key, then the payload. A client's frames~n"),
    format("   are masked; a server's are not.~n"),
    atom_codes('Hello', Hello),
    ws_frame_bytes(1, 1, [55, 250, 33, 61], Hello, F),
    must('a masked text frame, as RFC 6455 section 5.7 prints it', F,
         [129, 133, 55, 250, 33, 61, 127, 159, 77, 81, 88]),
    ws_frame(F, Frame, Rest),
    must('...read back: FIN, text, the key, the payload unmasked', Frame-Rest,
         frame(1, 1, [55, 250, 33, 61], Hello)-[]),
    length(Big, 300), maplist(=(0), Big),
    ws_frame_bytes(1, 2, none, Big, BF), BF = [_, L|_],
    must('300 bytes: the length byte says 126, sixteen bits follow', L, 126).

t49_mask :-
    format("~n-- 3. MASKING IS XOR, AND ITS OWN INVERSE~n"),
    format("   So one predicate masks and unmasks. The key travels with the~n"),
    format("   frame: it is not a secret, it is what stops a script in a~n"),
    format("   browser writing bytes a proxy would read as HTTP.~n"),
    atom_codes('Hello', Hello),
    ws_mask(Hello, [55, 250, 33, 61], Masked),
    must('masked', Masked, [127, 159, 77, 81, 88]),
    ws_mask(Masked, [55, 250, 33, 61], Back),
    must('masked again is the original', Back, Hello).

t49_session :-
    format("~n-- 4. A SESSION, BOTH ENDS IN ONE PROCESS~n"),
    Port = 18879,
    tcp_listen(Port, Listener),
    tcp_connect('127.0.0.1', Port, CS),
    tcp_accept(Listener, 2000, SS, _),
    %% THE CLIENT ASKS. A lesson's fixed key; ws_open draws sixteen fresh bytes.
    Key = 'dGhlIHNhbXBsZSBub25jZQ==',
    ws_handshake_request('/echo', '127.0.0.1', Key, [chat], [], Req),
    tcp_write(CS, Req),
    %% THE SERVER READS IT AS HTTP -- which it is -- and checks it whole.
    tcp_read(SS, 4096, 2000, Got),
    http_request(Got, Request, After),
    ws_handshake_check(Request, After, Result),
    must('the server finds a handshake, and the protocol offered', Result, accept(Key, [chat])),
    ws_accept_key(Key, Accept),
    ws_handshake_response(Accept, chat, Resp),
    tcp_write(SS, Resp),
    %% THE CLIENT READS THE 101 to its blank line and not a byte further.
    ws_read_head(plain(CS), 2000, 16384, Head),
    ws_handshake_answer(Head, Key, [chat], Protocol, Why),
    must('the client accepts the 101, and the protocol it names', Protocol-Why, chat-ok),
    %% FROM HERE ON, TWO WEBSOCKETS.
    Client = websocket(plain(CS), client, chat),
    Server = websocket(plain(SS), server, chat),
    ws_send(Client, text('hello, server')),
    ws_receive(Server, M1, [timeout(2000), format(atom)]),
    must('text, client to server', M1, text('hello, server')),
    ws_send(Server, binary([1, 2, 3, 0, 255])),
    ws_receive(Client, M2, [timeout(2000)]),
    must('binary, server to client, NULs and all', M2, binary([1, 2, 3, 0, 255])),
    %% A PING IS ANSWERED BY THE LIBRARY, not by the program: the server's
    %% receive replies to it on the way to the next real message.
    ws_send(Client, ping(are_you_there)),
    ws_send(Client, text(after)),
    ws_receive(Server, M3, [timeout(2000), format(atom)]),
    must('the server sees the message after the ping', M3, text(after)),
    ws_receive(Client, M4, [timeout(2000)]),
    ( M4 = pong(Cs) -> atom_codes(A4, Cs), G4 = pong(A4) ; G4 = M4 ),
    must('...and the client the pong, with the ping''s own data', G4, pong(are_you_there)),
    %% THE CLOSE: the client says so, the server's receive hears it and
    %% replies, and the client's next receive reads that reply.
    ws_send(Client, close(1000, 'all done')),
    ws_receive(Server, M5, [timeout(2000)]),
    must('the server hears close(Code, Why)', M5, close(1000, 'all done')),
    tcp_close(SS),                      % a server's socket is its loop's -- here, ours
    ws_receive(Client, M6, [timeout(2000)]),
    must('the client reads the reply, its code echoed', M6, close(1000, '')),
    tcp_sockets(Open),
    must('and closes its own socket: only the listener is left', Open, [Listener]),
    tcp_close(Listener).

t49_shapes :-
    format("~n-- 5. A SERVER IS AN httpd PAGE, A CLIENT IS ONE CALL~n"),
    format("     :- use_module(library(httpd)).~n"),
    format("     httpd_page('/echo', _Request, websocket(echo)).~n"),
    format("     echo(WS) :-~n"),
    format("         ws_receive(WS, M),~n"),
    format("         ( M = close(_, _) -> true ; ws_send(WS, M), echo(WS) ).~n"),
    format("     main :- httpd_serve(8080, [workers(4)]).~n~n"),
    format("     ws_open('ws://127.0.0.1:8080/echo', WS),~n"),
    format("     ws_send(WS, text(hi)), ws_receive(WS, text(Echo)),~n"),
    format("     ws_close(WS).~n"),
    format("   A session holds its connection for as long as it lasts, so a~n"),
    format("   server with sessions wants workers(N); and a session is one~n"),
    format("   transaction, as a connection always is in library(httpd).~n"),
    format("   wss:// is library(tls): httpd's tls(...) option on the server,~n"),
    format("   ws_open's tls(Creds) on the client.~n").

must(What, Got, Want) :-
    (   Got == Want
    ->  format("     ok: ~w -> ~q~n", [What, Got])
    ;   format("     ~w = ~q  BUT THIS LESSON SAYS ~q~n", [What, Got, Want]),
        fail
    ).
