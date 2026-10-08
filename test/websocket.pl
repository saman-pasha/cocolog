%% websocket: library(websocket) -- RFC 6455's own examples byte for byte,
%% the handshake both ways, and live sessions against an httpd page.
%%
%% THE PIECES ARE CHECKED WITHOUT A SOCKET, against the documents rather
%% than against this library's own idea of itself: FIPS 180's SHA-1
%% vectors, RFC 4648's base64 ones, the handshake key of RFC 6455 section
%% 1.3, and every frame section 5.7 spells out in hex. A frame library
%% that agrees with itself and not with the RFC is the failure this case
%% exists to catch.
%%
%% THE SESSIONS ARE ONE COCOLOG TALKING TO ANOTHER: a spawned httpd whose
%% pages answer `websocket(Goal)', and this process as the client -- through
%% ws_open/3 where the client is meant to be right, and through raw frames
%% written by hand where the point is a client that is WRONG (unmasked, not
%% UTF-8, fragmented with a ping in the middle), because ws_send cannot be
%% made to send those and the server's answer to them is the claim.
%%
%%     cocolog -s test/websocket.pl        from the checkout root

:- use_module('test/prelude.pl').
:- use_module(library(websocket)).

main :-
    ( catch(use_module(library(tcp)), _, fail) -> true ; skip('no library(tcp): sh modules/tcp/build.sh') ),
    scratch(D),
    digests, the_handshake, frames, utf8_rules,
    sessions(D),
    pooled(D),
    secure(D),
    shl(['rm -rf ', D]),
    checks_done.

%% ---- SHA-1 and base64, against their standards --------------------------

digests :-
    section('SHA-1 and base64, against FIPS 180 and RFC 4648'),
    hex_digest('abc', H1),
    check('sha1("abc")', H1, a9993e364706816aba3e25717850c26c9cd0d89d),
    hex_digest('', H2),
    check('sha1("")', H2, da39a3ee5e6b4b0d3255bfef95601890afd80709),
    hex_digest(abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq, H3),
    check('sha1 of the 448-bit message, two blocks', H3, '84983e441c3bd26ebaae4aa1f95129e5e54670f1'),
    %% AND AGAINST library(sha), WHERE IT LOADS: the one cocolog already
    %% trusts. A thousand bytes is sixteen blocks and a padding block.
    (   catch(use_module(library(sha)), _, fail),
        catch(sha_hash(sha1, x, _), _, fail)
    ->  length(L4, 1000), maplist(=(0'q), L4), atom_codes(A4, L4),
        hex_digest(A4, Mine4), sha_hash(sha1, A4, Theirs4),
        downcase_atom(Theirs4, T4),
        check('sha1 of a thousand bytes, as library(sha) has it', Mine4, T4)
    ;   format("     (skipped: library(sha) -- the FIPS vectors above stand alone)~n")
    ),
    forall(member(In-Out, [''-'', f-'Zg==', fo-'Zm8=', foo-'Zm9v', foob-'Zm9vYg==',
                           fooba-'Zm9vYmE=', foobar-'Zm9vYmFy']),
           ( atom_codes(In, Bs), ws_base64(Bs, Got),
             atomic_list_concat(['base64("', In, '")'], L),
             check(L, Got, Out) )),
    findall(In, ( member(In, [f, fo, foo, foob, fooba, foobar]),
                  atom_codes(In, Bs), ws_base64(Bs, B64), ws_unbase64(B64, Back), Back == Bs ), RT),
    check('base64 decodes back to every input', RT, [f, fo, foo, foob, fooba, foobar]),
    findall(Bad, ( member(Bad, ['Zm9', 'Zm=v', 'Z===', 'Zm9v!', 'Zh==']), ws_unbase64(Bad, _) ), Taken),
    check('malformed base64 is refused, and so is padding with bits left over', Taken, []).

hex_digest(Atom, Hex) :-
    atom_codes(Atom, Bs), ws_sha1(Bs, D), bytes_hex(D, Hex).

bytes_hex(Bytes, Hex) :-
    findall(C, ( member(B, Bytes), H is B >> 4, L is B /\ 15,
                 ( member(N, [H, L]), hexit(N, C) ) ), Cs),
    atom_codes(Hex, Cs).

hexit(N, C) :- N < 10, !, C is 0'0 + N.
hexit(N, C) :- C is 0'a + N - 10.

%% ---- the opening handshake -------------------------------------------------

the_handshake :-
    section('the opening handshake'),
    ws_accept_key('dGhlIHNhbXBsZSBub25jZQ==', A1),
    check('the key of RFC 6455 section 1.3', A1, 's3pPLMBiTxaQ9kYGzzhZRbK+xOo='),
    Key = 'dGhlIHNhbXBsZSBub25jZQ==',
    ws_handshake_request('/chat?room=1', 'server.example.com', Key, [chat, superchat],
                         ['Origin'-'http://example.com'], Req2),
    http_request(Req2, R2, Rest2),
    ws_handshake_check(R2, Rest2, Res2),
    check('a request as ws_open writes it is accepted, its protocols read', Res2,
          accept(Key, [chat, superchat])),
    ( R2 = request(get, '/chat', [room-'1'], _, _, _) -> G2 = yes ; G2 = R2 ),
    check('...and it is a GET for the path and query', G2, yes),
    refused(['GET / HTTP/1.1', 'Host: x', 'Upgrade: websocket', 'Connection: Upgrade',
             'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==', 'Sec-WebSocket-Version: 8'], S3, H3),
    check('version 8 is 426, naming 13', S3-H3, 426-['Sec-WebSocket-Version'-'13']),
    refused(['GET / HTTP/1.1', 'Host: x', 'Upgrade: websocket', 'Connection: Upgrade',
             'Sec-WebSocket-Version: 13'], S4, _),
    check('no key is 400', S4, 400),
    refused(['GET / HTTP/1.1', 'Host: x', 'Upgrade: websocket', 'Connection: Upgrade',
             'Sec-WebSocket-Key: c2hvcnQ=', 'Sec-WebSocket-Version: 13'], S5, _),
    check('a key that is not sixteen bytes is 400', S5, 400),
    refused(['POST / HTTP/1.1', 'Host: x', 'Upgrade: websocket', 'Connection: Upgrade',
             'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==', 'Sec-WebSocket-Version: 13',
             'Content-Length: 0'], S6, _),
    check('a POST is 405', S6, 405),
    refused(['GET / HTTP/1.1', 'Host: x', 'Upgrade: websocket',
             'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==', 'Sec-WebSocket-Version: 13'], S7, _),
    check('no Connection: Upgrade is 400', S7, 400),
    %% THE TOKENS ARE A LIST, AND CASE IS NOT A DIFFERENCE: what a browser
    %% sends through a proxy looks like this.
    lines_codes(['GET / HTTP/1.1', 'Host: x', 'Upgrade: WebSocket', 'Connection: keep-alive, Upgrade',
                 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==', 'Sec-WebSocket-Version: 13'], Q8),
    http_request(Q8, R8, Rest8), ws_handshake_check(R8, Rest8, Res8),
    ( Res8 = accept(_, _) -> G8 = accepted ; G8 = Res8 ),
    check('Upgrade: WebSocket and Connection: keep-alive, Upgrade are accepted', G8, accepted),
    append(Q8, [129, 133, 1, 2, 3, 4, 5, 6, 7, 8, 9], Q9),
    http_request(Q9, R9, Rest9), ws_handshake_check(R9, Rest9, Res9),
    ( Res9 = refuse(S9, _, _) -> true ; S9 = Res9 ),
    check('a frame sent before the 101 is refused, 400', S9, 400),
    %% THE ANSWER, both ways round: what a server sends, read by what a
    %% client checks.
    ws_handshake_response(A1, chat, Resp10),
    ws_handshake_answer(Resp10, Key, [superchat, chat], P10, Why10),
    check('the 101 a server sends is one a client accepts, with its protocol', P10-Why10, chat-ok),
    ws_handshake_answer(Resp10, 'AAAAAAAAAAAAAAAAAAAAAA==', [chat], _, Why11),
    check('...and refuses for any other key', Why11, 'Sec-WebSocket-Accept is not this key''s'),
    ws_handshake_answer(Resp10, Key, [superchat], _, Why12),
    check('...and when the server chose a protocol nobody offered', Why12,
          'the server chose chat, which was not offered'),
    ws_handshake_response(A1, '', Resp13),
    atom_codes(Head13, Resp13),
    ( sub_atom(Head13, _, _, _, 'Content-Length') -> CL13 = present ; CL13 = absent ),
    check('the 101 carries no Content-Length (RFC 7230 section 3.3.2)', CL13, absent).

refused(Lines, Status, Headers) :-
    lines_codes(Lines, Cs),
    http_request(Cs, R, Rest),
    ws_handshake_check(R, Rest, refuse(Status, Headers, _)).

lines_codes(Lines, Codes) :-
    atomic_list_concat(Lines, '\r\n', A0),
    atom_concat(A0, '\r\n\r\n', A),
    atom_codes(A, Codes).

%% ---- frames, RFC 6455 section 5.7 ------------------------------------------

frames :-
    section('frames, as RFC 6455 section 5.7 writes them'),
    Hello = [72, 101, 108, 108, 111],
    Mask = [55, 250, 33, 61],
    ws_frame_bytes(1, 1, none, Hello, F1),
    check('a single-frame unmasked text message', F1, [129, 5, 72, 101, 108, 108, 111]),
    ws_frame_bytes(1, 1, Mask, Hello, F2),
    check('a single-frame masked text message', F2,
          [129, 133, 55, 250, 33, 61, 127, 159, 77, 81, 88]),
    ws_frame(F2, Fr2, Rest2),
    check('...and read back, unmasked, with the key it came with', Fr2-Rest2,
          frame(1, 1, Mask, Hello)-[]),
    append([1, 3, 72, 101, 108], [128, 2, 108, 111], Frag),
    ws_frame(Frag, Fa, AfterA), ws_frame(AfterA, Fb, AfterB),
    check('a fragmented unmasked text message, two frames', Fa-Fb-AfterB,
          frame(0, 1, none, [72, 101, 108])-frame(1, 0, none, [108, 111])-[]),
    ws_frame([137, 5, 72, 101, 108, 108, 111], Ping, _),
    check('an unmasked ping', Ping, frame(1, 9, none, Hello)),
    ws_frame([138, 133, 55, 250, 33, 61, 127, 159, 77, 81, 88], Pong, _),
    check('a masked pong', Pong, frame(1, 10, Mask, Hello)),
    length(B256, 256), maplist(=(7), B256),
    ws_frame_bytes(1, 2, none, B256, F256), length(H256, 4), append(H256, _, F256),
    check('256 bytes of binary: 126 and a 16-bit length', H256, [130, 126, 1, 0]),
    length(B64k, 65536), maplist(=(9), B64k),
    ws_frame_bytes(1, 2, none, B64k, F64k), length(H64k, 10), append(H64k, Body64k, F64k),
    check('64 KiB of binary: 127 and a 64-bit length', H64k, [130, 127, 0, 0, 0, 0, 0, 1, 0, 0]),
    length(Body64k, N64k),
    check('...followed by every byte', N64k, 65536),
    ws_frame(F64k, frame(_, _, _, P64k), _), length(P64k, NP64k),
    check('...and read back whole', NP64k, 65536),
    %% THE RULES, each as the code it fails with
    framed([129, 5, 72, 101], G9),
    check('a frame that has not all arrived is not a frame yet', G9, incomplete),
    framed([193, 0], G10),
    check('an RSV bit set is 1002', G10, ws_fail(1002)),
    framed([131, 0], G11),
    check('opcode 3 is 1002', G11, ws_fail(1002)),
    framed([9, 0], G12),
    check('a ping in fragments is 1002', G12, ws_fail(1002)),
    length(L126, 126), maplist(=(0), L126), append([137, 126, 0, 126], L126, F13),
    framed(F13, G13),
    check('a ping of 126 bytes is 1002', G13, ws_fail(1002)),
    framed([130, 127, 0, 0, 0, 1, 0, 0, 0, 0], G14),
    check('a length of four gigabytes is 1009, before any of it is read', G14, ws_fail(1009)),
    length(L200, 200), maplist(=(1), L200), ws_frame_bytes(1, 2, none, L200, F15),
    ( catch(( ws_frame(F15, 100, _, _), G15 = read ), ws_fail(C15, _), G15 = ws_fail(C15)) -> true ; G15 = failed ),
    check('a frame over max_message is 1009', G15, ws_fail(1009)),
    findall(N, ( between(0, 9, N), length(X, N), maplist(=(170), X),
                 ws_mask(X, Mask, Y), ws_mask(Y, Mask, Z), Z == X ), Ns),
    check('masking is its own inverse, at every length 0..9', Ns, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]).

framed(Bytes, G) :-
    (   catch(( ws_frame(Bytes, _, _), G0 = read ), ws_fail(C, _), G0 = ws_fail(C))
    ->  G = G0
    ;   G = incomplete
    ).

%% ---- UTF-8 -----------------------------------------------------------------

utf8_rules :-
    section('UTF-8, strictly'),
    atom_codes('héllo, wörld', A1),
    findall(Name, ( member(Name-Bs, [ascii-[104, 105], latin-A1, euro-[226, 130, 172],
                                      clef-[240, 157, 132, 158], empty-[]]),
                    ws_utf8(Bs) ), Good),
    check('ASCII, two, three and four bytes, and nothing, are UTF-8', Good,
          [ascii, latin, euro, clef, empty]),
    findall(Name, ( member(Name-Bs, [overlong-[192, 128], overlong3-[224, 128, 128],
                                      surrogate-[237, 160, 128], too_high-[244, 144, 128, 128],
                                      cut-[226, 130], lone-[128], ff-[255]]),
                    ws_utf8(Bs) ), Bad),
    check('overlongs, a surrogate, past U+10FFFF, a cut sequence, a lone tail, 0xFF are not', Bad, []).

%% ---- live sessions -----------------------------------------------------------

%% `cocolog ARGS' in a session of its own, under a cap, until its port listens
serving(Args, Port, Pid) :-
    cocolog(C),
    sh_join(['timeout 120 ', C, ' ', Args, ' >/dev/null 2>&1'], Cmd),
    spawn(Cmd, Pid),
    sh_join(['lsof -iTCP:', Port, ' -sTCP:LISTEN >/dev/null 2>&1'], Listening),
    ( proc_until(sh_exit(Listening, 0), 8000, 100) -> true ; true ).

reap(Pid) :- ( proc_wait(Pid, 3000, _) -> true ; proc_stop(Pid) ).

server_lines(Serve,
    [ ':- use_module(library(httpd)).',
      'httpd_page(''/echo'', _, websocket(echo)).',
      'httpd_page(''/chat'', _, websocket(chat, [protocols([chat])])).',
      'httpd_page(''/bye'', _, websocket(bye)).',
      'httpd_page(''/quiet'', _, websocket(quiet)).',
      'httpd_page(''/boom'', _, websocket(boom)).',
      'httpd_page(''/late'', _, websocket(late)).',
      'httpd_page(''/plain'', _, reply(200, [], ''plain page'')).',
      'echo(WS) :- ws_receive(WS, M), ( M = close(_, _) -> true ; ws_send(WS, M), echo(WS) ).',
      'chat(WS) :- ws_subprotocol(WS, P), ws_send(WS, text(P)), echo(WS).',
      'bye(WS) :- ws_send(WS, text(hello)), ws_close(WS, 1001, ''going away'').',
      'quiet(WS) :- ws_send(WS, text(hello)).',
      'boom(WS) :- ws_send(WS, text(hello)), throw(boom).',
      'late(WS) :- ws_receive(WS, close(_, _)), throw(late).',
      Serve ]).

%% THE SERVER IS REAPED WHATEVER THE CHECKS DID. A check that failed outright
%% used to end this section before the reap, and the server lived on for
%% its whole cap holding the port -- which the next run then talked to.
sessions(D) :-
    section('live sessions against an httpd page'),
    Port = 18895,
    atom_concat(D, '/server.pl', Server),
    %% THIRTEEN CONNECTIONS, one accept each, in the order below
    server_lines('serve :- httpd_serve(18895, [accept_timeout(20000)], 13).', Lines),
    fixture(Server, Lines),
    sh_join(['run ', Server, ' serve'], Args),
    serving(Args, Port, Pid),
    (   catch(session_checks(Port), E, true)
    ->  ( var(E) -> true ; check('the session checks ran to the end', E, ran) )
    ;   check('the session checks ran to the end', failed, ran)
    ),
    reap(Pid).

session_checks(Port) :-
    tcp_sockets(Before),
    Url = 'ws://127.0.0.1:18895/echo',
    %% 1. the round trips
    (   ws_open(Url, WS)
    ->  sent(WS, text(hello)), recv(WS, [], M1),
        check('a text message comes back', M1, text([104, 101, 108, 108, 111])),
        sent(WS, text('héllo, wörld')), recv(WS, [format(atom)], M2),
        check('...UTF-8, as an atom when asked', M2, text('héllo, wörld')),
        sent(WS, binary([0, 1, 2, 255, 0])), recv(WS, [], M3),
        check('binary, NULs and all', M3, binary([0, 1, 2, 255, 0])),
        sent(WS, ping(abc)), recv(WS, [], M4),
        check('a ping is answered with its own data', M4, pong([97, 98, 99])),
        length(Big, 70000), maplist(=(0'z), Big),
        sent(WS, text(Big)), recv(WS, [], M5),
        ( M5 == text(Big) -> G5 = same ; G5 = M5 ),
        check('70 000 bytes, a 64-bit length both ways', G5, same),
        ( ws_receive(WS, M19, [timeout(200)]) -> G19 = M19 ; G19 = timed_out ),
        sent(WS, text(still)), recv(WS, [format(atom)], M19b),
        check('a timeout is a plain failure, and the conversation goes on', G19-M19b,
              timed_out-text(still)),
        length(Bin, 100000), maplist(=(0), Bin),
        sent(WS, binary(Bin)), recv(WS, [max_message(50000)], M6),
        ( M6 = close(C6, _) -> true ; C6 = M6 ),
        check('a message over max_message ends it, 1009', C6, 1009)
    ;   ws_why(W), check('ws_open to an echo page', W, opened)
    ),
    %% 2. the closing handshake, and nothing left behind
    ( ws_open(Url, WS7) -> ws_close(WS7) ; true ),
    tcp_sockets(After),
    check('the closing handshakes leave no socket behind', After, Before),
    %% 3. a protocol chosen
    (   ws_open('ws://127.0.0.1:18895/chat', WS8, [protocols([superchat, chat])])
    ->  ws_subprotocol(WS8, P8), recv(WS8, [format(atom)], M8),
        check('the protocol both sides speak is the one agreed', P8-M8, chat-text(chat)),
        ws_close(WS8)
    ;   ws_why(W8), check('ws_open with protocols', W8, opened)
    ),
    %% 4. the server closes
    (   ws_open('ws://127.0.0.1:18895/bye', WS9)
    ->  recv(WS9, [format(atom)], M9a),
        recv(WS9, [], M9b),
        check('a server''s close arrives as close(Code, Why)', M9a-M9b,
              text(hello)-close(1001, 'going away'))
    ;   ws_why(W9), check('ws_open to a page that closes', W9, opened)
    ),
    %% 4b. a session that returns with its conversation open is closed for
    %% it -- and a WebSocket that has ended says so, and touches nothing
    (   ws_open('ws://127.0.0.1:18895/quiet', WS16)
    ->  recv(WS16, [format(atom)], M16a), recv(WS16, [], M16b),
        check('a session that returns is closed for it, 1000', M16a-M16b,
              text(hello)-close(1000, '')),
        %% ITS SLOT IS GIVEN OUT AGAIN -- library(tcp) hands out the lowest
        %% free one, here to a listener of this process's own -- and the
        %% ended WebSocket must not write to it or close it
        WS16 = websocket(plain(H16), _, _),
        tcp_listen(18899, L16),
        tcp_sockets(S16a), ws_close(WS16), tcp_sockets(S16b),
        check('ws_close on an ended conversation touches nothing, though its slot is taken',
              L16-S16b, H16-S16a),
        ( catch(( ws_send(WS16, text(more)), G16s = sent ), error(E16s, _), G16s = E16s) -> true ; G16s = failed ),
        ( catch(( ws_receive(WS16, _, [timeout(100)]), G16r = received ), error(E16r, _), G16r = E16r) -> true ; G16r = failed ),
        check('...and ws_send and ws_receive on it raise', G16s-G16r,
              permission_error(send, closed_websocket, WS16)-permission_error(receive, closed_websocket, WS16)),
        ignore(tcp_close(L16))
    ;   ws_why(W16), check('ws_open to a page that returns', W16, opened)
    ),
    %% 4c. a session that throws
    (   ws_open('ws://127.0.0.1:18895/boom', WS17)
    ->  recv(WS17, [format(atom)], M17a), recv(WS17, [], M17b),
        check('a session that throws is closed 1011', M17a-M17b,
              text(hello)-close(1011, 'internal error'))
    ;   ws_why(W17), check('ws_open to a page that throws', W17, opened)
    ),
    %% 4d. one that throws AFTER the closing handshake says nothing more: a
    %% close is the last frame a side sends
    ws_frame_bytes(1, 8, [7, 7, 7, 7], [3, 232], Close18),
    raw_case(Port, '/late', [Close18-2], Fs18),
    check('a session that throws once its conversation is over sends no 1011 after the close',
          Fs18, [[close(1000), nothing]]),
    %% 5. and 6. pages that do not upgrade
    ( ws_open('ws://127.0.0.1:18895/plain', _) -> G10 = opened ; ws_why(G10) ),
    check('a page that answers 200 is not a websocket', G10, 'the server answered 200, not 101'),
    ( ws_open('ws://127.0.0.1:18895/nowhere', _) -> G11 = opened ; ws_why(G11) ),
    check('nor is a path nobody claims', G11, 'the server answered 404, not 101'),
    %% 7. plain HTTP to a websocket page
    tcp_connect('127.0.0.1', Port, S12),
    atom_codes('GET /echo HTTP/1.1\r\nHost: x\r\n\r\n', Q12), tcp_write(S12, Q12),
    ( tcp_read(S12, 4096, 5000, R12) -> atom_codes(A12, R12) ; A12 = '' ),
    tcp_close(S12),
    ( sub_atom(A12, 9, 3, _, St12) -> true ; St12 = none ),
    ( sub_atom(A12, _, _, _, 'Upgrade: websocket') -> U12 = upgrade ; U12 = none ),
    check('a plain GET to a websocket page is 426, saying which', St12-U12, '426'-upgrade),
    %% 8. a client that does not mask
    ws_frame_bytes(1, 1, none, [104, 105], F13),
    raw_case(Port, [F13-1], Fs13),
    check('an unmasked frame from a client is answered 1002', Fs13, [[close(1002)]]),
    %% 9. fragments, with a ping between them, then a close
    ws_frame_bytes(0, 1, [1, 2, 3, 4], [72, 101, 108], A14),
    ws_frame_bytes(1, 9, [5, 6, 7, 8], [120], B14),
    ws_frame_bytes(1, 0, [9, 9, 9, 9], [108, 111], C14),
    append([A14, B14, C14], All14),
    ws_frame_bytes(1, 8, [1, 1, 1, 1], [3, 232], Close14),
    raw_case(Port, [All14-2, Close14-1], Fs14),
    check('fragments come back as one message, the ping answered in between; a close echoed', Fs14,
          [[frame(10, [120]), frame(1, [72, 101, 108, 108, 111])], [close(1000)]]),
    %% 10. text that is not UTF-8
    ws_frame_bytes(1, 1, [1, 2, 3, 4], [192, 128], F15),
    raw_case(Port, [F15-1], Fs15),
    check('a text message that is not UTF-8 is answered 1007', Fs15, [[close(1007)]]).

%% A send that fails shows up as the next receive's `timed_out', and a
%% receive that fails AS that -- never as a section that ends without a word.
sent(WS, M) :- ignore(ws_send(WS, M)).

recv(WS, Options, M) :-
    (   ws_receive(WS, M0, [timeout(5000)|Options]) -> M = M0 ; M = timed_out ).

%% A client by hand: the handshake through the library's pieces, then each
%% Bytes-N of Steps -- the bytes written, N frames read back -- and the
%% frames of every step as the answer; `no_handshake' when there was none.
raw_case(Port, Steps, Got) :- raw_case(Port, '/echo', Steps, Got).

raw_case(Port, Path, Steps, Got) :-
    (   raw_open(Port, Path, S)
    ->  findall(Fs, ( member(Bytes-N, Steps), tcp_write(S, Bytes), raw_frames(S, N, Fs) ), Got0),
        tcp_close(S),
        Got = Got0
    ;   Got = no_handshake
    ).

raw_open(Port, Path, S) :-
    tcp_connect('127.0.0.1', Port, S),
    ws_handshake_request(Path, x, 'dGhlIHNhbXBsZSBub25jZQ==', [], [], Req),
    tcp_write(S, Req),
    (   ws_read_head(plain(S), 5000, 16384, _)
    ->  true
    ;   tcp_close(S),
        fail
    ).

%% N frames from the server, as frame(Opcode, Payload) -- or close(Code)
raw_frames(S, N, Frames) :- raw_frames(S, N, [], Frames).

raw_frames(_, 0, _, []) :- !.
raw_frames(S, N, Buf, [F|Fs]) :-
    (   catch(ws_frame(Buf, frame(_, Op, _, P), Rest), _, fail)
    ->  ( Op =:= 8, P = [H, L|_] -> C is H << 8 \/ L, F = close(C) ; F = frame(Op, P) ),
        N1 is N - 1,
        raw_frames(S, N1, Rest, Fs)
    ;   tcp_read(S, 65536, 5000, More)
    ->  append(Buf, More, Buf1),
        raw_frames(S, N, Buf1, [F|Fs])
    ;   F = nothing, Fs = []
    ).

%% ---- a pool ------------------------------------------------------------------

%% TWO SESSIONS AT ONCE, which is what workers(N) is for: the single-threaded
%% loop holds its one conversation until the session ends, so a second
%% client's handshake would wait for the first to close. The pages are a
%% MODULE -- `-s', not `run' -- because a pool's worker finds only those.
pooled(D) :-
    section('two sessions at once, through workers(2)'),
    (   catch(use_module(library(thread)), _, fail)
    ->  atom_concat(D, '/pool.pl', Server),
        server_lines('main :- httpd_serve(18898, [workers(2), accept_timeout(20000)], 2).', Lines),
        fixture(Server, Lines),
        sh_join(['-s ', Server], Args),
        serving(Args, 18898, Pid),
        (   catch(pool_checks, E, true)
        ->  ( var(E) -> true ; check('the pool checks ran to the end', E, ran) )
        ;   check('the pool checks ran to the end', failed, ran)
        ),
        reap(Pid)
    ;   format("     (skipped: workers(N) -- no library(thread))~n")
    ).

pool_checks :-
    Url = 'ws://127.0.0.1:18898/echo',
    (   ws_open(Url, A, [timeout(5000)])
    ->  (   ws_open(Url, B, [timeout(5000)])
        ->  sent(A, text(first)), sent(B, text(second)),
            recv(B, [format(atom)], MB), recv(A, [format(atom)], MA),
            check('two sessions open at once, each its own conversation', MA-MB,
                  text(first)-text(second)),
            ws_close(B)
        ;   ws_why(W), check('a second session while the first is open', W, opened)
        ),
        ws_close(A)
    ;   ws_why(W0), check('ws_open under workers(2)', W0, opened)
    ).

%% ---- wss:// ------------------------------------------------------------------

secure(D) :-
    section('wss://, through library(tls)'),
    ( getenv('ZIGURATIP', Z) -> true ; getenv('HOME', H), atom_concat(H, '/ZiguratIP', Z) ),
    atom_concat(Z, '/home/etc/cert', Cert),
    atom_concat(Cert, '/dont-use-certificate.crt', CaCrt),
    (   catch(use_module(library(tls)), _, fail),
        exists_file(CaCrt)
    ->  atom_concat(D, '/secure.pl', Server),
        sh_join(['serve :- httpd_serve(18896, [ tls([ certificate(''', CaCrt, '''), key(''', Cert,
                 '/dont-use-private.key''), authority(''', CaCrt, '''), client_auth(none) ]),',
                 ' accept_timeout(20000) ], 1).'], Serve),
        server_lines(Serve, Lines),
        fixture(Server, Lines),
        sh_join(['run ', Server, ' serve'], Args),
        serving(Args, 18896, Pid),
        (   ws_open('wss://127.0.0.1:18896/echo', WS,
                    [tls([authority(CaCrt), client_auth(none)])])
        ->  sent(WS, text('over TLS')), recv(WS, [format(atom)], M),
            check('a message over wss:// comes back', M, text('over TLS')),
            ( ws_receive(WS, M2, [timeout(200)]) -> G2 = M2 ; G2 = timed_out ),
            sent(WS, text(again)), recv(WS, [format(atom)], M3),
            check('over wss:// too, a timeout is a plain failure and the conversation goes on',
                  G2-M3, timed_out-text(again)),
            ws_close(WS)
        ;   ws_why(W), check('ws_open over wss://', W, opened)
        ),
        reap(Pid)
    ;   format("     (skipped: wss:// -- no library(tls) or no ZiguratIP certificate directory)~n")
    ).
