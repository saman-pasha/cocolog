%% --tls: the BINARY protocol over TLS.
%%
%% WHAT ZiguratIP ACTUALLY OFFERS. `SERVER/TLS_MODE: TRUE' in
%% ziguratip.conf turns 2160 into an encrypted port -- the same port, a
%% different thing on it.
%%
%% A CLIENT CERTIFICATE IS OPTIONAL, and the SERVER says which:
%% `SERVER/TLS_CLIENT_AUTH' takes REQUIRED (the default), OPTIONAL or NONE
%% -- loadzigurat.cpp accepts all three -- so `--tls' with no `--cert' is a
%% real arrangement rather than a half-configured one, and this case
%% exercises both.
%%
%% WHAT A CERTIFICATE IS MANDATORY FOR IS PERMISSIONS. ZiguratIP identifies
%% every TLS peer, certificate or not: one with none is identified with an
%% empty subject and an empty permission set, and `Globals::permits' lets
%% everything through only for a peer that is NOT identified -- which is to
%% say a plain connection. So under `SECURITY/PERMISSIONS_MODE': plain
%% reaches everything, TLS with a certificate reaches what the certificate
%% grants, and TLS WITHOUT one reaches nothing. Turning TLS on is what
%% turns access control on. That half is ZiguratIP's own suite's to prove;
%% what is proved here is that the CLIENT can do either.
%%
%% THIS IS A REHEARSAL, AND SAYS SO. Turning TLS_MODE on means restarting
%% the suite's shared server with different credentials, which every other
%% case would then have to speak. So a TLS TERMINATOR stands in front of
%% 2160 and forwards the decrypted bytes -- exactly what test/tunnel.pl
%% does for the Cloudflare edge, and for the same reason. What it proves is
%% the CLIENT half: that the handshake happens before the greeting, that
%% the framing survives, that a reconnect comes back secure, and that the
%% hostname is checked. What it does not prove is ZiguratIP's own server
%% side, which is ZiguratIP's suite's business.
%%
%%     cocolog -s test/zigurat-tls.pl        from the checkout root
%%
%% SKIPS without a server, without openssl, or without a TLS build. Every
%% check IS a child: the client under test is the command line.

:- use_module('test/prelude.pl').

main :-
    ( sh_exit('command -v openssl >/dev/null 2>&1', 0) -> true ; skip('no openssl to make a certificate with') ),
    ( cocolog_run('--host 127.0.0.1 --tcp 2160 --timeout 5 --kb main list >/dev/null 2>&1', _, 0) -> true ; skip('no server on 2160') ),
    scratch(D),
    ( getenv('COCOLOG_ZIGTLS_PORT', PA) -> atom_number(PA, Port) ; Port = 22160 ),
    %% The second stands for `TLS_CLIENT_AUTH: REQUIRED'; the first for NONE.
    CPort is Port + 1,
    sh_join(['openssl req -x509 -newkey rsa:2048 -nodes -keyout ', D, '/s.pem -out ', D, '/s.crt -days 2 -subj ''/CN=localhost'' -addext ''subjectAltName=DNS:localhost'' >/dev/null 2>&1'], Srv),
    ( sh_exit(Srv, 0) -> true ; skip('openssl would not make a certificate') ),
    shl(['cat ', D, '/s.pem ', D, '/s.crt > ', D, '/full.pem']),
    %% THE CLIENT'S OWN, for the REQUIRED half. Self-signed and its own
    %% authority, which is all the terminator needs to be told to trust:
    %% what is under test is that cocolog PRESENTS one when asked, not who
    %% signed it. A real ZiguratIP would name a CA under SECURITY/AUTHORITY
    %% and read the subject out of the certificate to decide permissions.
    sh_join(['openssl req -x509 -newkey rsa:2048 -nodes -keyout ', D, '/c.key -out ', D, '/c.crt -days 2 -subj ''/CN=cocolog-client'' >/dev/null 2>&1'], Cli),
    ( sh_exit(Cli, 0) -> true ; skip('openssl would not make a client certificate') ),
    %% THE TERMINATOR IS test/term.pl, in cocolog: library(tls) in front,
    %% library(tcp) behind, and MODE choosing whether the authority is named
    %% -- `none' stands in for TLS_CLIENT_AUTH: NONE and `required' for the
    %% default REQUIRED, which are the two arrangements a cocolog has to speak.
    cocolog(C),
    sh_join([C, ' -s test/term.pl -- ', D, '/full.pem ', Port, ' 2160 none > ', D, '/term.out 2>&1'], T1),
    spawn(T1, P1),
    sh_join([C, ' -s test/term.pl -- ', D, '/full.pem ', CPort, ' 2160 required ', D, '/c.crt > ', D, '/cterm.out 2>&1'], T2),
    spawn(T2, P2),
    forall(member(F, ['term.out', 'cterm.out']), up(D, F, P1, P2, Port, CPort)),
    the_checks(D, Port, CPort),
    proc_stop(P1), proc_stop(P2),
    shl(['rm -rf ', D]),
    checks_done.

%% a terminator says `up' once it listens, or `CANNOT BIND'
up(D, F, P1, P2, Port, CPort) :-
    sh_join(['grep -q up ', D, '/', F, ' 2>/dev/null'], Up),
    sh_join(['grep -q "CANNOT BIND" ', D, '/', F, ' 2>/dev/null'], Cannot),
    ( proc_until(( sh_exit(Up, 0) ; sh_exit(Cannot, 0) ), 3000, 300) -> true ; true ),
    (   sh_exit(Cannot, 0)
    ->  proc_stop(P1), proc_stop(P2), sh_join(['cannot bind ', Port, '/', CPort], Why), skip(Why)
    ;   sh_exit(Up, 0)
    ->  true
    ;   proc_stop(P1), proc_stop(P2), skip('a terminator did not come up')
    ).

%% the first line of a child's output, both streams
first(Args, Line) :-
    sh_join([Args, ' 2>&1 | head -1'], A), cocolog_run(A, Line, _).

the_checks(D, Port, CPort) :-
    sh_join(['--host localhost --tls ', Port, ' --cacert ', D, '/s.crt'], Secure),
    section('the handshake happens BEFORE the greeting, and the framing survives'),
    sh_join([Secure, ' --kb main --timeout 20 list'], A1), first(A1, G1),
    check('a command over TLS', G1, '  no suspended machines in ''main'''),
    sh_join([Secure, ' --kb main --timeout 20 query ''true'''], A2), first(A2, G2),
    check('and a query', G2, '  1. true'),
    section('assert and read back in a SECOND process, over an encrypted connection'),
    sh_join([Secure, ' --kb tls_test --timeout 20 query ''assertz(secure_fact(carried))'' >/dev/null 2>&1'], A3), cocolog_run(A3, _, _),
    sh_join([Secure, ' --kb tls_test --timeout 20 query ''secure_fact(X)'''], A4), first(A4, G4),
    check('a clause written and read by two processes', G4, '  1. secure_fact(carried)'),
    section('THE HOSTNAME IS CHECKED'),
    %% The same terminator by address: the chain still verifies -- --cacert
    %% names the very certificate -- and the NAME does not.
    sh_join(['--host 127.0.0.1 --tls ', Port, ' --cacert ', D, '/s.crt --kb main --timeout 20 list'], A5), first(A5, G5),
    sh_join(['cocolog: no server at 127.0.0.1:', Port, ' -- the server''s certificate was refused: hostname mismatch'], W5),
    check('a name the certificate does not carry is refused', G5, W5),
    sh_join(['--host 127.0.0.1 --tls ', Port, ' --insecure --kb main --timeout 20 list 2>/dev/null | head -1'], A6), cocolog_run(A6, G6, _),
    check('--insecure reaches it anyway', G6, '  no suspended machines in ''main'''),
    %% AND PLAIN --tcp AGAINST THE TLS PORT FAILS, rather than sending the
    %% protocol in the clear at something expecting a ClientHello.
    sh_join(['--host localhost --tcp ', Port, ' --kb main --timeout 5 list 2>&1 | grep -c ''cocolog:'''], A7), cocolog_run(A7, G7, _),
    check('plaintext against a TLS port does not go through', G7, '1'),
    section('TLS with and without a client certificate'),
    %% Every check above went through the NONE terminator with no --cert at
    %% all, so cert-less TLS is already proved; these three are about the
    %% other setting, and about the failure being legible when the two
    %% disagree. A certificate is ACCEPTED where none is demanded -- the
    %% OPTIONAL case, where a peer that has one presents it and the server
    %% may or may not care...
    sh_join([Secure, ' --cert ', D, '/c.crt --key ', D, '/c.key --kb main --timeout 20 list'], A8), first(A8, G8),
    check('a certificate offered where none is required', G8, '  no suspended machines in ''main'''),
    %% ...and it is what gets through where one IS demanded
    sh_join(['--host localhost --tls ', CPort, ' --cacert ', D, '/s.crt --cert ', D, '/c.crt --key ', D, '/c.key --kb main --timeout 20 list'], A9), first(A9, G9),
    check('a certificate where one is required', G9, '  no suspended machines in ''main'''),
    %% WITHOUT ONE, AGAINST A SERVER THAT WANTS ONE, THE REFUSAL IS LEGIBLE.
    %% Under TLS 1.3 this is not a failed handshake: the client is finished
    %% talking before the server looks at what it sent, so `SSL_connect'
    %% SUCCEEDS and the refusal comes back as an ALERT on the first read.
    %% Without client/tls.c's `coco_client_tls_why' the reader gets
    %% `read failed: Success' and goes looking at the wrong end.
    sh_join(['--host localhost --tls ', CPort, ' --cacert ', D, '/s.crt --kb main --timeout 20 list'], A10), first(A10, G10),
    sh_join(['cocolog: no server at localhost:', CPort, ' -- read failed: tlsv13 alert certificate required -- this server wants a client certificate: --cert and --key'], W10),
    check('no certificate where one is required, said plainly', G10, W10),
    section('half a certificate is a mistake, and named as one before any socket'),
    sh_join(['--host localhost --tls ', CPort, ' --cert ', D, '/c.crt --kb main list'], A11), first(A11, G11),
    check('--cert without --key is refused', G11, 'cocolog: --cert and --key go together'),
    section('and the two arrangements are not confusable'),
    first('--tls --https --kb main list', G12),
    check('--tls and --https together are refused', G12, 'cocolog: --tls names the binary protocol and --http/--https names Zeytun; choose one').
