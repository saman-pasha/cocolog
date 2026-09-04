%% library(tls): a secure connection between two cocolog PROCESSES.
%%
%% TWO PROCESSES, NOT TWO THREADS, and that is the point of the case. A
%% handshake is between two ends that do not share memory; a test that
%% proved one process could talk to itself would have proved the least
%% interesting half. So a server is raised in the background and clients
%% are run against it, exactly as a real one would be reached.
%%
%% WHAT IT ESTABLISHES, in order: that a mutually authenticated handshake
%% completes and each end can name the other; that bytes cross intact, a
%% zero byte included; that the PERMISSIONS an issuer wrote into a
%% certificate arrive with the handshake, so authorisation is a rule over
%% facts and not a second round trip; that a peer whose certificate this
%% authority did not sign is refused BEFORE any byte moves; that
%% `client_auth(none)' admits a client with no certificate at all, which
%% is the browser case; and that a handle is a slot, so an integer this
%% module did not hand out is not a connection.
%%
%%     cocolog -s test/tls.pl        from the checkout root
%%
%% SKIPS without library/tls.so or without ZiguratIP's sample authority,
%% because "no ZiguratIP built here" and "the binding is wrong" are
%% different findings.

:- use_module('test/prelude.pl').

main :-
    forall(member(M, [tls, x509]),
           ( sh_join(['library/', M, '.so'], So),
             ( exists_file(So) -> true ; sh_join(['no ', So, ' -- sh modules/', M, '/build.sh'], Why), skip(Why) ) )),
    ( getenv('ZIGURATIP', Z) -> true ; getenv('HOME', H), atom_concat(H, '/ZiguratIP', Z) ),
    atom_concat(Z, '/home/etc/cert', Cert),
    atom_concat(Cert, '/issuer.conf', Issuer),
    ( exists_file(Issuer) -> true ; sh_join(['no ', Cert, ' -- set ZIGURATIP to a built checkout'], Why2), skip(Why2) ),
    ( getenv('COCOLOG_TLS_PORT', PortA) -> atom_number(PortA, Port) ; Port = 19451 ),
    scratch(D),
    alice(D, Cert),
    server_file(D, Cert, Port, Server),
    client_file(D, Cert, Port, Client),
    cocolog(C),
    atom_concat(D, '/server.log', ServerLog),
    sh_join([C, ' run ', Server, ' main > ', ServerLog, ' 2>&1'], ServerCmd),
    spawn(ServerCmd, Srv),
    %% Wait for the port rather than sleeping a guess at it.
    sh_join(['grep -q READY ', ServerLog, ' 2>/dev/null'], Ready),
    ( proc_until(sh_exit(Ready, 0), 4000, 200) -> true ; true ),
    (   sh_exit(Ready, 0)
    ->  true
    ;   proc_stop(Srv), skip('the server did not come up')
    ),
    log(C, Client, alice, D, 'alice.log'),
    log(C, Client, mallory, D, 'mallory.log'),
    log(C, Client, alice, D, 'alice2.log'),
    log(C, Client, browser, D, 'browser.log'),
    ( proc_wait(Srv, 20000, _) -> true ; proc_stop(Srv) ),
    log(C, Client, handles, D, 'handles.log'),
    log(C, Client, quiet, D, 'quiet.log'),
    verdicts(D),
    shl(['rm -rf ', D]),
    checks_done.

%% a client goal, its transcript in a log file under D
log(C, Client, Goal, D, Name) :-
    sh_join([D, '/', Name], Log),
    sh_join([C, ' run ', Client, ' ', Goal, ' > ', Log, ' 2>&1'], Cmd),
    sh_exit(Cmd, _).

%% check LABEL EXPECTED-PATTERN FILE: the .sh's grep -q over a log
saw(Label, Pat, D, Name) :-
    sh_join([D, '/', Name], Log),
    read_file_to_codes(Log, Cs),
    (   re_match(Pat, Cs) -> check(Label, found, found)
    ;   atom_codes(Text, Cs), check(Label, Text, Pat)
    ).

alice(D, Cert) :-
    atom_concat(D, '/subject.conf', Subject),
    fixture(Subject,
            [ 'COUNTRY: IR', 'ORGANIZATION: Coco', 'ORGANIZATIONAL_UNIT: ',
              'DISTINGUISHED_NAME_QUALIFIER: ', 'STATE_OR_PROVINCE_NAME: ', 'COMMON_NAME: alice',
              'SERIAL_NUMBER: ', 'LOCALITY: ', 'TITLE: ', 'NAME: ', 'SURNAME: ', 'GIVEN_NAME: ',
              'INITIALS: ', 'PSEUDONYM: ', 'GENERATION_QUALIFIER: ', 'DOMAIN_COMPONENT: ',
              'EMAIL_ADDRESS: alice@example.org' ]),
    %% A holder the sample authority signed, carrying two permissions. This
    %% is a real RSA key pair and a real issuance -- a few seconds, and there
    %% is no cheaper way to have a certificate that is genuinely signed.
    sh_join(['query "use_module(library(x509)), x509_keygen([], ''', D, '/alice.key'', ''', D, '/alice.pub'', _), x509_csr(''', D, '/subject.conf'', ''', D, '/alice.key'', [], ''', D, '/alice.csr''), x509_issue([serial(7), permission(read), permission(''ledger.write'')], ''', Cert, '/issuer.conf'', ''', Cert, '/dont-use-private.key'', ''', D, '/alice.csr'', ''', D, '/alice.crt'')" >/dev/null 2>&1'], Issue),
    (   cocolog_run(Issue, _, 0) -> true ; skip('could not issue a test certificate') ).

server_file(D, Cert, Port, Server) :-
    atom_concat(D, '/server.pl', Server),
    sh_join(['creds([ certificate(''', Cert, '/dont-use-certificate.crt''),'], C1),
    sh_join(['        key(''', Cert, '/dont-use-private.key''),'], C2),
    sh_join(['        authority(''', Cert, '/dont-use-certificate.crt'') ]).'], C3),
    sh_join(['open_creds([ certificate(''', Cert, '/dont-use-certificate.crt''),'], O1),
    sh_join(['             key(''', Cert, '/dont-use-private.key''),'], O2),
    sh_join(['             authority(''', Cert, '/dont-use-certificate.crt''),'], O3),
    sh_join(['    tls_listen(', Port, ', S),'], Listen),
    fixture(Server,
            [ ':- use_module(library(tls)).', ':- use_module(library(ca)).', '',
              C1, C2, C3, '',
              '%% THE BROWSER PORT: no certificate demanded of the peer. Same key, same',
              '%% authority, one different option -- which is the whole difference',
              '%% between a port for machines that have been enrolled and a port for',
              '%% anybody.',
              O1, O2, O3, '             client_auth(none) ]).', '',
              'main :-', Listen,
              '    %% AND FLUSH IT. cocolog''s output is BLOCK buffered when it is a file',
              '    %% rather than a terminal, so without this the harness waits for a',
              '    %% READY that is sitting in a buffer and the whole transcript arrives',
              '    %% at exit. flush_output/0 exists because of this line.',
              '    format("READY~n"), flush_output,',
              '    rounds(S, 4),',
              '    tls_close(S).', '',
              'rounds(_, 0) :- !.',
              'rounds(S, N) :-',
              '    ( N =:= 1 -> open_creds(Cs) ; creds(Cs) ),',
              '    (   tls_accept(S, 15000, Cs, C, Peer)',
              '    ->  tls_peer_subject(C, Who),',
              '        tls_peer_permissions(C, Perms),',
              '        format("ADMIT ~w | ~w | ~q~n", [Peer, Who, Perms]), flush_output,',
              '        (   tls_read(C, 4096, 5000, In)',
              '        ->  atom_codes(A, In), format("GOT ~w~n", [A])',
              '        ;   format("GOT nothing~n") ),',
              '        %% A ZERO BYTE ON PURPOSE: an atom in cocolog is a C string and',
              '        %% stops at the first NUL, so codes are the only shape that can',
              '        %% carry one back. This is what tls_read/4 answering codes is for.',
              '        tls_write(C, [80, 79, 78, 71, 0, 33]),',
              '        tls_close(C)',
              '    ;   tls_why(W), format("REFUSE ~w~n", [W]), flush_output ),',
              '    N1 is N - 1,',
              '    rounds(S, N1).' ]).

client_file(D, Cert, Port, Client) :-
    atom_concat(D, '/client.pl', Client),
    sh_join(['alice([ certificate(''', D, '/alice.crt''), key(''', D, '/alice.key''),'], A1),
    sh_join(['        authority(''', Cert, '/dont-use-certificate.crt'') ]).'], A2),
    sh_join(['mallory([ certificate(''', Cert, '/dont-use-certificate.crt''),'], M1),
    sh_join(['          key(''', Cert, '/dont-use-private.key''),'], M2),
    sh_join(['          authority(''', D, '/alice.crt''), client_auth(none) ]).'], M3),
    sh_join(['browser([ authority(''', Cert, '/dont-use-certificate.crt''), client_auth(none) ]).'], B1),
    sh_join(['    (   tls_connect(''127.0.0.1'', ''', Port, ''', Cs, C)'], Connect),
    fixture(Client,
            [ ':- use_module(library(tls)).', '',
              '%% Enrolled: a certificate the server''s authority signed.', A1, A2, '',
              '%% An impostor: a perfectly good certificate, signed by somebody else.',
              '%% Naming alice''s own certificate as the authority is what makes the',
              '%% server''s one fail to verify -- a stranger, from either end''s view.',
              M1, M2, M3, '',
              '%% A browser: no certificate at all, and it still checks the server''s.', B1, '',
              'talk(Which) :-',
              '    ( Which == alice -> alice(Cs) ; Which == mallory -> mallory(Cs) ; browser(Cs) ),',
              Connect,
              '    ->  tls_peer_subject(C, Who), format("SERVER ~w~n", [Who]),',
              '        atom_codes(''HELLO'', H), tls_write(C, H),',
              '        (   tls_read(C, 4096, 5000, In)',
              '        ->  length(In, L), format("REPLY ~w bytes ~q~n", [L, In])',
              '        ;   format("REPLY none~n") ),',
              '        tls_close(C)',
              '    ;   tls_why(W), format("DENIED ~w~n", [W]) ).', '',
              'alice   :- talk(alice).',
              'mallory :- talk(mallory).',
              'browser :- talk(browser).', '',
              '%% A HANDLE IS A SLOT, and an integer this module did not hand out is not',
              '%% a connection. Prolog does arithmetic, so this is the difference',
              '%% between a failed call and a closed stdout.',
              'handles :-',
              '    ( tls_read(9999, 16, 100, _) -> format("BOGUS read succeeded~n") ; format("BOGUS read failed~n") ),',
              '    ( tls_write(-1, [65]) -> format("BOGUS write succeeded~n") ; format("BOGUS write failed~n") ),',
              '    ( tls_peer_subject(77, _) -> format("BOGUS subject succeeded~n") ; format("BOGUS subject failed~n") ),',
              '    tls_close(9999),',
              '    format("BOGUS close is a no-op~n").', '',
              '%% Nobody arrives: accept has to give the port back rather than hold it.',
              'quiet :-',
              '    tls_listen(19452, S),',
              '    alice(Cs),',
              '    ( tls_accept(S, 300, Cs, _, _) -> format("QUIET somebody came~n") ; format("QUIET nobody came~n") ),',
              '    tls_close(S),',
              '    tls_connections(N), format("QUIET open handles ~w~n", [N]).' ]).

verdicts(D) :-
    section('an enrolled peer gets in, and is named by the handshake'),
    saw('alice is admitted', 'ADMIT 127.0.0.1:', D, 'server.log'),
    saw('and named', 'CN=alice', D, 'server.log'),
    saw('the client names the server', 'SERVER .*CN=ZiguratIP', D, 'alice.log'),
    saw('her request arrives', 'GOT HELLO', D, 'server.log'),
    section('PERMISSIONS COME WITH THE HANDSHAKE, which is the interesting part'),
    saw('and her grants arrive with her', '\\[read,''ledger.write''\\]', D, 'server.log'),
    section('bytes cross intact, a zero byte included'),
    saw('the reply is six bytes', 'REPLY 6 bytes', D, 'alice.log'),
    saw('and carries a zero byte', '\\[80,79,78,71,0,33\\]', D, 'alice.log'),
    section('an impostor is refused AT THE HANDSHAKE, and both ends say so'),
    saw('mallory is denied', 'DENIED', D, 'mallory.log'),
    saw('and told why', 'certificate verify failed', D, 'mallory.log'),
    saw('the server refuses her', 'REFUSE', D, 'server.log'),
    %% THE SERVER CARRIED ON, which is the property that matters: one
    %% impostor knocking must not take the port down for everybody else.
    %% Checked on the CLIENT's log because a reply is what "still serving"
    %% means to a caller -- the server's own "GOT" line proves it read, not
    %% that anybody heard back.
    saw('and carries on serving', 'REPLY 6 bytes', D, 'alice2.log'),
    section('the browser case: no certificate demanded, the server''s still checked'),
    saw('a certificate-less client is admitted', 'ADMIT', D, 'server.log'),
    saw('and grants nothing', 'REPLY 6 bytes', D, 'browser.log'),
    section('a handle is a slot'),
    saw('a bogus read fails', 'BOGUS read failed', D, 'handles.log'),
    saw('a bogus write fails', 'BOGUS write failed', D, 'handles.log'),
    saw('a bogus subject fails', 'BOGUS subject failed', D, 'handles.log'),
    saw('a bogus close is a no-op', 'BOGUS close is a no-op', D, 'handles.log'),
    section('accept gives the port back'),
    saw('accept times out', 'QUIET nobody came', D, 'quiet.log'),
    saw('and closing frees the slot', 'QUIET open handles 0', D, 'quiet.log').
