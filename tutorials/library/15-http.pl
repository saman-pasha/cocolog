%% LIBRARY 15 -- library(http): HTTP/1.1 as a grammar
%%
%%     ./cocolog run tutorials/library/15-http.pl main
%%
%% TIER 2: `use_module(library(http))'. Clauses only -- there is no C in
%% it at all, and there should never be any. Sockets need a C half
%% because a syscall is not something a clause can reach; PARSING is the
%% opposite, and a DCG over a code list IS the message format written
%% down.
%%
%% IT PARSES CODES, NOT AN ATOM, and that is a correctness decision. An
%% atom in cocolog is a C string and stops at the first NUL, so an
%% atom-shaped parser would silently truncate a body -- and a body is not
%% text. Codes carry every byte.
%%
%% WHAT A REQUEST BECOMES:
%%
%%     request(Method, Path, Query, Version, Headers, Body)
%%
%%     Method   a lowercase atom -- so a page matches `get' with no quotes
%%     Path     percent-DECODED
%%     Query    a list of Key-Value, decoded, `+' read as a space
%%     Version  http(1,1), structured, so you can ask about the major
%%     Headers  Name-Value with names DOWNCASED, because HTTP field names
%%              are case-insensitive and code that has to remember whether
%%              the client said `Host' or `host' gets it wrong eventually
%%     Body     a code list, exactly Content-Length bytes, or []
%%
%% WHERE IT IS STRICT, and each is a decision rather than an omission: no
%% obs-fold (RFC 7230 says reject it -- it is a smuggling surface); no
%% chunked transfer-encoding, and the parse FAILS rather than
%% half-succeeding so a server can answer 501; a bare LF is accepted
%% because the spec allows it and every hand-written client sends one; and
%% Content-Length is believed EXACTLY.

:- use_module(library(http)).

main :-
    format("~n-- a request, taken apart~n"),
    Req = "GET /hello HTTP/1.1\r\nHost: example.org\r\n\r\n",
    http_request(Req, request(M, P, Q, V, Hs, B)),
    must('the method is a LOWERCASE atom', M, get),
    must('the path', P, '/hello'),
    must('no query', Q, []),
    must('the version is structured', V, http(1, 1)),
    must('the headers, name downcased', Hs, [host-'example.org']),
    must('and no body', B, []),

    format("~n-- a query string, decoded~n"),
    Req2 = "GET /search?q=a+b&n=2 HTTP/1.1\r\n\r\n",
    http_request(Req2, request(_, P2, Q2, _, _, _)),
    must('the path stops at the ?', P2, '/search'),
    must('+ is a space, and the pairs are decoded', Q2, ['q'-'a b', 'n'-'2']),

    format("~n-- percent-decoding, in the path as well~n"),
    Req3 = "GET /a%20b HTTP/1.1\r\n\r\n",
    http_request(Req3, request(_, P3, _, _, _, _)),
    must('%20 in a path', P3, '/a b'),

    format("~n-- a body, believed EXACTLY as long as it says~n"),
    Req4 = "POST /x HTTP/1.1\r\nContent-Length: 5\r\n\r\nhello",
    http_request(Req4, request(M4, _, _, _, _, B4)),
    atom_codes(BodyAtom, B4),
    must('the method', M4, post),
    must('the body', BodyAtom, hello),

    format("~n-- and http_request/3 hands back what was NOT this request~n"),
    Two = "GET /a HTTP/1.1\r\n\r\nGET /b HTTP/1.1\r\n\r\n",
    http_request(Two, request(_, PA, _, _, _, _), Rest),
    must('the first request', PA, '/a'),
    http_request(Rest, request(_, PB, _, _, _, _)),
    must('and the second, from what was left', PB, '/b'),
    format("   That is what makes a PIPELINED pair cost one read. It is~n"),
    format("   also the same rule read forwards: believing~n"),
    format("   Content-Length exactly stops two requests being read as~n"),
    format("   one, and handing back the leftovers lets the second be~n"),
    format("   read as ITSELF.~n"),

    format("~n-- what it refuses~n"),
    refuses("GET /x HTTP/1.1\r\nH: a\r\n b\r\n\r\n", 'an obs-fold header'),
    refuses("POST /x HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n",
            'chunked transfer-encoding'),
    refuses("GET /x HTTP/1.1\r\nHost: a\r\n", 'headers that never end'),
    format("   The obs-fold is deprecated by RFC 7230 3.2.4, which says a~n"),
    format("   server MUST reject or replace it: it is a smuggling~n"),
    format("   surface. Chunked FAILS rather than half-succeeding, so a~n"),
    format("   server can answer 501 -- handing back a body still wrapped~n"),
    format("   in its chunk framing is the version that corrupts data.~n"),

    format("~n-- and a bare LF is accepted, because the spec allows it~n"),
    ( http_request("GET /x HTTP/1.1\n\n", request(_, PL, _, _, _, _))
    -> true ; PL = refused ),
    must('LF instead of CRLF', PL, '/x'),

    format("~n-- writing a response~n"),
    http_response(200, ['Content-Type'-'text/plain'], 'hi', Out),
    atom_codes(OutAtom, Out),
    ( sub_atom(OutAtom, 0, 15, _, Status) -> true ; Status = OutAtom ),
    must('the status line', Status, 'HTTP/1.1 200 OK'),
    ( sub_atom(OutAtom, _, _, 0, 'hi') -> Body = at_the_end ; Body = OutAtom ),
    must('and the body after the blank line', Body, at_the_end),

    format("~n-- library(httpd) is the server over this; library(curl)~n"),
    format("   is a client. This file is the GRAMMAR both of them use.~n~n"),
    format("done~n").

refuses(Codes, Label) :-
    ( catch(http_request(Codes, _), _, fail) -> R = parsed ; R = refused ),
    must(Label, R, refused).

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
