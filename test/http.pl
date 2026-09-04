%% library(http) -- HTTP/1.1 as a grammar, and what it refuses.
%%
%% WHAT IS BEING PINNED, and where the answers come from:
%%
%%   THE DECODING IS CHECKED AGAINST WRITTEN-OUT ANSWERS, not against this
%%   file's opinion of itself. Percent-decoding and form-decoding are
%%   exactly the kind of thing that looks right in every case an author
%%   thinks to write down; the expected values here are facts about RFC
%%   3986, and the one asymmetry worth pinning -- `+' stays a plus in a
%%   path and becomes a space in a query -- has a loop for each side.
%%
%%   AND THE WHOLE THING IS CHECKED AGAINST curl. The last section raises a
%%   cocolog that parses a real request and answers with a real response,
%%   and drives it with an HTTP client nobody here wrote. A parser tested
%%   only against strings its author typed is a parser tested against its
%%   author's idea of HTTP.
%%
%%   WHAT IT REFUSES IS THE POINT, not the leftovers. obs-fold is a
%%   request-smuggling surface that RFC 7230 says a server MUST reject;
%%   chunked framing handed back as a body is silent corruption; a body
%%   shorter than Content-Length is an incomplete request and not a short
%%   one. Each of those FAILS the parse, and each is checked, because a
%%   parser's refusals are the half that decides whether the server built
%%   on it is safe.
%%
%%   BODIES ARE CODES AND CARRY EVERY BYTE, including the NUL that would
%%   have ended an atom. That is why tcp_read/4 answers codes and why this
%%   parser never turns a body into one.
%%
%%     cocolog -s test/http.pl        from the checkout root
%%
%% ONE PROCESS FOR THE GRAMMAR, where test/http.sh spawned one per check
%% (18.3 s on this machine, forty-four of them before curl). The three curl
%% checks still raise a server each, because a server is a second process
%% by definition -- and each waits for its port rather than sleeping three
%% seconds, watched through lsof, never through a probe connection: the
%% server accepts ONCE, and a probe would be the request.

:- use_module('test/prelude.pl').

main :-
    (   catch(use_module(library(http)), _, fail)
    ->  true
    ;   skip('(library(http) will not load)')
    ),
    request_line, headers, query_and_body, every_byte, refusals, decoding, responses,
    against_curl,
    checks_done.

req('GET /a%20b?x=1&y=hi+there HTTP/1.1\r\nHost: example.org\r\nContent-Length: 5\r\n\r\nhello').

%% Whether a request parses at all.
parses(Text, Got) :-
    written(( atom_codes(Text, Cs), ( http_request(Cs, _) -> X = parsed ; X = refused ) ), X, Got).

%% A parsed request, from its text.
request_of(Text, R) :- atom_codes(Text, Cs), http_request(Cs, R).

request_line :-
    section('the request line'),
    req(Req),
    written(request_of(Req, request(M1,_,_,_,_,_)), M1, G1),
    check('the method is a lowercase atom', G1, get),
    written(request_of(Req, request(_,P2,_,_,_,_)), P2, G2),
    check('the path is percent-decoded', G2, '/a b'),
    written(( request_of(Req, request(_,_,_,http(Ma3,Mi3),_,_)), atomic_list_concat([Ma3,'.',Mi3], X3) ), X3, G3),
    check('the version is structured', G3, '1.1'),
    written(request_of('PROPFIND / HTTP/1.1\r\n\r\n', request(M4,_,_,_,_,_)), M4, G4),
    check('an unknown method still arrives', G4, propfind),
    written(( request_of('GET / HTTP/1.0\r\n\r\n', request(_,_,_,http(Ma5,Mi5),_,_)), atomic_list_concat([Ma5,'.',Mi5], X5) ), X5, G5),
    check('HTTP/1.0 is parsed, not assumed', G5, '1.0').

headers :-
    section('headers'),
    req(Req),
    written(request_of(Req, request(_,_,_,_,H1,_)), H1, G1),
    check('names are downcased', G1, '[host-example.org,content-length-5]'),
    written(( request_of(Req, R2), http_header(R2, 'HOST', X2) ), X2, G2),
    check('lookup is case-insensitive', G2, 'example.org'),
    written(( request_of('GET / HTTP/1.1\r\nX: a  b\r\n\r\n', R3), http_header(R3, x, X3) ), X3, G3),
    check('a value keeps its inner spaces', G3, 'a  b'),
    written(( request_of('GET / HTTP/1.1\r\nX:   trimmed   \r\n\r\n', R4), http_header(R4, x, X4) ), X4, G4),
    check('and loses the outer ones', G4, trimmed),
    written(request_of('GET / HTTP/1.1\r\nX: 1\r\nX: 2\r\n\r\n', request(_,_,_,_,H5,_)), H5, G5),
    check('a duplicated header keeps both', G5, '[x-1,x-2]'),
    written(request_of('GET / HTTP/1.1\r\n\r\n', request(_,_,_,_,H6,_)), H6, G6),
    check('a request with no headers at all', G6, '[]').

query_and_body :-
    section('the query, and the body'),
    req(Req),
    written(request_of(Req, request(_,_,Q1,_,_,_)), Q1, G1),
    check('the query splits into pairs', G1, '[x-1,y-hi there]'),
    written(request_of('GET /?flag HTTP/1.1\r\n\r\n', request(_,_,Q2,_,_,_)), Q2, G2),
    check('a key with no value is empty', G2, '[flag-]'),
    written(request_of('GET /p HTTP/1.1\r\n\r\n', request(_,_,Q3,_,_,_)), Q3, G3),
    check('no query at all is the empty list', G3, '[]'),
    written(( request_of(Req, request(_,_,_,_,_,B4)), atom_codes(X4, B4) ), X4, G4),
    check('the body is exactly Content-Length', G4, hello),
    written(( request_of('GET / HTTP/1.1\r\n\r\n', request(_,_,_,_,_,B5)), length(B5, X5) ), X5, G5),
    check('and no body means no body', G5, '0'),
    written(( request_of('POST / HTTP/1.1\r\nContent-Length: 2\r\n\r\nhiEXTRA', request(_,_,_,_,_,B6)), atom_codes(X6, B6) ), X6, G6),
    check('bytes past the length are not it', G6, hi),
    written(http_form("a=1&b=two+words", X7), X7, G7),
    check('a form body decodes like a query', G7, '[a-1,b-two words]').

every_byte :-
    section('every byte survives, which is why bodies are codes'),
    written(( atom_codes('POST / HTTP/1.1\r\nContent-Length: 5\r\n\r\nab', H1),
              append(H1, [0, 99, 100], Cs1), http_request(Cs1, request(_,_,_,_,_,B1)),
              length(B1, X1) ), X1, G1),
    check('a NUL in the body does not end it', G1, '5'),
    written(( atom_codes('POST / HTTP/1.1\r\nContent-Length: 5\r\n\r\nab', H2),
              append(H2, [0, 99, 100], Cs2), http_request(Cs2, request(_,_,_,_,_,B2)),
              nth0(3, B2, X2) ), X2, G2),
    check('and the byte after the NUL is kept', G2, '99').

refusals :-
    section('what it refuses, which is the half that decides safety'),
    parses('GET / HTTP/1.1\r\nX: a\r\n  b\r\n\r\n', G1),
    check('obs-fold is refused', G1, refused),
    parses('POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nhello\r\n0\r\n\r\n', G2),
    check('chunked framing is refused', G2, refused),
    parses('POST / HTTP/1.1\r\nContent-Length: 99\r\n\r\nhi', G3),
    check('a body short of its length is refused', G3, refused),
    parses('GET /\r\n\r\n', G4),
    check('a request line with no version', G4, refused),
    parses('GET HTTP/1.1\r\n\r\n', G5),
    check('a request line with no target', G5, refused),
    parses('GET / HTTP/1.1\r\nHost: x\r\n', G6),
    check('headers that never end', G6, refused),
    parses('', G7),
    check('an empty request', G7, refused),
    parses('GET / HTTP/1.1\nHost: x\n\n', G8),
    check('a bare LF is ACCEPTED, by the spec', G8, parsed).

decoding :-
    section('the decoding, held to RFC 3986 rather than to itself'),
    %% THE EXPECTED VALUES ARE WRITTEN OUT, not computed by a second decoder.
    %% They used to come from Python's urllib.parse.unquote, which made this a
    %% differential test -- strong while it lasted, and impossible to keep once
    %% the Python went. What replaces it is not a cocolog decoder (that would
    %% compare cocolog against itself and pass for any pair of consistent
    %% bugs) but the ANSWERS, which are facts about RFC 3986 and not about any
    %% implementation.
    forall(member(Raw-Want, ['a%20b'-'a b', '%2Fslash'-'/slash', 'plus+kept'-'plus+kept',
                             '%41%42%43'-'ABC', 'caf%C3%A9'-'café', '100%25'-'100%', 'a%2Bb'-'a+b']),
           ( written(( atom_codes(Raw, Cs), http_percent_decode(Cs, D), atom_codes(X, D) ), X, G),
             atom_concat('percent-decode ', Raw, Label),
             check(Label, G, Want) )),
    %% ONE KEY AT A TIME, because comparing the printed list compares cocolog's
    %% WRITER as well as its parser: `e-@home' is written `e- @home', with a
    %% space, so that reading it back cannot mistake `-@' for one operator. The
    %% writer is right and the comparison was wrong.
    forall(member(Qs-Key-Want, ['a=1&b=2'-b-'2', 'x=hi+there'-x-'hi there', 'e=%40home'-e-'@home',
                                'k=a%26b'-k-'a&b', 'u=caf%C3%A9'-u-'café']),
           ( written(( atom_codes(Qs, QCs), http_query(QCs, Q), memberchk(Key-X, Q) ), X, G),
             atomic_list_concat(['query ', Qs, ' -> ', Key], Label),
             check(Label, G, Want) )).

responses :-
    section('building a response'),
    written(( http_response(200, [], hello, Cs1), atom_codes(A1, Cs1), sub_atom(A1, 0, 15, _, X1) ), X1, G1),
    check('the status line and a computed length', G1, 'HTTP/1.1 200 OK'),
    written(( http_response(200, ['Content-Length'-999], hello, Cs2), atom_codes(A2, Cs2),
              ( sub_atom(A2, _, _, _, 'Content-Length: 5') -> X2 = computed ; X2 = trusted ) ), X2, G2),
    check('Content-Length is computed, not taken', G2, computed),
    written(( http_response(499, [], '', Cs3), atom_codes(A3, Cs3), sub_atom(A3, 9, 11, _, X3) ), X3, G3),
    check('an unknown status still goes out', G3, '499 Unknown'),
    written(( http_response(200, [], [104,105], Cs4), atom_codes(A4, Cs4),
              ( sub_atom(A4, _, _, 0, hi) -> X4 = ends_with_body ; X4 = mangled ) ), X4, G4),
    check('and a body of codes is written as bytes', G4, ends_with_body).

against_curl :-
    section('and the whole thing against curl, which nobody here wrote'),
    (   sh_exit('command -v curl >/dev/null 2>&1', 0)
    ->  scratch(D),
        atom_concat(D, '/server.pl', Server),
        fixture(Server,
                [ ':- use_module(library(tcp)).',
                  ':- use_module(library(http)).',
                  '',
                  'serve(Port) :-',
                  '    tcp_listen(Port, S),',
                  '    tcp_accept(S, 10000, C, _),',
                  '    tcp_read(C, 65536, 5000, Codes),',
                  '    ( http_request(Codes, R) -> answer(C, R) ; refuse(C) ),',
                  '    tcp_close(S).',
                  '',
                  'answer(C, request(Method, Path, Query, _, _, Body)) :-',
                  '    length(Body, N),',
                  '    ( memberchk(name-Who, Query) -> true ; Who = nobody ),',
                  '    atomic_list_concat([Method, '' '', Path, '' '', Who, '' '', N], Text),',
                  '    http_response(200, [''Content-Type''-''text/plain''], Text, Out),',
                  '    tcp_write(C, Out),',
                  '    tcp_close(C).',
                  '',
                  'refuse(C) :-',
                  '    http_response(400, [], ''no'', Out),',
                  '    tcp_write(C, Out),',
                  '    tcp_close(C).' ]),
        served(Server, 18830, 'curl -s --max-time 8 ''http://127.0.0.1:18830/hello%20world?name=ada''', G1),
        check('curl gets what the grammar parsed', G1, 'get /hello world ada 0'),
        served(Server, 18831, 'curl -s --max-time 8 -X POST --data-binary ''twelve bytes'' ''http://127.0.0.1:18831/p''', G2),
        check('a POST body arrives with its length', G2, 'post /p nobody 12'),
        served(Server, 18832, 'curl -s -o /dev/null -w ''%{http_code}'' --max-time 8 ''http://127.0.0.1:18832/''', G3),
        check('and curl reads the status line', G3, '200'),
        shl(['rm -rf ', D])
    ;   format("     (skipped: no curl to drive it with)~n", [])
    ).

%% raise the one-shot server on Port, wait for the port, run the client
%% command, reap the server
served(Server, Port, Client, Got) :-
    cocolog(C),
    sh_join(['timeout 25 ', C, ' run ', Server, ' "serve(', Port, ')" >/dev/null 2>&1'], Cmd),
    proc_spawn(Cmd, Pid),
    sh_join(['lsof -iTCP:', Port, ' -sTCP:LISTEN >/dev/null 2>&1'], Listening),
    ( proc_until(sh_exit(Listening, 0), 5000, 100) -> true ; true ),
    shl_atom([Client, ' 2>/dev/null'], Got),
    ( proc_wait(Pid, 10000, _) -> true ; proc_stop(Pid) ).
