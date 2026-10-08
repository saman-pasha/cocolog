%% library(websocket) -- RFC 6455, a client and a server, over the bytes
%% library(tcp) and library(tls) give back.
%%
%% EVERY PREDICATE IN HERE IS `ws_'-PREFIXED, helpers included, for the
%% reason library(http) gives at length: cocolog has ONE namespace, and a
%% library's private names are everybody's.
%%
%% IT IS ALL CLAUSES. A socket is library(tcp)'s C and a TLS session
%% library(tls)'s; the opening handshake is HTTP, read with library(http)'s
%% own grammar; and everything a WebSocket adds to that -- the frame, the
%% mask, the closing handshake -- is bit arithmetic over a code list, which
%% is a clause's business. There is no C in this file.
%%
%%
%% THE SHAPE
%%
%%     ws_open(+URL, -WS)                    ws://host:port/path, or wss://
%%     ws_open(+URL, -WS, +Options)
%%     ws_send(+WS, +Message)
%%     ws_receive(+WS, -Message)             the next message, an hour's patience
%%     ws_receive(+WS, -Message, +Options)
%%     ws_close(+WS)                         the closing handshake, 1000
%%     ws_close(+WS, +Code, +Reason)
%%     ws_subprotocol(+WS, -Protocol)        what the handshake agreed, or ''
%%     ws_why(-Reason)                       why the last ws_open failed
%%
%% AND THE SERVER HALF IS A PAGE. library(httpd) routes a request to a page
%% as it always has, and a page that answers `websocket(Goal)' -- or
%% `websocket(Goal, Options)' -- is given the connection: httpd checks the
%% handshake, sends the 101, and calls `call(Goal, WS)' for as long as the
%% session lasts.
%%
%%     httpd_page('/echo', _Request, websocket(echo)).
%%
%%     echo(WS) :-
%%         ws_receive(WS, M),
%%         (   M = close(_, _)
%%         ->  true
%%         ;   ws_send(WS, M),
%%             echo(WS)
%%         ).
%%
%% `ws_accept/5' is the same half for a loop that is not httpd's.
%%
%% AND THE PIECES, socket-free where they can be, which is how the suite
%% checks RFC 6455's own examples byte for byte:
%%
%%     ws_accept_key(+Key, -Accept)                  the handshake's arithmetic
%%     ws_handshake_request(+Target, +Host, +Key, +Protocols, +Headers, -Codes)
%%     ws_handshake_check(+Request, +Rest, -Result)  accept(Key, Offered) or refuse(S, Hs, Body)
%%     ws_handshake_response(+Accept, +Protocol, -Codes)
%%     ws_handshake_answer(+Head, +Key, +Offered, -Protocol, -Why)
%%     ws_read_head(+Conn, +TimeoutMs, +Max, -Head)   to the blank line, no further
%%     ws_frame_bytes(+Fin, +Opcode, +Mask, +Payload, -Bytes)
%%     ws_frame(+Bytes, -frame(Fin, Opcode, Mask, Payload), -Rest)
%%     ws_send_frame(+WS, +Fin, +Opcode, +Payload)
%%     ws_mask(+Bytes, +Key, -Masked)                its own inverse
%%     ws_utf8(+Bytes)                               RFC 3629, strictly
%%     ws_sha1(+Bytes, -Digest)   ws_base64(+Bytes, -Atom)   ws_unbase64(+Atom, -Bytes)
%%
%% A WEBSOCKET IS A TERM, `websocket(Conn, Role, Protocol)': Conn the
%% tagged transport, Role `client' or `server', Protocol what the
%% handshake agreed. Two ends wired by hand -- a test, a lesson talking to
%% itself -- are two of these.
%%
%%
%% A MESSAGE IS ONE OF FIVE TERMS, SWI-Prolog's own shapes, both ways:
%%
%%     text(Text)        UTF-8. Sent: an atom, a string or a code list.
%%                       Received: a code list, or an atom with format(atom)
%%     binary(Bytes)     a code list, 0..255 each
%%     ping(Data)        answered by the library: ws_receive never returns one
%%     pong(Data)        returned, except between a message's fragments
%%     close(Code, Why)  the last message of every conversation
%%
%% CODES ARE BYTES HERE, as everywhere in cocolog: an atom is its UTF-8, so
%% `text('héllo')' goes out as the atom's bytes with nothing encoded on the
%% way. What is CHECKED is that the bytes are UTF-8 at all -- RFC 6455 says a
%% text message that is not is a protocol error, in both directions.
%%
%% A RECEIVED TEXT IS A CODE LIST UNLESS ASKED, for library(tcp)'s reason:
%% an atom is a C string and stops at the first NUL, and a text frame may
%% carry U+0000. `format(atom)' is there for the programs whose text never
%% does, which is most of them.
%%
%%
%% EVERY CONVERSATION ENDS WITH close(Code, Why), whoever ended it, so a
%% session loop has one way out to test for:
%%
%%     the peer said so          its code and reason; this side has replied
%%     this side failed it       1002 a protocol error, 1007 a text that is
%%                               not UTF-8, 1009 a message over max_message
%%                               -- the close frame with that code was sent
%%     the connection was lost   1006, never sent, the reason the socket's
%%
%% AND A TIMEOUT IS A PLAIN FAILURE, as it is in library(tcp): "nothing came
%% in an hour" is an answer, not an end. A timeout INSIDE a message -- part
%% of a frame arrived, or a message stopped between its fragments -- is not
%% that answer, because the stream can no longer be read: it is close(1006).
%%
%% THE SIDE THAT OPENED THE SOCKET CLOSES IT. A client's socket is
%% `ws_open/3''s, so the client closes it once the closing handshake is
%% done -- after waiting a moment for the server to close first, as RFC
%% 6455 section 7.1.1 asks. A server's is the accepting loop's, so a
%% server session leaves it open, and httpd closes it when the goal
%% returns -- having closed the conversation first, 1000, if the goal
%% left it open.
%%
%% A WEBSOCKET THAT HAS ENDED SAYS SO: ws_close/1,3 on it does nothing,
%% and ws_send/2 and ws_receive/2,3 raise permission_error(_,
%% closed_websocket, WS). That holds until a new conversation is given its
%% slot -- a handle is a slot, and a slot is given out again -- so a
%% program does not keep a WebSocket past its end.
%%
%%
%% WHERE IT IS STRICT, and each is a decision:
%%
%%   A CLIENT'S FRAMES MUST BE MASKED AND A SERVER'S MUST NOT BE, and a
%%   frame the wrong way round fails the connection (1002). The mask is
%%   not a secret -- it travels with the frame -- but it is what stops a
%%   script in a browser writing bytes an intermediary would read as HTTP,
%%   so the client's keys come from /dev/urandom, four fresh bytes a frame.
%%
%%   A CONTROL FRAME IS SHORT AND WHOLE: at most 125 bytes and never
%%   fragmented, or 1002. RSV bits must be zero, because no extension is
%%   spoken here, and an unknown opcode is 1002.
%%
%%   A LENGTH IS BELIEVED ONLY UP TO max_message (16 MiB by default), and a
%%   frame claiming more is refused before a byte of its payload is read
%%   (1009). A 64-bit length whose top half is not zero is that by
%%   construction -- and it is checked before the number is built, because
%%   a cell holds 60 bits.
%%
%%   THE HANDSHAKE IS CHECKED WHOLE: GET, HTTP/1.1, a Host, `Upgrade:
%%   websocket', `Connection: Upgrade', a key that is sixteen bytes of
%%   base64, and version 13 -- anything else is 426 with the version this
%%   server speaks. A client that sent bytes after its request, before the
%%   101, is refused: RFC 6455 section 4.1 says it must wait.
%%
%% WHAT IS NOT HERE: extensions (permessage-deflate among them; a server
%% that is offered one simply does not accept it), and sending a message in
%% fragments -- every message goes out as one frame, and fragments are
%% READ, interleaved control frames and all. `ws_send_frame/4' writes one
%% frame for whoever needs to send the pieces by hand.
%%
%% SHA-1 AND BASE64 ARE CLAUSES HERE TOO, and that is a decision against
%% library(sha). The handshake needs SHA-1 of sixty bytes, once, and
%% library(sha) needs a BUILT ZiguratIP -- so leaning on it would make
%% `ws://' need ZiguratIP where `http://' does not. test/websocket.pl checks
%% this SHA-1 against FIPS 180's vectors, RFC 6455's worked handshake, and
%% library(sha)'s own answer wherever that loads.

:- use_module(library(tcp)).
:- use_module(library(http)).
%% wss:// ONLY, AND ASKED FOR QUIETLY. A use_module directive naming a
%% library this build does not carry is reported, in SWI's words, since
%% 1.8.39 -- and a cocolog with no tls.so, one built without ZiguratIP,
%% still speaks ws:// perfectly well. So this one is a goal that tries: the
%% load says nothing, and ws_open('wss://...') throws by name instead.
:- catch(use_module(library(tls)), _, true).
%% the client's random bytes, read from /dev/urandom
:- use_module(library(stream)).

%% ======================================================================
%% ---- the client ----------------------------------------------------------
%% ======================================================================

%% ws_open(+URL, -WS) is semidet.
%% ws_open(+URL, -WS, +Options) is semidet.
%%
%% Options:
%%     headers(List)       more Name-Value request headers (an Origin, a cookie)
%%     protocols(List)     subprotocols to offer, in order of preference
%%     tls(Creds)          library(tls)'s credentials, for wss://
%%     timeout(Ms)         per read while the handshake answers (default 30000)
%%
%% FAILS, as tcp_connect/3 and tls_connect/4 do, when there is nobody to
%% talk to or the server will not upgrade; `ws_why/1' says which. A URL
%% that is not ws:// or wss:// is a domain error: that is a program's
%% mistake, not the network's answer.
ws_open(URL, WS) :- ws_open(URL, WS, []).

ws_open(URL, WS, Options) :-
    ws_parse_url(URL, Scheme, Host, Port, Target),
    ws_option(timeout(T), Options, 30000),
    (   ws_connect(Scheme, Host, Port, Options, C)
    ->  true
    ;   ws_sock_scheme_why(Scheme, Why0),
        atomic_list_concat(['cannot connect to ', Host, ':', Port, ' (', Why0, ')'], Why),
        ws_set_why(Why),
        fail
    ),
    ws_forget(C),
    (   catch(ws_client_handshake(C, Scheme, Host, Port, Target, Options, T, Protocol), E,
              ( ws_sock_close(C), throw(E) ))
    ->  WS = websocket(C, client, Protocol)
    ;   ws_sock_close(C),
        fail
    ).

ws_why(Why) :-
    catch(nb_getval('$ws_why', Why), _, Why = '').

ws_set_why(Why) :- nb_setval('$ws_why', Why).

ws_subprotocol(websocket(_, _, P), P).

%% ws://host[:port][/path][?query], wss:// the same. The port defaults to
%% the scheme's; the target to `/'.
ws_parse_url(URL, Scheme, Host, Port, Target) :-
    (   atom(URL) -> true ; throw(error(type_error(atom, URL), context(ws_open/3, _))) ),
    (   atom_concat('ws://', Rest, URL) -> Scheme = ws, DefPort = 80
    ;   atom_concat('wss://', Rest, URL) -> Scheme = wss, DefPort = 443
    ;   throw(error(domain_error(websocket_url, URL), context(ws_open/3, _)))
    ),
    atom_codes(Rest, Cs),
    ws_split_authority(Cs, Auth, TargetCs),
    (   TargetCs == [] -> Target = '/' ; atom_codes(Target, TargetCs) ),
    (   append(HostCs, [0':|PortCs], Auth), PortCs \== []
    ->  atom_codes(Host, HostCs),
        (   catch(number_codes(Port, PortCs), _, fail), integer(Port), Port > 0, Port < 65536
        ->  true
        ;   throw(error(domain_error(websocket_url, URL), context(ws_open/3, _)))
        )
    ;   atom_codes(Host, Auth),
        Port = DefPort
    ),
    (   Host == '' -> throw(error(domain_error(websocket_url, URL), context(ws_open/3, _))) ; true ).

%% The authority runs to the first `/' or `?'; a `?' with no path before it
%% is a query on `/'.
ws_split_authority([], [], []).
ws_split_authority([0'/|T], [], [0'/|T]) :- !.
ws_split_authority([0'?|T], [], [0'/, 0'?|T]) :- !.
ws_split_authority([C|Cs], [C|As], T) :- ws_split_authority(Cs, As, T).

ws_connect(ws, Host, Port, _, plain(C)) :-
    tcp_connect(Host, Port, C).
ws_connect(wss, Host, Port, Options, secure(C)) :-
    ws_option(tls(Creds), Options, []),
    atom_number(Service, Port),             % a service, as tls_connect/4 names it
    catch(tls_connect(Host, Service, Creds, C),
          error(existence_error(procedure, _), _),
          throw(error(existence_error(procedure, tls_connect/4),
                      'websocket: wss:// needs library(tls) -- sh modules/tls/build.sh'))).

ws_sock_scheme_why(ws, Why) :- catch(tcp_why(Why), _, Why = 'no answer').
ws_sock_scheme_why(wss, Why) :- catch(tls_why(Why), _, Why = 'no answer').

%% THE CLIENT'S HALF OF THE HANDSHAKE: a request with a fresh key, then the
%% server's answer read up to its blank line and no further. ONE BYTE AT A
%% TIME, and on purpose: a server may send its first frame in the same
%% segment as the 101, and a chunked read here would swallow it. A few
%% hundred reads, once per connection, buy a reader that never takes a byte
%% the frames are owed.
ws_client_handshake(C, Scheme, Host, Port, Target, Options, T, Protocol) :-
    ws_random_bytes(16, Nonce),
    ws_base64(Nonce, Key),
    ws_host_header(Scheme, Host, Port, HostHeader),
    ws_option(protocols(Offered), Options, []),
    ws_option(headers(Extra), Options, []),
    ws_handshake_request(Target, HostHeader, Key, Offered, Extra, Request),
    ws_sock_write(C, Request),
    (   ws_read_head(C, T, 16384, Head)
    ->  true
    ;   ws_set_why('the server sent no answer to the handshake'),
        fail
    ),
    (   ws_handshake_answer(Head, Key, Offered, Protocol, Why)
    ->  (   Why == ok
        ->  true
        ;   ws_set_why(Why),
            fail
        )
    ;   ws_set_why('the server''s answer is not HTTP'),
        fail
    ).

ws_host_header(ws, Host, 80, Host) :- !.
ws_host_header(wss, Host, 443, Host) :- !.
ws_host_header(_, Host, Port, HH) :- atomic_list_concat([Host, ':', Port], HH).

%% ws_handshake_request(+Target, +Host, +Key, +Protocols, +Headers, -Codes) is det.
%% The opening request, socket-free.
ws_handshake_request(Target, Host, Key, Offered, Extra, Codes) :-
    (   Offered == []
    ->  PL = ''
    ;   atomic_list_concat(Offered, ', ', Ps),
        atomic_list_concat(['Sec-WebSocket-Protocol: ', Ps, '\r\n'], PL)
    ),
    ws_header_lines(Extra, EL),
    atomic_list_concat(['GET ', Target, ' HTTP/1.1\r\n',
                        'Host: ', Host, '\r\n',
                        'Upgrade: websocket\r\n',
                        'Connection: Upgrade\r\n',
                        'Sec-WebSocket-Key: ', Key, '\r\n',
                        'Sec-WebSocket-Version: 13\r\n',
                        PL, EL, '\r\n'], A),
    atom_codes(A, Codes).

ws_header_lines([], '').
ws_header_lines([N-V|Hs], Out) :-
    atomic_list_concat([N, ': ', V, '\r\n'], One),
    ws_header_lines(Hs, Rest),
    atom_concat(One, Rest, Out).

%% Up to and including the blank line that ends a head, a byte at a time,
%% and never past Max bytes.
ws_read_head(C, T, Max, Head) :- ws_read_head_(C, T, Max, [], Head).

ws_read_head_(C, T, Max, Rev, Head) :-
    Max > 0,
    ws_sock_read(C, 1, T, [B]),
    Rev1 = [B|Rev],
    (   ws_head_ended(Rev1)
    ->  reverse(Rev1, Head)
    ;   Max1 is Max - 1,
        ws_read_head_(C, T, Max1, Rev1, Head)
    ).

%% CRLF CRLF, or a bare LF LF, which library(http) accepts as well.
ws_head_ended([10, 13, 10, 13|_]) :- !.
ws_head_ended([10, 10|_]).

%% ws_handshake_answer(+Head, +Key, +Offered, -Protocol, -Why) is semidet.
%% Fails when Head is not an HTTP response at all; otherwise Why is `ok' or
%% the sentence that says what was wrong with it.
ws_handshake_answer(Head, Key, Offered, Protocol, Why) :-
    phrase(ws_response_head(Status, Headers), Head, _),
    !,
    ws_accept_key(Key, Want),
    (   Status =\= 101
    ->  atomic_list_concat(['the server answered ', Status, ', not 101'], Why), Protocol = ''
    ;   \+ ( memberchk(upgrade-U, Headers), ws_has_token(U, websocket) )
    ->  Why = 'the 101 has no Upgrade: websocket', Protocol = ''
    ;   \+ ( memberchk(connection-Cn, Headers), ws_has_token(Cn, upgrade) )
    ->  Why = 'the 101 has no Connection: Upgrade', Protocol = ''
    ;   \+ memberchk('sec-websocket-accept'-Want, Headers)
    ->  Why = 'Sec-WebSocket-Accept is not this key''s', Protocol = ''
    ;   memberchk('sec-websocket-extensions'-_, Headers)
    ->  Why = 'the server named an extension nobody offered it', Protocol = ''
    ;   memberchk('sec-websocket-protocol'-P, Headers)
    ->  (   memberchk(P, Offered)
        ->  Protocol = P, Why = ok
        ;   Protocol = '',
            atomic_list_concat(['the server chose ', P, ', which was not offered'], Why)
        )
    ;   Protocol = '', Why = ok
    ).

%% A status line and its headers, through library(http)'s own rules for
%% what a header and a line ending are.
ws_response_head(Status, Headers) -->
    http_version(_), " ",
    http_digits_(SC), { SC = [_, _, _], number_codes(Status, SC) },
    http_line_codes(_), http_eol,
    http_headers(Headers),
    http_eol.

%% ======================================================================
%% ---- the server -----------------------------------------------------------
%% ======================================================================

%% ws_upgrade_asked(+Request) is semidet.
%% A GET that names websocket in its Upgrade header -- the cheap test
%% library(httpd) makes before it routes a request as a handshake.
ws_upgrade_asked(request(get, _, _, _, Headers, _)) :-
    memberchk(upgrade-U, Headers),
    ws_has_token(U, websocket).

%% ws_accept(+Conn, +Request, +Rest, :Goal, +Options) is semidet.
%%
%% The server half for an accepting loop: Conn is `plain(S)' or `secure(S)',
%% Request what library(http) parsed and Rest what arrived after it. A
%% handshake that is right is answered 101 and Goal is called with the
%% WebSocket; one that is not is answered with the status that says why,
%% and Goal never runs. THE SOCKET IS LEFT OPEN EITHER WAY: it is the
%% loop's, and the loop closes it.
%%
%% Options:
%%     protocols(List)     the subprotocols this server speaks, in order of
%%                         preference; the first one the client offered is
%%                         chosen, and none is no header at all
%%
%% A SESSION THAT RETURNS WITH ITS CONVERSATION OPEN is closed properly,
%% 1000, as SWI-Prolog's is: the client is told, not cut off when the loop
%% closes the socket. A goal that FAILS has ended its session too, which is
%% all a failure can mean here. AN ERROR THAT ESCAPES THE GOAL is told to
%% the peer as 1011 before it goes on up, for the same reason.
ws_accept(C, Request, Rest, Goal, Options) :-
    ws_handshake_check(Request, Rest, Result),
    (   Result = accept(Key, Offered)
    ->  ws_option(protocols(Mine), Options, []),
        ws_choose(Mine, Offered, Protocol),
        ws_accept_key(Key, Accept),
        ws_handshake_response(Accept, Protocol, Head),
        (   ws_sock_write(C, Head)
        ->  WS = websocket(C, server, Protocol),
            ws_forget(C),
            (   catch(call(Goal, WS), E, true) -> true ; true ),
            (   var(E)
            ->  catch(ws_close(WS), _, true),
                ws_forget(C)
            ;   (   ws_done(C)
                ->  true
                ;   ignore(ws_send_close_frame(WS, 1011, 'internal error'))
                ),
                ws_forget(C),
                throw(E)
            )
        ;   true
        )
    ;   Result = refuse(Status, Headers, Body),
        http_response(Status, ['Connection'-close|Headers], Body, Codes),
        ws_sock_write(C, Codes)
    ).

%% ws_handshake_check(+Request, +Rest, -Result) is det.
%% Result is accept(Key, OfferedProtocols) or refuse(Status, Headers, Body).
ws_handshake_check(request(Method, _, _, Version, Hs, _), Rest, Result) :-
    (   Method \== get
    ->  Result = refuse(405, ['Allow'-'GET'], 'a websocket opens with GET')
    ;   \+ ws_http11(Version)
    ->  Result = refuse(400, [], 'a websocket needs HTTP/1.1')
    ;   \+ memberchk(host-_, Hs)
    ->  Result = refuse(400, [], 'no Host header')
    ;   \+ ( memberchk(upgrade-U, Hs), ws_has_token(U, websocket) )
    ->  Result = refuse(400, [], 'no Upgrade: websocket')
    ;   \+ ( memberchk(connection-Cn, Hs), ws_has_token(Cn, upgrade) )
    ->  Result = refuse(400, [], 'no Connection: Upgrade')
    ;   \+ memberchk('sec-websocket-version'-'13', Hs)
    ->  Result = refuse(426, ['Sec-WebSocket-Version'-'13'], 'only version 13 is spoken here')
    ;   \+ ( memberchk('sec-websocket-key'-Key, Hs), ws_key_ok(Key) )
    ->  Result = refuse(400, [], 'no Sec-WebSocket-Key of sixteen bytes')
    ;   Rest \== []
    ->  Result = refuse(400, [], 'bytes sent before the handshake was answered')
    ;   %% FETCHED AGAIN, because the test above was under `\+', which binds
        %% nothing it proves
        memberchk('sec-websocket-key'-Key, Hs),
        ws_offered(Hs, Offered),
        Result = accept(Key, Offered)
    ).

ws_http11(http(Major, Minor)) :- Major > 1 ; Major =:= 1, Minor >= 1.

ws_key_ok(Key) :- ws_unbase64(Key, Bytes), length(Bytes, 16).

%% Every Sec-WebSocket-Protocol the client sent, each a comma-separated list.
ws_offered(Hs, Offered) :-
    findall(P, ( member('sec-websocket-protocol'-V, Hs), ws_tokens(V, Ps), member(P, Ps) ), Offered).

ws_choose([], _, '').
ws_choose([P|Ps], Offered, Protocol) :-
    (   memberchk(P, Offered) -> Protocol = P ; ws_choose(Ps, Offered, Protocol) ).

%% ws_handshake_response(+Accept, +Protocol, -Codes) is det.
%% The 101, built here and not by http_response/4, because that computes a
%% Content-Length and RFC 7230 section 3.3.2 forbids one on a 1xx.
ws_handshake_response(Accept, Protocol, Codes) :-
    (   Protocol == ''
    ->  PL = ''
    ;   atomic_list_concat(['Sec-WebSocket-Protocol: ', Protocol, '\r\n'], PL)
    ),
    atomic_list_concat(['HTTP/1.1 101 Switching Protocols\r\n',
                        'Upgrade: websocket\r\n',
                        'Connection: Upgrade\r\n',
                        'Sec-WebSocket-Accept: ', Accept, '\r\n',
                        PL, '\r\n'], A),
    atom_codes(A, Codes).

%% ws_accept_key(+Key, -Accept) is det.
%% RFC 6455 section 1.3: the key, the protocol's own GUID, SHA-1, base64.
ws_accept_key(Key, Accept) :-
    atom_concat(Key, '258EAFA5-E914-47DA-95CA-C5AB0DC85B11', Both),
    atom_codes(Both, Bytes),
    ws_sha1(Bytes, Digest),
    ws_base64(Digest, Accept).

%% A header value is a comma-separated list of tokens -- `keep-alive,
%% Upgrade' is ordinary -- compared without regard to case.
ws_has_token(Value, Token) :- ws_tokens(Value, Ts), memberchk(Token, Ts).

ws_tokens(Value, Tokens) :-
    atom_codes(Value, Cs),
    ws_split_commas(Cs, Pieces),
    findall(T, ( member(P, Pieces), ws_trim(P, TC), TC \== [],
                 atom_codes(A, TC), downcase_atom(A, T) ), Tokens).

ws_split_commas(Cs, [P|Ps]) :-
    (   append(P, [0',|Rest], Cs)
    ->  ws_split_commas(Rest, Ps)
    ;   P = Cs, Ps = []
    ).

ws_trim(Cs, T) :- ws_drop_space(Cs, C1), reverse(C1, R), ws_drop_space(R, R1), reverse(R1, T).

ws_drop_space([C|Cs], T) :- ( C =:= 32 ; C =:= 9 ), !, ws_drop_space(Cs, T).
ws_drop_space(Cs, Cs).

%% ======================================================================
%% ---- sending ---------------------------------------------------------------
%% ======================================================================

%% ws_send(+WS, +Message) is semidet.
%% Fails when the socket will not take the bytes. Sending `close(Code,
%% Why)' sends the close frame and no more: the reply is the next
%% ws_receive's, and `ws_close/3' is the call that waits for it. On a
%% conversation that has ended it RAISES, as ws_receive does: nothing can
%% be said on it, and a program still talking has lost track of it.
ws_send(WS, Message) :-
    WS = websocket(C, _, _),
    (   ws_done(C)
    ->  throw(error(permission_error(send, closed_websocket, WS), context(ws_send/2, _)))
    ;   Message = close(Code, Why)
    ->  ws_send_close_frame(WS, Code, Why)
    ;   ws_closing(C)
    ->  throw(error(permission_error(send, closing_websocket, WS), context(ws_send/2, _)))
    ;   ws_message_frame(Message, Op, Payload)
    ->  ws_send_frame(WS, 1, Op, Payload)
    ;   throw(error(domain_error(websocket_message, Message), context(ws_send/2, _)))
    ).

%% ws_send_frame(+WS, +Fin, +Opcode, +Payload) is semidet.
%% ONE FRAME, as given: Fin 1 or 0, Opcode 0..15, Payload bytes. Masked
%% with a fresh key from a client and not at all from a server -- the one
%% rule this predicate keeps for its caller. A message sent in fragments is
%% this, by hand: the first frame its opcode and Fin 0, the rest opcode 0.
ws_send_frame(websocket(C, Role, _), Fin, Op, Payload) :-
    (   Role == client
    ->  ws_random_bytes(4, Mask)
    ;   Mask = none
    ),
    ws_frame_bytes(Fin, Op, Mask, Payload, Bytes),
    ws_sock_write(C, Bytes).

%% What each message is on the wire. Text is checked to be UTF-8 HERE, on
%% the way out, because the peer would fail the connection over it and say
%% only "1007" -- a program is better told which of its terms it was.
ws_message_frame(text(T), 1, Bytes) :-
    ws_text_bytes(T, Bytes),
    (   ws_utf8(Bytes) -> true
    ;   throw(error(domain_error(utf8_text, T), context(ws_send/2, _)))
    ).
ws_message_frame(binary(B), 2, Bytes) :- ws_data_bytes(B, Bytes).
ws_message_frame(ping(D), 9, Bytes) :- ws_data_bytes(D, Bytes), ws_control_size(Bytes, D).
ws_message_frame(pong(D), 10, Bytes) :- ws_data_bytes(D, Bytes), ws_control_size(Bytes, D).

ws_control_size(Bytes, D) :-
    length(Bytes, N),
    (   N =< 125 -> true
    ;   throw(error(domain_error(control_frame_payload, D), context(ws_send/2, _)))
    ).

ws_text_bytes(T, Bytes) :-
    (   is_list(T)    -> ws_byte_list(T), Bytes = T
    ;   string(T)     -> string_codes(T, Bytes)
    ;   atomic(T)     -> atom_codes(T, Bytes)
    ;   throw(error(type_error(text, T), context(ws_send/2, _)))
    ).

ws_data_bytes(D, Bytes) :- ws_text_bytes(D, Bytes).

ws_byte_list([]).
ws_byte_list([B|Bs]) :-
    (   integer(B), B >= 0, B =< 255 -> ws_byte_list(Bs)
    ;   throw(error(type_error(byte, B), context(ws_send/2, _)))
    ).

%% THE CLOSE FRAME, and the mark that one was sent. The mark is what tells
%% the next ws_receive that a close arriving is the REPLY, owed nothing --
%% without it the reply would be answered with a second close.
ws_send_close_frame(WS, Code, Why) :-
    WS = websocket(C, _, _),
    ws_close_payload(Code, Why, Payload),
    (   ws_closing(C)
    ->  true                            % one close a side, and it has gone
    ;   ws_mark_closing(C),
        (   ws_send_frame(WS, 1, 8, Payload)
        ->  true
        ;   ws_unmark_closing(C),
            fail
        )
    ).

ws_close_payload(Code, Why, [H, L|RB]) :-
    (   integer(Code), ws_code_sendable(Code) -> true
    ;   throw(error(domain_error(websocket_close_code, Code), context(ws_close/3, _)))
    ),
    ws_text_bytes(Why, RB0),
    (   ws_utf8(RB0) -> true
    ;   throw(error(domain_error(utf8_text, Why), context(ws_close/3, _)))
    ),
    ws_cut_reason(RB0, RB),
    H is Code >> 8,
    L is Code /\ 255.

%% A reason travels in a control frame, so it is at most 123 bytes after
%% the code -- cut, and cut where a UTF-8 character begins, so the cut
%% never leaves half of one behind.
ws_cut_reason(Bytes, Cut) :-
    length(Bytes, N),
    (   N =< 123
    ->  Cut = Bytes
    ;   length(P, 123), append(P, _, Bytes),
        ws_utf8_whole(P, Cut)
    ).

ws_utf8_whole(P, P) :- ws_utf8(P), !.
ws_utf8_whole(P, Cut) :- append(Shorter, [_], P), !, ws_utf8_whole(Shorter, Cut).
ws_utf8_whole(_, []).

%% Codes this side may SEND: RFC 6455 section 7.4.1, and the registered
%% 1012-1014, and the 3000-4999 left to libraries and applications. 1005,
%% 1006 and 1015 are names for what happened without a code, and never go
%% on the wire.
ws_code_sendable(C) :- C >= 1000, C =< 1003.
ws_code_sendable(C) :- C >= 1007, C =< 1014.
ws_code_sendable(C) :- C >= 3000, C =< 4999.

%% ======================================================================
%% ---- receiving -------------------------------------------------------------
%% ======================================================================

%% ws_receive(+WS, -Message) is semidet.
%% ws_receive(+WS, -Message, +Options) is semidet.
%%
%% Options:
%%     timeout(Ms)          for the next message to begin (default an hour)
%%     max_message(Bytes)   a message larger is refused, 1009 (default 16 MiB)
%%     format(F)            codes (the default) or atom, for a text message
%%     close_timeout(Ms)    a client's wait for the server to close its end,
%%                          once the closing handshake is done (default 2000)
ws_receive(WS, Message) :- ws_receive(WS, Message, []).

ws_receive(WS, Message, Options) :-
    WS = websocket(C, _, _),
    (   ws_done(C)
    ->  throw(error(permission_error(receive, closed_websocket, WS), context(ws_receive/3, _)))
    ;   true
    ),
    ws_option(timeout(T), Options, 3600000),
    ws_option(max_message(Max), Options, 16777216),
    ws_option(format(Format), Options, codes),
    ws_option(close_timeout(CT), Options, 2000),
    ws_next(WS, T, Max, CT, none, M0),
    ws_formatted(Format, M0, Message).

ws_formatted(atom, text(Cs), text(A)) :- !, atom_codes(A, Cs).
ws_formatted(_, M, M).

%% The next frame, and what it means with whatever message is half-built.
ws_next(WS, T, Max, CT, Partial, Message) :-
    WS = websocket(C, _, _),
    (   ws_sock_read(C, 1, T, [B0])
    ->  catch(( ws_frame_rest(conn(C, T), B0, Max, Frame, _), Out = Frame ),
              ws_fail(Code, Why), Out = failed(Code, Why)),
        ws_next_frame(Out, WS, T, Max, CT, Partial, Message)
    ;   ws_sock_why(C, Why),
        (   Why == timeout, Partial == none
        ->  fail
        ;   Why == timeout
        ->  ws_lost(WS, CT, 'timed out between the fragments of a message', Message)
        ;   ws_lost(WS, CT, Why, Message)
        )
    ).

ws_next_frame(failed(1006, Why), WS, _, _, CT, _, Message) :- !,
    ws_lost(WS, CT, Why, Message).
ws_next_frame(failed(Code, Why), WS, _, _, CT, _, Message) :- !,
    ws_fail_connection(WS, Code, Why, CT, Message).
ws_next_frame(frame(Fin, Op, Mask, Payload), WS, T, Max, CT, Partial, Message) :-
    WS = websocket(_, Role, _),
    (   \+ ws_mask_right(Role, Mask)
    ->  ws_mask_wrong(Role, Why),
        ws_fail_connection(WS, 1002, Why, CT, Message)
    ;   Op =:= 9
    ->  %% A PING IS ANSWERED HERE, and with the same data, as RFC 6455
        %% section 5.5.2 says -- and not while this side is closing, when
        %% only the close reply is still owed.
        (   WS = websocket(C, _, _), ws_closing(C) -> true
        ;   ignore(ws_send_frame(WS, 1, 10, Payload))
        ),
        ws_next(WS, T, Max, CT, Partial, Message)
    ;   Op =:= 10
    ->  (   Partial == none
        ->  Message = pong(Payload)
        ;   ws_next(WS, T, Max, CT, Partial, Message)
        )
    ;   Op =:= 8
    ->  ws_close_received(WS, Payload, CT, Message)
    ;   Op =:= 0
    ->  (   Partial = partial(Kind, Size0, Chunks)
        ->  length(Payload, N),
            Size is Size0 + N,
            (   Size > Max
            ->  ws_fail_connection(WS, 1009, 'a message over max_message', CT, Message)
            ;   Fin =:= 1
            ->  reverse([Payload|Chunks], Parts),
                append(Parts, Whole),
                ws_message(WS, Kind, Whole, CT, Message)
            ;   ws_next(WS, T, Max, CT, partial(Kind, Size, [Payload|Chunks]), Message)
            )
        ;   ws_fail_connection(WS, 1002, 'a continuation with no message to continue', CT, Message)
        )
    ;   Partial \== none
    ->  ws_fail_connection(WS, 1002, 'a new message inside a fragmented one', CT, Message)
    ;   ws_kind(Op, Kind),
        (   Fin =:= 1
        ->  ws_message(WS, Kind, Payload, CT, Message)
        ;   length(Payload, N),
            ws_next(WS, T, Max, CT, partial(Kind, N, [Payload]), Message)
        )
    ).

ws_kind(1, text).
ws_kind(2, binary).

ws_message(WS, text, Bytes, CT, Message) :- !,
    (   ws_utf8(Bytes)
    ->  Message = text(Bytes)
    ;   ws_fail_connection(WS, 1007, 'a text message that is not UTF-8', CT, Message)
    ).
ws_message(_, binary, Bytes, _, binary(Bytes)).

%% A server is owed masked frames and a client unmasked ones.
ws_mask_right(server, Mask) :- Mask \== none.
ws_mask_right(client, none).

ws_mask_wrong(server, 'an unmasked frame from a client').
ws_mask_wrong(client, 'a masked frame from a server').

%% THE PEER'S CLOSE. Its code and reason are checked -- a code nobody may
%% send, or a reason that is not UTF-8, is the peer's protocol error -- and
%% then answered: with the same code, unless this side already sent a close
%% and this is the reply to it.
ws_close_received(WS, Payload, CT, Message) :-
    WS = websocket(C, _, _),
    (   Payload == []
    ->  Code = 1005, Reason = []
    ;   Payload = [H, L|Reason]
    ->  Code is H << 8 \/ L
    ;   Code = bad, Reason = []
    ),
    (   Code == bad
    ->  ws_fail_connection(WS, 1002, 'a close frame of one byte', CT, Message)
    ;   Code =\= 1005, \+ ws_code_sendable(Code)
    ->  ws_fail_connection(WS, 1002, 'a close code nobody may send', CT, Message)
    ;   \+ ws_utf8(Reason)
    ->  ws_fail_connection(WS, 1007, 'a close reason that is not UTF-8', CT, Message)
    ;   (   ws_closing(C)
        ->  true
        ;   (   Code =:= 1005 -> Echo = [] ; HE is Code >> 8, LE is Code /\ 255, Echo = [HE, LE] ),
            ignore(ws_send_frame(WS, 1, 8, Echo))
        ),
        atom_codes(R, Reason),
        Message = close(Code, R),
        ws_finished(WS, CT)
    ).

%% THIS SIDE FAILS THE CONNECTION: the close frame with the code that says
%% why (when one has not already gone), and the conversation is over.
ws_fail_connection(WS, Code, Why, CT, close(Code, Why)) :-
    WS = websocket(C, _, _),
    (   ws_closing(C) -> true
    ;   ws_close_payload(Code, Why, P),
        ignore(ws_send_frame(WS, 1, 8, P))
    ),
    ws_finished(WS, CT).

%% THE CONNECTION WAS LOST: 1006, which is never sent, and nothing is.
ws_lost(WS, CT, Why, close(1006, Why)) :- ws_finished(WS, CT).

%% THE END OF A CONVERSATION. A client closes its socket, having waited up
%% to CT for the server to close first; a server leaves its socket to the
%% loop that accepted it. Either way the conversation is marked done, and
%% nothing touches the transport again until a new one begins on it.
ws_finished(websocket(C, client, _), CT) :- !,
    ignore(ws_drain(C, CT)),
    ignore(ws_sock_close(C)),
    ws_unmark_closing(C),
    ws_mark_done(C).
ws_finished(websocket(C, server, _), _) :-
    ws_unmark_closing(C),
    ws_mark_done(C).

%% Whatever the server still sends before it closes, read and dropped,
%% until end of stream or until CT is up.
ws_drain(C, CT) :-
    ws_sock_read(C, 65536, CT, _),
    !,
    ws_drain(C, CT).
ws_drain(_, _).

%% ======================================================================
%% ---- the closing handshake --------------------------------------------------
%% ======================================================================

%% ws_close(+WS) is det.
%% ws_close(+WS, +Code, +Reason) is det.
%% A close frame, then whatever comes until the peer's close, which is
%% read and owed nothing, or until five seconds have passed; then a client
%% closes its socket. ON A CONVERSATION THAT HAS ALREADY ENDED THIS DOES
%% NOTHING AT ALL -- not a write, not a close: a client's socket went at
%% the end, and its slot may be somebody else's by now.
ws_close(WS) :- ws_close(WS, 1000, '').

ws_close(WS, Code, Why) :-
    WS = websocket(C, _, _),
    (   ws_done(C)
    ->  true
    ;   ws_send_close_frame(WS, Code, Why)
    ->  ws_await_close(WS, 5000)
    ;   %% NOTHING WENT: the socket is broken, and the conversation is over
        ws_finished(WS, 0)
    ).

%% The peer's close, or the end, whichever is first, inside T in all. Data
%% that arrives in the meantime is dropped -- this side has said it is done
%% -- and anything ws_receive would call an ending ends the wait. A DEADLINE
%% AND NOT A TIMEOUT PER READ, or a peer that never stops talking would keep
%% this side here for ever.
ws_await_close(WS, T) :-
    get_time(Now),
    Deadline is Now + T / 1000,
    ws_await_close_(WS, Deadline).

ws_await_close_(WS, Deadline) :-
    get_time(Now),
    Left is integer((Deadline - Now) * 1000),
    (   Left =< 0
    ->  ws_finished(WS, 0)
    ;   catch(ws_receive(WS, M, [timeout(Left), close_timeout(Left)]), _,
              ( ws_finished(WS, 0), M = close(1006, error) ))
    ->  (   M = close(_, _)
        ->  true
        ;   ws_await_close_(WS, Deadline)
        )
    ;   %% the peer said nothing in time: this side's end is finished anyway
        ws_finished(WS, 0)
    ).

%% THE MARKS ARE PER CONNECTION AND PER STORE: the transport terms this side
%% has sent a close on (`closing'), and those whose conversation is over
%% (`done'), each a list in a global. A global belongs to the store, so a
%% session in one of httpd's workers -- a fresh store for each connection --
%% sees only its own. A conversation that begins on a transport forgets
%% both, because a slot is given out again.
ws_closing(C) :- ws_marked('$ws_closing', C).
ws_mark_closing(C) :- ws_mark('$ws_closing', C).
ws_unmark_closing(C) :- ws_unmark('$ws_closing', C).

ws_done(C) :- ws_marked('$ws_done', C).
ws_mark_done(C) :- ws_mark('$ws_done', C).

ws_forget(C) :- ws_unmark('$ws_closing', C), ws_unmark('$ws_done', C).

ws_marked(G, C) :- ws_mark_set(G, S), memberchk(C, S).

ws_mark_set(G, S) :- catch(nb_getval(G, S), _, S = []).

ws_mark(G, C) :-
    ws_mark_set(G, S),
    (   memberchk(C, S) -> true ; nb_setval(G, [C|S]) ).

ws_unmark(G, C) :-
    ws_mark_set(G, S),
    (   memberchk(C, S)
    ->  ws_delete(S, C, S1),
        nb_setval(G, S1)
    ;   true
    ).

ws_delete([], _, []).
ws_delete([X|Xs], C, Out) :-
    (   X == C -> Out = Rest ; Out = [X|Rest] ),
    ws_delete(Xs, C, Rest).

%% ======================================================================
%% ---- the frame -------------------------------------------------------------
%% ======================================================================
%%
%%      0               1               2               3
%%      7 6 5 4 3 2 1 0 7 6 5 4 3 2 1 0 ...
%%     +-+-+-+-+-------+-+-------------+-------------------------------+
%%     |F|R|R|R| opcode|M| length 0-125| 126: 16 bits, 127: 64 bits   |
%%     |I|S|S|S|       |A| or 126/127  | of length, big-endian         |
%%     |N|V|V|V|       |S|             +-------------------------------+
%%     | |1|2|3|       |K|             | then the mask key, if MASK    |
%%     +-+-+-+-+-------+-+-------------+-------------------------------+
%%     |                    then the payload, masked if MASK          |
%%     +---------------------------------------------------------------+

%% ws_frame_bytes(+Fin, +Opcode, +Mask, +Payload, -Bytes) is det.
%% Mask is `none' or four bytes. The length is written in the fewest bytes
%% that hold it, as RFC 6455 section 5.2 requires of a sender.
ws_frame_bytes(Fin, Op, Mask, Payload, Bytes) :-
    length(Payload, Len),
    B0 is Fin << 7 \/ Op,
    (   Mask == none
    ->  M = 0, Key = [], Body = Payload
    ;   M = 128, Key = Mask, ws_mask(Payload, Mask, Body)
    ),
    ws_length_bytes(Len, M, LenBytes),
    append(Key, Body, KB),
    append([B0|LenBytes], KB, Bytes).

ws_length_bytes(Len, M, [B]) :- Len < 126, !, B is M \/ Len.
ws_length_bytes(Len, M, [B, H, L]) :- Len < 65536, !,
    B is M \/ 126, H is Len >> 8, L is Len /\ 255.
ws_length_bytes(Len, M, [B|Eight]) :-
    B is M \/ 127,
    ws_be_bytes(8, Len, Eight).

%% N bytes of V, most significant first.
ws_be_bytes(N, V, Bytes) :- ws_be_bytes_(N, V, [], Bytes).
ws_be_bytes_(0, _, Acc, Acc) :- !.
ws_be_bytes_(N, V, Acc, Bytes) :-
    B is V /\ 255, V1 is V >> 8, N1 is N - 1,
    ws_be_bytes_(N1, V1, [B|Acc], Bytes).

%% ws_frame(+Bytes, -Frame, -Rest) is semidet.
%% THE SAME READER AS THE SOCKET'S, over a code list: one frame, unmasked,
%% as frame(Fin, Opcode, Mask, Payload) with Mask `none' or the key it came
%% with, and the bytes after it. Fails on a frame that has not all arrived;
%% throws ws_fail(Code, Why) on one that breaks a rule.
ws_frame(Bytes, Frame, Rest) :-
    ws_frame(Bytes, 16777216, Frame, Rest).

ws_frame([B0|Bs], Max, Frame, Rest) :-
    ws_frame_rest(bytes(Bs), B0, Max, Frame, bytes(Rest)).

%% Everything after the first byte, from a source: bytes(List), or
%% conn(C, Timeout), a socket read exactly. The frame's own rules are
%% checked here, as early as each can be.
ws_frame_rest(Src0, B0, Max, frame(Fin, Op, Mask, Payload), Src) :-
    ws_take(Src0, 1, [B1], Src1),
    Fin is B0 >> 7,
    Rsv is (B0 >> 4) /\ 7,
    Op is B0 /\ 15,
    MaskBit is B1 >> 7,
    L0 is B1 /\ 127,
    (   Rsv =\= 0 -> throw(ws_fail(1002, 'an RSV bit set, and no extension spoken')) ; true ),
    (   ws_opcode(Op) -> true ; throw(ws_fail(1002, 'an opcode RFC 6455 does not define')) ),
    (   Op >= 8, Fin =:= 0 -> throw(ws_fail(1002, 'a control frame in fragments')) ; true ),
    (   Op >= 8, L0 > 125 -> throw(ws_fail(1002, 'a control frame over 125 bytes')) ; true ),
    ws_payload_length(L0, Src1, Max, Len, Src2),
    (   MaskBit =:= 1
    ->  ws_take(Src2, 4, Mask, Src3)
    ;   Mask = none, Src3 = Src2
    ),
    ws_take(Src3, Len, Raw, Src),
    (   Mask == none -> Payload = Raw ; ws_mask(Raw, Mask, Payload) ).

ws_opcode(0).
ws_opcode(1).
ws_opcode(2).
ws_opcode(8).
ws_opcode(9).
ws_opcode(10).

%% THE LENGTH IS CHECKED AGAINST Max BEFORE IT IS READ. A 64-bit length
%% with anything in its top half is over every Max there is, and is refused
%% from the bytes, before a 60-bit cell could be asked to hold it.
ws_payload_length(L0, Src, Max, L0, Src) :- L0 < 126, !,
    ws_fits(L0, Max).
ws_payload_length(126, Src0, Max, Len, Src) :- !,
    ws_take(Src0, 2, [H, L], Src),
    Len is H << 8 \/ L,
    ws_fits(Len, Max).
ws_payload_length(127, Src0, Max, Len, Src) :-
    %% TAKEN ONCE: from a socket the eight bytes are gone when they are read,
    %% so the decision is made over them here and never by a second clause
    %% reading eight more
    ws_take(Src0, 8, [A, B, C, D, E, F, G, H], Src),
    (   A =:= 0, B =:= 0, C =:= 0, D =:= 0
    ->  Len is E << 24 \/ F << 16 \/ G << 8 \/ H,
        ws_fits(Len, Max)
    ;   throw(ws_fail(1009, 'a frame longer than four gigabytes'))
    ).

ws_fits(Len, Max) :-
    (   Len =< Max -> true ; throw(ws_fail(1009, 'a frame over max_message')) ).

%% Exactly N bytes from a source. A socket that times out or closes in the
%% middle of a frame has lost the frame: 1006, and the stream cannot be read
%% any further.
ws_take(bytes(L0), N, Bs, bytes(L)) :-
    length(Bs, N),
    append(Bs, L, L0).
ws_take(conn(C, T), N, Bs, conn(C, T)) :-
    (   ws_read_exact(C, N, T, Bs)
    ->  true
    ;   ws_sock_why(C, Why),
        atom_concat('lost inside a frame: ', Why, W),
        throw(ws_fail(1006, W))
    ).

ws_read_exact(_, 0, _, []) :- !.
ws_read_exact(C, N, T, Bytes) :-
    ws_read_exact_(C, N, T, Chunks),
    append(Chunks, Bytes).

ws_read_exact_(_, 0, _, []) :- !.
ws_read_exact_(C, N, T, [Chunk|Cs]) :-
    Ask is min(N, 1048576),
    ws_sock_read(C, Ask, T, Chunk),
    length(Chunk, Got),
    N1 is N - Got,
    ws_read_exact_(C, N1, T, Cs).

%% ws_mask(+Bytes, +Key, -Masked) is det.
%% XOR with the key, byte i with key byte i mod 4 -- its own inverse, which
%% is why one predicate masks and unmasks. Four at a time, so the key does
%% not rotate a byte at a time through a list.
ws_mask(Bytes, [K0, K1, K2, K3], Out) :- ws_mask4(Bytes, K0, K1, K2, K3, Out).

ws_mask4([A, B, C, D|T], K0, K1, K2, K3, [W, X, Y, Z|R]) :- !,
    W is xor(A, K0), X is xor(B, K1), Y is xor(C, K2), Z is xor(D, K3),
    ws_mask4(T, K0, K1, K2, K3, R).
ws_mask4([A, B, C], K0, K1, K2, _, [W, X, Y]) :- !,
    W is xor(A, K0), X is xor(B, K1), Y is xor(C, K2).
ws_mask4([A, B], K0, K1, _, _, [W, X]) :- !,
    W is xor(A, K0), X is xor(B, K1).
ws_mask4([A], K0, _, _, _, [W]) :- !,
    W is xor(A, K0).
ws_mask4([], _, _, _, _, []).

%% ======================================================================
%% ---- UTF-8 -----------------------------------------------------------------
%% ======================================================================

%% ws_utf8(+Bytes) is semidet.
%% RFC 3629 exactly: no overlong form, no surrogate, nothing past U+10FFFF,
%% and every sequence whole. The ranges are the RFC's own table, written in
%% decimal because a reader with no `0x' would otherwise be a dependency.
ws_utf8([]).
ws_utf8([B|Bs]) :- B < 128, !, ws_utf8(Bs).
ws_utf8([B0, B1|Bs]) :- B0 >= 194, B0 =< 223, !,                 % C2..DF
    ws_tail(B1), ws_utf8(Bs).
ws_utf8([224, B1, B2|Bs]) :- !,                                  % E0 A0..BF
    B1 >= 160, B1 =< 191, ws_tail(B2), ws_utf8(Bs).
ws_utf8([B0, B1, B2|Bs]) :- B0 >= 225, B0 =< 236, !,             % E1..EC
    ws_tail(B1), ws_tail(B2), ws_utf8(Bs).
ws_utf8([237, B1, B2|Bs]) :- !,                                  % ED 80..9F
    B1 >= 128, B1 =< 159, ws_tail(B2), ws_utf8(Bs).
ws_utf8([B0, B1, B2|Bs]) :- B0 >= 238, B0 =< 239, !,             % EE..EF
    ws_tail(B1), ws_tail(B2), ws_utf8(Bs).
ws_utf8([240, B1, B2, B3|Bs]) :- !,                              % F0 90..BF
    B1 >= 144, B1 =< 191, ws_tail(B2), ws_tail(B3), ws_utf8(Bs).
ws_utf8([B0, B1, B2, B3|Bs]) :- B0 >= 241, B0 =< 243, !,         % F1..F3
    ws_tail(B1), ws_tail(B2), ws_tail(B3), ws_utf8(Bs).
ws_utf8([244, B1, B2, B3|Bs]) :-                                 % F4 80..8F
    B1 >= 128, B1 =< 143, ws_tail(B2), ws_tail(B3), ws_utf8(Bs).

ws_tail(B) :- B >= 128, B =< 191.

%% ======================================================================
%% ---- SHA-1 -----------------------------------------------------------------
%% ======================================================================

%% ws_sha1(+Bytes, -Digest) is det.
%% FIPS 180-4, section 6.1, over a byte list: twenty bytes back. Every word
%% is held under 2^32 by masking after each step; a cell's 60 bits are room
%% enough for the sums in between.
ws_sha1(Bytes, Digest) :-
    length(Bytes, Len),
    Zeros is (55 - Len) mod 64,
    length(Zs, Zeros), ws_all_zero(Zs),
    Bits is Len * 8,
    ws_be_bytes(8, Bits, LenBytes),
    append([Bytes, [128], Zs, LenBytes], Padded),
    ws_sha1_blocks(Padded, 1732584193, 4023233417, 2562383102, 271733878, 3285377520,
                   H0, H1, H2, H3, H4),
    ws_words_bytes([H0, H1, H2, H3, H4], Digest).

ws_all_zero([]).
ws_all_zero([0|T]) :- ws_all_zero(T).

ws_sha1_blocks([], A, B, C, D, E, A, B, C, D, E) :- !.
ws_sha1_blocks(Bytes, H0, H1, H2, H3, H4, O0, O1, O2, O3, O4) :-
    length(Block, 64),
    append(Block, Rest, Bytes),
    ws_bytes_words(Block, W16),
    ws_sha1_schedule(W16, W80),
    ws_sha1_rounds(W80, 0, H0, H1, H2, H3, H4, A, B, C, D, E),
    N0 is (H0 + A) /\ 4294967295,
    N1 is (H1 + B) /\ 4294967295,
    N2 is (H2 + C) /\ 4294967295,
    N3 is (H3 + D) /\ 4294967295,
    N4 is (H4 + E) /\ 4294967295,
    ws_sha1_blocks(Rest, N0, N1, N2, N3, N4, O0, O1, O2, O3, O4).

%% The sixteen words, and sixty-four more, each the XOR of four earlier ones
%% rotated left by one: a window of sixteen slides along.
ws_sha1_schedule(W16, W80) :-
    ws_sha1_more(64, W16, More),
    append(W16, More, W80).

ws_sha1_more(0, _, []) :- !.
ws_sha1_more(N, [W0, W1, W2, W3, W4, W5, W6, W7, W8, W9, W10, W11, W12, W13, W14, W15], [W|Ws]) :-
    X is xor(xor(W13, W8), xor(W2, W0)),
    W is (X << 1 \/ X >> 31) /\ 4294967295,
    N1 is N - 1,
    ws_sha1_more(N1, [W1, W2, W3, W4, W5, W6, W7, W8, W9, W10, W11, W12, W13, W14, W15, W], Ws).

ws_sha1_rounds([], _, A, B, C, D, E, A, B, C, D, E).
ws_sha1_rounds([W|Ws], T, A, B, C, D, E, A9, B9, C9, D9, E9) :-
    ws_sha1_f(T, B, C, D, F, K),
    Rot is (A << 5 \/ A >> 27) /\ 4294967295,
    Temp is (Rot + F + E + K + W) /\ 4294967295,
    B30 is (B << 30 \/ B >> 2) /\ 4294967295,
    T1 is T + 1,
    ws_sha1_rounds(Ws, T1, Temp, A, B30, C, D, A9, B9, C9, D9, E9).

ws_sha1_f(T, B, C, D, F, 1518500249) :- T < 20, !,
    F is (B /\ C) \/ (xor(B, 4294967295) /\ D).
ws_sha1_f(T, B, C, D, F, 1859775393) :- T < 40, !,
    F is xor(xor(B, C), D).
ws_sha1_f(T, B, C, D, F, 2400959708) :- T < 60, !,
    F is (B /\ C) \/ (B /\ D) \/ (C /\ D).
ws_sha1_f(_, B, C, D, F, 3395469782) :-
    F is xor(xor(B, C), D).

ws_bytes_words([], []).
ws_bytes_words([A, B, C, D|T], [W|Ws]) :-
    W is A << 24 \/ B << 16 \/ C << 8 \/ D,
    ws_bytes_words(T, Ws).

ws_words_bytes([], []).
ws_words_bytes([W|Ws], [A, B, C, D|T]) :-
    A is W >> 24 /\ 255, B is W >> 16 /\ 255, C is W >> 8 /\ 255, D is W /\ 255,
    ws_words_bytes(Ws, T).

%% ======================================================================
%% ---- base64 ----------------------------------------------------------------
%% ======================================================================

%% ws_base64(+Bytes, -Atom) is det.
%% RFC 4648's alphabet, padded with `='.
ws_base64(Bytes, Atom) :-
    ws_b64_enc(Bytes, Cs),
    atom_codes(Atom, Cs).

ws_b64_enc([], []).
ws_b64_enc([A], [C1, C2, 0'=, 0'=]) :- !,
    I1 is A >> 2, I2 is (A /\ 3) << 4,
    ws_b64_char(I1, C1), ws_b64_char(I2, C2).
ws_b64_enc([A, B], [C1, C2, C3, 0'=]) :- !,
    I1 is A >> 2, I2 is (A /\ 3) << 4 \/ B >> 4, I3 is (B /\ 15) << 2,
    ws_b64_char(I1, C1), ws_b64_char(I2, C2), ws_b64_char(I3, C3).
ws_b64_enc([A, B, C|T], [C1, C2, C3, C4|Cs]) :-
    I1 is A >> 2, I2 is (A /\ 3) << 4 \/ B >> 4,
    I3 is (B /\ 15) << 2 \/ C >> 6, I4 is C /\ 63,
    ws_b64_char(I1, C1), ws_b64_char(I2, C2), ws_b64_char(I3, C3), ws_b64_char(I4, C4),
    ws_b64_enc(T, Cs).

ws_b64_char(I, C) :- I < 26, !, C is 0'A + I.
ws_b64_char(I, C) :- I < 52, !, C is 0'a + I - 26.
ws_b64_char(I, C) :- I < 62, !, C is 0'0 + I - 52.
ws_b64_char(62, 0'+).
ws_b64_char(63, 0'/).

%% ws_unbase64(+Atom, -Bytes) is semidet.
%% Strict: four characters a group, `=' only at the end and only as the
%% padding the last group needs, and nothing outside the alphabet.
ws_unbase64(Atom, Bytes) :-
    atom(Atom),
    atom_codes(Atom, Cs),
    length(Cs, N),
    N mod 4 =:= 0,
    ws_b64_dec(Cs, Bytes).

ws_b64_dec([], []).
ws_b64_dec([C1, C2, 0'=, 0'=], [A]) :- !,
    ws_b64_val(C1, I1), ws_b64_val(C2, I2),
    I2 /\ 15 =:= 0,
    A is I1 << 2 \/ I2 >> 4.
ws_b64_dec([C1, C2, C3, 0'=], [A, B]) :- !,
    ws_b64_val(C1, I1), ws_b64_val(C2, I2), ws_b64_val(C3, I3),
    I3 /\ 3 =:= 0,
    A is I1 << 2 \/ I2 >> 4,
    B is (I2 /\ 15) << 4 \/ I3 >> 2.
ws_b64_dec([C1, C2, C3, C4|Cs], [A, B, C|Bs]) :-
    ws_b64_val(C1, I1), ws_b64_val(C2, I2), ws_b64_val(C3, I3), ws_b64_val(C4, I4),
    A is I1 << 2 \/ I2 >> 4,
    B is (I2 /\ 15) << 4 \/ I3 >> 2,
    C is (I3 /\ 3) << 6 \/ I4,
    ws_b64_dec(Cs, Bs).

ws_b64_val(C, I) :- C >= 0'A, C =< 0'Z, !, I is C - 0'A.
ws_b64_val(C, I) :- C >= 0'a, C =< 0'z, !, I is C - 0'a + 26.
ws_b64_val(C, I) :- C >= 0'0, C =< 0'9, !, I is C - 0'0 + 52.
ws_b64_val(0'+, 62).
ws_b64_val(0'/, 63).

%% ======================================================================
%% ---- randomness, and the transport -----------------------------------------
%% ======================================================================

%% ws_random_bytes(+N, -Bytes) is det.
%% From /dev/urandom, through library(stream): a client's mask keys and its
%% handshake key are what RFC 6455 section 10.3 says must not be guessable.
ws_random_bytes(N, Bytes) :-
    catch(stream_open('/dev/urandom', read, [type(binary)], S),
          error(existence_error(procedure, _), _),
          throw(error(existence_error(procedure, stream_open/4),
                      'websocket: a client needs library(stream) for its random keys -- sh modules/stream/build.sh'))),
    (   stream_read_bytes(S, N, Bytes), length(Bytes, N)
    ->  stream_close(S)
    ;   stream_close(S),
        throw(error(resource_error(random_bytes), context(ws_random_bytes/2, _)))
    ).

%% THE SAME TAGGED CONNECTIONS library(httpd) passes about: `plain(S)', a
%% library(tcp) handle, and `secure(S)', a library(tls) one. Kept here
%% under this library's own names so a client needs no server loaded.
ws_sock_read(plain(C), Max, T, Codes) :- tcp_read(C, Max, T, Codes).
ws_sock_read(secure(C), Max, T, Codes) :- tls_read(C, Max, T, Codes).

ws_sock_write(plain(C), Codes) :- tcp_write(C, Codes).
ws_sock_write(secure(C), Codes) :- tls_write(C, Codes).

ws_sock_close(plain(C)) :- tcp_close(C).
ws_sock_close(secure(C)) :- tls_close(C).

ws_sock_why(plain(_), Why) :- catch(tcp_why(Why), _, Why = 'connection lost').
ws_sock_why(secure(_), Why) :- catch(tls_why(Why), _, Why = 'connection lost').

%% ws_option(+Template, +Options, +Default) is det.
ws_option(Template, Options, Default) :-
    (   memberchk(Template, Options)
    ->  true
    ;   arg(1, Template, Default)
    ).
