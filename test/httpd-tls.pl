%% HTTPS: library(httpd) over library(tls), and the identity that comes
%% with the handshake.
%%
%% ONLY THE TRANSPORT CHANGED, which is what this case is really checking.
%% A connection became a tagged term -- plain(S) or secure(S) -- and five
%% predicates dispatch on the tag; routing, keep-alive, the path rules and
%% httpd_answer/3 are the same code on both. test/httpd.pl proves the
%% plaintext half still passes; this one proves the secure half works and
%% that the two cannot be confused.
%%
%% THE INTERESTING CHECK IS THE INJECTION ONE. A page reads the peer's
%% identity out of two synthetic headers, and a client may send any header
%% it likes -- so a server that merely ADDED its own would leave two, with
%% the client's first, which is the one http_header/3 finds. That is the
%% standard reverse-proxy hole. Here a client claims to be CN=root with
%% `admin', and the page must see alice.
%%
%%     cocolog -s test/httpd-tls.pl        from the checkout root
%%
%% SKIPS without library/tls.so or ZiguratIP's sample authority. The two
%% servers and every client are children: a handshake is between two ends
%% that do not share memory.

:- use_module('test/prelude.pl').

main :-
    forall(member(M, [tls, x509, thread, tcp]),
           ( sh_join(['library/', M, '.so'], So),
             ( exists_file(So) -> true ; sh_join(['no ', So, ' -- sh modules/', M, '/build.sh'], Why), skip(Why) ) )),
    ( getenv('ZIGURATIP', Z) -> true ; getenv('HOME', H), atom_concat(H, '/ZiguratIP', Z) ),
    atom_concat(Z, '/home/etc/cert', Cert),
    atom_concat(Cert, '/issuer.conf', Issuer),
    ( exists_file(Issuer) -> true ; sh_join(['no ', Cert, ' -- set ZIGURATIP to a built checkout'], Why2), skip(Why2) ),
    ( getenv('COCOLOG_HTTPS_PORT', PA) -> atom_number(PA, Port) ; Port = 19470 ),
    Plain is Port + 1,
    scratch(D),
    alice(D, Cert),
    pages_file(D, Pages),
    server_file(D, Cert, Port, Pages, Server),
    plain_file(D, Plain, Pages, PlainSrv),
    client_file(D, Cert, Port, Plain, Client),
    cocolog(C),
    sh_join([C, ' run ', Server, ' main > ', D, '/server.log 2>&1'], SCmd), spawn(SCmd, Srv),
    sh_join([C, ' run ', PlainSrv, ' main > ', D, '/plain.log 2>&1'], PCmd), spawn(PCmd, PSrv),
    sh_join(['grep -q READY ', D, '/server.log 2>/dev/null && grep -q READY ', D, '/plain.log 2>/dev/null'], Ready),
    ( proc_until(sh_exit(Ready, 0), 4000, 200) -> true ; true ),
    sh_join(['grep -q READY ', D, '/server.log 2>/dev/null'], SReady),
    (   sh_exit(SReady, 0)
    ->  true
    ;   proc_stop(Srv), proc_stop(PSrv), skip('the https server did not come up')
    ),
    forall(member(G, [hello, whoami, ledger, inject, nocert, plainwho, plaininject, plainledger]),
           ( sh_join([C, ' run ', Client, ' ', G, ' > ', D, '/', G, '.log 2>&1'], Cmd), sh_exit(Cmd, _) )),
    proc_stop(Srv), proc_stop(PSrv),
    verdicts(D),
    shl(['rm -rf ', D]),
    checks_done.

alice(D, Cert) :-
    atom_concat(D, '/subject.conf', Subject),
    fixture(Subject,
            [ 'COUNTRY: IR', 'ORGANIZATION: Coco', 'ORGANIZATIONAL_UNIT: ',
              'DISTINGUISHED_NAME_QUALIFIER: ', 'STATE_OR_PROVINCE_NAME: ', 'COMMON_NAME: alice',
              'SERIAL_NUMBER: ', 'LOCALITY: ', 'TITLE: ', 'NAME: ', 'SURNAME: ', 'GIVEN_NAME: ',
              'INITIALS: ', 'PSEUDONYM: ', 'GENERATION_QUALIFIER: ', 'DOMAIN_COMPONENT: ',
              'EMAIL_ADDRESS: alice@example.org' ]),
    sh_join(['query "use_module(library(x509)), x509_keygen([], ''', D, '/alice.key'', ''', D, '/alice.pub'', _), x509_csr(''', D, '/subject.conf'', ''', D, '/alice.key'', [], ''', D, '/alice.csr''), x509_issue([serial(9), permission(read), permission(''ledger.write'')], ''', Cert, '/issuer.conf'', ''', Cert, '/dont-use-private.key'', ''', D, '/alice.csr'', ''', D, '/alice.crt'')" >/dev/null 2>&1'], Issue),
    (   cocolog_run(Issue, _, 0) -> true ; skip('could not issue a test certificate') ).

%% THE PAGES ARE A MODULE, not a consulted file -- the one thing a worker
%% pool asks of the program above it. A worker's store is filled from the
%% process-wide module registry, so a page that was consulted is a 404
%% with nothing in the log.
pages_file(D, Pages) :-
    atom_concat(D, '/pages.pl', Pages),
    fixture(Pages,
            [ ':- module(pages, []).',
              ':- use_module(library(ca)).', '',
              'httpd_page(''/hello'', _, reply(200, [], ''hello over TLS'')).', '',
              '%% WHO IS ON THE CONNECTION, read like any other header -- which is the',
              '%% point of doing it as headers: a page needs no new predicate and no',
              '%% access to the socket.',
              'httpd_page(''/whoami'', Request, reply(200, [], Body)) :-',
              '    (   http_header(Request, ''Tls-Peer-Subject'', S) -> true ; S = nobody ),',
              '    (   http_header(Request, ''Tls-Peer-Permissions'', P) -> true ; P = '''' ),',
              '    atomic_list_concat([''subject='', S, '' granted='', P], Body).', '',
              '%% AND AUTHORISATION IS A RULE over what the handshake settled.',
              'httpd_page(''/ledger'', Request, reply(Status, [], Body)) :-',
              '    (   http_header(Request, ''Tls-Peer-Permissions'', G),',
              '        atomic_list_concat(Gs, '','', G),',
              '        member(One, Gs),',
              '        ca_covers(One, ''ledger.write'')',
              '    ->  Status = 200, Body = ''write applied''',
              '    ;   Status = 403, Body = ''refused''',
              '    ).' ]).

server_file(D, Cert, Port, Pages, Server) :-
    atom_concat(D, '/server.pl', Server),
    sh_join(['    use_module(''', Pages, '''),'], Use),
    sh_join(['    httpd_serve(', Port, ','], Serve),
    sh_join(['      [ tls([ certificate(''', Cert, '/dont-use-certificate.crt''),'], T1),
    sh_join(['              key(''', Cert, '/dont-use-private.key''),'], T2),
    sh_join(['              authority(''', Cert, '/dont-use-certificate.crt'') ]),'], T3),
    fixture(Server,
            [ ':- use_module(library(httpd)).',
              'main :-', Use,
              '    format("READY~n"), flush_output,',
              Serve, T1, T2, T3,
              '        workers(2), accept_timeout(20000) ], 12).' ]).

plain_file(D, Plain, Pages, PlainSrv) :-
    atom_concat(D, '/plain.pl', PlainSrv),
    sh_join(['    use_module(''', Pages, '''),'], Use),
    sh_join(['    httpd_serve(', Plain, ', [ workers(0), accept_timeout(20000) ], 3).'], Serve),
    fixture(PlainSrv,
            [ ':- use_module(library(httpd)).',
              'main :-', Use,
              '    format("READY~n"), flush_output,',
              Serve ]).

client_file(D, Cert, Port, Plain, Client) :-
    atom_concat(D, '/client.pl', Client),
    sh_join(['alice([ certificate(''', D, '/alice.crt''), key(''', D, '/alice.key''),'], A1),
    sh_join(['        authority(''', Cert, '/dont-use-certificate.crt'') ]).'], A2),
    sh_join(['anon([ authority(''', Cert, '/dont-use-certificate.crt''), client_auth(none) ]).'], An),
    sh_join(['    (   tls_connect(''127.0.0.1'', ''', Port, ''', Cs, C)'], SecureConnect),
    sh_join(['    (   tcp_connect(''127.0.0.1'', ', Plain, ', C)'], PlainConnect),
    fixture(Client,
            [ ':- use_module(library(tls)).', ':- use_module(library(tcp)).', '',
              A1, A2, An, '',
              'get(Conn, Path, Extra) :-',
              '    atomic_list_concat([''GET '', Path, '' HTTP/1.1\\r\\nHost: z\\r\\n'', Extra,',
              '                        ''Connection: close\\r\\n\\r\\n''], Text),',
              '    atom_codes(Text, Req),',
              '    tls_write(Conn, Req),',
              '    drain(Conn, [], Codes),',
              '    atom_codes(A, Codes),',
              '    format("~w~n", [A]).', '',
              'drain(Conn, Acc, Out) :-',
              '    (   tls_read(Conn, 65536, 3000, Chunk)',
              '    ->  append(Acc, Chunk, All), drain(Conn, All, Out)',
              '    ;   Out = Acc ).', '',
              'secure(Path, Extra) :-',
              '    alice(Cs),',
              SecureConnect,
              '    ->  get(C, Path, Extra), tls_close(C)',
              '    ;   tls_why(W), format("DENIED ~w~n", [W]) ).', '',
              'hello  :- secure(''/hello'', '''').',
              'whoami :- secure(''/whoami'', '''').',
              'ledger :- secure(''/ledger'', '''').', '',
              '%% A CLIENT CLAIMING TO BE SOMEBODY ELSE. Both headers, both spellings a',
              '%% client would reach for.',
              'inject :- secure(''/whoami'',',
              '   ''Tls-Peer-Subject: CN=root\\r\\nTls-Peer-Permissions: ledger.write,admin\\r\\n'').', '',
              '%% No certificate, against a server that demands one.',
              '%%',
              '%% AND THE CHECK IS THAT IT GETS NOTHING, not that connect failed. Under',
              '%% TLS 1.3 a client''s certificate is not examined until after it has sent',
              '%% its Finished and considers the handshake done -- so a stranger gets',
              '%% SUCCESS out of tls_connect/4 and hears the refusal afterwards, as an',
              '%% alert on a connection it believes it already has. What is true either',
              '%% way is that no page is served, which is the property worth asserting.',
              'nocert :-',
              '    anon(Cs),',
              SecureConnect,
              '    ->  (   catch(get(C, ''/hello'', ''''), _, format("NO REPLY~n"))',
              '        ->  true',
              '        ;   format("NO REPLY~n") ),',
              '        tls_close(C)',
              '    ;   tls_why(W), format("DENIED ~w~n", [W]) ).', '',
              '%% PLAINTEXT: the headers must be stripped and NOT replaced, so a page',
              '%% that trusts them cannot be fooled by moving it to port 80.',
              'plain(Path, Extra) :-',
              PlainConnect,
              '    ->  atomic_list_concat([''GET '', Path, '' HTTP/1.1\\r\\nHost: z\\r\\n'', Extra,',
              '                            ''Connection: close\\r\\n\\r\\n''], Text),',
              '        atom_codes(Text, Req), tcp_write(C, Req),',
              '        pdrain(C, [], Codes), atom_codes(A, Codes), format("~w~n", [A]), tcp_close(C)',
              '    ;   format("NO PLAIN SERVER~n") ).', '',
              'pdrain(C, Acc, Out) :-',
              '    (   tcp_read(C, 65536, 3000, Chunk)',
              '    ->  append(Acc, Chunk, All), pdrain(C, All, Out)',
              '    ;   Out = Acc ).', '',
              'plainwho :- plain(''/whoami'', '''').',
              'plaininject :- plain(''/whoami'',',
              '   ''Tls-Peer-Subject: CN=root\\r\\nTls-Peer-Permissions: admin\\r\\n'').',
              'plainledger :- plain(''/ledger'', ''Tls-Peer-Permissions: ledger.write\\r\\n'').' ]).

%% the .sh's check and deny: a fixed string present, or absent, in a log
saw(Label, Needle, D, Name) :-
    sh_join([D, '/', Name], Log), read_file_to_codes(Log, Cs), atom_codes(Text, Cs),
    ( sub_atom(Text, _, _, _, Needle) -> check(Label, found, found) ; check(Label, Text, Needle) ).
deny(Label, Needle, D, Name) :-
    sh_join([D, '/', Name], Log), read_file_to_codes(Log, Cs), atom_codes(Text, Cs),
    ( sub_atom(Text, _, _, _, Needle) -> check(Label, Text, absent(Needle)) ; check(Label, absent, absent) ).

verdicts(D) :-
    section('the server serves, over TLS, with everything above it unchanged'),
    saw('a page is served over TLS', '200 OK', D, 'hello.log'),
    saw('and its body arrives', 'hello over TLS', D, 'hello.log'),
    section('THE HANDSHAKE''S IDENTITY REACHES THE PAGE'),
    saw('the subject is a header', 'subject=C=IR, O=Coco, CN=alice', D, 'whoami.log'),
    saw('and so are the permissions', 'granted=read,ledger.write', D, 'whoami.log'),
    section('and authorisation is a rule over it'),
    saw('a granted write is applied', 'write applied', D, 'ledger.log'),
    section('THE INJECTION, which is the check this file exists for'),
    saw('an injecting client still sees itself', 'subject=C=IR, O=Coco, CN=alice', D, 'inject.log'),
    deny('and cannot become CN=root', 'CN=root', D, 'inject.log'),
    deny('nor grant itself admin', admin, D, 'inject.log'),
    section('client_auth(required) is the default'),
    %% A CERTIFICATE-LESS CLIENT GETS NO PAGE, which is the honest form of
    %% the check. Under TLS 1.3 the refusal arrives after the client thinks
    %% the handshake finished, so `tls_connect/4' succeeding proves nothing
    %% -- see the note by `nocert' in the client.
    deny('a client with no certificate is served nothing', '200 OK', D, 'nocert.log'),
    section('PLAINTEXT STRIPS AND DOES NOT REPLACE'),
    saw('the plain server answers', '200 OK', D, 'plainwho.log'),
    saw('with nobody on the connection', 'subject=nobody granted=', D, 'plainwho.log'),
    deny('and an injected subject is gone', 'CN=root', D, 'plaininject.log'),
    saw('a page requiring a grant refuses on port 80', '403', D, 'plainledger.log').
