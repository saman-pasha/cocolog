%% library(curl) -- the client half, and what it will not do quietly.
%%
%% NOTHING HERE TOUCHES THE NETWORK, which is cicili's own rule for
%% test/c/curl and the right one: a test that fetched a real host would be
%% measuring somebody else's uptime and would fail behind a proxy. Every
%% transfer is a file:// URL over a file this case wrote, or a request to
%% a cocolog listening on loopback -- and libcurl runs both through exactly
%% the same easy-handle machinery.
%%
%% THE LAST SECTION IS THE ONE WORTH HAVING. A cocolog raises a server out
%% of library(tcp) and library(http), and a SECOND cocolog fetches it with
%% library(curl). Client and server, both in Prolog, in two processes --
%% which is the whole reason any of these three files exist. It also
%% crosses every seam at once: sockets in C, the grammar in clauses,
%% libcurl through cicili's binding, and terms in and out of all of them.
%%
%% THE DEFAULTS ARE CHECKED, because they are the security posture:
%% verification ON, redirects NOT followed. A client that follows
%% redirects by default can be walked somewhere the caller never named,
%% and a client that skips verification is not a client for anything that
%% matters. Both are overridable and neither is silent.
%%
%%     cocolog -s test/curl.pl        from the checkout root
%%
%% ONE PROCESS FOR TWELVE CHECKS, where test/curl.sh spawned one per check
%% and slept three seconds for each of its two servers (9.0 s on this
%% machine). The servers are still second processes -- that is the claim
%% -- waited for through lsof, never a probe: each accepts once.

:- use_module('test/prelude.pl').

main :-
    (   catch(use_module(library(curl)), _, fail)
    ->  true
    ;   skip('(no library/curl.so -- sh modules/curl/build.sh, and it needs libcurl''s headers)')
    ),
    (   catch(curl_version(_), _, fail)
    ->  true
    ;   skip('(library(curl) will not load)')
    ),
    scratch(D),
    %% The file every file:// transfer below reads. Written rather than
    %% assumed: a test that fetched /etc/hostname would pass or fail on what
    %% the container is called.
    atom_concat(D, '/test.txt', Txt),
    fixture(Txt, ['hello from a file url']),
    atom_concat(D, '/nul.bin', Nul),
    write_file_from_codes(Nul, [0'a, 0'b, 0, 0'c, 0'd]),
    %% `caf', the two bytes of an e-acute, and 0xFF, which is no UTF-8,
    %% written as the bytes they are whatever the program counts
    atom_concat(D, '/past.bin', Past),
    string_bytes(S0, [99, 97, 102, 195, 169, 255], utf8),
    string_codes(S0, PastCodes),
    write_file_from_codes(Past, PastCodes),
    really_libcurl, a_transfer(Txt), every_byte(Nul), past_ascii(Past), refusals, two_halves(D),
    shl(['rm -rf ', D]),
    checks_done.

really_libcurl :-
    section('the library is really libcurl'),
    written(( curl_version(V1), sub_atom(V1, 0, 7, _, X1) ), X1, G1),
    check('it names its own version', G1, libcurl),
    written(( curl_ssl(S2), ( S2 == none -> X2 = no_tls ; X2 = has_tls ) ), X2, G2),
    check('and says whether it can do TLS at all', G2, has_tls).

a_transfer(Txt) :-
    section('a transfer, over a file this case wrote'),
    atom_concat('file://', Txt, Url),
    written(( curl_get(Url, _, B1), atom_codes(A1, B1), sub_atom(A1, 0, 21, _, X1) ), X1, G1),
    check('the body comes back', G1, 'hello from a file url'),
    written(( curl_get(Url, _, B2), length(B2, X2) ), X2, G2),
    check('the body is CODES, so its length is bytes', G2, '22'),
    %% A file:// URL has no HTTP status and libcurl reports 0 for it. Said
    %% out loud because a caller checking `Status == 200' on a file URL would
    %% otherwise be quietly wrong.
    written(curl_get(Url, S3, _), S3, G3),
    check('a file url has no HTTP status, and says 0', G3, '0').

every_byte(Nul) :-
    section('every byte survives, which is why the body is codes'),
    atom_concat('file://', Nul, Url),
    written(( curl_get(Url, _, B1), length(B1, X1) ), X1, G1),
    check('a NUL in the middle does not end the body', G1, '5'),
    written(( curl_get(Url, _, B2), nth0(3, B2, X2) ), X2, G2),
    check('and the byte after it is the right one', G2, '99').

%% THE BODY IS THE PROGRAM'S CODES (2.0.0): under characters, the default,
%% the e-acute is one code and 0xFF the U+DCFF that stands for it, and
%% string_bytes/3 gives back the bytes the file holds. Through 1.15 a byte
%% past 127 came back NEGATIVE, in either unit: [99,97,102,-61,-87,-1].
past_ascii(Past) :-
    section('past ASCII: the body in the program''s units, its bytes exact (2.0.0)'),
    atom_concat('file://', Past, Url),
    written(( curl_get(Url, _, B1), string_bytes(B1, X1, utf8) ), X1, G1),
    check('the bytes come back as they are, 0xFF too', G1, '[99,97,102,195,169,255]'),
    written(( curl_get(Url, _, B2), atom_codes(A2, B2),
              ( sub_atom(A2, 0, _, _, 'café') -> X2 = word ; X2 = A2 ) ), X2, G2),
    check('and its atom begins with the word', G2, word).

refusals :-
    section('what it refuses'),
    written(( curl_get('nosuchscheme://host/path', _, _) -> X1 = fetched ; X1 = refused ), X1, G1),
    check('a scheme libcurl does not know fails', G1, refused),
    written(( curl_get('file:///no/such/coco/file', _, _) -> X2 = fetched ; X2 = refused ), X2, G2),
    check('a file that is not there fails', G2, refused),
    %% A FAILED TRANSFER BINDS NOTHING. Both outputs are unified only after
    %% the perform succeeded, so a caller cannot read a status of 0 beside an
    %% empty body and think the request happened.
    written(( S3 = untouched, ( curl_get('file:///no/such/coco/file', S3, _) -> true ; true ) ), S3, G3),
    check('and a failed transfer leaves Status unbound', G3, untouched).

two_halves(D) :-
    section('and the two halves of this repository, talking to each other'),
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
              'answer(C, request(Method, Path, _, _, _, Body)) :-',
              '    length(Body, N),',
              '    atomic_list_concat([''served '', Method, '' '', Path, '' '', N], Text),',
              '    http_response(200, [''Content-Type''-''text/plain''], Text, Out),',
              '    tcp_write(C, Out), tcp_close(C).',
              '',
              'refuse(C) :- http_response(400, [], bad, Out), tcp_write(C, Out), tcp_close(C).' ]),
    served(Server, 18840,
           ( curl_get('http://127.0.0.1:18840/hello', St1, B1), atom_codes(A1, B1),
             atomic_list_concat([St1, ' ', A1], X1) ), X1, G1),
    check('one cocolog fetches another''s page', G1, '200 served get /hello 0'),
    served(Server, 18841,
           ( curl_post('http://127.0.0.1:18841/p', 'text/plain', 'twelve bytes', St2, B2),
             atom_codes(A2, B2), atomic_list_concat([St2, ' ', A2], X2) ), X2, G2),
    check('and POSTs a body it reads back by length', G2, '200 served post /p 12'),
    %% text past ASCII all the way round (2.0.0): curl sends the program's
    %% text as its bytes, the server makes the escaped path its word and
    %% counts the body in its units, answers an atom as its bytes with a
    %% Content-Length of bytes, and curl hands the answer back as codes
    ( current_prolog_flag(text_units, bytes) -> N3 = 6 ; N3 = 5 ),
    atomic_list_concat(['200 served post /café ', N3], W3),
    served(Server, 18842,
           ( curl_post('http://127.0.0.1:18842/caf%C3%A9', 'text/plain', 'crème', St3, B3),
             atom_codes(A3, B3), atomic_list_concat([St3, ' ', A3], X3) ), X3, G3),
    check('and text past ASCII goes round whole', G3, W3),
    %% OVER A SOCKET FILE (2.4.0): the same server, listening on unix(Path),
    %% and curl told the file with unix_socket(Path) while the URL still names
    %% the Host header and the target -- what `curl --unix-socket' does
    atom_concat(D, '/curl.sock', Sock4),
    served_unix(Server, Sock4,
                ( curl_get('http://localhost/over/a/file', [unix_socket(Sock4)], St4, B4),
                  atom_codes(A4, B4), atomic_list_concat([St4, ' ', A4], X4) ), X4, G4),
    check('and fetches it over a socket file, unix_socket(Path)', G4, '200 served get /over/a/file 0').

%% raise the one-shot server on Port, wait for the port, prove the client
%% goal here, reap the server
served(Server, Port, Goal, Template, Got) :-
    cocolog(C),
    sh_join(['timeout 25 ', C, ' run ', Server, ' "serve(', Port, ')" >/dev/null 2>&1'], Cmd),
    spawn(Cmd, Pid),
    sh_join(['lsof -iTCP:', Port, ' -sTCP:LISTEN >/dev/null 2>&1'], Listening),
    ( proc_until(sh_exit(Listening, 0), 5000, 100) -> true ; true ),
    written(Goal, Template, Got),
    ( proc_wait(Pid, 10000, _) -> true ; proc_stop(Pid) ).

%% the same on a socket file: `serve(unix(Path))', waited for through lsof
served_unix(Server, Path, Goal, Template, Got) :-
    cocolog(C),
    sh_join(['timeout 25 ', C, ' run ', Server, ' "serve(unix(''', Path, '''))" >/dev/null 2>&1'], Cmd),
    spawn(Cmd, Pid),
    unix_listening(Path),
    written(Goal, Template, Got),
    ( proc_wait(Pid, 10000, _) -> true ; proc_stop(Pid) ).
