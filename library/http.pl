%% library(http) -- HTTP/1.1 as a grammar, over the bytes lib/tcp gives back.
%%
%% EVERY PREDICATE IN HERE IS `http_'-PREFIXED, helpers included, because
%% COCOLOG HAS ONE NAMESPACE. A library's private names are not private:
%% they are everybody's, and the first clash is silent. This file had a
%% plain `eol//0' and library(dcg_basics) has one too -- whose last clause
%% is `eol --> eos.', so it treats END OF INPUT as a line ending. The
%% moment the vendored SWI libraries became always-present, a request
%% whose headers simply STOPPED began to parse: the blank line that must
%% terminate them was matched by the other file's end-of-input rule. A
%% truncated request read as a complete one, which is precisely the shape
%% of a request-smuggling bug.
%%
%% Found by the suite the same hour, because `headers that never end' was
%% already a check. It would not have been found by reading either file.
%%
%% THE WHOLE THING IS CLAUSES. Sockets needed a C half because a syscall is
%% not something a clause can reach; parsing is the opposite -- it is what
%% Prolog is for, and a DCG over a code list IS the message format written
%% down. There is no C in this file and there should never be any.
%%
%% IT PARSES CODES, NOT AN ATOM, and that is why tcp_read/4 answers codes.
%% An atom in cocolog is a C string and stops at the first NUL, so an
%% atom-shaped parser would silently truncate a body -- and a body is not
%% text. Codes carry every byte, and `phrase/2' walks them.
%%
%% WHAT A REQUEST BECOMES:
%%
%%     request(Method, Path, Query, Version, Headers, Body)
%%
%%     Method   a lowercase atom: get, post, delete. SWI does the same, and
%%              a page matching `get' rather than `'GET'' needs no quotes.
%%     Path     an atom, percent-DECODED: '/a b' from '/a%20b'
%%     Query    a list of Key-Value, both decoded, `+' read as a space
%%     Version  http(1,1) -- structured, so a page can ask about the major
%%     Headers  a list of Name-Value. NAMES ARE DOWNCASED ATOMS, because
%%              HTTP field names are case-insensitive and a page that has
%%              to remember whether the client said `Host' or `host' will
%%              get it wrong on some client eventually
%%     Body     a code list. Exactly Content-Length bytes, or [] when there
%%              is no body
%%
%% WHERE IT IS STRICT, and each is a decision rather than an omission:
%%
%%   NO obs-fold. A header value continued on the next line by leading
%%   whitespace is deprecated by RFC 7230 section 3.2.4, which says a
%%   server MUST reject it or replace it -- it is a request-smuggling
%%   surface, and this parser fails rather than guessing.
%%
%%   NO chunked transfer-encoding, and the parse FAILS rather than
%%   half-succeeding. A server can answer 501 off that failure. Accepting
%%   the headers and quietly handing back a body still wrapped in its
%%   chunk framing is the version of this that corrupts data silently.
%%
%%   A bare LF IS accepted as a line ending, alongside CRLF. That one is
%%   spec-sanctioned -- RFC 7230 section 3.5 lets a recipient recognise a
%%   single LF -- and every hand-written client sends it eventually.
%%
%%   CONTENT-LENGTH IS BELIEVED EXACTLY. More bytes than it names are not
%%   the body, and fewer means the request is not complete yet, which is a
%%   failure and not a short body. Both matter: a server that reads past
%%   the length it was given is one that can be fed two requests as one.

:- dynamic http_status_text/2.

%% ---- the entry point -------------------------------------------------

%% http_request(+Codes, -Request) is semidet.
http_request(Codes, request(Method, Path, Query, Version, Headers, Body)) :-
    phrase(http_request_head(Method, Target, Version, Headers), Codes, Rest),
    !,
    \+ member('transfer-encoding'-_, Headers),
    http_body(Headers, Rest, Body),
    http_target(Target, Path, Query).

%% http_header(+Request, +Name, -Value) is semidet.
%% Name is matched downcased, so a caller may ask for 'Content-Type'.
http_header(request(_,_,_,_,Headers,_), Name, Value) :-
    downcase_atom(Name, Key),
    memberchk(Key-Value, Headers).

%% The body of a request that carries one. Absent Content-Length means no
%% body at all: a length nobody stated is zero, never "whatever arrived".
http_body(Headers, Rest, Body) :-
    (   memberchk('content-length'-L, Headers)
    ->  atom_number(L, N),
        N >= 0,
        length(Body, N),
        append(Body, _, Rest)     % fails when fewer than N bytes arrived
    ;   Body = []
    ).

%% ---- the request line and headers ------------------------------------

http_request_head(Method, Target, Version, Headers) -->
    http_method(Method), " ",
    http_target_codes(TC), { TC \== [], atom_codes(Target, TC) }, " ",
    http_version(Version), http_eol,
    http_headers(Headers),
    http_eol.

%% A method is one or more token characters, downcased. HTTP methods are
%% case-sensitive by the spec and uppercase by convention; downcasing them
%% is what makes `get' a plain atom at every call site, and an unknown
%% method still arrives intact rather than being rejected here -- deciding
%% what to do about `PROPFIND' is the server's business, not the parser's.
http_method(Method) -->
    http_token_codes(Cs), { Cs \== [], atom_codes(A, Cs), downcase_atom(A, Method) }.

http_target_codes([C|Cs]) --> [C], { C \== 32, C \== 13, C \== 10 }, !,
                              http_target_codes(Cs).
http_target_codes([]) --> [].

http_version(http(Major, Minor)) -->
    "HTTP/", http_digits_(D1), ".", http_digits_(D2),
    { D1 \== [], D2 \== [],
      number_codes(Major, D1), number_codes(Minor, D2) }.

http_headers([Name-Value|Hs]) -->
    http_header_name(Name), ":", http_ows, http_header_value(Value), http_eol, !,
    http_headers(Hs).
http_headers([]) --> [].

%% Downcased, because field names are case-insensitive and remembering
%% which spelling a client used is not a thing a page should have to do.
http_header_name(Name) -->
    http_token_codes(Cs), { Cs \== [], atom_codes(A, Cs), downcase_atom(A, Name) }.

%% To the end of the line, then trailing whitespace trimmed. Leading
%% whitespace was eaten by `http_ows'; the two together are RFC 7230's OWS
%% around a field value.
http_header_value(Value) -->
    http_line_codes(Cs), { http_trim_right(Cs, T), atom_codes(Value, T) }.

http_line_codes([C|Cs]) --> [C], { C \== 13, C \== 10 }, !, http_line_codes(Cs).
http_line_codes([]) --> [].

%% ---- the target: path, query, and per cent ---------------------------

%% http_target(+Target, -Path, -Query) is det.
http_target(Target, Path, Query) :-
    atom_codes(Target, Cs),
    (   append(P, [63|Q], Cs)          % 63 is `?'
    ->  true
    ;   P = Cs, Q = []
    ),
    http_percent_decode(P, PD), atom_codes(Path, PD),
    http_query(Q, Query).

%% http_query(+Codes, -Params) is det.
http_query([], []) :- !.
http_query(Cs, [Key-Value|Ps]) :-
    (   append(Pair, [38|Rest], Cs)    % 38 is `&'
    ->  true
    ;   Pair = Cs, Rest = []
    ),
    (   append(K, [61|V], Pair)        % 61 is `='
    ->  true
    ;   K = Pair, V = []
    ),
    http_form_decode(K, KD), atom_codes(Key, KD),
    http_form_decode(V, VD), atom_codes(Value, VD),
    http_query(Rest, Ps).

%% http_form(+Codes, -Params) is det.
%% An application/x-www-form-urlencoded body is a query string in the body,
%% so it is the same rule under a name that says where it came from.
http_form(Codes, Params) :- http_query(Codes, Params).

%% `+' is a space in a query or a form and is NOT a space in a path, which
%% is why there are two decoders rather than one with a flag. A path with a
%% literal plus in it -- and they exist -- must survive.
http_form_decode([], []) :- !.
http_form_decode([43|Cs], [32|Ds]) :- !, http_form_decode(Cs, Ds).
http_form_decode([37,H,L|Cs], [B|Ds]) :- http_hex_digit(H, HV), http_hex_digit(L, LV), !,
    B is HV * 16 + LV, http_form_decode(Cs, Ds).
http_form_decode([C|Cs], [C|Ds]) :- http_form_decode(Cs, Ds).

http_percent_decode([], []) :- !.
http_percent_decode([37,H,L|Cs], [B|Ds]) :- http_hex_digit(H, HV), http_hex_digit(L, LV), !,
    B is HV * 16 + LV, http_percent_decode(Cs, Ds).
http_percent_decode([C|Cs], [C|Ds]) :- http_percent_decode(Cs, Ds).

%% A malformed escape -- `%zz', or `%' at the end -- decodes to itself
%% rather than failing, because a parser that rejects a whole request over
%% one stray per cent sign is a parser people route around.
http_hex_digit(C, V) :- C >= 0'0, C =< 0'9, !, V is C - 0'0.
http_hex_digit(C, V) :- C >= 0'a, C =< 0'f, !, V is C - 0'a + 10.
http_hex_digit(C, V) :- C >= 0'A, C =< 0'F, !, V is C - 0'A + 10.

%% ---- building a response ---------------------------------------------

%% http_response(+Status, +Headers, +Body, -Codes) is det.
%% Body may be an atom or a code list. Content-Length is COMPUTED and never
%% taken from the caller: a length that disagrees with the bytes is how a
%% response gets read as two, and it is not a mistake worth allowing.
http_response(Status, Headers, Body, Codes) :-
    http_body_codes(Body, BC),
    length(BC, Len),
    http_status_line(Status, Line),
    atom_codes(LineA, Line),
    http_header_lines([ 'Content-Length'-Len | Headers ], HL),
    atom_concat(LineA, HL, Head),
    atom_codes(Head, HeadC),
    append(HeadC, BC, Codes).

http_body_codes(Body, Codes) :- is_list(Body), !, Codes = Body.
http_body_codes(Body, Codes) :- atom_codes(Body, Codes).

http_status_line(Status, Line) :-
    ( http_status_text(Status, Text) -> true ; Text = 'Unknown' ),
    atomic_list_concat(['HTTP/1.1 ', Status, ' ', Text, '\r\n'], A),
    atom_codes(A, Line).

http_header_lines([], '\r\n').
http_header_lines([N-V|Hs], Out) :-
    atomic_list_concat([N, ': ', V, '\r\n'], One),
    http_header_lines(Hs, Rest),
    atom_concat(One, Rest, Out).

%% The ones a server built on this will actually send. A status with no
%% text here still goes out, with `Unknown' as its reason phrase, because
%% the number is what a client acts on and inventing a reason is harmless.
http_status_text(200, 'OK').
http_status_text(201, 'Created').
http_status_text(204, 'No Content').
http_status_text(301, 'Moved Permanently').
http_status_text(302, 'Found').
http_status_text(304, 'Not Modified').
http_status_text(400, 'Bad Request').
http_status_text(403, 'Forbidden').
http_status_text(404, 'Not Found').
http_status_text(405, 'Method Not Allowed').
http_status_text(408, 'Request Timeout').
http_status_text(411, 'Length Required').
http_status_text(413, 'Payload Too Large').
http_status_text(414, 'URI Too Long').
http_status_text(500, 'Internal Server Error').
http_status_text(501, 'Not Implemented').
http_status_text(503, 'Service Unavailable').

%% ---- the small print -------------------------------------------------

%% A token character, RFC 7230's `http_tchar': everything a field name or a
%% method may contain. Written as the complement of the delimiters because
%% that is how the spec reads and because the delimiter set is the shorter
%% one to get right.
http_token_codes([C|Cs]) --> [C], { http_tchar(C) }, !, http_token_codes(Cs).
http_token_codes([]) --> [].

http_tchar(C) :- C > 32, C < 127, \+ http_tchar_delim(C).

http_tchar_delim(0'").
http_tchar_delim(0'().
http_tchar_delim(0')).
http_tchar_delim(0',).
http_tchar_delim(0'/).
http_tchar_delim(0':).
http_tchar_delim(0';).
http_tchar_delim(0'<).
http_tchar_delim(0'=).
http_tchar_delim(0'>).
http_tchar_delim(0'?).
http_tchar_delim(0'@).
http_tchar_delim(0'[).
http_tchar_delim(0'\\).
http_tchar_delim(0']).
http_tchar_delim(0'{).
http_tchar_delim(0'}).

http_digits_([C|Cs]) --> [C], { C >= 0'0, C =< 0'9 }, !, http_digits_(Cs).
http_digits_([]) --> [].

%% Optional whitespace before a field value. NOT a line continuation: a
%% value that begins on the next line is obs-fold, and this grammar has no
%% rule that would accept one.
http_ows --> [32], !, http_ows.
http_ows --> [9], !, http_ows.
http_ows --> [].

http_trim_right(Cs, T) :-
    append(T, Tail, Cs),
    http_all_space(Tail),
    \+ ( append(T2, [C|_], T), T2 = T, ( C == 32 ; C == 9 ) ),
    !.
http_trim_right(Cs, Cs).

http_all_space([]).
http_all_space([32|T]) :- http_all_space(T).
http_all_space([9|T]) :- http_all_space(T).

%% CRLF, or a bare LF. See the header: RFC 7230 section 3.5 permits the
%% second and every hand-written client sends it sooner or later.
http_eol --> [13, 10], !.
http_eol --> [10].
