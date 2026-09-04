%% The Zeytun read path through a hostname-routing edge -- the local
%% rehearsal of a Cloudflare tunnel in front of a Colab VM (colab/COLAB.md).
%%
%% WHAT IT IS CHECKING, and why:
%%
%%   AN EDGE ROUTES BY THE HOST HEADER, and a quick tunnel's hostname is
%%   registered bare -- no port. So the client must send `Host: name' on
%%   the default port and `Host: name:port' elsewhere, and the whole
%%   knowledge-base read path -- warm, then a page per predicate -- must
%%   survive a proxy hop that admits only the exact registered name and
%%   forwards verbatim, which is what the test/edge.pl stand-in does and
%%   what the Cloudflare edge + cloudflared pair do for real.
%%
%% The wire half of the story (the trainer writing) is zigurat.cicili's and
%% repl.pl's business; this case is the reader behind the proxy. SKIPs
%% without a server, and the port-80 check is skipped when 80 cannot be
%% bound.
%%
%%     cocolog -s test/tunnel.pl        from the checkout root
%%
%% Every edge and every reader IS a child: a proxy hop is between processes.

:- use_module('test/prelude.pl').

main :-
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    ( getenv('ZEYTUN_PORT', Zeytun) -> true ; Zeytun = 2190 ),
    sh_join(['--kb tunnel_test --host ', Host, ' --tcp ', Port, ' --timeout 10'], W),
    sh_join([W, ' list >/dev/null 2>&1'], Probe),
    (   cocolog_run(Probe, _, 0, 20000)
    ->  true
    ;   sh_join(['no Zigurat server at ', Host, ':', Port], Why), skip(Why)
    ),
    scratch(D),
    %% the fact the reader will be asked for, in over the wire
    sh_join([W, ' query ''assertz(edge_fact(routed))'' >/dev/null 2>&1'], Seed), cocolog_run(Seed, _, _),
    high_port(D, Zeytun), https(D, Zeytun), port_80(D, Zeytun),
    sh_join([W, ' forget >/dev/null 2>&1'], Forget), cocolog_run(Forget, _, _),
    shl(['rm -rf ', D]),
    checks_done.

%% THE EDGE IS WAITED FOR, NOT SLEPT AT. It prints `edge up' once it is
%% listening, and a fixed second was not enough on a Mac whose python3 was
%% a pyenv shim that took two to four seconds to start: the query then met
%% nothing on the port, `Connection refused' read as a routing failure, and
%% the kill at the end of the check reached the edge before it had printed
%% a line -- nine reds, every one of them the same second. Fifteen seconds
%% is the ceiling; the usual wait is well under one. `CANNOT BIND' is the
%% other thing an edge says, on a privileged port it may not have -- waited
%% for too, so a skip below is decided on what the edge said and not on
%% what it had not yet said.
%%
%% The edge stand-in is test/edge.pl, in cocolog: it admits only requests
%% whose Host header is exactly PUBLIC -- the way the Cloudflare edge routes
%% a quick tunnel by its registered hostname -- and forwards verbatim to
%% Zeytun, which is what cloudflared does at the far end. Every Host seen
%% is logged. Naming a .pem turns it into a TLS terminator, which is what
%% the real edge is.
edge(D, EdgePort, Public, Zeytun, HostsLog, Pem, Name, Pid, Said) :-
    cocolog(C),
    sh_join([D, '/', Name, '.out'], Out),
    sh_join([C, ' -s test/edge.pl -- ', EdgePort, ' "', Public, '" ', Zeytun, ' ', D, '/', HostsLog, ' ', Pem, ' > ', Out, ' 2>&1'], Cmd),
    spawn(Cmd, Pid),
    sh_join(['grep -qE ''edge up|CANNOT BIND'' ', Out, ' 2>/dev/null'], Ready),
    ( proc_until(sh_exit(Ready, 0), 15000, 100) -> true ; true ),
    sh_join(['grep -q "CANNOT BIND" ', Out, ' 2>/dev/null'], Cannot),
    ( sh_exit(Cannot, 0) -> Said = cannot_bind ; Said = up ).

%% the first line of a child cocolog's stdout, stderr dropped
first_out(Args, Line) :- sh_join([Args, ' 2>/dev/null | head -1'], A), cocolog_run(A, Line, _).
%% the first line of its stderr, stdout dropped
first_err(Args, Line) :- sh_join([Args, ' 2>&1 >/dev/null | head -1'], A), cocolog_run(A, Line, _).

%% the hosts an edge saw, `sort -u | tr '\n' ' ''
hosts_seen(D, HostsLog, Seen) :-
    sh_join([D, '/', HostsLog], Log),
    (   exists_file(Log)
    ->  read_file_to_codes(Log, Cs), codes_lines(Cs, Ls), findall(A, ( member(L, Ls), L \== [], atom_codes(A, L) ), As),
        sort(As, Us), findall(S, ( member(U, Us), atom_concat(U, ' ', S) ), Ss), atomic_list_concat(Ss, Seen)
    ;   Seen = ''
    ).

high_port(D, Zeytun) :-
    section('a high port: the Host carries the port'),
    edge(D, 18080, 'localhost:18080', Zeytun, 'hosts-high.log', '', 'edge-high', Pid, _),
    first_out('--host localhost --http 18080 --kb tunnel_test query ''edge_fact(X)''', G1),
    check('a query answers through the Host-routing edge', G1, '  1. edge_fact(routed)'),
    hosts_seen(D, 'hosts-high.log', G2),
    check('off the default port, Host names the port', G2, 'localhost:18080 '),
    proc_stop(Pid).

https(D, Zeytun) :-
    section('HTTPS: the same edge, terminating TLS'),
    %% WHAT CLOUDFLARE ACTUALLY IS. A quick tunnel is reached over TLS and
    %% nothing else -- the `https://NAME.trycloudflare.com' URL is the only
    %% one -- so a client that could only speak plaintext had to be given
    %% port 80 and hope the edge did not redirect. This is that arrangement,
    %% locally: a TLS-terminating edge that routes by Host and forwards
    %% decrypted bytes to Zeytun, and a cocolog reaching it with `--https'.
    %%
    %% THE CERTIFICATE IS MADE HERE AND TRUSTED BY NAME. `--cacert' points at
    %% the same self-signed certificate the edge presents, and `localhost' is
    %% its subject -- so the HOSTNAME check that `--https' does without being
    %% asked has something true to check. A test that reached for
    %% `--insecure' would have proved the bytes moved and nothing about the
    %% verification.
    sh_join(['openssl req -x509 -newkey rsa:2048 -nodes -keyout ', D, '/edge.pem -out ', D, '/edge.crt -days 2 -subj ''/CN=localhost'' -addext ''subjectAltName=DNS:localhost'' >/dev/null 2>&1'], Make),
    (   sh_exit(Make, 0)
    ->  shl(['cat ', D, '/edge.pem ', D, '/edge.crt > ', D, '/edge-full.pem']),
        sh_join([D, '/edge-full.pem'], Full),
        edge(D, 18443, 'localhost:18443', Zeytun, 'hosts-tls.log', Full, 'edge-tls', Pid, _),
        sh_join(['--host localhost --https 18443 --cacert ', D, '/edge.crt --kb tunnel_test query ''edge_fact(X)'''], A1),
        first_out(A1, G1),
        check('a query answers through a TLS edge', G1, '  1. edge_fact(routed)'),
        %% AND --insecure GOES THROUGH, loudly. It exists because a
        %% self-signed rehearsal is a real thing to want; what it must not be
        %% is quiet.
        first_out('--host localhost --https 18443 --insecure --kb tunnel_test query ''edge_fact(X)''', G2),
        check('--insecure reaches it anyway', G2, '  1. edge_fact(routed)'),
        first_err('--host localhost --https 18443 --insecure --kb tunnel_test query ''edge_fact(X)''', G3),
        check('and says so on stderr', G3, 'cocolog: --insecure: the server is NOT being verified'),
        %% ---- AND FROM INSIDE A PROGRAM: library(curl) reaches Zeytun over
        %% https.
        %%
        %% The `--https' checks above are the ARRANGEMENT reading its
        %% knowledge base through the edge. This is the other reader a Colab
        %% tunnel has: a cocolog PROGRAM, using library(curl), fetching a
        %% Zeytun page with an https:// URL -- which is the only kind of URL
        %% a quick tunnel has. The page is a real one
        %% (`/cocolog/predicates.zt', the same page `--http' warms from), the
        %% certificate is verified with `ca_info(...)' against the very cert
        %% the edge presents, and the hostname check has something true to
        %% check because the URL says `localhost' and so does the subject.
        %%
        %% THE DEFAULT IS ALSO HELD: without ca_info, the self-signed edge
        %% must be REFUSED, because verification defaulting to on is the
        %% client's security posture (test/curl.pl pins it for file URLs;
        %% this pins it against a live TLS listener). A curl_get that quietly
        %% trusted a self-signed edge would pass every other line in this
        %% file and be wrong.
        (   exists_file('library/curl.so'), catch(use_module(library(curl)), _, fail)
        ->  atom_concat(D, '/edge.crt', Crt),
            written(( curl_get('https://localhost:18443/cocolog/predicates.zt?kb=tunnel_test', [ca_info(Crt)], S4, B4),
                      atom_codes(A4, B4),
                      ( S4 == 200, sub_atom(A4, _, _, _, edge_fact) -> R4 = page_read ; R4 = wrong(S4) ) ), R4, G4),
            check('curl_get reads a Zeytun page through the TLS edge', G4, page_read),
            written(( curl_get('https://localhost:18443/cocolog/predicates.zt?kb=tunnel_test', S5, _) -> R5 = fetched(S5) ; R5 = refused ), R5, G5),
            check('and without ca_info the self-signed edge is refused', G5, refused)
        ;   format("     (skipped: curl -- no library/curl.so; sh modules/curl/build.sh)~n", [])
        ),
        proc_stop(Pid),
        %% THE HOSTNAME IS CHECKED, and this is how we know: a SECOND edge,
        %% on the same loopback and routing the same Host, presenting a
        %% certificate for a name nobody asked for. The chain still verifies
        %% -- it is its own authority and --cacert names it -- and the NAME
        %% does not, which is precisely the man-in-the-middle case a client
        %% that skipped this check would have missed.
        %%
        %% A SEPARATE EDGE rather than reaching the first one by address,
        %% because the Host header would then be 127.0.0.1:PORT and the edge
        %% would answer 404 before TLS was ever the reason.
        shl(['openssl req -x509 -newkey rsa:2048 -nodes -keyout ', D, '/other.pem -out ', D, '/other.crt -days 2 -subj ''/CN=other.invalid'' -addext ''subjectAltName=DNS:other.invalid'' >/dev/null 2>&1']),
        shl(['cat ', D, '/other.pem ', D, '/other.crt > ', D, '/other-full.pem']),
        sh_join([D, '/other-full.pem'], OtherFull),
        edge(D, 18444, 'localhost:18444', Zeytun, 'hosts-bad.log', OtherFull, 'edge-bad', Pid2, _),
        cocolog(C),
        sh_join([C, ' --host localhost --https 18444 --cacert ', D, '/other.crt --kb tunnel_test query ''edge_fact(X)'' 2>&1 >/dev/null | grep -c ''hostname mismatch'''], Cmd6),
        shell(Cmd6, G6, _),
        check('a name the certificate does not carry is refused', G6, '2'),
        %% AND THE REFUSAL IS VISIBLE, which is the half that was missing. A
        %% failed fetch used to go into the store and answer 0, which the
        %% engine reads as "no clauses" -- so an unreachable edge, a refused
        %% certificate and an empty knowledge base were all
        %% `existence_error(procedure, ...)'.
        sh_join(['--host localhost --https 18444 --cacert ', D, '/other.crt --kb tunnel_test query ''edge_fact(X)'''], A7),
        first_err(A7, G7),
        check('and names the server it was refused by', G7,
              'cocolog: Zeytun at localhost:18444 -- fetching clauses: the server''s certificate was refused: hostname mismatch'),
        proc_stop(Pid2)
    ;   format("     (skipped: https -- no openssl to make a certificate with)~n", [])
    ).

port_80(D, Zeytun) :-
    section('port 80: the Host is the bare hostname, as an edge registers it'),
    edge(D, 80, localhost, Zeytun, 'hosts-80.log', '', 'edge-80', Pid, Said),
    (   Said == cannot_bind
    ->  format("     (skipped: port 80 -- cannot bind without privilege)~n", []),
        proc_stop(Pid)
    ;   first_out('--host localhost --http 80 --kb tunnel_test query ''edge_fact(X)''', G1),
        check('the same query on port 80', G1, '  1. edge_fact(routed)'),
        hosts_seen(D, 'hosts-80.log', G2),
        check('on the default port, Host is the bare name', G2, 'localhost '),
        proc_stop(Pid)
    ).
